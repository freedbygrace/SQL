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

transactions = []
fraudulent_transactions = []
batch_size = 100000
start_date = datetime(2023, 1, 1)
end_date = datetime(2024, 12, 31)

with open(DATA_DIR / "transactions.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["transaction_id", "account_id", "card_id", "merchant_id", "transaction_type",
                     "amount", "currency", "transaction_date", "status", "is_flagged", "fraud_score",
                     "ip_address", "device_id", "location_city", "location_country"])

    for i in range(1, NUM_TRANSACTIONS + 1):
        account_id = random.choice(accounts)
        card_id = random.choice(cards) if random.random() > 0.3 else ""
        merchant_id = random.choice(merchants) if random.random() > 0.1 else ""
        trans_type = random.choice(TRANSACTION_TYPES)

        # Determine if fraudulent
        is_fraud = random.random() < FRAUD_RATE
        fraud_score = round(random.uniform(70, 100), 2) if is_fraud else round(random.uniform(0, 30), 2)
        is_flagged = is_fraud or (fraud_score > 60)

        # Amount varies by transaction type
        if trans_type in ["PURCHASE", "PAYMENT"]:
            amount = round(random.uniform(5, 5000), 2)
        elif trans_type in ["ATM_WITHDRAWAL", "TRANSFER_OUT"]:
            amount = round(random.uniform(20, 2000), 2)
        elif trans_type in ["WIRE_OUT", "WIRE_IN"]:
            amount = round(random.uniform(1000, 50000), 2)
        else:
            amount = round(random.uniform(10, 1000), 2)

        # Fraudulent transactions tend to be larger
        if is_fraud:
            amount = amount * random.uniform(2, 10)

        city_idx = random.randint(0, len(CITIES) - 1)

        transaction = [
            i,  # transaction_id
            account_id,
            card_id,
            merchant_id,
            trans_type,
            round(amount, 2),
            "USD",
            random_datetime(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S"),
            random.choice(["COMPLETED", "COMPLETED", "COMPLETED", "PENDING", "FAILED"]),
            is_flagged,
            fraud_score,
            f"{random.randint(1, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}",
            random.randint(1, 75000) if random.random() > 0.2 else "",
            CITIES[city_idx],
            random.choice(COUNTRIES)
        ]
        writer.writerow(transaction)
        transactions.append(i)

        if is_fraud:
            fraudulent_transactions.append(i)

        if i % batch_size == 0:
            print(f"  Generated {i:,} transactions...")

print(f"✓ Generated {NUM_TRANSACTIONS:,} transactions ({len(fraudulent_transactions):,} fraudulent)")

print("[6/10] Generating alerts...")
alerts = []
with open(DATA_DIR / "alerts.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["alert_id", "transaction_id", "customer_id", "alert_type", "severity",
                     "alert_date", "status", "assigned_to", "resolution_notes"])

    alert_id = 1
    for trans_id in fraudulent_transactions:
        if random.random() > 0.3:  # 70% of fraudulent transactions generate alerts
            alert = [
                alert_id,
                trans_id,
                random.choice(customers),
                random.choice(["UNUSUAL_AMOUNT", "UNUSUAL_LOCATION", "VELOCITY_CHECK", "BLACKLIST_MATCH"]),
                random.choice(["LOW", "MEDIUM", "HIGH", "CRITICAL"]),
                random_datetime(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S"),
                random.choice(["OPEN", "INVESTIGATING", "RESOLVED", "FALSE_POSITIVE"]),
                f"analyst{random.randint(1, 10)}" if random.random() > 0.3 else "",
                ""
            ]
            writer.writerow(alert)
            alerts.append(alert_id)
            alert_id += 1

print(f"✓ Generated {len(alerts):,} alerts")

print("[7/10] Generating fraud cases...")
with open(DATA_DIR / "fraud_cases.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["case_id", "customer_id", "case_number", "fraud_type_id", "case_status",
                     "total_loss_amount", "recovered_amount", "opened_date", "closed_date",
                     "assigned_investigator", "priority"])

    case_id = 1
    for i in range(len(fraudulent_transactions) // 10):  # About 10% of fraudulent transactions become cases
        case = [
            case_id,
            random.choice(customers),
            f"CASE-{datetime.now().year}-{case_id:06d}",
            random.randint(1, 20),  # fraud_type_id
            random.choice(["OPEN", "INVESTIGATING", "CLOSED", "ESCALATED"]),
            round(random.uniform(500, 50000), 2),
            round(random.uniform(0, 10000), 2),
            random_datetime(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S"),
            random_datetime(start_date, end_date).strftime("%Y-%m-%d %H:%M:%S") if random.random() > 0.4 else "",
            f"investigator{random.randint(1, 5)}",
            random.choice(["LOW", "MEDIUM", "HIGH", "CRITICAL"])
        ]
        writer.writerow(case)
        case_id += 1

print(f"✓ Generated {case_id - 1:,} fraud cases")

print("[8/10] Generating devices...")
with open(DATA_DIR / "devices.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["device_id", "customer_id", "device_fingerprint", "device_type",
                     "os_type", "browser", "first_seen", "last_seen", "is_trusted"])

    for i in range(1, 75001):
        device = [
            i,
            random.choice(customers),
            f"fp_{random.randint(100000000, 999999999)}",
            random.choice(["MOBILE", "DESKTOP", "TABLET"]),
            random.choice(["iOS", "Android", "Windows", "macOS", "Linux"]),
            random.choice(["Chrome", "Safari", "Firefox", "Edge", "Opera"]),
            random_datetime(datetime(2022, 1, 1), datetime(2024, 1, 1)).strftime("%Y-%m-%d %H:%M:%S"),
            random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)).strftime("%Y-%m-%d %H:%M:%S"),
            random.choice([True, True, True, False])
        ]
        writer.writerow(device)

        if i % 10000 == 0:
            print(f"  Generated {i:,} devices...")

