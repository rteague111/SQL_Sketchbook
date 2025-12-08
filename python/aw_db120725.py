# ETL practice using the mini_aw.sqlite database
# adding more data and automating reports

import sqlite3
from datetime import datetime, timedelta
import random

# connecting to an existing database
DB_FILE = "mini_aw.sqlite"
con = sqlite3.connect(DB_FILE)
cur = con.cursor()

print("Expanding mini_aw.sqlite with more data...\n")