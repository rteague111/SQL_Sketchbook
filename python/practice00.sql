# SQLite to PostgreSQL Warehouse Management Guide
## (Fully Annotated with Explanations)

---

## Table of Contents
1. [SQLite vs PostgreSQL Quick Reference](#sqlite-vs-postgresql)
2. [Database Schema Setup](#database-schema)
3. [Sample Data](#sample-data)
4. [Practice Queries (Beginner to Advanced)](#practice-queries)
5. [Challenge Exercises](#challenge-exercises)
6. [PostgreSQL Migration Guide](#postgresql-migration)
7. [Power BI Integration](#power-bi-integration)
8. [Key Concepts Glossary](#glossary)

---

## SQLite vs PostgreSQL Quick Reference {#sqlite-vs-postgresql}

**Note:** SQLite is great for learning and practice. PostgreSQL is what you'll use in production. About 95% of SQL transfers directly between them.

| Feature | SQLite | PostgreSQL | Notes |
|---------|--------|------------|-------|
| **Data types** | Flexible (TEXT, INTEGER, REAL, BLOB) | Strict (VARCHAR, TIMESTAMP, etc.) | PostgreSQL enforces types strictly |
| **Auto-increment** | `INTEGER PRIMARY KEY AUTOINCREMENT` | `SERIAL PRIMARY KEY` | Both create IDs automatically |
| **Date/Time** | Stored as TEXT or INTEGER | True TIMESTAMP/DATE types | PostgreSQL has real date math |
| **Boolean** | INTEGER (0/1) | TRUE/FALSE | SQLite uses numbers for booleans |
| **Window functions** | ✅ Supported (3.25+) | ✅ Supported | RANK(), PARTITION BY, etc. |
| **CTEs** | ✅ Supported | ✅ Supported | WITH clauses for readable queries |
| **Concurrency** | Limited (file-based) | Excellent (true server) | PostgreSQL handles multiple users better |

---

## Database Schema Setup {#database-schema}

**What is a schema?** Think of it as the blueprint for your database. It defines what tables exist, what columns they have, and how they relate to each other.

### Entity Relationship Diagram

**Visual representation of how tables connect:**

```
┌─────────┐         ┌──────────┐         ┌──────────┐
│ pickers │────────<│  picks   │>────────│  orders  │
└─────────┘         └──────────┘         └──────────┘
   (who)               (action)            (what for)
                          │                     
                          │                     
                          ▼                     
                    ┌──────────┐         
                    │   skus   │         
                    └──────────┘         
                     (what item)
                          
                    ┌───────────┐        ┌────────┐
                    │ locations │───────<│ zones  │
                    └───────────┘        └────────┘
                      (where)            (area)
```

**Relationships explained:**
- One picker → many picks (one person does many picks)
- One order → many picks (one order requires multiple items picked)
- One SKU → many picks (same item picked multiple times)
- One location → many picks (same spot used repeatedly)
- One zone → many locations (a zone contains multiple bin locations)

---

### Create Tables (SQLite)

```sql
-- ============================================
-- PICKERS TABLE: Stores information about warehouse workers
-- ============================================
CREATE TABLE pickers (
    -- PRIMARY KEY: Unique identifier for each picker
    -- AUTOINCREMENT: SQLite automatically assigns 1, 2, 3, etc.
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- NOT NULL: This field is required (can't be empty)
    name TEXT NOT NULL,
    
    -- UNIQUE: No two pickers can have the same employee number
    employee_number TEXT UNIQUE NOT NULL,
    
    -- CHECK constraint: Only allows specific values
    shift TEXT CHECK(shift IN ('day', 'night', 'swing')),
    
    -- REAL: Decimal number (like 18.50)
    hourly_rate REAL,
    
    -- Stored as TEXT in SQLite (format: '2024-01-15')
    hire_date TEXT,
    
    -- DEFAULT: If not specified, use this value
    -- SQLite uses 1 for TRUE, 0 for FALSE
    is_active INTEGER DEFAULT 1
);

-- ============================================
-- ZONES TABLE: Defines areas in the warehouse
-- ============================================
CREATE TABLE zones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    zone_code TEXT UNIQUE NOT NULL,  -- Like "Z-A", "Z-B"
    zone_name TEXT,                   -- Human-readable name
    zone_type TEXT CHECK(zone_type IN ('picking', 'packing', 'receiving', 'shipping'))
);

-- ============================================
-- LOCATIONS TABLE: Specific bin locations
-- ============================================
CREATE TABLE locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_code TEXT UNIQUE NOT NULL,  -- Like "A-01-02-03"
    
    -- FOREIGN KEY: Links to zones table
    -- This location belongs to a specific zone
    zone_id INTEGER,
    
    -- Physical location breakdown
    aisle TEXT,   -- Like "01", "02"
    bay TEXT,     -- Like "03", "04"
    level TEXT,   -- Like "02", "03"
    
    is_active INTEGER DEFAULT 1,
    
    -- This line creates the relationship to zones
    FOREIGN KEY (zone_id) REFERENCES zones(id)
);

-- ============================================
-- SKUS TABLE: Items/products in inventory
-- ============================================
-- SKU = Stock Keeping Unit (unique product identifier)
CREATE TABLE skus (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sku TEXT UNIQUE NOT NULL,        -- Like "WID-001"
    description TEXT,                 -- Human-readable name
    category TEXT,                    -- Group items together
    weight_lbs REAL,                  -- Weight in pounds
    is_active INTEGER DEFAULT 1
);

-- ============================================
-- ORDERS TABLE: Customer orders to fulfill
-- ============================================
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_number TEXT UNIQUE NOT NULL,  -- Like "ORD-1001"
    customer_name TEXT,
    order_date TEXT NOT NULL,
    
    -- Priority determines pick order
    priority TEXT CHECK(priority IN ('standard', 'expedited', 'rush')),
    
    -- Status tracks order progress
    status TEXT CHECK(status IN ('pending', 'picking', 'picked', 'packing', 'shipped'))
);

-- ============================================
-- PICKS TABLE: The heart of the system!
-- This records every individual pick action
-- ============================================
CREATE TABLE picks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- These are all FOREIGN KEYS linking to other tables
    order_id INTEGER,      -- Which order is this pick for?
    picker_id INTEGER,     -- Who did the pick?
    sku_id INTEGER,        -- What item was picked?
    location_id INTEGER,   -- Where was it picked from?
    
    -- How many units were picked
    -- CHECK: Must be greater than 0 (can't pick negative!)
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    
    -- Timestamps to measure performance
    pick_start_time TEXT,  -- When picker started
    pick_end_time TEXT,    -- When picker finished
    
    -- Was this a short pick? (couldn't find enough inventory)
    is_short_pick INTEGER DEFAULT 0,
    
    -- These lines create the relationships to other tables
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (picker_id) REFERENCES pickers(id),
    FOREIGN KEY (sku_id) REFERENCES skus(id),
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

-- ============================================
-- INDEXES: Make queries faster
-- ============================================
-- Think of an index like a book's index - helps you find things quickly
-- Without indexes, database has to scan every row (slow!)
-- With indexes, it can jump directly to relevant rows (fast!)

-- Index on picker_id: Makes "find all picks by this picker" fast
CREATE INDEX idx_picks_picker_id ON picks(picker_id);

-- Index on order_id: Makes "find all picks for this order" fast
CREATE INDEX idx_picks_order_id ON picks(order_id);

-- Index on sku_id: Makes "find all picks of this SKU" fast
CREATE INDEX idx_picks_sku_id ON picks(sku_id);

-- Index on pick_end_time: Makes date-range queries fast
CREATE INDEX idx_picks_pick_end_time ON picks(pick_end_time);
```

---

## Sample Data {#sample-data}

**Note:** This creates realistic test data you can query against. Adjust the dates to match when you're practicing.

```sql
-- ============================================
-- INSERT PICKERS: Add warehouse workers
-- ============================================
INSERT INTO pickers (name, employee_number, shift, hourly_rate, hire_date) VALUES
('Alice Johnson', 'E001', 'day', 18.50, '2024-01-15'),
('Bob Smith', 'E002', 'day', 17.25, '2024-02-01'),
('Charlie Davis', 'E003', 'night', 19.00, '2023-11-20'),
('Diana Martinez', 'E004', 'day', 18.00, '2024-03-10'),
('Eve Wilson', 'E005', 'swing', 17.50, '2024-04-05'),
('Frank Brown', 'E006', 'night', 19.25, '2023-10-15');

-- Result: 6 pickers created with IDs 1-6

-- ============================================
-- INSERT ZONES: Define warehouse areas
-- ============================================
INSERT INTO zones (zone_code, zone_name, zone_type) VALUES
('Z-A', 'Zone A - Fast Movers', 'picking'),      -- High-velocity items
('Z-B', 'Zone B - Bulk Items', 'picking'),       -- Large/heavy items
('Z-C', 'Zone C - Small Parts', 'picking'),      -- Small components
('Z-PACK', 'Packing Station', 'packing'),        -- Where orders get boxed
('Z-RECV', 'Receiving Dock', 'receiving'),       -- Incoming shipments
('Z-SHIP', 'Shipping Dock', 'shipping');         -- Outgoing shipments

-- Result: 6 zones created with IDs 1-6

-- ============================================
-- INSERT LOCATIONS: Specific bin locations
-- ============================================
-- Format: Zone-Aisle-Bay-Level (like "A-01-02-03")
INSERT INTO locations (location_code, zone_id, aisle, bay, level) VALUES
('A-01-02-03', 1, '01', '02', '03'),  -- Zone A, Aisle 1, Bay 2, Level 3
('A-01-03-02', 1, '01', '03', '02'),
('A-02-01-04', 1, '02', '01', '04'),
('B-01-05-01', 2, '01', '05', '01'),  -- Zone B locations
('B-02-03-02', 2, '02', '03', '02'),
('C-01-01-01', 3, '01', '01', '01'),  -- Zone C locations
('C-01-02-03', 3, '01', '02', '03'),
('C-02-04-02', 3, '02', '04', '02');

-- Result: 8 locations created with IDs 1-8

-- ============================================
-- INSERT SKUS: Products in inventory
-- ============================================
INSERT INTO skus (sku, description, category, weight_lbs) VALUES
('WID-001', 'Widget Assembly Red', 'Widgets', 2.5),
('WID-002', 'Widget Assembly Blue', 'Widgets', 2.5),
('WID-003', 'Widget Assembly Green', 'Widgets', 2.5),
('GAD-101', 'Gadget Pro', 'Gadgets', 5.0),
('GAD-102', 'Gadget Lite', 'Gadgets', 3.5),
('BOL-201', 'Bolt Set 100pc', 'Hardware', 1.0),
('BOL-202', 'Bolt Set 50pc', 'Hardware', 0.5),
('NUT-301', 'Nut Assortment', 'Hardware', 0.8);

-- Result: 8 SKUs created with IDs 1-8

-- ============================================
-- INSERT ORDERS: Customer orders
-- ============================================
INSERT INTO orders (order_number, customer_name, order_date, priority, status) VALUES
('ORD-1001', 'Acme Corp', '2025-11-04', 'standard', 'shipped'),
('ORD-1002', 'TechStart Inc', '2025-11-04', 'expedited', 'picked'),
('ORD-1003', 'BuildCo', '2025-11-05', 'standard', 'picking'),
('ORD-1004', 'QuickShip LLC', '2025-11-05', 'rush', 'picking'),
('ORD-1005', 'MegaStore', '2025-11-05', 'standard', 'pending');

-- Result: 5 orders created with IDs 1-5

-- ============================================
-- INSERT PICKS: Individual pick actions
-- ============================================
-- Note: Adjust dates to match when you're practicing!

-- Alice's picks (early morning shift today)
INSERT INTO picks (order_id, picker_id, sku_id, location_id, quantity, pick_start_time, pick_end_time) VALUES
-- Order 1, Picker 1 (Alice), SKU 1 (WID-001), Location 1, 5 units
(1, 1, 1, 1, 5, '2025-11-05 08:00:00', '2025-11-05 08:03:30'),  -- Took 3.5 minutes
(1, 1, 4, 4, 2, '2025-11-05 08:05:00', '2025-11-05 08:08:15'),  -- Took 3.25 minutes
(2, 1, 2, 2, 3, '2025-11-05 08:10:00', '2025-11-05 08:12:45'),
(2, 1, 6, 6, 10, '2025-11-05 08:15:00', '2025-11-05 08:17:20'),
(3, 1, 3, 3, 4, '2025-11-05 08:20:00', '2025-11-05 08:23:10');
-- Alice completed 5 picks, 24 total units

-- Bob's picks (mid-morning)
INSERT INTO picks (order_id, picker_id, sku_id, location_id, quantity, pick_start_time, pick_end_time) VALUES
(1, 2, 5, 5, 1, '2025-11-05 09:00:00', '2025-11-05 09:02:30'),
(2, 2, 7, 7, 8, '2025-11-05 09:05:00', '2025-11-05 09:07:15'),
(3, 2, 1, 1, 6, '2025-11-05 09:10:00', '2025-11-05 09:13:45');
-- Bob completed 3 picks, 15 total units

-- Diana's picks (late morning)
INSERT INTO picks (order_id, picker_id, sku_id, location_id, quantity, pick_start_time, pick_end_time) VALUES
(3, 4, 4, 4, 3, '2025-11-05 10:00:00', '2025-11-05 10:04:20'),
(3, 4, 8, 8, 12, '2025-11-05 10:08:00', '2025-11-05 10:11:30'),
(4, 4, 2, 2, 7, '2025-11-05 10:15:00', '2025-11-05 10:18:45'),
(4, 4, 6, 6, 5, '2025-11-05 10:20:00', '2025-11-05 10:22:10');
-- Diana completed 4 picks, 27 total units

-- Charlie's picks (night shift yesterday)
INSERT INTO picks (order_id, picker_id, sku_id, location_id, quantity, pick_start_time, pick_end_time) VALUES
(1, 3, 3, 3, 2, '2025-11-04 22:00:00', '2025-11-04 22:03:15'),
(2, 3, 5, 5, 4, '2025-11-04 22:10:00', '2025-11-04 22:13:20'),
(2, 3, 7, 7, 6, '2025-11-04 22:20:00', '2025-11-04 22:22:45');
-- Charlie completed 3 picks, 12 total units

-- Frank's picks (night shift yesterday)
INSERT INTO picks (order_id, picker_id, sku_id, location_id, quantity, pick_start_time, pick_end_time) VALUES
(1, 6, 1, 1, 3, '2025-11-04 23:00:00', '2025-11-04 23:02:50'),
(1, 6, 8, 8, 8, '2025-11-04 23:10:00', '2025-11-04 23:13:15');
-- Frank completed 2 picks, 11 total units

-- Total: 17 picks across 5 pickers
```

---

## Practice Queries (Beginner to Advanced) {#practice-queries}

**Learning path:** Start with Query 1 and work your way down. Each query builds on concepts from previous ones.

---

### Query 1: Simple SELECT - See all pickers

**Concept:** Basic SELECT statement retrieves data from a table

```sql
-- SELECT * means "select all columns"
-- FROM pickers means "from the pickers table"
SELECT * FROM pickers;
```

**What this does:** Shows every column and every row in the pickers table

**Expected output:** 6 rows (Alice, Bob, Charlie, Diana, Eve, Frank) with all their details

---

### Query 2: Filtered SELECT - Active day shift pickers

**Concept:** WHERE clause filters results based on conditions

```sql
-- Only select specific columns (not all)
SELECT name, employee_number, hourly_rate
FROM pickers
-- AND means both conditions must be true
WHERE shift = 'day' AND is_active = 1;
```

**What this does:** 
- Only shows name, employee_number, and hourly_rate (not all columns)
- Only shows pickers where shift is 'day'
- AND only shows pickers where is_active is 1 (TRUE)

**Expected output:** 3 rows (Alice, Bob, Diana) - the day shift workers

---

### Query 3: COUNT - How many picks total?

**Concept:** Aggregation functions perform calculations across multiple rows

```sql
-- COUNT(*) counts the number of rows
-- AS gives the result a name (alias)
SELECT COUNT(*) as total_picks FROM picks;
```

**What this does:** Counts every row in the picks table

**Expected output:** One number (17) - the total number of picks

---

### Query 4: SUM - Total units picked

**Concept:** SUM adds up numeric values

```sql
-- SUM(quantity) adds up the quantity column for all rows
SELECT SUM(quantity) as total_units FROM picks;
```

**What this does:** Adds up all the quantities from every pick

**Expected output:** One number (89) - total units picked

---

### Query 5: GROUP BY - Picks per picker (no names yet)

**Concept:** GROUP BY groups rows with the same value together, then aggregates each group

```sql
SELECT 
    picker_id,                -- Group by this
    COUNT(*) as picks,        -- Count picks in each group
    SUM(quantity) as units    -- Sum quantities in each group
FROM picks
GROUP BY picker_id            -- Create one row per unique picker_id
ORDER BY picks DESC;          -- Sort by picks, highest first
```

**What this does:** 
- Groups all picks by picker_id (all Alice's picks together, all Bob's together, etc.)
- Counts how many picks each picker did
- Sums how many units each picker collected
- Sorts by pick count (most productive first)

**Problem:** You see picker_id (1, 2, 3) but not their names. Let's fix that...

**Expected output:** 
```
picker_id | picks | units
1         | 5     | 24
4         | 4     | 27
2         | 3     | 15
```

---

### Query 6: JOIN - Picks per picker WITH NAMES

**Concept:** JOIN connects tables using their relationships (foreign keys)

```sql
SELECT 
    p.name,                      -- p is alias for pickers table
    p.shift,
    COUNT(pk.id) as picks,       -- pk is alias for picks table
    SUM(pk.quantity) as units
FROM pickers p                   -- Start with pickers table
LEFT JOIN picks pk ON p.id = pk.picker_id  -- Connect to picks table
GROUP BY p.id, p.name, p.shift   -- Group by picker
ORDER BY picks DESC;
```

**What this does:**
- Starts with pickers table (every picker)
- LEFT JOIN says "include all pickers, even if they have no picks"
- ON p.id = pk.picker_id is how tables connect (picker's ID matches picker_id in picks)
- Now we can show picker names AND their stats

**LEFT JOIN vs INNER JOIN:**
- LEFT JOIN: Shows all pickers (even if 0 picks) - Eve and others with no picks today still show up
- INNER JOIN: Only shows pickers who have picks - would exclude Eve

**Expected output:**
```
name           | shift | picks | units
Diana Martinez | day   | 4     | 27
Alice Johnson  | day   | 5     | 24
Bob Smith      | day   | 3     | 15
```

---

### Query 7: Filter by Date - Today's picks only

**Concept:** Filtering by date in WHERE clause

```sql
SELECT 
    p.name,
    COUNT(pk.id) as picks,
    SUM(pk.quantity) as units
FROM pickers p
LEFT JOIN picks pk ON p.id = pk.picker_id
-- DATE() function extracts just the date part from timestamp
WHERE DATE(pk.pick_end_time) = '2025-11-05'  -- Change to current date when practicing
GROUP BY p.id, p.name
ORDER BY picks DESC;
```

**What this does:**
- Same as Query 6, but only counts picks from today
- DATE(pk.pick_end_time) converts '2025-11-05 08:00:00' to '2025-11-05'
- Filters to only match that specific date

**SQLite date note:** Dates are stored as TEXT, but DATE() function extracts the date portion

**Expected output:** Only pickers who worked today (Alice, Bob, Diana) with today's counts

---

### Query 8: Calculate Pick Duration

**Concept:** Date/time arithmetic to measure performance

```sql
SELECT 
    p.name,
    s.sku,
    pk.quantity,
    pk.pick_start_time,
    pk.pick_end_time,
    -- This calculates seconds between start and end
    ROUND((JULIANDAY(pk.pick_end_time) - JULIANDAY(pk.pick_start_time)) * 86400, 2) as duration_seconds
FROM picks pk
JOIN pickers p ON pk.picker_id = p.id
JOIN skus s ON pk.sku_id = s.id
ORDER BY duration_seconds DESC;
```

**What this does:**
- JULIANDAY() converts text date to a decimal number (days since Jan 1, 4713 BC)
- Subtracting gives difference in days (like 0.00243 days)
- Multiply by 86400 (seconds in a day) to get seconds
- ROUND(..., 2) rounds to 2 decimal places

**Why this matters:** Shows which picks took longest (performance analysis)

**Expected output:** Each pick with how many seconds it took

---

### Query 9: Average Pick Time per Picker

**Concept:** Using AVG() aggregation with date calculations

```sql
SELECT 
    p.name,
    COUNT(pk.id) as picks,
    -- AVG calculates average across all picks for each picker
    ROUND(AVG((JULIANDAY(pk.pick_end_time) - JULIANDAY(pk.pick_start_time)) * 86400), 2) as avg_seconds
FROM pickers p
JOIN picks pk ON p.id = pk.picker_id
WHERE pk.pick_end_time IS NOT NULL  -- Only include completed picks
GROUP BY p.id, p.name
ORDER BY avg_seconds ASC;  -- Fastest average first
```

**What this does:**
- Groups picks by picker
- Calculates average duration for each picker's picks
- Shows who's fastest on average

**Expected output:** Each picker with their average pick time

---

### Query 10: WINDOW FUNCTIONS - Leaderboard with Ranking

**Concept:** RANK() is a window function that assigns rankings without collapsing rows

```sql
SELECT 
    name,
    picks,
    units,
    -- RANK() OVER (ORDER BY ...) assigns rank based on sorting
    RANK() OVER (ORDER BY picks DESC) as rank
FROM (
    -- Inner query: Calculate stats per picker
    SELECT 
        p.name,
        COUNT(pk.id) as picks,
        SUM(pk.quantity) as units
    FROM pickers p
    LEFT JOIN picks pk ON p.id = pk.picker_id
    WHERE DATE(pk.pick_end_time) = '2025-11-05'
    GROUP BY p.id, p.name
)
ORDER BY picks DESC;
```

**What this does:**
- Inner query (subquery) calculates each picker's stats
- Outer query adds ranking using RANK() window function
- RANK() OVER (ORDER BY picks DESC) means "rank by picks, highest first"

**RANK vs ROW_NUMBER vs DENSE_RANK:**
- RANK(): Ties share rank, next rank skips (1, 2, 2, 4)
- DENSE_RANK(): Ties share rank, next rank doesn't skip (1, 2, 2, 3)
- ROW_NUMBER(): No ties, always unique (1, 2, 3, 4)

**This is your real-time leaderboard query!**

**Expected output:**
```
name           | picks | units | rank
Diana Martinez | 4     | 27    | 1
Alice Johnson  | 5     | 24    | 2
Bob Smith      | 3     | 15    | 3
```

---

### Query 11: Multiple JOINS - Full Pick Details

**Concept:** Joining 5+ tables to show complete context

```sql
SELECT 
    o.order_number,          -- From orders table
    p.name as picker_name,   -- From pickers table
    s.sku,                   -- From skus table
    s.description,           -- From skus table
    l.location_code,         -- From locations table
    z.zone_name,             -- From zones table
    pk.quantity,             -- From picks table
    pk.pick_end_time         -- From picks table
FROM picks pk                -- Start with picks (the central table)
JOIN orders o ON pk.order_id = o.id             -- Connect to orders
JOIN pickers p ON pk.picker_id = p.id           -- Connect to pickers
JOIN skus s ON pk.sku_id = s.id                 -- Connect to skus
JOIN locations l ON pk.location_id = l.id       -- Connect to locations
JOIN zones z ON l.zone_id = z.id                -- Connect to zones (through locations)
ORDER BY pk.pick_end_time DESC;  -- Most recent first
```

**What this does:**
- Starts with picks table (has all the foreign keys)
- Joins to 5 other tables to get descriptive information
- Shows complete story: "Alice picked 5 of WID-001 from location A-01-02-03 in Zone A for order ORD-1001"

**This shows the full context of every pick!**

---

### Query 12: CTE - Top Performers with Shift Rankings

**Concept:** CTE (Common Table Expression) makes complex queries readable

```sql
-- WITH creates a temporary named result set
WITH picker_stats AS (
    -- Everything in here runs first, creates "picker_stats" table
    SELECT 
        p.id,
        p.name,
        p.shift,
        COUNT(pk.id) as picks,
        SUM(pk.quantity) as units,
        ROUND(AVG((JULIANDAY(pk.pick_end_time) - JULIANDAY(pk.pick_start_time)) * 86400), 2) as avg_seconds
    FROM pickers p
    LEFT JOIN picks pk ON p.id = pk.picker_id
    WHERE DATE(pk.pick_end_time) = '2025-11-05'
    GROUP BY p.id, p.name, p.shift
)
-- Now we can query picker_stats like it's a real table
SELECT 
    name,
    shift,
    picks,
    units,
    avg_seconds,
    -- Overall ranking (across all shifts)
    RANK() OVER (ORDER BY picks DESC) as overall_rank,
    -- Ranking within each shift (PARTITION BY splits into groups)
    RANK() OVER (PARTITION BY shift ORDER BY picks DESC) as shift_rank
FROM picker_stats
WHERE picks > 0          -- Only show pickers who actually picked today
ORDER BY picks DESC;
```

**What this does:**
- WITH picker_stats AS (...) creates a temporary result set
- Makes query readable (calculate stats, THEN rank them)
- PARTITION BY shift means "rank separately for day, night, and swing shifts"

**PARTITION BY explanation:** Like having 3 separate leaderboards (one per shift)

**Expected output:**
```
name           | shift | picks | overall_rank | shift_rank
Diana Martinez | day   | 4     | 1            | 1
Alice Johnson  | day   | 5     | 2            | 2
Bob Smith      | day   | 3     | 3            | 3
```

---

### Query 13: Hot SKUs - Most Picked Items

**Concept:** Analyzing product popularity

```sql
SELECT 
    s.sku,
    s.description,
    s.category,
    COUNT(pk.id) as times_picked,      -- How many picks included this SKU
    SUM(pk.quantity) as total_units    -- Total units of this SKU picked
FROM skus s
JOIN picks pk ON s.id = pk.sku_id
GROUP BY s.id, s.sku, s.description, s.category
ORDER BY times_picked DESC
LIMIT 10;  -- Top 10 only
```

**What this does:**
- Groups all picks by SKU
- Counts how many times each SKU was picked
- Sums total units picked for each SKU
- Shows top 10 most frequently picked items

**Why this matters:** 
- Hot SKUs should be in easy-to-reach locations (slotting optimization)
- Identifies fast-moving inventory

---

### Query 14: Zone Performance

**Concept:** Analyzing efficiency by warehouse area

```sql
SELECT 
    z.zone_name,
    COUNT(pk.id) as picks,
    SUM(pk.quantity) as units,
    COUNT(DISTINCT pk.picker_id) as pickers_used  -- DISTINCT removes duplicates
FROM zones z
JOIN locations l ON z.id = l.zone_id    -- Zones have many locations
JOIN picks pk ON l.id = pk.location_id  -- Locations have many picks
GROUP BY z.id, z.zone_name
ORDER BY picks DESC;
```

**What this does:**
- Groups picks by zone
- Shows which zones are bus