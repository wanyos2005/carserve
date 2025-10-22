-- Create alert tables with the updated enum
-- This script creates all the alert tables with the APP_DOWNLOAD_PROMPT enum value

-- Create alerts table
CREATE TABLE IF NOT EXISTS alerts.alerts (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id INTEGER NOT NULL,
    type alerttype NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority INTEGER DEFAULT 1,
    vehicle_id VARCHAR,
    policy_id VARCHAR,
    booking_id VARCHAR,
    provider_id VARCHAR,
    channels JSON NOT NULL,
    status alertstatus DEFAULT 'pending',
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    action_url VARCHAR,
    action_text VARCHAR,
    alert_metadata JSON,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_alerts_user_id ON alerts.alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts.alerts(type);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts.alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_vehicle_id ON alerts.alerts(vehicle_id);

-- Create alert_rules table
CREATE TABLE IF NOT EXISTS alerts.alert_rules (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    alert_type alerttype NOT NULL,
    trigger_conditions JSON NOT NULL,
    message_template TEXT NOT NULL,
    title_template VARCHAR(255) NOT NULL,
    channels JSON NOT NULL,
    priority INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT true,
    schedule_expression VARCHAR,
    created_by VARCHAR,
    version VARCHAR DEFAULT '1.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create alert_preferences table
CREATE TABLE IF NOT EXISTS alerts.alert_preferences (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id INTEGER NOT NULL,
    alert_type alerttype NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    channels JSON NOT NULL,
    frequency VARCHAR DEFAULT 'immediate',
    quiet_hours_start VARCHAR,
    quiet_hours_end VARCHAR,
    timezone VARCHAR DEFAULT 'Africa/Nairobi',
    min_priority INTEGER DEFAULT 1,
    batch_alerts BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notification_logs table
CREATE TABLE IF NOT EXISTS alerts.notification_logs (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    alert_id VARCHAR REFERENCES alerts.alerts(id),
    user_id INTEGER NOT NULL,
    channel VARCHAR NOT NULL,
    status alertstatus NOT NULL,
    external_id VARCHAR,
    external_response JSON,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for notification_logs
CREATE INDEX IF NOT EXISTS idx_notification_logs_alert_id ON alerts.notification_logs(alert_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON alerts.notification_logs(user_id);

-- Verify the tables were created
SELECT table_name, table_schema 
FROM information_schema.tables 
WHERE table_schema = 'alerts' 
ORDER BY table_name;

