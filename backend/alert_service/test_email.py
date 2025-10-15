#!/usr/bin/env python3
"""
Test Email Integration for Alert Service
This script tests if the email configuration works with your existing Gmail setup
"""

import asyncio
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig

async def test_email():
    """Test email sending with your existing Gmail configuration"""
    
    # Use same config as your user service
    conf = ConnectionConfig(
        MAIL_USERNAME="tastytasty101@gmail.com",
        MAIL_PASSWORD="degp zfga fqfp sifz",
        MAIL_FROM="tastytasty101@gmail.com",
        MAIL_PORT=587,
        MAIL_SERVER="smtp.gmail.com",
        MAIL_FROM_NAME="DriveOn",
        MAIL_SSL_TLS=False,
        MAIL_STARTTLS=True,
        USE_CREDENTIALS=True,
        VALIDATE_CERTS=True
    )
    
    # Create test message
    message = MessageSchema(
        subject="🚗 Alert Service Test - DriveOn",
        recipients=["tastytasty101@gmail.com"],  # Send to yourself for testing
        body="""
        <html>
        <body>
            <h2>🎉 Alert Service Email Test Successful!</h2>
            <p>This is a test email from your new Alert Service.</p>
            <p>If you received this, your email integration is working correctly!</p>
            <hr>
            <p><small>DriveOn Alert Service</small></p>
        </body>
        </html>
        """,
        subtype="html"
    )
    
    try:
        fm = FastMail(conf)
        await fm.send_message(message)
        print("✅ Email test successful! Check your inbox.")
        return True
    except Exception as e:
        print(f"❌ Email test failed: {str(e)}")
        return False

if __name__ == "__main__":
    print("🧪 Testing Alert Service Email Integration...")
    print("=" * 50)
    
    success = asyncio.run(test_email())
    
    if success:
        print("\n🎉 Email integration is working!")
        print("You can now use email alerts in your alert service.")
    else:
        print("\n⚠️  Email integration needs attention.")
        print("Check your Gmail app password and network connection.")
