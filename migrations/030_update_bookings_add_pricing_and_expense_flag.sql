BEGIN;

ALTER TABLE bookings.bookings
    ADD COLUMN IF NOT EXISTS base_price INTEGER,
    ADD COLUMN IF NOT EXISTS agreed_price INTEGER;

ALTER TABLE bookings.bookings
    ADD COLUMN IF NOT EXISTS has_negotiated BOOLEAN,
    ADD COLUMN IF NOT EXISTS negotiation_notes TEXT;

ALTER TABLE bookings.bookings
    ADD COLUMN IF NOT EXISTS expense_recorded BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE bookings.bookings
SET expense_recorded = FALSE
WHERE expense_recorded IS NULL;

COMMIT;
