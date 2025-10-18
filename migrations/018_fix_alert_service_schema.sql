-- ==============================================
-- FIX ALERT SERVICE SCHEMA
-- ==============================================
-- This migration updates the alert service tables to match the current models
-- Fixes legacy schema issues and adds missing columns

-- ==============================================
-- CREATE ALERT ENUMS (if they don't exist)
-- ==============================================

-- Create AlertType enum
DO $$ BEGIN
    CREATE TYPE alert_type AS ENUM (
        'insurance_expiry',
        'service_due', 
        'promotional',
        'maintenance_reminder',
        'claim_update',
        'payment_reminder'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create AlertStatus enum
DO $$ BEGIN
    CREATE TYPE alert_status AS ENUM (
        'pending',
        'sent',
        'delivered',
        'failed',
        'cancelled'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create AlertChannel enum
DO $$ BEGIN
    CREATE TYPE alert_channel AS ENUM (
        'in_app',
        'push',
        'sms',
        'email',
        'whatsapp'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================
-- UPDATE ALERTS.ALERTS TABLE
-- ==============================================

-- Add missing columns to alerts.alerts table
ALTER TABLE alerts.alerts 
ADD COLUMN IF NOT EXISTS type alert_type,
ADD COLUMN IF NOT EXISTS title VARCHAR(255),
ADD COLUMN IF NOT EXISTS message TEXT,
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS vehicle_id VARCHAR,
ADD COLUMN IF NOT EXISTS policy_id VARCHAR,
ADD COLUMN IF NOT EXISTS booking_id VARCHAR,
ADD COLUMN IF NOT EXISTS provider_id VARCHAR,
ADD COLUMN IF NOT EXISTS channels JSONB,
ADD COLUMN IF NOT EXISTS status alert_status DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS action_url VARCHAR,
ADD COLUMN IF NOT EXISTS action_text VARCHAR,
ADD COLUMN IF NOT EXISTS alert_metadata JSONB,
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_retries INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS error_message TEXT,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts.alerts(type);
CREATE INDEX IF NOT EXISTS idx_alerts_vehicle_id ON alerts.alerts(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_alerts_policy_id ON alerts.alerts(policy_id);
CREATE INDEX IF NOT EXISTS idx_alerts_booking_id ON alerts.alerts(booking_id);
CREATE INDEX IF NOT EXISTS idx_alerts_provider_id ON alerts.alerts(provider_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts.alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_scheduled_at ON alerts.alerts(scheduled_at);

-- ==============================================
-- UPDATE ALERTS.ALERT_RULES TABLE
-- ==============================================

-- Add missing columns to alerts.alert_rules table
ALTER TABLE alerts.alert_rules 
ADD COLUMN IF NOT EXISTS name VARCHAR(255),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS alert_type alert_type,
ADD COLUMN IF NOT EXISTS trigger_conditions JSONB,
ADD COLUMN IF NOT EXISTS message_template TEXT,
ADD COLUMN IF NOT EXISTS title_template VARCHAR(255),
ADD COLUMN IF NOT EXISTS channels JSONB,
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 2,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS schedule_expression VARCHAR,
ADD COLUMN IF NOT EXISTS created_by VARCHAR,
ADD COLUMN IF NOT EXISTS version VARCHAR DEFAULT '1.0',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_alert_rules_alert_type ON alerts.alert_rules(alert_type);
CREATE INDEX IF NOT EXISTS idx_alert_rules_is_active ON alerts.alert_rules(is_active);

-- ==============================================
-- CREATE ALERTS.ALERT_PREFERENCES TABLE
-- ==============================================

CREATE TABLE IF NOT EXISTS alerts.alert_preferences (
    id VARCHAR PRIMARY KEY,
    user_id INTEGER NOT NULL,
    alert_type alert_type NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    channels JSONB NOT NULL,
    frequency VARCHAR DEFAULT 'immediate',
    quiet_hours_start VARCHAR,
    quiet_hours_end VARCHAR,
    timezone VARCHAR DEFAULT 'Africa/Nairobi',
    min_priority INTEGER DEFAULT 1,
    batch_alerts BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for alert_preferences
CREATE INDEX IF NOT EXISTS idx_alert_preferences_user_id ON alerts.alert_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_preferences_alert_type ON alerts.alert_preferences(alert_type);

-- ==============================================
-- UPDATE ALERTS.NOTIFICATION_LOGS TABLE
-- ==============================================

-- Add missing columns to alerts.notification_logs table
ALTER TABLE alerts.notification_logs 
ADD COLUMN IF NOT EXISTS alert_id VARCHAR,
ADD COLUMN IF NOT EXISTS user_id INTEGER,
ADD COLUMN IF NOT EXISTS channel alert_channel,
ADD COLUMN IF NOT EXISTS status alert_status,
ADD COLUMN IF NOT EXISTS external_id VARCHAR,
ADD COLUMN IF NOT EXISTS external_response JSONB,
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS error_message TEXT,
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Add indexes for notification_logs
CREATE INDEX IF NOT EXISTS idx_notification_logs_alert_id ON alerts.notification_logs(alert_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON alerts.notification_logs(user_id);

-- ==============================================
-- ADD FOREIGN KEY CONSTRAINTS
-- ==============================================

-- Add foreign key from notification_logs to alerts
ALTER TABLE alerts.notification_logs 
ADD CONSTRAINT IF NOT EXISTS fk_notification_logs_alert_id 
FOREIGN KEY (alert_id) REFERENCES alerts.alerts(id);

-- ==============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ==============================================

COMMENT ON TABLE alerts.alerts IS 'Individual alerts sent to users';
COMMENT ON TABLE alerts.alert_rules IS 'Rules that define when and how alerts are triggered';
COMMENT ON TABLE alerts.alert_preferences IS 'User preferences for alert types and delivery';
COMMENT ON TABLE alerts.notification_logs IS 'Log of notification delivery attempts and results';

COMMENT ON COLUMN alerts.alerts.type IS 'Type of alert (insurance_expiry, service_due, etc.)';
COMMENT ON COLUMN alerts.alerts.priority IS 'Alert priority: 1=low, 2=medium, 3=high, 4=urgent';
COMMENT ON COLUMN alerts.alerts.channels IS 'JSON array of delivery channels';
COMMENT ON COLUMN alerts.alerts.status IS 'Current status of the alert';
COMMENT ON COLUMN alerts.alerts.alert_metadata IS 'Additional data for the alert';

COMMENT ON COLUMN alerts.alert_rules.trigger_conditions IS 'JSON object containing conditions that trigger the alert';
COMMENT ON COLUMN alerts.alert_rules.message_template IS 'Template string for alert message with placeholders';
COMMENT ON COLUMN alerts.alert_rules.title_template IS 'Template string for alert title with placeholders';
COMMENT ON COLUMN alerts.alert_rules.channels IS 'JSON array of default delivery channels';
COMMENT ON COLUMN alerts.alert_rules.priority IS 'Default priority for alerts created by this rule';

COMMENT ON COLUMN alerts.alert_preferences.channels IS 'JSON array of preferred delivery channels';
COMMENT ON COLUMN alerts.alert_preferences.frequency IS 'How often to send alerts: immediate, daily, weekly, never';
COMMENT ON COLUMN alerts.alert_preferences.min_priority IS 'Only send alerts with this priority or higher';

COMMENT ON COLUMN alerts.notification_logs.channel IS 'Specific channel used for delivery';
COMMENT ON COLUMN alerts.notification_logs.status IS 'Delivery status for this channel';
COMMENT ON COLUMN alerts.notification_logs.external_response IS 'Response from external service (FCM, Twilio, etc.)';

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify table structures
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'alerts' 
    AND table_name IN ('alerts', 'alert_rules', 'alert_preferences', 'notification_logs')
ORDER BY table_name, ordinal_position;

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '🎉 Alert service schema updated successfully!';
    RAISE NOTICE '📋 Updated Tables:';
    RAISE NOTICE '1. alerts.alerts - Individual alerts with full schema';
    RAISE NOTICE '2. alerts.alert_rules - Alert trigger rules with templates';
    RAISE NOTICE '3. alerts.alert_preferences - User alert preferences';
    RAISE NOTICE '4. alerts.notification_logs - Delivery tracking';
    RAISE NOTICE '🚀 Ready for alert rule seeding!';
END $$;
