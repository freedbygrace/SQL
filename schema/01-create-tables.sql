-- ============================================================================
-- Financial Fraud Detection Database Schema
-- Purpose: Educational SQL learning with realistic fraud investigation scenarios
-- ============================================================================
-- This script is IDEMPOTENT - it will drop and recreate all objects
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- DROP ALL EXISTING OBJECTS (in reverse dependency order)
-- ============================================================================

-- Drop triggers first
DROP TRIGGER IF EXISTS trg_update_balance ON transactions;
DROP TRIGGER IF EXISTS trg_check_suspicious ON transactions;

-- Drop functions
DROP FUNCTION IF EXISTS update_account_balance() CASCADE;
DROP FUNCTION IF EXISTS check_suspicious_transaction() CASCADE;
DROP FUNCTION IF EXISTS generate_fraud_score(DECIMAL, BOOLEAN, DECIMAL, INT, BOOLEAN) CASCADE;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS suspicious_activity_reports CASCADE;
DROP TABLE IF EXISTS case_alerts CASCADE;
DROP TABLE IF EXISTS case_transactions CASCADE;
DROP TABLE IF EXISTS fraud_cases CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS transfers CASCADE;
DROP TABLE IF EXISTS beneficiaries CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS login_sessions CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customer_relationships CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS merchants CASCADE;
DROP TABLE IF EXISTS merchant_categories CASCADE;
DROP TABLE IF EXISTS fraud_types CASCADE;
DROP TABLE IF EXISTS transaction_types CASCADE;
DROP TABLE IF EXISTS countries CASCADE;

-- ============================================================================
-- REFERENCE/LOOKUP TABLES
-- ============================================================================

-- Countries reference table
CREATE TABLE countries (
    country_id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL UNIQUE,
    country_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    risk_level VARCHAR(20) DEFAULT 'LOW' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Merchant categories
CREATE TABLE merchant_categories (
    category_id SERIAL PRIMARY KEY,
    category_code VARCHAR(10) NOT NULL UNIQUE,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    risk_weight DECIMAL(3,2) DEFAULT 1.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction types
CREATE TABLE transaction_types (
    type_id SERIAL PRIMARY KEY,
    type_code VARCHAR(20) NOT NULL UNIQUE,
    type_name VARCHAR(100) NOT NULL,
    description TEXT,
    requires_merchant BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fraud types
CREATE TABLE fraud_types (
    fraud_type_id SERIAL PRIMARY KEY,
    fraud_code VARCHAR(20) NOT NULL UNIQUE,
    fraud_name VARCHAR(100) NOT NULL,
    description TEXT,
    severity VARCHAR(20) DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CUSTOMER DOMAIN
-- ============================================================================

-- Customers table
CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE NOT NULL,
    ssn_hash VARCHAR(64) NOT NULL UNIQUE, -- Hashed SSN for privacy
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country_id INT NOT NULL REFERENCES countries(country_id),
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    kyc_status VARCHAR(20) DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'EXPIRED')),
    kyc_verified_date TIMESTAMP,
    risk_score DECIMAL(5,2) DEFAULT 50.00 CHECK (risk_score BETWEEN 0 AND 100),
    is_pep BOOLEAN DEFAULT FALSE, -- Politically Exposed Person
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customer relationships (for detecting collusion networks)
CREATE TABLE customer_relationships (
    relationship_id BIGSERIAL PRIMARY KEY,
    customer_id_1 BIGINT NOT NULL REFERENCES customers(customer_id),
    customer_id_2 BIGINT NOT NULL REFERENCES customers(customer_id),
    relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN ('FAMILY', 'BUSINESS', 'SHARED_ADDRESS', 'SHARED_DEVICE', 'SHARED_IP', 'SUSPECTED_MULE')),
    confidence_score DECIMAL(5,2) DEFAULT 50.00 CHECK (confidence_score BETWEEN 0 AND 100),
    detected_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    CONSTRAINT different_customers CHECK (customer_id_1 != customer_id_2),
    CONSTRAINT unique_relationship UNIQUE (customer_id_1, customer_id_2, relationship_type)
);

-- ============================================================================
-- ACCOUNT DOMAIN
-- ============================================================================

-- Accounts table
CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('CHECKING', 'SAVINGS', 'CREDIT', 'INVESTMENT', 'LOAN')),
    currency CHAR(3) DEFAULT 'USD',
    opening_date DATE NOT NULL DEFAULT CURRENT_DATE,
    closing_date DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED', 'FROZEN')),
    current_balance DECIMAL(15,2) DEFAULT 0.00,
    available_balance DECIMAL(15,2) DEFAULT 0.00,
    credit_limit DECIMAL(15,2),
    overdraft_limit DECIMAL(15,2) DEFAULT 0.00,
    interest_rate DECIMAL(5,4),
    monthly_fee DECIMAL(8,2) DEFAULT 0.00,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cards table