print(f"✓ Generated 75,000 devices")

print("[9/10] Generating customer segments...")
with open(DATA_DIR / "customer_segments.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["segment_id", "segment_name", "segment_description", "criteria_definition",
                     "min_clv", "max_clv"])

    segments = [
        (1, "VIP", "Top tier customers", '{"criteria": "clv > 50000"}', 50000, 999999),
        (2, "High Value", "High spending customers", '{"criteria": "clv > 10000"}', 10000, 50000),
        (3, "Regular", "Standard active customers", '{"criteria": "clv > 1000"}', 1000, 10000),
        (4, "New", "Recently acquired customers", '{"criteria": "tenure < 90"}', 0, 999999),
        (5, "At Risk", "Customers showing signs of churn", '{"criteria": "activity_score < 30"}', 0, 999999),
        (6, "Dormant", "Inactive customers", '{"criteria": "last_activity > 180"}', 0, 999999),
    ]

    for segment in segments:
        writer.writerow(segment)

print(f"✓ Generated {len(segments)} customer segments")

print("[10/10] Generating customer lifetime value...")
with open(DATA_DIR / "customer_lifetime_value.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["clv_id", "customer_id", "segment_id", "total_revenue", "total_transactions",
                     "average_transaction_value", "customer_tenure_days", "predicted_clv",
                     "calculation_date"])

    for i in range(1, NUM_CUSTOMERS + 1):
        total_trans = random.randint(1, 500)
        total_rev = round(random.uniform(100, 100000), 2)

        clv = [
            i,
            i,  # customer_id
            random.randint(1, 6),  # segment_id
            total_rev,
            total_trans,
            round(total_rev / total_trans, 2),
            random.randint(30, 1500),
            round(total_rev * random.uniform(1.2, 3.0), 2),
            datetime.now().strftime("%Y-%m-%d")
        ]
        writer.writerow(clv)

        if i % 10000 == 0:
            print(f"  Generated {i:,} CLV records...")

print(f"✓ Generated {NUM_CUSTOMERS:,} CLV records")

print()
print("=" * 80)
print("✓ CSV Data Generation Complete!")
print("=" * 80)
print(f"CSV files saved to: {DATA_DIR}")
print()
print("Generated files:")
print(f"  - customers.csv ({NUM_CUSTOMERS:,} rows)")
print(f"  - accounts.csv ({NUM_ACCOUNTS:,} rows)")
print(f"  - merchants.csv ({NUM_MERCHANTS:,} rows)")
print(f"  - cards.csv ({NUM_CARDS:,} rows)")
print(f"  - transactions.csv ({NUM_TRANSACTIONS:,} rows)")
print(f"  - alerts.csv ({len(alerts):,} rows)")
print(f"  - fraud_cases.csv")
print(f"  - devices.csv (75,000 rows)")
print(f"  - customer_segments.csv ({len(segments)} rows)")
print(f"  - customer_lifetime_value.csv ({NUM_CUSTOMERS:,} rows)")
print()
print("Next step: Run the CSV import script to load data into PostgreSQL")
print("=" * 80)

