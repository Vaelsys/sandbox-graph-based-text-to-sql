import asyncio
import json
from datetime import date, datetime
from decimal import Decimal
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse

from app.graph.text_to_sql_graph import build_text_to_sql_graph
from app.state.agent_state import GlobalState

router = APIRouter()


def _json_default(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    return str(obj)


def format_agent_update(node_name: str, state: GlobalState) -> dict:
    """Generate structured agent update messages."""
    msg = ""

    if node_name == "query_rewriter_node":
        msg = (
            f"🔁 Rewriting query...\n✅ Rewritten: {state.get('rewritten_query', 'N/A')}\n"
            f"💡 {state.get('rewrite_explanation', '')}"
        )

    elif node_name == "schema_agent_node":
        tables = state.get("relevant_tables", [])
        msg = f"📚 Schema retrieved.\n✅ Relevant tables: {', '.join(tables) or 'N/A'}"

    elif node_name == "query_generation_node":
        sql = state.get("generated_sql", "")
        msg = f"🧮 Generated SQL:\n{sql}"

    elif node_name == "validation_node":
        passed = state.get("validation_passed", False)
        msg = "🧩 SQL validation " + ("✅ passed." if passed else "❌ failed.")

    elif node_name == "query_execution_node":
        result = state.get("execution_result", {})
        row_count = len(result.get("rows", []))
        msg = f"⚙️ Executed query.\n✅ Rows returned: {row_count}"

    elif node_name == "explainability_node":
        msg = f"💡 Explanation:\n{state.get('natural_language_explanation', '')}"

    elif node_name == "supervisor_agent_node":
        msg = f"🧭 Supervisor decided next step: {state.get('next_action', '')}"

    else:
        msg = f"🧠 Processing node: {node_name}"

    # Return structured payload
    return {
        "stage": node_name,
        "message": msg,
        "state": {
            "generated_sql": state.get("generated_sql"),
            "execution_result": state.get("execution_result"),
            "natural_language_explanation": state.get("natural_language_explanation"),
            "status": state.get("status"),
        },
    }


@router.post("/query/stream")
async def query_stream(request: Request):
    """Stream Text-to-SQL LangGraph pipeline progress."""
    payload = await request.json()
    user_query = payload.get("query", "")
    session_id = payload.get("session_id", "demo_session")

    async def event_stream():
        # Initial status
        #yield json.dumps({"event": "start", "message": "🚀 Running multi-agent pipeline..."}) + "\n"

        # Initialize global state
        state = GlobalState(
            user_id="demo_user",
            session_id=session_id,
            original_query=user_query,
            logs=[],
        )

        # Build LangGraph
        graph = build_text_to_sql_graph()

        # Stream through agents
        async for event in graph.astream(state, config={"configurable": {"thread_id": session_id}}):
            if not isinstance(event, dict):
                continue

            for node_name, node_output in event.items():
                state.update(node_output)

                update = format_agent_update(node_name, state)
                yield json.dumps(update, default=_json_default) + "\n"
                await asyncio.sleep(0.3)

        # Final result message
        final_rows = state.get("execution_result", {}).get("rows", [])
        if final_rows:
            yield json.dumps({
                "event": "complete",
                "message": "✅ All agents completed successfully!",
                "rows": final_rows,
                "explanation": state.get("natural_language_explanation", "")
            }, default=_json_default) + "\n"
        else:
            yield json.dumps({
                "event": "complete",
                "message": "⚠️ All agents finished but no data was returned.",
                "rows": [],
                "explanation": state.get("natural_language_explanation", "")
            }, default=_json_default) + "\n"

    return StreamingResponse(event_stream(), media_type="application/json")
