# 🧠 Text-to-SQL Multi-Agent System

<img width="1671" height="333" alt="Screenshot 2025-11-02 at 1 12 09 PM" src="https://github.com/user-attachments/assets/17164a79-3ed1-435f-a13d-2420ce6d7fb7" />

A fully multi-agent LangGraph pipeline that converts natural language queries into SQL, executes them on a database, and streams real-time explanations and insights to the UI — powered by FastAPI, LangChain, Streamlit, and Chroma (RAG).

# 🚀 Overview

This project demonstrates how LLM agents can collaborate to perform complex reasoning and data querying tasks — from query understanding → SQL generation → validation → execution → visualization → natural language explanation.

**🌟 Key Highlights**

1. Multi-Agent pipeline using LangGraph

2. Real-time streaming with FastAPI + SSE

3. Interactive frontend using Streamlit

4. RAG-based schema retrieval via Chroma embeddings

5. Natural language explanation of SQL and results

6. Modular and async design — each agent is a separate node

# 🧩 Architecture


```text
User Query ─► Query Rewriter
              ├─► Schema Agent (RAG + Chroma)
              ├─► SQL Generator
              ├─► SQL Validator
              ├─► Query Executor (SQLite)
              ├─► Visualization Agent
              └─► Explainability Agent
```

All agents share a global GlobalState — updated at each step and streamed live to the UI.

# ⚙️ Tech Stack

1. **Backend:** 	FastAPI, LangGraph, LangChain
2. **Vector DB:** 	Chroma
3. **Frontend:** 	Streamlit
4. **Database:** 	SQLite (FakeDB)
5. **Model:** 	OpenAI / Any LLM via langchain
6. **Memory:** 	GlobalState JSON state sharing

# 🧪 Installation
```text
git clone https://github.com/yourusername/Text-to-SQL-MultiAgent.git
cd Text-to-SQL-MultiAgent
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate (Windows)
pip install -r requirements.txt

```

# Running the System
## 1️⃣ Start the FastAPI backend:
```text
uvicorn app.main:app --reload

```
## 2️⃣ Run the Streamlit UI:
```text
streamlit run app/ui/stream_ui.py

```

#### Now open:  http://localhost:8501

<img width="1662" height="856" alt="Screenshot 2025-11-02 at 1 12 44 PM" src="https://github.com/user-attachments/assets/3d0e30bb-106d-4394-a3e6-545e1fde736d" />


At the end, results and insights are displayed:

1. 🧮 Generated SQL

2. 📊 Query Results

3. 💡 Insights (in plain language)
   
<img width="1679" height="597" alt="Screenshot 2025-11-02 at 1 13 12 PM" src="https://github.com/user-attachments/assets/81e0b34d-7fce-4110-8849-f32fade98a01" />


 # Refresh Schema Embeddings

***If your database schema changes, rebuild Chroma embeddings:**
```text
python fakedb/db_test.py  # rebuild fake DB
python app/utils/rebuild_schema_index.py  # re-index schema
```

This ensures the RAG retriever stays in sync with your latest database.

# 🔮 Future Enhancements

1. 🤖 Add memory for contextual multi-turn conversations

2. 🧱 Support multiple databases (Postgres, MySQL)

3. ⚙️ Caching to optimize repeated queries

4. 🪄 Self-healing SQL correction via validator feedback

5. 📈 Auto chart suggestions in visualization agent

# 🧩 Credits

**Built with ❤️ using:**

1. LangChain

2. LangGraph

3. Streamlit

4. FastAPI

5. Chroma

# 📜 License

This project is licensed under the MIT License — feel free to use and modify.
