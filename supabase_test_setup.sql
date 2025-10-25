-- Simple test table for Supabase connection testing
-- Run this in your Supabase SQL Editor

-- Create a simple test table
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert a test record
INSERT INTO test_table (name, email) VALUES ('Test User', 'test@example.com');

-- Enable Row Level Security (optional for testing)
ALTER TABLE test_table ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows all operations (for testing only)
CREATE POLICY "Allow all operations for testing" ON test_table
FOR ALL USING (true) WITH CHECK (true);

-- Verify the table was created
SELECT * FROM test_table;
