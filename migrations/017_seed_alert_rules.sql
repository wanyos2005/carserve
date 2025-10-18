-- ==============================================
-- SEED DEFAULT ALERT RULES FOR MVP
-- ==============================================
-- This script creates the core MVP alert rules based on the Python seed_alert_rules.py
-- Maintains exact structure and data shape from the Python script

-- Clear existing alert rules (optional - remove if you want to keep existing data)
-- DELETE FROM alerts.alert_rules;

-- ==============================================
-- INSERT ALERT RULES
-- ==============================================

-- 1. Insurance Expiry Reminders
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'insurance-expiry-rule',
    'Insurance Expiry Reminder',
    'Reminds users when their insurance is about to expire',
    'insurance_expiry',
    '{"days_before_expiry": [30, 7, 1], "check_frequency": "daily"}',
    'Your insurance policy expires in {days} day(s). Renew now to avoid penalties and stay protected.',
    'Insurance Expires in {days} day(s)',
    '["in_app", "email", "sms"]',
    3,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- 2. Service Due Reminders
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'service-due-rule',
    'Service Due Reminder',
    'Reminds users when their vehicle service is due',
    'service_due',
    '{"mileage_intervals": [5000, 10000, 15000], "time_intervals": [6], "check_frequency": "daily"}',
    'Your vehicle service is due. You''ve driven {mileage} km since last service. Book your appointment now.',
    'Service Due - {mileage} km',
    '["in_app", "email"]',
    2,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- 3. Maintenance Reminders
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'maintenance-reminder-rule',
    'Maintenance Reminder',
    'General maintenance reminders based on vehicle age and usage',
    'maintenance_reminder',
    '{"maintenance_types": ["oil_change", "filter_replacement", "tyre_rotation"], "check_frequency": "weekly"}',
    'Time for {maintenance_type}. Keep your vehicle in top condition.',
    'Maintenance Due: {maintenance_type}',
    '["in_app", "email"]',
    2,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- 4. Promotional Alerts
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'promotional-rule',
    'Promotional Alerts',
    'Relevant offers and discounts from partner providers',
    'promotional',
    '{"user_preferences": ["service_types", "location_radius"], "partner_promotions": true, "check_frequency": "daily"}',
    'Special offer: {offer_description}. Valid until {expiry_date}.',
    '🎉 Special Offer: {provider_name}',
    '["in_app", "email"]',
    1,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- 5. Payment Reminders
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'payment-reminder-rule',
    'Payment Reminder',
    'Reminds users about upcoming payments for services or insurance',
    'payment_reminder',
    '{"days_before_payment": [7, 3, 1], "check_frequency": "daily"}',
    'Payment reminder: {payment_type} of {amount} is due in {days} day(s).',
    'Payment Due: {payment_type}',
    '["in_app", "email", "sms"]',
    3,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- ==============================================
-- ADDITIONAL ENHANCED ALERT RULES
-- ==============================================

-- 6. Claim Update Notifications
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'claim-update-rule',
    'Claim Update Notification',
    'Notifies users about updates to their insurance claims',
    'claim_update',
    '{"claim_statuses": ["submitted", "under_review", "approved", "rejected", "paid"], "check_frequency": "real_time"}',
    'Your insurance claim #{claim_number} status has been updated to: {status}. {additional_info}',
    'Claim Update: {claim_number}',
    '["in_app", "email", "sms"]',
    2,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- 7. Vehicle Registration Expiry
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'registration-expiry-rule',
    'Vehicle Registration Expiry',
    'Reminds users when their vehicle registration is about to expire',
    'maintenance_reminder',
    '{"days_before_expiry": [60, 30, 14, 7], "check_frequency": "daily"}',
    'Your vehicle registration expires in {days} day(s). Renew at NTSA to avoid penalties.',
    'Registration Expires in {days} day(s)',
    '["in_app", "email", "sms"]',
    3,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- 8. Driver License Expiry
INSERT INTO alerts.alert_rules (
    id,
    name,
    description,
    alert_type,
    trigger_conditions,
    message_template,
    title_template,
    channels,
    priority,
    is_active,
    created_by,
    version,
    created_at,
    updated_at
) VALUES (
    'license-expiry-rule',
    'Driver License Expiry',
    'Reminds users when their driver license is about to expire',
    'maintenance_reminder',
    '{"days_before_expiry": [90, 60, 30, 14], "check_frequency": "daily"}',
    'Your driver license expires in {days} day(s). Renew at NTSA to stay legal on the road.',
    'License Expires in {days} day(s)',
    '["in_app", "email", "sms"]',
    3,
    true,
    'system',
    '1.0',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    alert_type = EXCLUDED.alert_type,
    trigger_conditions = EXCLUDED.trigger_conditions,
    message_template = EXCLUDED.message_template,
    title_template = EXCLUDED.title_template,
    channels = EXCLUDED.channels,
    priority = EXCLUDED.priority,
    is_active = EXCLUDED.is_active,
    created_by = EXCLUDED.created_by,
    version = EXCLUDED.version,
    updated_at = CURRENT_TIMESTAMP;

-- ==============================================
-- VERIFICATION AND SUMMARY
-- ==============================================

-- Verify the alert rules were created successfully
SELECT 
    id,
    name,
    alert_type,
    priority,
    is_active,
    created_by,
    version
FROM alerts.alert_rules 
ORDER BY priority DESC, name;

-- Add comments for documentation
COMMENT ON TABLE alerts.alert_rules IS 'Default alert rules for MVP - triggers various types of alerts for users';
COMMENT ON COLUMN alerts.alert_rules.trigger_conditions IS 'JSON object containing conditions that trigger the alert';
COMMENT ON COLUMN alerts.alert_rules.message_template IS 'Template string for alert message with placeholders';
COMMENT ON COLUMN alerts.alert_rules.title_template IS 'Template string for alert title with placeholders';
COMMENT ON COLUMN alerts.alert_rules.channels IS 'JSON array of delivery channels (in_app, email, sms, etc.)';
COMMENT ON COLUMN alerts.alert_rules.priority IS 'Alert priority: 1=low, 2=medium, 3=high, 4=urgent';

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '🎉 Default alert rules created successfully!';
    RAISE NOTICE '📋 Created Rules:';
    RAISE NOTICE '1. Insurance Expiry Reminders (30, 7, 1 days)';
    RAISE NOTICE '2. Service Due Reminders (mileage & time-based)';
    RAISE NOTICE '3. Maintenance Reminders (oil, filters, tyres)';
    RAISE NOTICE '4. Promotional Alerts (partner offers)';
    RAISE NOTICE '5. Payment Reminders (insurance, services)';
    RAISE NOTICE '6. Claim Update Notifications (real-time)';
    RAISE NOTICE '7. Vehicle Registration Expiry (60, 30, 14, 7 days)';
    RAISE NOTICE '8. Driver License Expiry (90, 60, 30, 14 days)';
    RAISE NOTICE '🚀 Ready for MVP testing!';
END $$;
