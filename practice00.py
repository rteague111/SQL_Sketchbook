import sqlite3
from sqlite3 import Error

# ===========================================
# 1. CONNECTING TO A DATABASE
# ===========================================
# In SQLite, the database is a single file on disk.
# If the file doesn't exist, it will be created automatically.

def create_connection(db_name="warehouse_basics.db"):
    """Create a connection to the SQLite database."""
    try:
        conn = sqlite3.connect(db_name)
        print(f"✅ Connected to {db_name} (SQLite version {sqlite3.sqlite_version})")
        return conn
    except Error as e:
        print(f"❌ Error connecting to database: {e}")
        return None


# ===========================================
# 2. CREATE TABLES
# ===========================================
# We'll make a very simple example: products in a warehouse.

def create_tables(conn):
    """Create tables using SQL executed via Python."""
    create_products_sql = """
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        quantity INTEGER DEFAULT 0,
        price REAL,
        in_stock INTEGER DEFAULT 1
    );
    """
    try:
        cursor = conn.cursor()
        cursor.execute(create_products_sql)
        conn.commit()
        print("✅ Table 'products' created (if not already).")
    except Error as e:
        print(f"❌ Error creating table: {e}")


# ===========================================
# 3. INSERT DATA (C = CREATE)
# ===========================================
# You can insert using `execute()` with placeholders (safer than f-strings).

def insert_product(conn, name, category, quantity, price, in_stock=1):
    """Insert a new product into the products table."""
    sql = """
    INSERT INTO products (name, category, quantity, price, in_stock)
    VALUES (?, ?, ?, ?, ?);
    """
    cursor = conn.cursor()
    cursor.execute(sql, (name, category, quantity, price, in_stock))
    conn.commit()
    print(f"🆕 Inserted: {name} ({category}) - {quantity} units @ ${price}")


# ===========================================
# 4. READ DATA (R = READ)
# ===========================================
# SELECT pulls information out of the database.
# Fetching can be done via fetchone(), fetchall(), or looping directly.

def show_all_products(conn):
    """Select and print all products."""
    sql = "SELECT id, name, category, quantity, price, in_stock FROM products;"
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    
    print("\n📦 Current Products:")
    print("-" * 50)
    for row in rows:
        print(row)
    print("-" * 50)


# ===========================================
# 5. UPDATE DATA (U = UPDATE)
# ===========================================
# UPDATE lets you modify existing rows. Use WHERE or you'll update everything!

def update_quantity(conn, product_id, new_quantity):
    """Update the quantity of a specific product."""
    sql = "UPDATE products SET quantity = ? WHERE id = ?;"
    cursor = conn.cursor()
    cursor.execute(sql, (new_quantity, product_id))
    conn.commit()
    print(f"🔄 Updated product ID {product_id} to quantity = {new_quantity}")


# ===========================================
# 6. DELETE DATA (D = DELETE)
# ===========================================
# DELETE removes rows. Use WHERE carefully — if omitted, deletes everything!

def delete_product(conn, product_id):
    """Delete a product by its ID."""
    sql = "DELETE FROM products WHERE id = ?;"
    cursor = conn.cursor()
    cursor.execute(sql, (product_id,))
    conn.commit()
    print(f"🗑️ Deleted product ID {product_id}")


# ===========================================
# 7. FILTERED QUERIES (WHERE, LIKE, ORDER BY)
# ===========================================
# These are basic SQL tools for targeting specific data.

def filter_products(conn, category=None, min_qty=0):
    """Select products by category and/or minimum quantity."""
    sql = """
    SELECT id, name, category, quantity, price
    FROM products
    WHERE quantity >= ?
    """
    params = [min_qty]
    
    if category:
        sql += " AND category = ?"
        params.append(category)
    
    sql += " ORDER BY quantity DESC;"
    
    cursor = conn.cursor()
    cursor.execute(sql, params)
    rows = cursor.fetchall()
    
    print(f"\n🔍 Products (Category={category}, MinQty={min_qty}):")
    for row in rows:
        print(row)


# ===========================================
# 8. SAFE EXECUTION WITH try/except
# ===========================================
# Always use try/except/finally blocks in production code.

def safe_query(conn, sql, params=None):
    """Safely execute a query with error handling."""
    try:
        cursor = conn.cursor()
        if params:
            cursor.execute(sql, params)
        else:
            cursor.execute(sql)
        conn.commit()
        print("✅ Query executed successfully.")
    except Error as e:
        print(f"❌ SQLite error: {e}")


# ===========================================
# 9. DEMO WORKFLOW (PUTTING IT ALL TOGETHER)
# ===========================================

def main():
    conn = create_connection()
    if not conn:
        return

    create_tables(conn)

    # Insert sample data
    insert_product(conn, "Widget A", "Widgets", 50, 2.99)
    insert_product(conn, "Widget B", "Widgets", 20, 3.99)
    insert_product(conn, "Gadget X", "Gadgets", 15, 7.49)
    insert_product(conn, "Gadget Y", "Gadgets", 0, 5.99, in_stock=0)

    show_all_products(conn)

    # Update quantity for product ID 2
    update_quantity(conn, 2, 35)
    show_all_products(conn)

    # Filter by category
    filter_products(conn, category="Widgets", min_qty=10)

    # Delete one record
    delete_product(conn, 4)
    show_all_products(conn)

    # Close connection
    conn.close()
    print("\n🔒 Database connection closed.")


if __name__ == "__main__":
    main()