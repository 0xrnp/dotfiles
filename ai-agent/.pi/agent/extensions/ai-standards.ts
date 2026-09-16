import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Permission = "allow" | "ask" | "deny";

interface HookDecision {
	permission: Permission;
	message: string;
}

const HOOK_DIR = join(homedir(), ".cursor", "hooks");
const HOOK_TIMEOUT_MS = 5_000;
const LOCAL_TOOLS = new Set(["apply_patch", "cursor", "edit", "find", "grep", "ls", "read", "write"]);
const MUTATING_NAME = /(?:^|[_:.-])(auth|create|delete|deploy|drop|execute|insert|patch|post|publish|put|remove|send|update|write)(?:$|[_:.-])/i;

function runHook(name: string, payload: object): Promise<HookDecision> {
	return new Promise((resolve) => {
		let finished = false;
		let output = "";
		let errorOutput = "";
		const child = spawn(join(HOOK_DIR, name), [], {
			stdio: ["pipe", "pipe", "pipe"],
		});
		const finish = (decision: HookDecision) => {
			if (finished) return;
			finished = true;
			clearTimeout(timeout);
			resolve(decision);
		};
		const deny = (message: string) => finish({ permission: "deny", message });
		const timeout = setTimeout(() => {
			child.kill();
			deny("Personal safety hook timed out.");
		}, HOOK_TIMEOUT_MS);

		child.stdout?.setEncoding("utf8");
		child.stdout?.on("data", (chunk: string) => { output += chunk; });
		child.stderr?.setEncoding("utf8");
		child.stderr?.on("data", (chunk: string) => { errorOutput += chunk; });
		child.on("error", (error) => deny(`Personal safety hook failed: ${error.message}`));
		child.stdin?.on("error", (error) => deny(`Personal safety hook input failed: ${error.message}`));
		child.on("close", (code) => {
			if (code !== 0) {
				deny(errorOutput.trim() || `Personal safety hook exited with status ${code ?? "unknown"}.`);
				return;
			}
			try {
				const value: unknown = JSON.parse(output);
				if (!value || typeof value !== "object" || !("permission" in value)) {
					deny("Personal safety hook returned an invalid decision.");
					return;
				}
				const result = value as Record<string, unknown>;
				const permission = result.permission;
				if (permission !== "allow" && permission !== "ask" && permission !== "deny") {
					deny("Personal safety hook returned an invalid permission.");
					return;
				}
				const message = typeof result.user_message === "string"
					? result.user_message
					: typeof result.agent_message === "string"
						? result.agent_message
						: "Review this action before continuing.";
				finish({ permission, message });
			} catch {
				deny("Personal safety hook returned invalid JSON.");
			}
		});
		child.stdin?.end(JSON.stringify(payload));
	});
}

export default function aiStandards(pi: ExtensionAPI): void {
	pi.on("tool_call", async (event, ctx) => {
		let decision: HookDecision;
		if (event.toolName === "bash" || event.toolName === "powershell") {
			const command = event.input.command;
			if (typeof command !== "string") {
				return { block: true, reason: "Shell tool has no valid command." };
			}
			decision = await runHook("gate-shell.sh", { command });
		} else if (LOCAL_TOOLS.has(event.toolName)) {
			// Local edits are authorized by the change request. Cursor SDK
			// native tools still pass through Cursor's own safety hooks.
			return undefined;
		} else if (
			event.toolName.startsWith("mcp:") ||
			event.toolName.startsWith("mcp__") ||
			MUTATING_NAME.test(event.toolName)
		) {
			decision = await runHook("gate-mcp.sh", { tool_name: event.toolName });
		} else {
			return undefined;
		}

		if (decision.permission === "allow") return undefined;
		if (decision.permission === "deny") {
			return { block: true, reason: decision.message };
		}
		if (!ctx.hasUI) {
			return { block: true, reason: `${decision.message} No UI is available for confirmation.` };
		}
		const confirmed = await ctx.ui.confirm("Allow sensitive action?", decision.message);
		return confirmed ? undefined : { block: true, reason: "Blocked by user." };
	});
}
