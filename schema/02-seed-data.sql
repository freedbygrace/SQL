-- ============================================================================
-- Seed Data for Reference Tables
-- ============================================================================
-- This script is IDEMPOTENT - it will delete and recreate all reference data
-- ============================================================================

-- Clear existing reference data (in reverse dependency order)
-- New analytics tables
TRUNCATE TABLE report_executions CASCADE;
TRUNCATE TABLE report_definitions RESTART IDENTITY CASCADE;
TRUNCATE TABLE data_quality_checks RESTART IDENTITY CASCADE;
TRUNCATE TABLE dashboard_snapshots RESTART IDENTITY CASCADE;
TRUNCATE TABLE trend_analysis RESTART IDENTITY CASCADE;
TRUNCATE TABLE monthly_summaries RESTART IDENTITY CASCADE;
TRUNCATE TABLE daily_metrics RESTART IDENTITY CASCADE;
TRUNCATE TABLE kpi_definitions RESTART IDENTITY CASCADE;
TRUNCATE TABLE revenue_forecasts RESTART IDENTITY CASCADE;
TRUNCATE TABLE sales_performance RESTART IDENTITY CASCADE;
TRUNCATE TABLE sales_targets RESTART IDENTITY CASCADE;
TRUNCATE TABLE sales_transactions RESTART IDENTITY CASCADE;
TRUNCATE TABLE product_catalog RESTART IDENTITY CASCADE;
TRUNCATE TABLE engagement_metrics RESTART IDENTITY CASCADE;
TRUNCATE TABLE customer_satisfaction RESTART IDENTITY CASCADE;
TRUNCATE TABLE churn_predictions RESTART IDENTITY CASCADE;
TRUNCATE TABLE customer_lifetime_value RESTART IDENTITY CASCADE;
TRUNCATE TABLE customer_segments RESTART IDENTITY CASCADE;

-- Existing tables
TRUNCATE TABLE suspicious_activity_reports CASCADE;
TRUNCATE TABLE case_alerts CASCADE;
TRUNCATE TABLE case_transactions CASCADE;
TRUNCATE TABLE fraud_cases CASCADE;
TRUNCATE TABLE alerts CASCADE;
TRUNCATE TABLE transfers CASCADE;
TRUNCATE TABLE beneficiaries CASCADE;
TRUNCATE TABLE transactions CASCADE;
TRUNCATE TABLE login_sessions CASCADE;
TRUNCATE TABLE devices CASCADE;
TRUNCATE TABLE cards CASCADE;
TRUNCATE TABLE accounts CASCADE;
TRUNCATE TABLE customer_relationships CASCADE;
TRUNCATE TABLE customers CASCADE;
TRUNCATE TABLE merchants CASCADE;
TRUNCATE TABLE merchant_categories RESTART IDENTITY CASCADE;
TRUNCATE TABLE fraud_types RESTART IDENTITY CASCADE;
TRUNCATE TABLE transaction_types RESTART IDENTITY CASCADE;
TRUNCATE TABLE countries RESTART IDENTITY CASCADE;

