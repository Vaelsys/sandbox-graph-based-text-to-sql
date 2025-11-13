import os
from typing import Optional

import psycopg
from psycopg.rows import dict_row
from langchain_core.documents import Document


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # points to project root
DATABASE_URL = os.getenv("DATABASE_URL")
DB_SCHEMA = os.getenv("DB_SCHEMA", "public")


def _require_database_url(database_url: Optional[str]) -> str:
    if not database_url:
        raise RuntimeError(
            "DATABASE_URL is not configured. Set the DATABASE_URL environment variable "
            "to a PostgreSQL connection string (e.g. postgresql://user:pass@host:5432/dbname)."
        )
    return database_url


def get_db_connection(database_url: Optional[str] = None, **kwargs):
    """
    Return a new psycopg connection to the configured PostgreSQL database.
    """
    url = _require_database_url(database_url or DATABASE_URL)
    return psycopg.connect(url, **kwargs)


def extract_schema_from_db(database_url: Optional[str] = None, schema: Optional[str] = None):
    """
    Extract the PostgreSQL schema and return a list of LangChain Documents.
    Each Document contains:
      - page_content: table definition (name + columns)
      - metadata: { 'source': <table_name> }
    """
    url = _require_database_url(database_url or DATABASE_URL)
    target_schema = schema or DB_SCHEMA

    docs = []

    with psycopg.connect(url) as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = %s
                  AND table_type = 'BASE TABLE'
                ORDER BY table_name;
                """,
                (target_schema,),
            )
            tables = cursor.fetchall()

            if not tables:
                print(f"⚠️ No tables found in schema '{target_schema}'.")
                return docs

            for row in tables:
                table_name = row["table_name"]
                cursor.execute(
                    """
                    SELECT column_name, data_type, is_nullable
                    FROM information_schema.columns
                    WHERE table_schema = %s
                      AND table_name = %s
                    ORDER BY ordinal_position;
                    """,
                    (target_schema, table_name),
                )
                columns = cursor.fetchall()
                if not columns:
                    continue

                col_defs = [
                    f"{col['column_name']} ({col['data_type']})"
                    + (" NOT NULL" if col["is_nullable"] == "NO" else "")
                    for col in columns
                ]
                schema_text = f"Table: {table_name}\nColumns:\n" + "\n".join(col_defs)
                docs.append(Document(page_content=schema_text, metadata={"source": table_name}))

    print(f"✅ Extracted schema for {len(docs)} tables from schema '{target_schema}'.")
    return docs


if __name__ == "__main__":
    docs = extract_schema_from_db()
    print(len(docs))
    for d in docs:
        print(d.page_content)