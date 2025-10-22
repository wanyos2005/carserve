-- Test the APP_DOWNLOAD_PROMPT enum
INSERT INTO alerts.alerts (user_id, type, title, message, channels) 
VALUES (1, 'APP_DOWNLOAD_PROMPT', 'Test Alert', 'Test message', '["email"]');