-- Insert Countries
INSERT INTO countries (country_code, country_name, region, risk_level) VALUES
('US', 'United States', 'North America', 'LOW'),
('CA', 'Canada', 'North America', 'LOW'),
('GB', 'United Kingdom', 'Europe', 'LOW'),
('DE', 'Germany', 'Europe', 'LOW'),
('FR', 'France', 'Europe', 'LOW'),
('IT', 'Italy', 'Europe', 'MEDIUM'),
('ES', 'Spain', 'Europe', 'MEDIUM'),
('AU', 'Australia', 'Oceania', 'LOW'),
('JP', 'Japan', 'Asia', 'LOW'),
('CN', 'China', 'Asia', 'MEDIUM'),
('IN', 'India', 'Asia', 'MEDIUM'),
('BR', 'Brazil', 'South America', 'MEDIUM'),
('MX', 'Mexico', 'North America', 'MEDIUM'),
('RU', 'Russia', 'Europe', 'HIGH'),
('NG', 'Nigeria', 'Africa', 'HIGH'),
('PK', 'Pakistan', 'Asia', 'HIGH'),
('IR', 'Iran', 'Middle East', 'CRITICAL'),
('KP', 'North Korea', 'Asia', 'CRITICAL'),
('SY', 'Syria', 'Middle East', 'CRITICAL'),
('VE', 'Venezuela', 'South America', 'HIGH'),
('CU', 'Cuba', 'Caribbean', 'HIGH'),
('MM', 'Myanmar', 'Asia', 'HIGH'),
('AF', 'Afghanistan', 'Asia', 'CRITICAL'),
('IQ', 'Iraq', 'Middle East', 'HIGH'),
('LY', 'Libya', 'Africa', 'HIGH'),
('SD', 'Sudan', 'Africa', 'HIGH'),
('SO', 'Somalia', 'Africa', 'CRITICAL'),
('YE', 'Yemen', 'Middle East', 'CRITICAL'),
('ZW', 'Zimbabwe', 'Africa', 'HIGH'),
('NL', 'Netherlands', 'Europe', 'LOW'),
('SE', 'Sweden', 'Europe', 'LOW'),
('NO', 'Norway', 'Europe', 'LOW'),
('DK', 'Denmark', 'Europe', 'LOW'),
('FI', 'Finland', 'Europe', 'LOW'),
('CH', 'Switzerland', 'Europe', 'LOW'),
('SG', 'Singapore', 'Asia', 'LOW'),
('HK', 'Hong Kong', 'Asia', 'MEDIUM'),
('KR', 'South Korea', 'Asia', 'LOW'),
('TW', 'Taiwan', 'Asia', 'LOW'),
('NZ', 'New Zealand', 'Oceania', 'LOW');

-- Insert Merchant Categories (based on MCC codes)
INSERT INTO merchant_categories (category_code, category_name, description, risk_weight) VALUES
('5411', 'Grocery Stores', 'Supermarkets and grocery stores', 0.50),
('5812', 'Restaurants', 'Eating places and restaurants', 0.60),
('5541', 'Gas Stations', 'Service stations and fuel', 0.55),
('5311', 'Department Stores', 'General merchandise stores', 0.70),
('5912', 'Pharmacies', 'Drug stores and pharmacies', 0.50),
('5999', 'Miscellaneous Retail', 'Specialty retail stores', 0.80),
('5732', 'Electronics', 'Electronics and computer stores', 1.20),
('5651', 'Clothing', 'Family clothing stores', 0.75),
('5814', 'Fast Food', 'Quick service restaurants', 0.60),
('5942', 'Books', 'Book stores', 0.65),
('5945', 'Hobby Shops', 'Hobby, toy, and game shops', 0.70),
('5971', 'Art Dealers', 'Art dealers and galleries', 1.50),
('5993', 'Cigar Stores', 'Cigar stores and stands', 1.10),
('5995', 'Pet Shops', 'Pet shops and supplies', 0.70),
('7011', 'Hotels', 'Lodging and hotels', 0.90),
('7512', 'Car Rental', 'Automobile rental agencies', 1.00),
('7523', 'Parking', 'Parking lots and garages', 0.60),
('7832', 'Movie Theaters', 'Motion picture theaters', 0.65),
('7922', 'Theatrical Producers', 'Theatrical producers and ticket agencies', 0.80),
('7991', 'Tourist Attractions', 'Tourist attractions and exhibits', 0.75),
('7995', 'Gambling', 'Betting and casino gambling', 2.50),
('5816', 'Digital Goods', 'Digital goods and games', 1.80),
('5967', 'Direct Marketing Inbound', 'Direct marketing and inbound telemarketing', 1.90),
('5966', 'Direct Marketing Outbound', 'Outbound telemarketing merchants', 2.00),
('6051', 'Cryptocurrency', 'Cryptocurrency and digital currency', 3.00),
('6211', 'Securities', 'Securities brokers and dealers', 1.50),
('6300', 'Insurance', 'Insurance sales and underwriting', 1.20),
('6513', 'Real Estate', 'Real estate agents and managers', 1.30),
('7273', 'Dating Services', 'Dating and escort services', 2.20),
('7297', 'Massage Parlors', 'Massage parlors', 2.50),
('7996', 'Online Gambling', 'Online gambling and betting', 3.50),
('5094', 'Precious Metals', 'Precious stones and metals', 2.80),
('5933', 'Pawn Shops', 'Pawn shops', 2.60),
('5960', 'Mail Order', 'Direct marketing and mail order', 1.70),
('4829', 'Wire Transfer', 'Money transfer services', 2.40);

