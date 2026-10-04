"""Remove personal and instance-specific fields from an n8n CLI export, then pretty-print it."""
import json
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "n8n" / "KPI Report.json"
DROP = ["shared", "createdAt", "updatedAt", "versionCounter", "versionId",
        "activeVersionId", "triggerCount", "sourceWorkflowId", "staticData", "versionMetadata"]

data = json.loads(PATH.read_text(encoding="utf-8"))
workflows = data if isinstance(data, list) else [data]
for wf in workflows:
    for key in DROP:
        wf.pop(key, None)

PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("Workflows:", len(workflows))
print("Nodes:", ascii([n["name"] for n in workflows[0]["nodes"]]))