#!/usr/bin/env python3
"""
Generate CSV files for bulk import into PostgreSQL
Much faster and more reliable than INSERT statements
"""

import csv
import random
import os
from datetime import datetime, timedelta
from pathlib import Path

# Configuration
NUM_CUSTOMERS = 100000
NUM_ACCOUNTS = 150000
NUM_MERCHANTS = 50000
NUM_CARDS = 200000
NUM_TRANSACTIONS = 5000000
FRAUD_RATE = 0.07

# Output directory
DATA_DIR = Path(__file__).parent.parent / "data" / "csv"
DATA_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("CSV Data Generation for Business Analytics Database")
print("=" * 80)
print(f"Output directory: {DATA_DIR}")
print(f"Customers: {NUM_CUSTOMERS:,}")
print(f"Accounts: {NUM_ACCOUNTS:,}")
print(f"Merchants: {NUM_MERCHANTS:,}")
print(f"Cards: {NUM_CARDS:,}")
print(f"Transactions: {NUM_TRANSACTIONS:,}")
print(f"Fraud rate: {FRAUD_RATE*100}%")
print("=" * 80)
print()

# Reference data
FIRST_NAMES = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", 
               "William", "Barbara", "David", "Elizabeth", "Richard", "Susan", "Joseph", "Jessica",
               "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa"]

LAST_NAMES = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
              "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas",
              "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White"]

CITIES = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio",
          "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville", "Fort Worth", "Columbus",
          "Charlotte", "San Francisco", "Indianapolis", "Seattle", "Denver", "Boston"]

STATES = ["NY", "CA", "IL", "TX", "AZ", "PA", "TX", "CA", "TX", "CA", "TX", "FL", "TX", "OH",
          "NC", "CA", "IN", "WA", "CO", "MA"]

COUNTRIES = ["US", "CA", "GB", "DE", "FR", "AU", "JP", "CN", "IN", "BR"]

MERCHANT_TYPES = [
    ("5411", "Grocery Stores"), ("5812", "Restaurants"), ("5541", "Gas Stations"),
    ("5311", "Department Stores"), ("5912", "Pharmacies"), ("5999", "Miscellaneous Retail"),
    ("5732", "Electronics"), ("5651", "Clothing"), ("5814", "Fast Food"),
    ("5942", "Books"), ("7011", "Hotels"), ("7512", "Car Rental")
]

TRANSACTION_TYPES = ["PURCHASE", "ATM_WITHDRAWAL", "TRANSFER_OUT", "TRANSFER_IN", "PAYMENT", 
                     "REFUND", "DEPOSIT", "WIRE_OUT", "WIRE_IN"]

FRAUD_CODES = ["CARD_STOLEN", "ACCOUNT_TAKEOVER", "IDENTITY_THEFT", "SYNTHETIC_IDENTITY",
               "CARD_NOT_PRESENT", "PHISHING", "ATM_SKIMMING", "WIRE_FRAUD"]

def generate_email(first_name, last_name, customer_id):
    """Generate realistic email address"""
    domains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "icloud.com"]
    return f"{first_name.lower()}.{last_name.lower()}{customer_id % 1000}@{random.choice(domains)}"

def generate_phone():
    """Generate US phone number"""
    return f"+1{random.randint(2000000000, 9999999999)}"

def generate_ssn():
    """Generate SSN-like identifier"""
    return f"{random.randint(100, 999)}-{random.randint(10, 99)}-{random.randint(1000, 9999)}"

def generate_card_number():
    """Generate realistic card number"""
    prefix = random.choice(["4", "5"])  # Visa or Mastercard
    return prefix + "".join([str(random.randint(0, 9)) for _ in range(15)])

def random_date(start_date, end_date):
    """Generate random date between start and end"""
    delta = end_date - start_date
    random_days = random.randint(0, delta.days)
    return start_date + timedelta(days=random_days)

def random_datetime(start_date, end_date):
    """Generate random datetime between start and end"""
    delta = end_date - start_date
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start_date + timedelta(seconds=random_seconds)

