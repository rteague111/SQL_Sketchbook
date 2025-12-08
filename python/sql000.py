"""
SQL + Pandas Practice Sheet
---------------------------
This script walks you through:
  • SQLite3 database creation & queries
  • Pandas equivalents for filtering, aggregation, joining, pivoting
  • Error handling examples
  • Practice exercises

Author: Your friendly AI tutor 😎
"""

import sqlite3
import pandas as pd

# -----------------------
# 1. CONNECT TO DATABASE
# -----------------------
print("Setting up SQLite database...")
conn = sqlite3.connect(":memory:")  # in-memory; use 'data.db' to save to file
cursor = conn.cursor()


# -----------------------
# 2. CREATE TABLES
# -----------------------
cursor.execute("""
CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    department TEXT,
    salary REAL,
    hire_date TEXT
)
""")

cursor.execute("""
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT
)
""")

print("Tables created successfully.\n")


# -----------------------
# 3. INSERT DATA
# -----------------------
employees_data = [
    (1, 'Alice', 'HR', 55000, '2020-01-15'),
    (2, 'Bob', 'IT', 72000, '2019-03-23'),
    (3, 'Charlie', 'Finance', 68000, '2021-07-11'),
    (4, 'Diana', 'IT', 80000, '2018-09-30'),
    (5, 'Ethan', 'HR', 52000, '2022-02-01')
]

departments_data = [
    (1, 'HR'),
    (2, 'IT'),
    (3, 'Finance')
]

cursor.executemany("INSERT INTO employees VALUES (?, ?, ?, ?, ?)", employees_data)
cursor.executemany("INSERT INTO departments VALUES (?, ?)", departments_data)
conn.commit()
print("Sample data inserted.\n")


# -----------------------
# 4. SQL QUERIES PRACTICE
# -----------------------
print("SQL Query Examples:\n")

print("All employees:")
for row in cursor.execute("SELECT * FROM employees"):
    print(row)
print()

print("IT department salaries:")
for row in cursor.execute("SELECT name, salary FROM employees WHERE department = 'IT'"):
    print(row)
print()

print("Average salary per department:")
for row in cursor.execute("""
    SELECT department, AVG(salary) AS avg_salary, COUNT(*) AS num_employees
    FROM employees
    GROUP BY department
    HAVING avg_salary > 60000
"""):
    print(row)
print()

print("Join employees with departments:")
for row in cursor.execute("""
    SELECT e.name, e.salary, d.dept_name
    FROM employees e
    JOIN departments d ON e.department = d.dept_name
"""):
    print(row)
print()


# -----------------------
# 5. LOAD INTO PANDAS
# -----------------------
print("Loading SQL data into Pandas DataFrames...\n")
df_employees = pd.read_sql_query("SELECT * FROM employees", conn)
df_departments = pd.read_sql_query("SELECT * FROM departments", conn)

print("Employees DataFrame:\n", df_employees, "\n")


# -----------------------
# 6. PANDAS OPERATIONS
# -----------------------

# Filtering
print("Employees with salary > 60000:\n", df_employees[df_employees['salary'] > 60000], "\n")

# Aggregation (like SQL GROUP BY)
agg = df_employees.groupby('department')['salary'].agg(['mean', 'count'])
print("Aggregation by department:\n", agg, "\n")

# Joining
joined = pd.merge(df_employees, df_departments, left_on='department', right_on='dept_name')
print("Joined DataFrame:\n", joined, "\n")

# Pivot table (easier than SQL)
pivot = pd.pivot_table(df_employees, values='salary', index='department', aggfunc='mean')
print("Pivot Table (avg salary per department):\n", pivot, "\n")


# -----------------------
# 7. SQL ERROR HANDLING
# -----------------------
print("Error Handling Example:\n")

try:
    # Attempt to insert duplicate primary key (will fail)
    cursor.execute("INSERT INTO employees VALUES (1, 'Fake', 'IT', 99999, '2024-01-01')")
    conn.commit()
except sqlite3.IntegrityError as e:
    print(f"IntegrityError caught: {e}")
except sqlite3.OperationalError as e:
    print(f"OperationalError caught: {e}")
except sqlite3.DatabaseError as e:
    print(f"DatabaseError caught: {e}")
finally:
    print("Query attempted.\n")


# -----------------------
# 8. EXERCISES
# -----------------------
print("PRACTICE EXERCISES:\n")

# 1. Highest-paid employee per department (SQL)
print("1️⃣ Highest-paid employee per department (SQL):")
query = """
SELECT department, name, MAX(salary) as max_salary
FROM employees
GROUP BY department
"""
print(pd.read_sql_query(query, conn), "\n")

# 2. Add bonus column (Pandas)
print("2️⃣ Add a 10% bonus column (Pandas):")
df_employees['bonus'] = df_employees['salary'] * 0.10
print(df_employees, "\n")

# 3. Join and filter IT employees only (Pandas)
print("3️⃣ IT employees (joined):")
print(joined[joined['dept_name'] == 'IT'], "\n")

# 4. Average salary for hires after 2020 (Pandas)
print("4️⃣ Average salary for hires after 2020:")
df_employees['hire_date'] = pd.to_datetime(df_employees['hire_date'])
print(df_employees[df_employees['hire_date'] > '2020-12-31']['salary'].mean(), "\n")

# 5. Handle attempted duplicate insert (already shown above)


# -----------------------
# 9. CLEANUP
# -----------------------
conn.close()
print("Database connection closed. ✅")