-- Insert Transaction Types
INSERT INTO transaction_types (type_code, type_name, description, requires_merchant) VALUES
('PURCHASE', 'Purchase', 'Card purchase at merchant', TRUE),
('ATM_WITHDRAWAL', 'ATM Withdrawal', 'Cash withdrawal from ATM', FALSE),
('DEPOSIT', 'Deposit', 'Cash or check deposit', FALSE),
('TRANSFER_OUT', 'Transfer Out', 'Outgoing transfer', FALSE),
('TRANSFER_IN', 'Transfer In', 'Incoming transfer', FALSE),
('PAYMENT', 'Bill Payment', 'Bill payment transaction', TRUE),
('REFUND', 'Refund', 'Merchant refund', TRUE),
('FEE', 'Fee', 'Bank fee or charge', FALSE),
('INTEREST', 'Interest', 'Interest credit', FALSE),
('WIRE_OUT', 'Wire Transfer Out', 'Outgoing wire transfer', FALSE),
('WIRE_IN', 'Wire Transfer In', 'Incoming wire transfer', FALSE),
('CHECK', 'Check Payment', 'Check payment', FALSE),
('DIRECT_DEBIT', 'Direct Debit', 'Automated direct debit', TRUE),
('CASH_ADVANCE', 'Cash Advance', 'Credit card cash advance', FALSE),
('BALANCE_TRANSFER', 'Balance Transfer', 'Credit card balance transfer', FALSE);

-- Insert Fraud Types
INSERT INTO fraud_types (fraud_code, fraud_name, description, severity) VALUES
('CARD_NOT_PRESENT', 'Card Not Present Fraud', 'Fraudulent online or phone transactions', 'HIGH'),
('CARD_STOLEN', 'Stolen Card', 'Transactions using stolen physical card', 'HIGH'),
('ACCOUNT_TAKEOVER', 'Account Takeover', 'Unauthorized access to customer account', 'CRITICAL'),
('IDENTITY_THEFT', 'Identity Theft', 'Fraudulent account opened with stolen identity', 'CRITICAL'),
('FRIENDLY_FRAUD', 'Friendly Fraud', 'Customer disputes legitimate transaction', 'MEDIUM'),
('MONEY_MULE', 'Money Mule', 'Account used to launder money', 'CRITICAL'),
('SYNTHETIC_IDENTITY', 'Synthetic Identity', 'Fake identity using real and fake information', 'CRITICAL'),
('BUST_OUT', 'Bust Out Fraud', 'Building credit then maxing out and disappearing', 'HIGH'),
('REFUND_FRAUD', 'Refund Fraud', 'Fraudulent refund requests', 'MEDIUM'),
('CHARGEBACK_FRAUD', 'Chargeback Fraud', 'Abusing chargeback process', 'MEDIUM'),
('ATM_SKIMMING', 'ATM Skimming', 'Card data stolen via ATM skimmer', 'HIGH'),
('PHISHING', 'Phishing', 'Credentials stolen via phishing attack', 'HIGH'),
('SIM_SWAP', 'SIM Swap', 'Phone number hijacked for 2FA bypass', 'CRITICAL'),
('CHECK_FRAUD', 'Check Fraud', 'Fraudulent or altered checks', 'MEDIUM'),
('WIRE_FRAUD', 'Wire Fraud', 'Fraudulent wire transfer', 'CRITICAL'),
('STRUCTURING', 'Structuring', 'Breaking up transactions to avoid reporting', 'HIGH'),
('SMURFING', 'Smurfing', 'Using multiple people to structure transactions', 'HIGH'),
('TRADE_BASED', 'Trade-Based Money Laundering', 'Using trade to launder money', 'CRITICAL'),
('SHELL_COMPANY', 'Shell Company', 'Using fake companies for fraud', 'CRITICAL'),
('INVOICE_FRAUD', 'Invoice Fraud', 'Fraudulent invoicing schemes', 'HIGH');

