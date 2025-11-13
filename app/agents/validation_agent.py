import logging
import re
from datetime import datetime
from app.state.agent_state import GlobalState
from app.utils import get_db_connection


async def validation_node(state: GlobalState) -> GlobalState:
    """
    Validation Agent (Enhanced):
    ✅ Cleans and validates SQL.
    ✅ Ensures it's read-only and syntactically valid.
    ✅ Logs detailed, user-friendly explanations.
    """

    sql_query = (state.get("generated_sql") or "").strip()
    if not sql_query:
        raise ValueError("No SQL found in state to validate")

    logging.info("🧩 Validating generated SQL for safety and syntax correctness...")

    # --- 1️⃣ Clean minor noise (LLM leftovers) ---
    sql_query = re.sub(r"```(?:sql)?|```", "", sql_query).strip()
    sql_query = re.sub(r"^\{+|\}+$", "", sql_query).strip()

    # --- 2️⃣ Security Validation (read-only enforcement) ---
    forbidden_keywords = ["delete", "drop", "update", "insert", "alter", "truncate"]
    lower_sql = sql_query.lower()

    for keyword in forbidden_keywords:
        if re.search(rf"\b{keyword}\b", lower_sql):
            explanation = f"❌ Unsafe SQL detected (contains '{keyword.upper()}'). Only SELECT queries are allowed."
            logging.warning(explanation)
            new_state = state.copy()
            new_state.update({
                "validation_passed": False,
                "validation_explanation": explanation,
                "status": "validation_failed"
            })
            return new_state

    if not lower_sql.startswith("select"):
        explanation = "❌ Only SELECT statements are permitted. This query is not read-only."
        logging.warning(explanation)
        new_state = state.copy()
        new_state.update({
            "validation_passed": False,
            "validation_explanation": explanation,
            "status": "validation_failed"
        })
        return new_state

    # --- 3️⃣ Syntax Validation (Dry Run) ---
    validation_passed = True
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # PostgreSQL EXPLAIN checks syntax and generates a plan without executing
                cursor.execute(f"EXPLAIN {sql_query}")
        explanation = "✅ SQL syntax is valid and query is read-only."

    except Exception as e:
        validation_passed = False
        msg = str(e)
        # Be nice to users in logs
        if "no such table" in msg:
            explanation = "⚠️ SQL syntax looks fine, but referenced tables may not exist in this environment."
        else:
            explanation = f"❌ SQL validation failed: {msg}"
        logging.error(explanation)

    # --- 4️⃣ Record History ---
    validation_history = state.get("validation_history", [])
    validation_history.append({
        "time": datetime.utcnow().isoformat(),
        "sql": sql_query,
        "passed": validation_passed,
        "explanation": explanation
    })

    # --- 5️⃣ Update Global State ---
    new_state = state.copy()
    new_state.update({
        "generated_sql": sql_query,
        "validation_passed": validation_passed,
        "validation_explanation": explanation,
        "validation_history": validation_history,
        "status": "validated" if validation_passed else "validation_failed"
    })

    if validation_passed:
        logging.info("✅ SQL validation passed.")
    else:
        logging.warning("⚠️ SQL validation failed.")

    return new_state
