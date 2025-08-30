-- Development seed data for __ApplicationName__
-- This script runs after the database is initialized in development environment

-- Insert sample data for Orders module (if exists)
DO $$
BEGIN
    -- Check if Orders table exists before inserting data
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Orders') THEN
        INSERT INTO "Orders" ("Id", "OrderNumber", "Status", "TotalAmount", "CreatedAt")
        VALUES 
            (uuid_generate_v4(), 'ORD-001', 'Pending', 99.99, NOW()),
            (uuid_generate_v4(), 'ORD-002', 'Completed', 149.50, NOW() - INTERVAL '1 day'),
            (uuid_generate_v4(), 'ORD-003', 'Cancelled', 75.25, NOW() - INTERVAL '2 days')
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE 'Sample orders inserted successfully';
    ELSE
        RAISE NOTICE 'Orders table does not exist, skipping sample data';
    END IF;
    
EXCEPTION 
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting sample data: %', SQLERRM;
END $$;

-- Insert sample users/authentication data if needed
DO $$
BEGIN
    -- Add sample users if user table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Users') THEN
        INSERT INTO "Users" ("Id", "Email", "FirstName", "LastName", "CreatedAt")
        VALUES 
            (uuid_generate_v4(), 'admin@__ApplicationName__.local', 'Admin', 'User', NOW()),
            (uuid_generate_v4(), 'user@__ApplicationName__.local', 'Regular', 'User', NOW())
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE 'Sample users inserted successfully';
    END IF;
    
EXCEPTION 
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting sample users: %', SQLERRM;
END $$;

COMMIT;
