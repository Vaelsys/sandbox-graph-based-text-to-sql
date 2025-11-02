import logging
from datetime import datetime

from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

from app.state.agent_state import GlobalState
from app.config import llm


# ------------------------------------------------------------
# 🧩 Define structured output model
# ------------------------------------------------------------
class QueryRewriteOutput(BaseModel):
    rewritten_query: str = Field(..., description="Rewritten SQL-friendly version of the query.")
    explanation: str = Field(..., description="Explanation of how and why the query was rewritten.")
    metadata: dict = Field(default_factory=dict, description="Optional metadata or notes.")


# ------------------------------------------------------------
# 🧠 Define prompt
# ------------------------------------------------------------
rewriter_prompt = ChatPromptTemplate.from_messages([
    (
        "system",
        """You are an expert query rewriter for a Text-to-SQL assistant.
Your job is to rewrite user natural-language queries into SQL-friendly questions.

Guidelines:
- Keep the user's original intent intact.
- Be explicit about filters, aggregations, or date ranges.
- If needed, use placeholders like <DATE_RANGE>.
- Respond ONLY in structured JSON as instructed below.

{format_instructions}
"""
    ),
    (
        "human",
        "Original user question: \"{query}\""
    ),
])


# ------------------------------------------------------------
# 🚀 Query Rewriter Node
# ------------------------------------------------------------
async def query_rewriter_node(state: GlobalState) -> GlobalState:
    """Query Rewriter Agent (safe structured version)."""
    query = state.get("original_query", "").strip()
    if not query:
        raise ValueError("Missing 'original_query' in GlobalState")

    logging.info("🔁 Rewriting user query...")

    # Setup structured parser
    parser = PydanticOutputParser(pydantic_object=QueryRewriteOutput)

    # Build chain
    chain = rewriter_prompt | llm | parser

    try:
        result: QueryRewriteOutput = await chain.ainvoke({
            "query": query,
            "format_instructions": parser.get_format_instructions(),
        })
    except Exception as e:
        logging.error(f"⚠️ Parsing or LLM error: {e}")
        # Fallback to raw LLM result if parser fails
        result = QueryRewriteOutput(
            rewritten_query=query,
            explanation=f"Parser failed — returning original query. ({e})",
            metadata={}
        )

    # Update history
    history = state.get("rewrite_history", [])
    history.append({
        "time": datetime.utcnow().isoformat(),
        "model": getattr(llm, "model", "unknown"),
        "input": query,
        "output": result.rewritten_query,
        "explanation": result.explanation,
        "metadata": result.metadata,
    })

    # Build new state
    new_state = state.copy()
    new_state.update({
        "rewritten_query": result.rewritten_query,
        "rewrite_explanation": result.explanation,
        "rewrite_metadata": result.metadata,
        "rewrite_history": history,
        "status": "query_rewritten",
    })

    logging.info(f"✅ Query rewritten: {result.rewritten_query}")
    return new_state
