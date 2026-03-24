-- Migration: add response_body to payments.webhook_delivery_logs
-- Run once against the payments database.

ALTER TABLE payments.webhook_delivery_logs
    ADD COLUMN IF NOT EXISTS response_body TEXT;
