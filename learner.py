

#!/usr/bin/env python3
"""
SQL Learning Tool - Interactive SQL Practice
Works with your db00.sql warehouse database
"""

import sqlite3
import sys
from datetime import datetime

class SQLLearner:
    def __init__(self, db_path="db00.sql"):
        self.db_path = db_path
        self.conn = None
        self.cursor = None

    def connect(self):
        """Connect to the database"""
        try:
            self.conn = sqlite3.connect(self.db_path)
            self.cursor = self.conn.cursor()
            print(f"✓ Connected to {self.db_path}\n")
            return True
        except sqlite3.Error as e:
            print(f"✗ Error connecting to database: {e}")
            return False

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
            print("\n✓ Database connection closed")

    def execute_query(self, query):
        """Execute a SQL query and display results"""
        try:
            self.cursor.execute(query)

            # Check if it's a SELECT query
            if query.strip().upper().startswith('SELECT'):
                results = self.cursor.fetchall()
                columns = [description[0] for description in self.cursor.description]

                if not results:
                    print("No results found.\n")
                    return

                # Print header
                header = " | ".join(f"{col:20}" for col in columns)
                print(header)
                print("-" * len(header))

                # Print rows
                for row in results:
                    print(" | ".join(f"{str(val):20}" for val in row))

                print(f"\n({len(results)} row(s) returned)\n")
            else:
                # For INSERT, UPDATE, DELETE
                self.conn.commit()
                print(f"✓ Query executed. {self.cursor.rowcount} row(s) affected.\n")

        except sqlite3.Error as e:
            print(f"✗ SQL Error: {e}\n")

    def show_tables(self):
        """Show all tables in the database"""
        query = "SELECT name FROM sqlite_master WHERE type='table';"
        print("=== TABLES IN DATABASE ===")
        self.execute_query(query)

    def show_schema(self, table_name):
        """Show schema for a specific table"""
        query = f"PRAGMA table_info({table_name});"
        print(f"=== SCHEMA FOR {table_name.upper()} ===")
        self.execute_query(query)

    def show_lessons(self):
        """Display available lessons"""
        lessons = {
            1: "Basic SELECT - View all inventory",
            2: "WHERE clause - Filter low stock items",
            3: "ORDER BY - Sort by price",
            4: "Aggregate Functions - COUNT, SUM, AVG",
            5: "GROUP BY - Sales by category",
            6: "JOINs - Combine inventory and orders",
            7: "Subqueries - Items never ordered",
            8: "CASE statements - Price categories",
            9: "Window Functions - Ranking",
            10: "CTEs - Common Table Expressions"
        }

        print("=== SQL LESSONS ===")
        for num, desc in lessons.items():
            print(f"{num}. {desc}")
        print()

    def run_lesson(self, lesson_num):
        """Run a specific lesson"""
        lessons = {
            1: self.lesson_basic_select,
            2: self.lesson_where_clause,
            3: self.lesson_order_by,
            4: self.lesson_aggregates,
            5: self.lesson_group_by,
            6: self.lesson_joins,
            7: self.lesson_subqueries,
            8: self.lesson_case,
            9: self.lesson_window_functions,
            10: self.lesson_cte
        }

        if lesson_num in lessons:
            lessons[lesson_num]()
        else:
            print("Invalid lesson number!")

    # LESSON METHODS
    def lesson_basic_select(self):
        print("=== LESSON 1: Basic SELECT ===")
        print("Goal: Retrieve all items from inventory\n")

        query = "SELECT * FROM inventory LIMIT 5;"
        print(f"Query: {query}\n")
        self.execute_query(query)

        print("Try it yourself: SELECT item_name, sale_price FROM inventory;")

    def lesson_where_clause(self):
        print("=== LESSON 2: WHERE Clause ===")
        print("Goal: Filter items with low stock\n")

        query = """
        SELECT item_name, quantity_in_stock, reorder_level
        FROM inventory
        WHERE quantity_in_stock < reorder_level;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Find items in category 'Tools'")

    def lesson_order_by(self):
        print("=== LESSON 3: ORDER BY ===")
        print("Goal: Sort items by price\n")

        query = """
        SELECT item_name, sale_price
        FROM inventory
        ORDER BY sale_price DESC
        LIMIT 5;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Sort by profit margin (sale_price - cost_price)")

    def lesson_aggregates(self):
        print("=== LESSON 4: Aggregate Functions ===")
        print("Goal: Calculate totals and averages\n")

        query = """
        SELECT
            COUNT(*) as total_items,
            SUM(quantity_in_stock) as total_stock,
            AVG(sale_price) as avg_price,
            MAX(sale_price) as highest_price,
            MIN(sale_price) as lowest_price
        FROM inventory;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Calculate total inventory value (quantity * sale_price)")

    def lesson_group_by(self):
        print("=== LESSON 5: GROUP BY ===")
        print("Goal: Aggregate by category\n")

        query = """
        SELECT
            category,
            COUNT(*) as item_count,
            AVG(sale_price) as avg_price
        FROM inventory
        GROUP BY category
        ORDER BY item_count DESC;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: GROUP BY supplier to see supplier statistics")

    def lesson_joins(self):
        print("=== LESSON 6: JOINs ===")
        print("Goal: Combine inventory and orders\n")

        query = """
        SELECT
            i.item_name,
            o.customer_name,
            o.quantity_ordered,
            o.total_price
        FROM orders o
        JOIN inventory i ON o.item_id = i.item_id
        LIMIT 5;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Find total quantity ordered per item")

    def lesson_subqueries(self):
        print("=== LESSON 7: Subqueries ===")
        print("Goal: Find items that have never been ordered\n")

        query = """
        SELECT item_name, quantity_in_stock
        FROM inventory
        WHERE item_id NOT IN (SELECT DISTINCT item_id FROM orders);
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Find items with above-average price")

    def lesson_case(self):
        print("=== LESSON 8: CASE Statements ===")
        print("Goal: Categorize items by price range\n")

        query = """
        SELECT
            item_name,
            sale_price,
            CASE
                WHEN sale_price < 10 THEN 'Budget'
                WHEN sale_price < 50 THEN 'Mid-range'
                ELSE 'Premium'
            END as price_category
        FROM inventory
        LIMIT 10;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Create stock status (Low/Medium/High)")

    def lesson_window_functions(self):
        print("=== LESSON 9: Window Functions ===")
        print("Goal: Rank items by profit within each category\n")

        query = """
        SELECT
            item_name,
            category,
            sale_price - cost_price as profit,
            RANK() OVER (PARTITION BY category ORDER BY sale_price - cost_price DESC) as profit_rank
        FROM inventory
        ORDER BY category, profit_rank;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Use ROW_NUMBER() to number all items")

    def lesson_cte(self):
        print("=== LESSON 10: CTEs (Common Table Expressions) ===")
        print("Goal: Use WITH clause for readable queries\n")

        query = """
        WITH profitable_items AS (
            SELECT
                item_id,
                item_name,
                sale_price - cost_price as profit
            FROM inventory
            WHERE sale_price - cost_price > 20
        )
        SELECT
            pi.item_name,
            pi.profit,
            COUNT(o.order_id) as times_ordered
        FROM profitable_items pi
        LEFT JOIN orders o ON pi.item_id = o.item_id
        GROUP BY pi.item_id, pi.item_name, pi.profit
        ORDER BY profit DESC;
        """
        print(f"Query: {query}")
        self.execute_query(query)

        print("Try: Create a CTE for low stock items and join with orders")

    def interactive_mode(self):
        """Run queries interactively"""
        print("\n=== INTERACTIVE SQL MODE ===")
        print("Type your SQL queries (end with semicolon)")
        print("Type 'exit' to return to main menu\n")

        query_buffer = ""
        while True:
            try:
                line = input("SQL> " if not query_buffer else "...> ")

                if line.strip().lower() == 'exit':
                    break

                query_buffer += " " + line

                if line.strip().endswith(';'):
                    self.execute_query(query_buffer.strip())
                    query_buffer = ""

            except KeyboardInterrupt:
                print("\nUse 'exit' to quit interactive mode")
                query_buffer = ""

    def main_menu(self):
        """Display main menu and handle user input"""
        while True:
            print("\n" + "="*50)
            print("SQL LEARNING TOOL - Main Menu")
            print("="*50)
            print("1. Show all tables")
            print("2. Show table schema")
            print("3. View lessons")
            print("4. Run a lesson")
            print("5. Interactive SQL mode")
            print("6. Execute custom query")
            print("7. Exit")
            print("="*50)

            choice = input("\nEnter choice (1-7): ").strip()

            if choice == '1':
                self.show_tables()
            elif choice == '2':
                table = input("Enter table name: ").strip()
                self.show_schema(table)
            elif choice == '3':
                self.show_lessons()
            elif choice == '4':
                self.show_lessons()
                lesson = input("Enter lesson number (1-10): ").strip()
                try:
                    self.run_lesson(int(lesson))
                except ValueError:
                    print("Invalid lesson number!")
            elif choice == '5':
                self.interactive_mode()
            elif choice == '6':
                print("Enter your SQL query (end with semicolon):")
                query = input("SQL> ").strip()
                self.execute_query(query)
            elif choice == '7':
                print("\nGoodbye! Keep practicing SQL!")
                break
            else:
                print("Invalid choice. Please enter 1-7.")

def main():
    """Main function"""
    print("="*50)
    print("Welcome to SQL Learning Tool!")
    print("="*50)

    # Check if database path provided
    db_path = sys.argv[1] if len(sys.argv) > 1 else "db00.sql"

    learner = SQLLearner(db_path)

    if learner.connect():
        try:
            learner.main_menu()
        finally:
            learner.close()
    else:
        print("Could not connect to database. Make sure db00.sql exists!")
        sys.exit(1)

if __name__ == "__main__":
    main()