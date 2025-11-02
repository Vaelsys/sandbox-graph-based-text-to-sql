import streamlit as st
import requests
import json
import pandas as pd

st.set_page_config(page_title="Text-to-SQL Multi-Agent", page_icon="🧠", layout="wide")
st.title("🧠 Text-to-SQL Multi-Agent System")

# --- Input Section ---
query = st.text_input("Enter your natural language query:")
run_button = st.button("Run Query")

if run_button and query:
    url = "http://localhost:8000/query/stream"

    # Streamlit placeholders for dynamic updates
    progress_placeholder = st.empty()
    sql_placeholder = st.empty()
    result_placeholder = st.empty()
    insight_placeholder = st.empty()

    # Hold data as pipeline progresses
    sql_text = ""
    explanation_text = ""
    result_df = None
    stream_output = ""

    with requests.post(url, json={"query": query, "session_id": "demo_session"}, stream=True) as response:
        for line in response.iter_lines():
            if not line:
                continue

            try:
                data = json.loads(line.decode("utf-8"))
            except json.JSONDecodeError:
                continue

            message = data.get("message", "")
            event = data.get("event", "")
            stage = data.get("stage", "")
            state = data.get("state", {})

            # --- Format step titles cleanly ---
            if stage:
                title = stage.replace("_node", "").replace("_agent", "").replace("_", " ").title()
                stream_output += f"\n\n### {title}\n{message}"
            else:
                stream_output += f"\n{message}"

            progress_placeholder.markdown(stream_output)

            # --- Capture SQL if available ---
            if "generated_sql" in state and state["generated_sql"]:
                sql_text = state["generated_sql"]

            # --- Capture query results ---
            if "execution_result" in state:
                exec_result = state["execution_result"]
                if exec_result and "rows" in exec_result and exec_result["rows"]:
                    result_df = pd.DataFrame(exec_result["rows"], columns=exec_result.get("columns", []))

            # --- Capture explanation ---
            if "natural_language_explanation" in state:
                explanation_text = state["natural_language_explanation"]

            # --- Final completion ---
            if event == "end":
                st.success("✅ All agents completed successfully.")
                break

    # --- Final Output Display ---
    if sql_text:
        st.subheader("🧮 Generated SQL")
        st.code(sql_text, language="sql")

    if result_df is not None and not result_df.empty:
        st.subheader("📊 Results")
        st.dataframe(result_df, use_container_width=True)
    else:
        st.warning("⚠️ No data returned for this query.")

    if explanation_text:
        st.subheader("💡 Insights")
        st.markdown(explanation_text)