-- Create a function to generate realistic transaction patterns
CREATE OR REPLACE FUNCTION generate_fraud_score(
    p_amount DECIMAL,
    p_is_international BOOLEAN,
    p_merchant_risk DECIMAL,
    p_time_of_day INT,
    p_is_online BOOLEAN
) RETURNS DECIMAL AS $$
DECLARE
    v_score DECIMAL := 0;
BEGIN
    -- Amount-based scoring
    IF p_amount > 5000 THEN v_score := v_score + 20; END IF;
    IF p_amount > 10000 THEN v_score := v_score + 30; END IF;
    
    -- International transactions
    IF p_is_international THEN v_score := v_score + 15; END IF;
    
    -- Merchant risk
    v_score := v_score + (p_merchant_risk * 10);
    
    -- Time of day (late night transactions)
    IF p_time_of_day >= 23 OR p_time_of_day <= 4 THEN v_score := v_score + 10; END IF;
    
    -- Online transactions
    IF p_is_online THEN v_score := v_score + 5; END IF;
    
    -- Cap at 100
    IF v_score > 100 THEN v_score := 100; END IF;
    
    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- Create a function to update account balances
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'COMPLETED' THEN
        IF TG_TABLE_NAME = 'transactions' THEN
            -- Update based on transaction type
            UPDATE accounts 
            SET current_balance = current_balance + 
                CASE 
                    WHEN NEW.type_id IN (SELECT type_id FROM transaction_types WHERE type_code IN ('DEPOSIT', 'TRANSFER_IN', 'WIRE_IN', 'REFUND', 'INTEREST')) 
                    THEN NEW.amount
                    ELSE -NEW.amount
                END,
                updated_at = CURRENT_TIMESTAMP
            WHERE account_id = NEW.account_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for balance updates (commented out for bulk loading)
-- CREATE TRIGGER trg_update_balance
-- AFTER INSERT ON transactions
-- FOR EACH ROW
-- EXECUTE FUNCTION update_account_balance();

-- Create a function to auto-generate alerts for suspicious transactions
CREATE OR REPLACE FUNCTION check_suspicious_transaction()
RETURNS TRIGGER AS $$
DECLARE
    v_alert_type VARCHAR(50);
    v_description TEXT;
    v_severity VARCHAR(20);
BEGIN
    -- High amount transactions
    IF NEW.amount > 10000 THEN
        v_alert_type := 'AMOUNT_ANOMALY';
        v_description := 'Large transaction amount: $' || NEW.amount;
        v_severity := 'HIGH';
        
        INSERT INTO alerts (transaction_id, customer_id, account_id, alert_type, severity, description, risk_score)
        SELECT NEW.transaction_id, a.customer_id, NEW.account_id, v_alert_type, v_severity, v_description, NEW.fraud_score
        FROM accounts a WHERE a.account_id = NEW.account_id;
    END IF;
    
    -- International transactions
    IF NEW.is_international AND NEW.amount > 1000 THEN
        v_alert_type := 'GEOGRAPHIC_ANOMALY';
        v_description := 'International transaction: $' || NEW.amount;
        v_severity := 'MEDIUM';
        
        INSERT INTO alerts (transaction_id, customer_id, account_id, alert_type, severity, description, risk_score)
        SELECT NEW.transaction_id, a.customer_id, NEW.account_id, v_alert_type, v_severity, v_description, NEW.fraud_score
        FROM accounts a WHERE a.account_id = NEW.account_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for alert generation (commented out for bulk loading)
-- CREATE TRIGGER trg_check_suspicious
-- AFTER INSERT ON transactions
-- FOR EACH ROW
-- WHEN (NEW.fraud_score > 50)
-- EXECUTE FUNCTION check_suspicious_transaction();

COMMENT ON FUNCTION generate_fraud_score IS 'Calculates fraud risk score based on transaction attributes';
COMMENT ON FUNCTION update_account_balance IS 'Automatically updates account balance after transaction';
COMMENT ON FUNCTION check_suspicious_transaction IS 'Generates alerts for suspicious transactions';

-- ============================================================================
-- SEED DATA FOR NEW ANALYTICS TABLES
-- ============================================================================

