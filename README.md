# AI-Powered Supply Chain Analytics & Automation
Work in progress.


## AI insight layer (mock mode)

The n8n workflow builds a payload from validated KPIs, exceptions and monthly delay rates. A summary is created from that payload and verified by a code checker (`n8n/ai_check.js`). Numbers not found in the payload and unsupported causal wording are rejected, and a rejected text is never stored.

**The summary step is a fixed template, not an AI model.** No AI call was run and no API key was used. A real model can replace the template, and the same checker would verify its output.

Details, tests and limits: `docs/ai_layer.md`. Prompt: `docs/ai_prompt.md`.