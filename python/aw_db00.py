import sqlite3

# Persistent DB
DB_FILE = "mini_aw.sqlite"
con = sqlite3.connect(DB_FILE)
cur = con.cursor()

# Territory table
cur.execute("""
CREATE TABLE IF NOT EXISTS Territory(
    TerritoryID INTEGER PRIMARY KEY,
    Name TEXT NOT NULL,
    CountryRegion TEXT NOT NULL            
);
""")

# Customer table
cur.execute("""
CREATE TABLE IF NOT EXISTS Customer(
    CustomerID INTEGER PRIMARY KEY,
    FirstName TEXT NOT NULL,
    LastName TEXT NOT NULL,
    TerritoryID INTEGER,
    FOREIGN KEY (TerritoryID) REFERENCES Territory(TerritoryID)
);
""")

# SalesOrderHeader table
cur.execute("""
CREATE TABLE IF NOT EXISTS SalesOrderHeader(
    SalesOrderID INTEGER PRIMARY KEY,
    CustomerID INTEGER NOT NULL,
    OrderDate TEXT NOT NULL,
    TotalDue REAL NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);
""")

# Insert Territories
cur.execute("SELECT COUNT(*) FROM Territory;")
if cur.fetchone()[0] == 0:
    territories = [
        (1, "Northwest", "United States"),
        (2, "Northeast", "United States"),
        (3, "Central", "United States"),
        (4, "Canada", "Canada"),
        (5, "France", "France")
    ]
    cur.executemany("INSERT INTO Territory VALUES (?, ?, ?)", territories)

# Insert Customers
cur.execute("SELECT COUNT(*) FROM Customer;")
if cur.fetchone()[0] == 0:
    customers = [
        (1, "John", "Smith", 4),
        (2, "Marie", "Dubois", 5),
        (3, "Alex", "Johnson", 1),
        (4, "Robert", "King", 4)
    ]
    cur.executemany("INSERT INTO Customer VALUES (?, ?, ?, ?)", customers)

# Insert Orders
cur.execute("SELECT COUNT(*) FROM SalesOrderHeader;")
if cur.fetchone()[0] == 0:
    orders = [
        (1001, 1, "2024-01-05", 120.50),
        (1002, 2, "2024-01-01", 89.99),
        (1003, 4, "2024-02-01", 220.00),
        (1004, 2, "2024-03-03", 150.00)
    ]
    cur.executemany("INSERT INTO SalesOrderHeader VALUES (?, ?, ?, ?)", orders)

con.commit()

# Demo query
rows = cur.execute("""
SELECT c.FirstName, c.LastName, t.Name AS Territory, o.SalesOrderID, o.TotalDue
FROM Customer c
JOIN Territory t ON c.TerritoryID = t.TerritoryID
JOIN SalesOrderHeader o ON c.CustomerID = o.CustomerID;
""").fetchall()

print("Sample Join Output:")
for r in rows:
    print(r)

con.close()

print("\nDatabase Created:", DB_FILE)
