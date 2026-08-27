---
name: unslop
description: Cut AI tells from PR bodies, docs, skill text, and other user-facing prose. Use when writing those. Not required before ordinary code edits.
disable-model-invocation: true
---

# Unslop

Rewrite so it sounds like a person. Keep meaning. Drop the costume.

## Process

1. Scan for the patterns below.
2. Rewrite.
3. Ask: "What still looks generated?" Fix that.

## Cut

- Chatbot: "I hope this helps", "Great question!", "Certainly!", "Let me know if…"
- Puffery: pivotal, testament, landscape, delve, leverage, utilize, seamless, robust, groundbreaking
- "Not just X, but Y." Replace "in order to" with "to". Delete "it is important to note"
- Bold on every noun. Emoji in headings. Use sentence case for headings
- Em dashes. Prefer a sentence, comma, colon, or parentheses
- Synonym cycling (three names for the same thing). Pick one word
- Generic closer: "The future looks bright." End on the fact or the next step
- Comments that narrate syntax. Keep only decisions, invariants, constraints,
  and non-obvious trade-offs

## Keep

- Opinions when you have them
- Short sentences mixed with longer ones
- Specific names, paths, commands, numbers
- "I" when it is you talking

If a sentence could be pasted into another repo unchanged, it says nothing. Cut it.
