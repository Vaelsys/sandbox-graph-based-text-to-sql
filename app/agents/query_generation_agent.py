import logging
from datetime import datetime

from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

from app.config import llm
from app.state.agent_state import GlobalState


# ------------------------------------------------------------
# 🧩 Structured Output Schema
# ------------------------------------------------------------
class SQLGenerationOutput(BaseModel):
    sql: str = Field(..., description="A valid SQLite-compatible SELECT query.")
    explanation: str = Field(..., description="Short reasoning behind how the SQL answers the query.")


# ------------------------------------------------------------
# 🧠 Prompt Template
# ------------------------------------------------------------
generation_prompt = ChatPromptTemplate.from_messages([
    (
        "system",
        """You are an expert SQL engineer.
Convert the natural language question into a **valid SQLite SELECT query** based on the schema.

Guidelines:
- Use table and column names exactly as provided.
- Never modify schema names or add imaginary columns.
- Only produce SELECT queries (read-only).
- If a filter involves a year, use: STRFTIME('%Y', <date_column>) = 'YYYY'
- Return output ONLY in JSON format as follows:
{format_instructions}
"""
    ),
    (
        "human",
        "Schema Context:\n{schema_context}\n\n"
        "Schema Summary:\n{schema_summary}\n\n"
        "User Query:\n{query}"
    ),
])


# ------------------------------------------------------------
# 🚀 Query Generation Node
# ------------------------------------------------------------
async def query_generation_node(state: GlobalState) -> GlobalState:
    """
    Query Generation Agent (structured output version)
    - Generates SQL + explanation with enforced schema.
    - Uses Pydantic parsing to avoid malformed responses.
    """
    query = state.get("rewritten_query") or state.get("original_query")
    schema_context = state.get("schema_context", "")
    schema_summary = state.get("schema_summary", "")

    if not query or not schema_context:
        raise ValueError("Missing rewritten_query or schema_context in GlobalState")

    logging.info("🧮 Generating SQL using structured output parser...")

    parser = PydanticOutputParser(pydantic_object=SQLGenerationOutput)
    chain = generation_prompt | llm | parser

    try:
        result: SQLGenerationOutput = await chain.ainvoke({
            "query": query,
            "schema_context": schema_context,
            "schema_summary": schema_summary,
            "format_instructions": parser.get_format_instructions(),
        })

        sql_query = result.sql.strip()
        explanation = result.explanation.strip()

    except Exception as e:
        logging.error(f"⚠️ SQL parsing or model error: {e}")
        # fallback
        sql_query = "SELECT 'Error generating SQL' AS error;"
        explanation = f"Parser failed: {e}"

    # ✅ Safety checks
    if not sql_query.lower().startswith("select"):
        logging.warning("⚠️ Non-select SQL detected; forcing read-only mode.")
        sql_query = "SELECT " + sql_query

    if not sql_query.endswith(";"):
        sql_query += ";"

    # --- Update history ---
    history = state.get("generation_history", [])
    history.append({
        "time": datetime.utcnow().isoformat(),
        "model": getattr(llm, "model", "unknown"),
        "input_query": query,
        "output_sql": sql_query,
        "explanation": explanation,
    })

    new_state = state.copy()
    new_state.update({
        "generated_sql": sql_query,
        "sql_explanation": explanation,
        "generation_history": history,
        "status": "sql_generated",
    })

    logging.info(f"✅ Structured SQL generated:\n{sql_query}")
    return new_state
