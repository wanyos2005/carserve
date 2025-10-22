-- Fix PostgreSQL enum issue: Add APP_DOWNLOAD_PROMPT to existing alerttype enum
-- This script adds the missing enum value to the existing enum type

-- Step 1: Add APP_DOWNLOAD_PROMPT to the existing alerttype enum
ALTER TYPE alerttype ADD VALUE 'APP_DOWNLOAD_PROMPT';

-- Step 2: Verify the enum values
SELECT typname, enumlabel 
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE typname = 'alerttype'
ORDER BY e.enumsortorder;

-- Step 3: Check if the value was added successfully
SELECT 
    typname,
    enumlabel,
    e.enumsortorder
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE typname = 'alerttype'
ORDER BY e.enumsortorder;

