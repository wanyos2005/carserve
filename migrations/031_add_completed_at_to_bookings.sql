BEGIN;

-- Add completed_at column to bookings table
ALTER TABLE bookings.bookings
    ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Set completed_at = created_at for existing completed bookings
UPDATE bookings.bookings
SET completed_at = created_at
WHERE status = 'completed' AND completed_at IS NULL;

COMMIT;