-- Customer Segments
INSERT INTO customer_segments (segment_name, segment_description, min_clv, max_clv) VALUES
('VIP', 'Very Important Person - Highest value customers', 50000, NULL),
('High Value', 'High spending customers with strong loyalty', 10000, 49999),
('Medium Value', 'Regular customers with moderate spending', 2000, 9999),
('Low Value', 'Occasional customers with low spending', 500, 1999),
('At Risk', 'Previously active customers showing decline', NULL, NULL),
('New Customer', 'Recently acquired customers (< 90 days)', NULL, NULL),
('Dormant', 'Inactive customers (> 180 days)', NULL, NULL),
('Churned', 'Lost customers who have not transacted in 365+ days', NULL, NULL);

-- Product Catalog (Sample Products)
INSERT INTO product_catalog (product_name, product_category, product_subcategory, unit_price, cost_price, margin_percentage, is_active, launch_date) VALUES
-- Banking Products
('Premium Checking Account', 'Banking', 'Checking', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('Basic Savings Account', 'Banking', 'Savings', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('High-Yield Savings', 'Banking', 'Savings', 0.00, 0.00, 0.00, TRUE, '2021-06-01'),
('Business Checking', 'Banking', 'Business', 15.00, 5.00, 66.67, TRUE, '2020-01-01'),
('Student Checking', 'Banking', 'Checking', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),

-- Credit Cards
('Platinum Credit Card', 'Credit', 'Premium', 99.00, 20.00, 79.80, TRUE, '2020-01-01'),
('Gold Credit Card', 'Credit', 'Standard', 49.00, 15.00, 69.39, TRUE, '2020-01-01'),
('Cash Back Card', 'Credit', 'Rewards', 0.00, 10.00, -100.00, TRUE, '2021-01-01'),
('Travel Rewards Card', 'Credit', 'Rewards', 95.00, 25.00, 73.68, TRUE, '2021-03-01'),
('Business Credit Card', 'Credit', 'Business', 75.00, 20.00, 73.33, TRUE, '2020-06-01'),

-- Loans
('Personal Loan', 'Lending', 'Personal', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('Auto Loan', 'Lending', 'Auto', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('Home Mortgage', 'Lending', 'Mortgage', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('Small Business Loan', 'Lending', 'Business', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),

-- Investment Products
('Index Fund', 'Investment', 'Mutual Funds', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('Bond Fund', 'Investment', 'Mutual Funds', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('Retirement Account (IRA)', 'Investment', 'Retirement', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),
('401k Plan', 'Investment', 'Retirement', 0.00, 0.00, 0.00, TRUE, '2020-01-01'),

-- Services
('Wire Transfer', 'Services', 'Transfers', 25.00, 5.00, 80.00, TRUE, '2020-01-01'),
('International Transfer', 'Services', 'Transfers', 45.00, 10.00, 77.78, TRUE, '2020-01-01'),
('Overdraft Protection', 'Services', 'Protection', 35.00, 5.00, 85.71, TRUE, '2020-01-01'),
('Safe Deposit Box', 'Services', 'Security', 75.00, 20.00, 73.33, TRUE, '2020-01-01'),
('Financial Advisory', 'Services', 'Advisory', 150.00, 50.00, 66.67, TRUE, '2021-01-01'),
('Mobile Banking Premium', 'Services', 'Digital', 9.99, 2.00, 79.98, TRUE, '2022-01-01');

-- KPI Definitions
INSERT INTO kpi_definitions (kpi_name, kpi_description, kpi_category, calculation_formula, target_value, threshold_warning, threshold_critical, unit_of_measure, refresh_frequency, is_active) VALUES
-- Sales KPIs
('Daily Revenue', 'Total revenue generated per day', 'SALES', 'SUM(amount) FROM transactions WHERE DATE(transaction_date) = CURRENT_DATE', 500000, 400000, 300000, 'USD', 'DAILY', TRUE),
('Monthly Revenue', 'Total revenue for the month', 'SALES', 'SUM(amount) FROM transactions WHERE MONTH(transaction_date) = CURRENT_MONTH', 15000000, 12000000, 10000000, 'USD', 'DAILY', TRUE),
('Average Transaction Value', 'Average value per transaction', 'SALES', 'AVG(amount) FROM transactions', 150, 100, 75, 'USD', 'DAILY', TRUE),
('Transactions Per Day', 'Number of transactions per day', 'SALES', 'COUNT(*) FROM transactions WHERE DATE(transaction_date) = CURRENT_DATE', 10000, 7500, 5000, 'Count', 'DAILY', TRUE),

-- Customer KPIs
('New Customers', 'New customer acquisitions', 'CUSTOMER', 'COUNT(*) FROM customers WHERE registration_date >= CURRENT_DATE - 30', 1000, 750, 500, 'Count', 'DAILY', TRUE),
('Customer Churn Rate', 'Percentage of customers churning', 'CUSTOMER', '(Churned / Total) * 100', 5, 7, 10, 'Percentage', 'WEEKLY', TRUE),
('Customer Lifetime Value', 'Average CLV across all customers', 'CUSTOMER', 'AVG(clv_score) FROM customer_lifetime_value', 5000, 4000, 3000, 'USD', 'WEEKLY', TRUE),
('Net Promoter Score', 'Customer satisfaction metric', 'CUSTOMER', 'AVG(nps_score) FROM customer_satisfaction', 50, 30, 10, 'Score', 'WEEKLY', TRUE),
('Customer Engagement Score', 'Average engagement across customers', 'CUSTOMER', 'AVG(engagement_score) FROM engagement_metrics', 75, 60, 45, 'Score', 'DAILY', TRUE),

-- Operational KPIs
('Transaction Success Rate', 'Percentage of successful transactions', 'OPERATIONAL', '(Successful / Total) * 100', 99, 97, 95, 'Percentage', 'HOURLY', TRUE),
('Average Response Time', 'System response time', 'OPERATIONAL', 'AVG(response_time_ms)', 200, 500, 1000, 'Milliseconds', 'REALTIME', TRUE),
('Fraud Detection Rate', 'Percentage of fraud caught', 'OPERATIONAL', '(Detected / Total Fraud) * 100', 95, 90, 85, 'Percentage', 'DAILY', TRUE),
('Alert Resolution Time', 'Average time to resolve alerts', 'OPERATIONAL', 'AVG(resolution_time_hours)', 24, 48, 72, 'Hours', 'DAILY', TRUE),

-- Financial KPIs
('Gross Margin', 'Overall profit margin', 'FINANCIAL', '((Revenue - Cost) / Revenue) * 100', 75, 65, 55, 'Percentage', 'DAILY', TRUE),
('Customer Acquisition Cost', 'Cost to acquire new customer', 'FINANCIAL', 'Marketing Spend / New Customers', 50, 75, 100, 'USD', 'WEEKLY', TRUE),
('Return on Investment', 'ROI on marketing campaigns', 'FINANCIAL', '((Revenue - Cost) / Cost) * 100', 300, 200, 100, 'Percentage', 'WEEKLY', TRUE);

-- Report Definitions
INSERT INTO report_definitions (report_name, report_description, report_category, output_format, schedule_frequency, is_active) VALUES
('Daily Sales Summary', 'Daily sales performance report', 'Sales', 'PDF', 'Daily at 6 AM', TRUE),
('Weekly Customer Analytics', 'Customer behavior and segmentation analysis', 'Customer', 'EXCEL', 'Weekly on Monday', TRUE),
('Monthly Financial Summary', 'Comprehensive monthly financial report', 'Financial', 'PDF', 'Monthly on 1st', TRUE),
('Fraud Detection Report', 'Daily fraud alerts and cases', 'Risk', 'PDF', 'Daily at 8 AM', TRUE),
('KPI Dashboard', 'Executive KPI dashboard', 'Executive', 'HTML', 'Daily at 7 AM', TRUE),
('Customer Churn Analysis', 'At-risk customer identification', 'Customer', 'EXCEL', 'Weekly on Friday', TRUE),
('Product Performance', 'Product sales and profitability analysis', 'Sales', 'EXCEL', 'Monthly on 5th', TRUE),
('Data Quality Report', 'Data validation and quality metrics', 'Operations', 'CSV', 'Daily at 5 AM', TRUE);