print("[1/10] Generating customers...")
customers = []
with open(DATA_DIR / "customers.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "first_name", "last_name", "email", "phone", "date_of_birth",
                     "ssn", "address_line1", "city", "state", "postal_code", "country_code",
                     "risk_score", "kyc_status", "created_at"])
    
    for i in range(1, NUM_CUSTOMERS + 1):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        city_idx = random.randint(0, len(CITIES) - 1)
        
        customer = [
            i,  # customer_id
            first_name,
            last_name,
            generate_email(first_name, last_name, i),
            generate_phone(),
            random_date(datetime(1950, 1, 1), datetime(2005, 12, 31)).strftime("%Y-%m-%d"),
            generate_ssn(),
            f"{random.randint(100, 9999)} {random.choice(['Main', 'Oak', 'Maple', 'Park'])} St",
            CITIES[city_idx],
            STATES[city_idx],
            f"{random.randint(10000, 99999)}",
            random.choice(COUNTRIES),
            round(random.uniform(0, 100), 2),
            random.choice(["VERIFIED", "PENDING", "REJECTED"]),
            random_datetime(datetime(2020, 1, 1), datetime(2024, 1, 1)).strftime("%Y-%m-%d %H:%M:%S")
        ]
        writer.writerow(customer)
        customers.append(i)
        
        if i % 10000 == 0:
            print(f"  Generated {i:,} customers...")

print(f"✓ Generated {NUM_CUSTOMERS:,} customers")

print("[2/10] Generating accounts...")
accounts = []
with open(DATA_DIR / "accounts.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["account_id", "customer_id", "account_number", "account_type", "currency",
                     "balance", "available_balance", "status", "opened_date", "closed_date"])
    
    for i in range(1, NUM_ACCOUNTS + 1):
        customer_id = random.choice(customers)
        account_type = random.choice(["CHECKING", "SAVINGS", "CREDIT"])
        balance = round(random.uniform(100, 50000), 2)
        
        account = [
            i,  # account_id
            customer_id,
            f"{random.randint(1000000000, 9999999999)}",
            account_type,
            "USD",
            balance,
            balance * random.uniform(0.8, 1.0),
            random.choice(["ACTIVE", "ACTIVE", "ACTIVE", "SUSPENDED", "CLOSED"]),
            random_date(datetime(2020, 1, 1), datetime(2024, 1, 1)).strftime("%Y-%m-%d"),
            "" if random.random() > 0.05 else random_date(datetime(2023, 1, 1), datetime(2024, 12, 31)).strftime("%Y-%m-%d")
        ]
        writer.writerow(account)
        accounts.append(i)
        
        if i % 10000 == 0:
            print(f"  Generated {i:,} accounts...")

print(f"✓ Generated {NUM_ACCOUNTS:,} accounts")

print("[3/10] Generating merchants...")
merchants = []
with open(DATA_DIR / "merchants.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["merchant_id", "merchant_name", "category_id", "country_code", "city",
                     "risk_rating", "is_active", "created_at"])
    
    for i in range(1, NUM_MERCHANTS + 1):
        category = random.choice(MERCHANT_TYPES)
        city_idx = random.randint(0, len(CITIES) - 1)
        
        merchant = [
            i,  # merchant_id
            f"{category[1]} #{i}",
            random.randint(1, 35),  # category_id from merchant_categories
            random.choice(COUNTRIES),
            CITIES[city_idx],
            round(random.uniform(1, 10), 2),
            random.choice([True, True, True, False]),
            random_datetime(datetime(2015, 1, 1), datetime(2024, 1, 1)).strftime("%Y-%m-%d %H:%M:%S")
        ]
        writer.writerow(merchant)
        merchants.append(i)
        
        if i % 5000 == 0:
            print(f"  Generated {i:,} merchants...")

print(f"✓ Generated {NUM_MERCHANTS:,} merchants")

print("[4/10] Generating cards...")
cards = []
with open(DATA_DIR / "cards.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["card_id", "account_id", "card_number", "card_type", "expiry_date",
                     "cvv", "status", "daily_limit", "issued_date"])
    
    for i in range(1, NUM_CARDS + 1):
        account_id = random.choice(accounts)
        
        card = [
            i,  # card_id
            account_id,
            generate_card_number(),
            random.choice(["DEBIT", "CREDIT", "PREPAID"]),
            random_date(datetime(2025, 1, 1), datetime(2030, 12, 31)).strftime("%Y-%m-%d"),
            f"{random.randint(100, 999)}",
            random.choice(["ACTIVE", "ACTIVE", "ACTIVE", "BLOCKED", "EXPIRED"]),
            round(random.choice([500, 1000, 2000, 5000, 10000]), 2),
            random_date(datetime(2020, 1, 1), datetime(2024, 1, 1)).strftime("%Y-%m-%d")
        ]
        writer.writerow(card)
        cards.append(i)
        
        if i % 20000 == 0:
            print(f"  Generated {i:,} cards...")

print(f"✓ Generated {NUM_CARDS:,} cards")

print("[5/10] Generating transactions (this will take a few minutes)...")
print(f"  Generating {NUM_TRANSACTIONS:,} transactions in batches...")

