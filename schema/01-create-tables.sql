-- ============================================================================
-- Business Analytics Database Schema
-- Purpose: Data Analyst training with routine/semi-routine analysis scenarios
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
-- New analytics tables
DROP TABLE IF EXISTS report_executions CASCADE;
DROP TABLE IF EXISTS report_definitions CASCADE;
DROP TABLE IF EXISTS data_quality_checks CASCADE;
DROP TABLE IF EXISTS dashboard_snapshots CASCADE;
DROP TABLE IF EXISTS trend_analysis CASCADE;
DROP TABLE IF EXISTS monthly_summaries CASCADE;
DROP TABLE IF EXISTS daily_metrics CASCADE;
DROP TABLE IF EXISTS kpi_definitions CASCADE;
DROP TABLE IF EXISTS revenue_forecasts CASCADE;
DROP TABLE IF EXISTS sales_performance CASCADE;
DROP TABLE IF EXISTS sales_targets CASCADE;
DROP TABLE IF EXISTS sales_transactions CASCADE;
DROP TABLE IF EXISTS product_catalog CASCADE;
DROP TABLE IF EXISTS engagement_metrics CASCADE;
DROP TABLE IF EXISTS customer_satisfaction CASCADE;
DROP TABLE IF EXISTS churn_predictions CASCADE;
DROP TABLE IF EXISTS customer_lifetime_value CASCADE;
DROP TABLE IF EXISTS customer_segments CASCADE;

-- Existing tables
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

-- ============================================================================
-- CUSTOMER ANALYTICS TABLES (for routine customer analysis)
-- ============================================================================

