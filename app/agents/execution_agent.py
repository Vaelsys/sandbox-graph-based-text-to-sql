import time
import logging
from datetime import datetime
from urllib.parse import urlsplit, urlunsplit

from psycopg.rows import dict_row  # type: ignore[import]

from app.state.agent_state import GlobalState
from app.utils import DATABASE_URL, get_db_connection


def _mask_database_url(database_url: str | None) -> str:
    if not database_url:
        return ""
    parts = urlsplit(database_url)
    host = parts.hostname or ""
    if parts.port:
        host = f"{host}:{parts.port}"
    return urlunsplit((parts.scheme, host, parts.path, parts.query, parts.fragment))


def execute_sql_on_replica(sql_query: str, database_url: str | None = None):
    """
    Executes a SQL query safely on a PostgreSQL DB.
    Returns columns, rows, and metadata.
    """
    try:
        with get_db_connection(database_url, row_factory=dict_row) as conn:
            with conn.cursor() as cursor:
                start = time.time()
                cursor.execute(sql_query)
                rows = cursor.fetchall()
                execution_time = round(time.time() - start, 4)

                # Extract column names
                columns = [desc.name for desc in cursor.description] if cursor.description else []

        return {
            "success": True,
            "columns": columns,
            "rows": rows,
            "row_count": len(rows),
            "execution_time": execution_time,
            "error": None
        }

    except Exception as e:
        logging.error(f"⚠️ SQL execution failed: {e}")
        return {
            "success": False,
            "columns": [],
            "rows": [],
            "row_count": 0,
            "execution_time": 0,
            "error": str(e)
        }


async def query_execution_node(state: GlobalState) -> GlobalState:
    """
    Execution Agent:
    - Runs validated SQL against replica DB.
    - Updates GlobalState with query results.
    """
    sql_query = state.get("validated_sql") or state.get("generated_sql")

    if not sql_query:
        raise ValueError("Missing validated_sql or generated_sql in GlobalState")

    logging.info(f"🚀 Executing SQL on replica: {sql_query}")

    result = execute_sql_on_replica(sql_query, DATABASE_URL)

    # ---- Update History ----
    execution_history = state.get("execution_history", [])
    execution_history.append({
        "time": datetime.utcnow().isoformat(),
        "query": sql_query,
        "db_url": _mask_database_url(DATABASE_URL),
        "success": result["success"],
        "row_count": result["row_count"],
        "execution_time": result["execution_time"],
        "error": result["error"]
    })

    new_state = state.copy()
    new_state.update({
        "execution_result": result,
        "execution_history": execution_history,
        "status": "query_executed" if result["success"] else "execution_failed"
    })

    if result["success"]:
        logging.info(f"✅ Query executed successfully — {result['row_count']} rows in {result['execution_time']}s")
    else:
        logging.warning(f"⚠️ Query execution failed: {result['error']}")

    return new_state
