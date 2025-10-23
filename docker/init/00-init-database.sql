-- ============================================================================
-- Database Initialization Script
-- ============================================================================
-- This script ensures the database is created and ready
-- It runs automatically when the PostgreSQL container starts
-- ============================================================================

-- Ensure the database exists (this runs in the default postgres database)
SELECT 'Database initialization starting...' AS status;

-- Set timezone
SET timezone = 'UTC';

-- Show current database
SELECT current_database() AS current_db, current_user AS current_user, version() AS pg_version;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

SELECT 'Extensions enabled successfully' AS status;

