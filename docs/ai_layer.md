# AI-Output Verification Layer (Phase 9)

Status: no model is connected. The summary step is a template.

## Status
- **The AI node is a MOCK.** `Mock AI` is a fixed template filled from payload values. It is not AI, and no AI model has generated any stored text.
- **Real model call: NOT TESTED.** No provider or API key has been set up.

## Purpose and rules
The AI layer is an interpretation layer, never the source of truth (PRD section 11). It may only use values supplied in the payload. Every output goes through a code check, and no numeric claim is trusted without it. Prompt: `docs/ai_prompt.md`.

## Flow
Build Report -> Log Run (inserts the KPI row with `ai_status = skipped`) -> Build AI Input -> Mock AI -> Check AI Output -> Log AI Result (updates the same row).
If the AI branch fails after Log Run, the KPI row stays logged as `skipped`. A rejected text is never stored, only the rejection reason.

## Payload (built in code by `Build AI Input`)
Fields: `kpis`, `exceptions`, `exception_rule`, `monthly` (latest 7 months), `material_change`, `material_change_rule`, `data_limits`.
Before slicing to 7 months, the node checks that monthly totals match the KPI totals (eligible 62,897, late 36,048) and throws an error if not.

## Documented decisions (choices, not findings)
- Material change: latest month's delay rate compared with the mean of the previous 6 months, flagged when the difference is at least 2.0 percentage points.
- Window: latest 7 months.
- Exception: a shipping mode whose delay rate is above the overall rate and that has at least 500 eligible orders.

## Checker rules (`n8n/ai_check.js`)
- Every number in the AI text must equal a numeric value found anywhere in the payload (thousands commas, trailing `%` and leading `+` are removed first). Rounded or derived numbers are rejected.
- List markers like `1)` at line start are ignored.
- Causal phrases are rejected outside "Questions for investigation": because, due to, caused by, driven by, as a result of, leads to, reason is.
- All five headings must exist.
- The copy inside the `Check AI Output` node must stay in sync with `n8n/ai_check.js`. It adds a try/catch wrapper, so it is not byte-identical, and there is no automated sync test.

## Tests run
**Checker unit tests** (`node n8n\ai_check.test.js`): 8 tests, all passed. They cover: good text, invented number, invented cause, missing section, "9,602" matching 9602, empty exceptions, sentence-final invented number, and numbers inside payload strings.
Tests 7 and 8 were added after a code review found that numbers at the end of a sentence were skipped. The failing run before the fix was not observed.

**Workflow tests** (rows in `analytics.report_log`):
| Run | Test | Result |
|---|---|---|
| 10 | Normal run with mock | `mock`, summary stored |
| 11 | Attempted invented-number test | Edit had not saved, so it logged `mock`. Not a valid test. |
| 12 | Invented number (`58%`) | `rejected`, summary NULL, reason `Invented or unsupported number: 58%` |
| 13 | Invented cause (`because`) | `rejected`, summary NULL, reason names the `because` pattern |
| 14 | Real mock restored | `mock`, summary stored |

## NOT TESTED
- A real AI model call and its output.
- The `skipped` path (an error in the AI branch after Log Run).
- The reconciliation error in `Build AI Input`.
- The "No exceptions found." fallback in `Mock AI`, run inside the workflow (the checker unit test covers only the checker).
- Checker cases: leading `+`, decimals such as 57.3, causal words inside the Questions section.

## Limits
- The checker allows a number if it appears anywhere in the payload. It does not check that the number is used in the right context.
- It checks numbers and causal words, not whether the wording is true.
- Shipping-mode delay patterns are unusually uniform and may reflect how the dataset was built. They are not proven operational findings.
- `Merge` has no downstream node. `Build AI Input` reads the earlier nodes by name.
- The log contains development test runs.