CREATE TABLE cards (
    card_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    card_number_hash VARCHAR(64) NOT NULL UNIQUE, -- Hashed card number
    card_last_four CHAR(4) NOT NULL,
    card_type VARCHAR(20) NOT NULL CHECK (card_type IN ('DEBIT', 'CREDIT', 'PREPAID', 'VIRTUAL')),
    card_network VARCHAR(20) NOT NULL CHECK (card_network IN ('VISA', 'MASTERCARD', 'AMEX', 'DISCOVER')),
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE NOT NULL,
    cvv_hash VARCHAR(64) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BLOCKED', 'EXPIRED', 'LOST', 'STOLEN')),
    daily_limit DECIMAL(10,2) DEFAULT 5000.00,
    monthly_limit DECIMAL(12,2) DEFAULT 50000.00,
    is_contactless BOOLEAN DEFAULT TRUE,
    is_international BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- MERCHANT DOMAIN
-- ============================================================================

-- Merchants table
CREATE TABLE merchants (
    merchant_id BIGSERIAL PRIMARY KEY,
    merchant_name VARCHAR(255) NOT NULL,
    merchant_code VARCHAR(50) UNIQUE,
    category_id INT NOT NULL REFERENCES merchant_categories(category_id),
    country_id INT NOT NULL REFERENCES countries(country_id),
    city VARCHAR(100),
    website VARCHAR(255),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BLACKLISTED', 'CLOSED')),
    risk_rating VARCHAR(20) DEFAULT 'LOW' CHECK (risk_rating IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    total_transactions BIGINT DEFAULT 0,
    total_volume DECIMAL(18,2) DEFAULT 0.00,
    fraud_incidents INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DEVICE & SESSION DOMAIN
-- ============================================================================

-- Devices table (for tracking login devices)
CREATE TABLE devices (
    device_id BIGSERIAL PRIMARY KEY,
    device_fingerprint VARCHAR(64) NOT NULL UNIQUE,
    device_type VARCHAR(20) CHECK (device_type IN ('MOBILE', 'TABLET', 'DESKTOP', 'OTHER')),
    os_name VARCHAR(50),
    os_version VARCHAR(50),
    browser_name VARCHAR(50),
    browser_version VARCHAR(50),
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_trusted BOOLEAN DEFAULT FALSE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Login sessions
CREATE TABLE login_sessions (
    session_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    device_id BIGINT NOT NULL REFERENCES devices(device_id),
    ip_address INET NOT NULL,
    country_id INT REFERENCES countries(country_id),
    city VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    login_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_timestamp TIMESTAMP,
    session_duration_seconds INT,
    is_successful BOOLEAN DEFAULT TRUE,
    failure_reason VARCHAR(255),
    risk_score DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TRANSACTION DOMAIN
-- ============================================================================

-- Transactions table (main transaction log)
CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    type_id INT NOT NULL REFERENCES transaction_types(type_id),
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) DEFAULT 'USD',
    merchant_id BIGINT REFERENCES merchants(merchant_id),
    card_id BIGINT REFERENCES cards(card_id),
    device_id BIGINT REFERENCES devices(device_id),
    ip_address INET,
    country_id INT REFERENCES countries(country_id),
    city VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    description TEXT,
    reference_number VARCHAR(50) UNIQUE,
    status VARCHAR(20) DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED', 'FLAGGED', 'BLOCKED')),
    is_online BOOLEAN DEFAULT TRUE,
    is_international BOOLEAN DEFAULT FALSE,
    is_card_present BOOLEAN DEFAULT FALSE,
    fraud_score DECIMAL(5,2) DEFAULT 0.00 CHECK (fraud_score BETWEEN 0 AND 100),
    is_flagged BOOLEAN DEFAULT FALSE,
    flagged_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Beneficiaries (for transfers)
CREATE TABLE beneficiaries (
    beneficiary_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    beneficiary_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    bank_name VARCHAR(255),
    bank_code VARCHAR(20),
    country_id INT NOT NULL REFERENCES countries(country_id),
    relationship VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP,
    total_transfers INT DEFAULT 0,
    total_amount DECIMAL(18,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transfer transactions
CREATE TABLE transfers (
    transfer_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(transaction_id),
    from_account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    to_account_id BIGINT REFERENCES accounts(account_id), -- NULL for external transfers
    beneficiary_id BIGINT REFERENCES beneficiaries(beneficiary_id),
    transfer_type VARCHAR(20) NOT NULL CHECK (transfer_type IN ('INTERNAL', 'DOMESTIC', 'INTERNATIONAL', 'WIRE')),
    purpose VARCHAR(255),
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FRAUD DETECTION & ALERTS DOMAIN
-- ============================================================================

-- Alerts table (system-generated suspicious activity alerts)
CREATE TABLE alerts (
    alert_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    customer_id BIGINT REFERENCES customers(customer_id),
    account_id BIGINT REFERENCES accounts(account_id),
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN (
        'VELOCITY_CHECK', 'AMOUNT_ANOMALY', 'GEOGRAPHIC_ANOMALY',
        'MERCHANT_RISK', 'DEVICE_CHANGE', 'UNUSUAL_TIME',
        'MULTIPLE_CARDS', 'ACCOUNT_TAKEOVER', 'MONEY_MULE', 'STRUCTURING'
    )),
    severity VARCHAR(20) DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT NOT NULL,
    risk_score DECIMAL(5,2) DEFAULT 50.00 CHECK (risk_score BETWEEN 0 AND 100),
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'INVESTIGATING', 'CLOSED', 'FALSE_POSITIVE', 'CONFIRMED_FRAUD')),
    assigned_to VARCHAR(100),
    reviewed_date TIMESTAMP,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fraud cases (confirmed fraud incidents)
CREATE TABLE fraud_cases (
    case_id BIGSERIAL PRIMARY KEY,
    case_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT REFERENCES customers(customer_id),
    account_id BIGINT REFERENCES accounts(account_id),
    fraud_type_id INT NOT NULL REFERENCES fraud_types(fraud_type_id),
    detection_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detection_method VARCHAR(50) CHECK (detection_method IN ('AUTOMATED', 'CUSTOMER_REPORT', 'MANUAL_REVIEW', 'THIRD_PARTY')),
    amount_lost DECIMAL(15,2) DEFAULT 0.00,
    amount_recovered DECIMAL(15,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'CLOSED', 'LEGAL_ACTION')),
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    assigned_investigator VARCHAR(100),
    investigation_notes TEXT,
    resolution_date TIMESTAMP,
    resolution_summary TEXT,
    law_enforcement_notified BOOLEAN DEFAULT FALSE,
    customer_notified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Case transactions (linking transactions to fraud cases)
CREATE TABLE case_transactions (
    case_transaction_id BIGSERIAL PRIMARY KEY,
    case_id BIGINT NOT NULL REFERENCES fraud_cases(case_id),
    transaction_id BIGINT NOT NULL REFERENCES transactions(transaction_id),
    is_fraudulent BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_case_transaction UNIQUE (case_id, transaction_id)
);

-- Case alerts (linking alerts to fraud cases)
CREATE TABLE case_alerts (
    case_alert_id BIGSERIAL PRIMARY KEY,
    case_id BIGINT NOT NULL REFERENCES fraud_cases(case_id),
    alert_id BIGINT NOT NULL REFERENCES alerts(alert_id),
    relevance_score DECIMAL(5,2) DEFAULT 50.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_case_alert UNIQUE (case_id, alert_id)
);

-- ============================================================================
-- AUDIT & COMPLIANCE DOMAIN
-- ============================================================================

-- Audit log (comprehensive audit trail)
CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Suspicious Activity Reports (SAR)
CREATE TABLE suspicious_activity_reports (
    sar_id BIGSERIAL PRIMARY KEY,
    sar_number VARCHAR(50) NOT NULL UNIQUE,
    case_id BIGINT REFERENCES fraud_cases(case_id),
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    filing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    activity_date_from DATE NOT NULL,
    activity_date_to DATE NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    activity_description TEXT NOT NULL,
    filed_by VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'ACKNOWLEDGED', 'CLOSED')),
    submission_date DATE,
    acknowledgment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Customer indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_country ON customers(country_id);
CREATE INDEX idx_customers_risk_score ON customers(risk_score DESC);
CREATE INDEX idx_customers_registration_date ON customers(registration_date);

-- Account indexes
CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_status ON accounts(status);
CREATE INDEX idx_accounts_type ON accounts(account_type);

-- Transaction indexes (critical for performance)
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX idx_transactions_merchant ON transactions(merchant_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_flagged ON transactions(is_flagged) WHERE is_flagged = TRUE;
CREATE INDEX idx_transactions_fraud_score ON transactions(fraud_score DESC);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_transactions_country ON transactions(country_id);

-- Card indexes
CREATE INDEX idx_cards_account ON cards(account_id);
CREATE INDEX idx_cards_status ON cards(status);

-- Alert indexes
CREATE INDEX idx_alerts_customer ON alerts(customer_id);
CREATE INDEX idx_alerts_transaction ON alerts(transaction_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_date ON alerts(alert_date DESC);
CREATE INDEX idx_alerts_severity ON alerts(severity);

-- Fraud case indexes
CREATE INDEX idx_fraud_cases_customer ON fraud_cases(customer_id);
CREATE INDEX idx_fraud_cases_status ON fraud_cases(status);
CREATE INDEX idx_fraud_cases_detection_date ON fraud_cases(detection_date DESC);

-- Login session indexes
CREATE INDEX idx_login_sessions_customer ON login_sessions(customer_id);
CREATE INDEX idx_login_sessions_timestamp ON login_sessions(login_timestamp DESC);
CREATE INDEX idx_login_sessions_ip ON login_sessions(ip_address);

-- Merchant indexes
CREATE INDEX idx_merchants_category ON merchants(category_id);
CREATE INDEX idx_merchants_country ON merchants(country_id);
CREATE INDEX idx_merchants_risk_rating ON merchants(risk_rating);

-- Comments for documentation
COMMENT ON TABLE customers IS 'Customer master data with KYC and risk information';
COMMENT ON TABLE accounts IS 'Customer accounts including checking, savings, credit, etc.';
COMMENT ON TABLE transactions IS 'Main transaction log with fraud scoring';
COMMENT ON TABLE alerts IS 'System-generated fraud alerts requiring review';
COMMENT ON TABLE fraud_cases IS 'Confirmed fraud cases under investigation';
COMMENT ON TABLE merchants IS 'Merchant directory with risk ratings';
COMMENT ON TABLE cards IS 'Payment cards linked to accounts';
COMMENT ON TABLE devices IS 'Device fingerprints for fraud detection';
COMMENT ON TABLE login_sessions IS 'Login history for account takeover detection';