CREATE TABLE customer_segments (
    segment_id SERIAL PRIMARY KEY,
    segment_name VARCHAR(100) NOT NULL UNIQUE,
    segment_description TEXT,
    criteria_definition JSONB,
    min_clv DECIMAL(15,2),
    max_clv DECIMAL(15,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_lifetime_value (
    clv_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    calculation_date DATE NOT NULL,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_transactions INT DEFAULT 0,
    average_order_value DECIMAL(15,2) DEFAULT 0,
    predicted_future_value DECIMAL(15,2),
    clv_score DECIMAL(10,2),
    segment_id INT REFERENCES customer_segments(segment_id),
    UNIQUE(customer_id, calculation_date)
);

CREATE TABLE churn_predictions (
    prediction_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    prediction_date DATE NOT NULL,
    churn_probability DECIMAL(5,2) CHECK (churn_probability BETWEEN 0 AND 100),
    risk_level VARCHAR(20) CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    last_transaction_date DATE,
    days_since_last_transaction INT,
    engagement_score DECIMAL(5,2),
    recommended_action TEXT,
    UNIQUE(customer_id, prediction_date)
);

CREATE TABLE customer_satisfaction (
    satisfaction_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    survey_date DATE NOT NULL,
    nps_score INT CHECK (nps_score BETWEEN -100 AND 100),
    csat_score DECIMAL(3,2) CHECK (csat_score BETWEEN 1 AND 5),
    feedback_text TEXT,
    category VARCHAR(50) CHECK (category IN ('PRODUCT', 'SERVICE', 'SUPPORT', 'BILLING', 'OTHER')),
    sentiment VARCHAR(20) CHECK (sentiment IN ('POSITIVE', 'NEUTRAL', 'NEGATIVE'))
);

CREATE TABLE engagement_metrics (
    metric_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    metric_date DATE NOT NULL,
    login_count INT DEFAULT 0,
    page_views INT DEFAULT 0,
    time_spent_minutes INT DEFAULT 0,
    features_used JSONB,
    support_tickets_opened INT DEFAULT 0,
    engagement_score DECIMAL(5,2),
    UNIQUE(customer_id, metric_date)
);

-- ============================================================================
-- SALES & REVENUE ANALYTICS TABLES (for semi-routine sales reporting)
-- ============================================================================

CREATE TABLE product_catalog (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    product_category VARCHAR(100),
    product_subcategory VARCHAR(100),
    unit_price DECIMAL(15,2) NOT NULL,
    cost_price DECIMAL(15,2),
    margin_percentage DECIMAL(5,2),
    is_active BOOLEAN DEFAULT TRUE,
    launch_date DATE,
    discontinued_date DATE
);

CREATE TABLE sales_transactions (
    sale_id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES transactions(transaction_id),
    product_id INT REFERENCES product_catalog(product_id),
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(15,2) NOT NULL,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    sale_date TIMESTAMP NOT NULL,
    sales_channel VARCHAR(50) CHECK (sales_channel IN ('ONLINE', 'STORE', 'PHONE', 'MOBILE_APP')),
    sales_rep_id INT,
    region VARCHAR(100)
);

CREATE TABLE sales_targets (
    target_id SERIAL PRIMARY KEY,
    target_period VARCHAR(20) CHECK (target_period IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    product_category VARCHAR(100),
    region VARCHAR(100),
    target_revenue DECIMAL(15,2),
    target_units INT,
    target_customers INT,
    created_by VARCHAR(100),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sales_performance (
    performance_id SERIAL PRIMARY KEY,
    period_date DATE NOT NULL,
    period_type VARCHAR(20) CHECK (period_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY')),
    product_id INT REFERENCES product_catalog(product_id),
    region VARCHAR(100),
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_units_sold INT DEFAULT 0,
    total_transactions INT DEFAULT 0,
    unique_customers INT DEFAULT 0,
    average_order_value DECIMAL(15,2),
    vs_target_percentage DECIMAL(5,2),
    UNIQUE(period_date, period_type, product_id, region)
);

CREATE TABLE revenue_forecasts (
    forecast_id SERIAL PRIMARY KEY,
    forecast_date DATE NOT NULL,
    forecast_period_start DATE NOT NULL,
    forecast_period_end DATE NOT NULL,
    product_category VARCHAR(100),
    region VARCHAR(100),
    forecasted_revenue DECIMAL(15,2),
    confidence_level VARCHAR(20) CHECK (confidence_level IN ('LOW', 'MEDIUM', 'HIGH')),
    forecast_method VARCHAR(50) CHECK (forecast_method IN ('HISTORICAL', 'TREND', 'SEASONAL', 'ML')),
    actual_revenue DECIMAL(15,2),
    variance_percentage DECIMAL(5,2)
);


-- ============================================================================
-- OPERATIONAL METRICS & KPI TABLES (for dashboard creation)
-- ============================================================================

CREATE TABLE kpi_definitions (
    kpi_id SERIAL PRIMARY KEY,
    kpi_name VARCHAR(100) NOT NULL UNIQUE,
    kpi_description TEXT,
    kpi_category VARCHAR(50) CHECK (kpi_category IN ('SALES', 'CUSTOMER', 'OPERATIONAL', 'FINANCIAL')),
    calculation_formula TEXT,
    target_value DECIMAL(15,2),
    threshold_warning DECIMAL(15,2),
    threshold_critical DECIMAL(15,2),
    unit_of_measure VARCHAR(50),
    refresh_frequency VARCHAR(20) CHECK (refresh_frequency IN ('REALTIME', 'HOURLY', 'DAILY', 'WEEKLY')),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE daily_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    kpi_id INT NOT NULL REFERENCES kpi_definitions(kpi_id),
    metric_value DECIMAL(15,2),
    vs_previous_day_percentage DECIMAL(5,2),
    vs_previous_week_percentage DECIMAL(5,2),
    vs_previous_month_percentage DECIMAL(5,2),
    status VARCHAR(20) CHECK (status IN ('ON_TARGET', 'WARNING', 'CRITICAL')),
    notes TEXT,
    UNIQUE(metric_date, kpi_id)
);

CREATE TABLE monthly_summaries (
    summary_id SERIAL PRIMARY KEY,
    summary_month INT CHECK (summary_month BETWEEN 1 AND 12),
    summary_year INT,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_transactions INT DEFAULT 0,
    total_customers INT DEFAULT 0,
    new_customers INT DEFAULT 0,
    churned_customers INT DEFAULT 0,
    average_transaction_value DECIMAL(15,2),
    customer_acquisition_cost DECIMAL(15,2),
    customer_lifetime_value DECIMAL(15,2),
    net_promoter_score DECIMAL(5,2),
    gross_margin_percentage DECIMAL(5,2),
    UNIQUE(summary_month, summary_year)
);

CREATE TABLE trend_analysis (
    trend_id SERIAL PRIMARY KEY,
    kpi_id INT NOT NULL REFERENCES kpi_definitions(kpi_id),
    analysis_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    trend_direction VARCHAR(20) CHECK (trend_direction IN ('UP', 'DOWN', 'FLAT')),
    trend_strength VARCHAR(20) CHECK (trend_strength IN ('WEAK', 'MODERATE', 'STRONG')),
    moving_average_7day DECIMAL(15,2),
    moving_average_30day DECIMAL(15,2),
    seasonality_detected BOOLEAN DEFAULT FALSE,
    anomalies_detected BOOLEAN DEFAULT FALSE,
    statistical_significance DECIMAL(5,4)
);

CREATE TABLE dashboard_snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    dashboard_name VARCHAR(100) NOT NULL,
    snapshot_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_payload JSONB,
    refresh_duration_seconds DECIMAL(10,2),
    row_count INT,
    last_updated_by VARCHAR(100)
);

-- ============================================================================
-- BUSINESS INTELLIGENCE & REPORTING TABLES
-- ============================================================================

CREATE TABLE report_definitions (
    report_id SERIAL PRIMARY KEY,
    report_name VARCHAR(200) NOT NULL UNIQUE,
    report_description TEXT,
    report_category VARCHAR(100),
    sql_query_template TEXT,
    parameters JSONB,
    output_format VARCHAR(20) CHECK (output_format IN ('PDF', 'EXCEL', 'CSV', 'HTML')),
    schedule_frequency VARCHAR(50),
    recipients TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE report_executions (
    execution_id SERIAL PRIMARY KEY,
    report_id INT NOT NULL REFERENCES report_definitions(report_id),
    execution_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    parameters_used JSONB,
    row_count INT,
    execution_duration_seconds DECIMAL(10,2),
    status VARCHAR(20) CHECK (status IN ('SUCCESS', 'FAILED', 'TIMEOUT')),
    error_message TEXT,
    output_file_path TEXT,
    executed_by VARCHAR(100)
);

CREATE TABLE data_quality_checks (
    check_id SERIAL PRIMARY KEY,
    check_name VARCHAR(200) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    check_type VARCHAR(50) CHECK (check_type IN ('NULL_CHECK', 'RANGE_CHECK', 'UNIQUENESS', 'REFERENTIAL_INTEGRITY', 'FORMAT_CHECK')),
    check_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    records_checked INT,
    records_failed INT,
    failure_percentage DECIMAL(5,2),
    status VARCHAR(20) CHECK (status IN ('PASS', 'FAIL', 'WARNING')),
    remediation_notes TEXT
);

-- ============================================================================
-- INDEXES FOR NEW ANALYTICS TABLES
-- ============================================================================

-- Customer Analytics indexes
CREATE INDEX idx_clv_customer ON customer_lifetime_value(customer_id);
CREATE INDEX idx_clv_date ON customer_lifetime_value(calculation_date);
CREATE INDEX idx_clv_segment ON customer_lifetime_value(segment_id);
CREATE INDEX idx_churn_customer ON churn_predictions(customer_id);
CREATE INDEX idx_churn_risk ON churn_predictions(risk_level);
CREATE INDEX idx_satisfaction_customer ON customer_satisfaction(customer_id);
CREATE INDEX idx_engagement_customer ON engagement_metrics(customer_id);
CREATE INDEX idx_engagement_date ON engagement_metrics(metric_date);

-- Sales Analytics indexes
CREATE INDEX idx_sales_trans_product ON sales_transactions(product_id);
CREATE INDEX idx_sales_trans_date ON sales_transactions(sale_date);
CREATE INDEX idx_sales_trans_channel ON sales_transactions(sales_channel);
CREATE INDEX idx_sales_perf_date ON sales_performance(period_date);
CREATE INDEX idx_sales_perf_product ON sales_performance(product_id);
CREATE INDEX idx_product_category ON product_catalog(product_category);
CREATE INDEX idx_product_active ON product_catalog(is_active);

-- KPI & Metrics indexes
CREATE INDEX idx_daily_metrics_date ON daily_metrics(metric_date);
CREATE INDEX idx_daily_metrics_kpi ON daily_metrics(kpi_id);
CREATE INDEX idx_monthly_summaries_period ON monthly_summaries(summary_year, summary_month);
CREATE INDEX idx_trend_kpi ON trend_analysis(kpi_id);
CREATE INDEX idx_trend_date ON trend_analysis(analysis_date);

-- Reporting indexes
CREATE INDEX idx_report_exec_report ON report_executions(report_id);
CREATE INDEX idx_report_exec_timestamp ON report_executions(execution_timestamp);
CREATE INDEX idx_data_quality_table ON data_quality_checks(table_name);
CREATE INDEX idx_data_quality_date ON data_quality_checks(check_date);

-- ============================================================================
-- COMMENTS FOR NEW TABLES
-- ============================================================================

COMMENT ON TABLE customer_segments IS 'Customer segmentation definitions for targeted analysis';
COMMENT ON TABLE customer_lifetime_value IS 'Customer lifetime value calculations and tracking';
COMMENT ON TABLE churn_predictions IS 'Customer churn risk predictions for retention analysis';
COMMENT ON TABLE customer_satisfaction IS 'Customer satisfaction scores and feedback';
COMMENT ON TABLE engagement_metrics IS 'Customer engagement tracking metrics';
COMMENT ON TABLE product_catalog IS 'Product master data for sales analysis';
COMMENT ON TABLE sales_transactions IS 'Detailed sales transaction records';
COMMENT ON TABLE sales_targets IS 'Sales performance targets and goals';
COMMENT ON TABLE sales_performance IS 'Aggregated sales performance metrics';
COMMENT ON TABLE revenue_forecasts IS 'Revenue forecasting and predictions';
COMMENT ON TABLE kpi_definitions IS 'Master list of tracked KPIs';
COMMENT ON TABLE daily_metrics IS 'Daily operational metrics for dashboards';
COMMENT ON TABLE monthly_summaries IS 'Monthly aggregated business summaries';
COMMENT ON TABLE trend_analysis IS 'Statistical trend analysis results';
COMMENT ON TABLE dashboard_snapshots IS 'Pre-calculated dashboard data snapshots';
COMMENT ON TABLE report_definitions IS 'Standard report catalog';
COMMENT ON TABLE report_executions IS 'Report execution history and logs';
COMMENT ON TABLE data_quality_checks IS 'Data quality validation tracking';

