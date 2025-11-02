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
class ExplanationOutput(BaseModel):
    query_purpose: str = Field(..., description="A short, clear summary of what the SQL query is doing.")
    data_insights: str = Field(..., description="Key findings, insights, or observations from the result sample.")
    summary: str = Field(..., description="A concise overall summary suitable for end users.")


# ------------------------------------------------------------
# 🧠 Explainability Node
# ------------------------------------------------------------
async def explainability_node(state: GlobalState) -> GlobalState:
    """
    Explainability Agent:
    - Explains what the SQL query does and summarizes its results.
    - Returns structured natural language outputs using Pydantic parsing.
    """

    sql_query = state.get("validated_sql") or state.get("generated_sql")
    execution_result = state.get("execution_result", {})

    if not sql_query:
        raise ValueError("Missing SQL to explain.")
    if not execution_result:
        raise ValueError("Missing execution results to explain.")

    logging.info("🧠 Generating structured natural language explanation for SQL and results...")

    # Use only top 5 rows to keep context compact
    sample_rows = execution_result.get("rows", [])[:5]

    # --- Prompt setup ---
    parser = PydanticOutputParser(pydantic_object=ExplanationOutput)

    explain_prompt = ChatPromptTemplate.from_messages([
        (
            "system",
            """You are a senior data analyst who explains SQL queries and their results in simple, clear language.
Return your response strictly in JSON format according to the following structure:
{format_instructions}

Guidelines:
- Be precise but simple.
- Avoid technical SQL jargon.
- Include both what the query does and what the results imply."""
        ),
        (
            "human",
            "SQL Query:\n{sql_query}\n\n"
            "Sample Query Results (first 5 rows):\n{sample_rows}"
        ),
    ])

    chain = explain_prompt | llm | parser

    try:
        result: ExplanationOutput = await chain.ainvoke({
            "sql_query": sql_query,
            "sample_rows": sample_rows,
            "format_instructions": parser.get_format_instructions(),
        })

        explanation_text = (
            f"### 🧩 What the Query Does:\n{result.query_purpose}\n\n"
            f"### 📊 Key Insights:\n{result.data_insights}\n\n"
            f"### 📝 Summary:\n{result.summary}"
        )

    except Exception as e:
        logging.error(f"⚠️ Failed to generate structured explanation: {e}")
        explanation_text = f"Error generating structured explanation: {str(e)}"

    # ---- Record History ----
    explanation_history = state.get("explanation_history", [])
    explanation_history.append({
        "time": datetime.utcnow().isoformat(),
        "sql": sql_query,
        "rows_used": len(sample_rows),
        "explanation": explanation_text
    })

    # ---- Update GlobalState ----
    new_state = state.copy()
    new_state.update({
        "natural_language_explanation": explanation_text,
        "explanation_history": explanation_history,
        "status": "explained"
    })

    logging.info("✅ Structured explainability successfully generated.")
    return new_state
