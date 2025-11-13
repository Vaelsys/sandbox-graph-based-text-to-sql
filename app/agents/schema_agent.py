import logging, os, json
from langchain_chroma import Chroma
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

from app.config import embeddings, llm
from app.state.agent_state import GlobalState
from app.utils import extract_schema_from_db, BASE_DIR

# ------------------------------------------------------------
# Paths & Caching
# ------------------------------------------------------------
CHROMA_PATH = os.path.join(BASE_DIR, "chroma_schema_index")
_vectorstore = None


# ------------------------------------------------------------
# Pydantic Structured Schema Summary
# ------------------------------------------------------------
class SchemaSummary(BaseModel):
    key_tables: list[str] = Field(..., description="List of the most relevant tables for this query.")
    key_columns: list[str] = Field(..., description="Important columns mentioned or implied by the query.")
    relationships: str = Field(..., description="How the tables are related or joined.")
    summary_text: str = Field(..., description="A concise human-readable summary of schema relevance.")


# ------------------------------------------------------------
# Helper to (Re)Build Schema Index
# ------------------------------------------------------------
def build_schema_index(schema_docs):
    """Creates and persists a Chroma vector index for schema documents."""
    if not schema_docs:
        raise ValueError("No schema documents to index.")
    logging.info(f"🔧 Building Chroma index for {len(schema_docs)} schema docs...")
    vectorstore = Chroma.from_documents(
        documents=schema_docs,
        embedding=embeddings,
        persist_directory=CHROMA_PATH,
    )
    logging.info("✅ Schema index built and persisted.")
    return vectorstore


# ------------------------------------------------------------
# Schema Agent Node
# ------------------------------------------------------------
async def schema_agent_node(state: GlobalState) -> GlobalState:
    """
    Schema Agent:
    - Retrieves the most relevant schema context from Chroma.
    - Summarizes it with the LLM into structured schema info.
    """

    global _vectorstore
    query = state.get("rewritten_query") or state.get("original_query")

    if not query:
        raise ValueError("Missing rewritten_query or original_query in GlobalState")

    # Load or rebuild Chroma index
    if _vectorstore is None:
        logging.info("📦 Loading Chroma index...")
        try:
            _vectorstore = Chroma(
                persist_directory=CHROMA_PATH,
                embedding_function=embeddings,
            )
            if _vectorstore._collection.count() == 0:
                raise ValueError("Empty Chroma index; rebuilding...")
        except Exception as e:
            logging.warning(f"⚠️ Rebuilding Chroma index due to: {e}")
            schema_docs = extract_schema_from_db()
            _vectorstore = build_schema_index(schema_docs)

    # Retrieve relevant schema documents
    retriever = _vectorstore.as_retriever(search_kwargs={"k": 3})
    results = retriever.invoke(query)

    # ---- Normalize metadata + build schema context ----
    rag_docs = []
    for doc in results:
        table_name = (
            doc.metadata.get("table_name")
            or doc.metadata.get("source")
            or "unknown"
        )
        # Normalize metadata
        rag_docs.append({
            "text": doc.page_content,
            "metadata": {"table_name": table_name}
        })

    # ✅ Dynamically sync relevant tables with normalized RAG docs
    relevant_tables = [doc["metadata"]["table_name"] for doc in rag_docs]
    schema_context = "\n".join([doc["text"] for doc in rag_docs])

    logging.info(f"📚 Retrieved schema context from {len(results)} docs: {relevant_tables}")

    # --- Structured schema summarization via LLM ---
    parser = PydanticOutputParser(pydantic_object=SchemaSummary)

    schema_prompt = ChatPromptTemplate.from_messages([
        (
            "system",
            "You are a database schema summarizer. Summarize key tables, columns, and relationships.\n"
            "Return your output in strict JSON according to this format:\n{format_instructions}",
        ),
        (
            "human",
            "User Query:\n{query}\n\nSchema Context:\n{schema_context}",
        ),
    ])

    chain = schema_prompt | llm | parser

    try:
        summary: SchemaSummary = await chain.ainvoke({
            "query": query,
            "schema_context": schema_context,
            "format_instructions": parser.get_format_instructions(),
        })
        schema_summary_text = summary.summary_text.strip()
    except Exception as e:
        logging.error(f"⚠️ Schema summarization failed: {e}")
        summary = None
        schema_summary_text = f"Error generating schema summary: {str(e)}"

    # ---- Update GlobalState ----
    new_state = state.copy()
    new_state.update({
        "schema_context": schema_context,
        "relevant_tables": relevant_tables,
        "rag_docs": rag_docs,
        "schema_summary": schema_summary_text,
        "structured_schema": summary.dict() if summary else {},
        "status": "schema_retrieved",
    })

    logging.info("✅ Schema Agent successfully retrieved and summarized schema.")
    return new_state
