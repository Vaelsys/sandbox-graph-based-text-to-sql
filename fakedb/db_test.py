import os
import sqlite3


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # points to project root
DB_PATH = os.path.join(BASE_DIR, "test_db.sqlite")


conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

cursor.execute("SELECT order_date FROM orders LIMIT 10;")
rows = cursor.fetchall()
print(rows[:10])

cursor.execute("SELECT DISTINCT STRFTIME('%Y', order_date) FROM orders;")
print("Years in data:", cursor.fetchall())

conn.close()