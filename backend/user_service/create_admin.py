#!/usr/bin/env python3
"""
Script to create the first admin user and subsequent admins.
Run this script to bootstrap your admin system.
"""

import sys
import os
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from datetime import datetime

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models.users import User, Roles, User_Roles
from core.db import get_db
from core.config import DATABASE_URL
# Override DATABASE_URL for local execution
# Check if we're running inside Docker (postgres service) or locally
import socket
try:
    socket.gethostbyname('postgres')
    # We're inside Docker, use postgres service name
    DATABASE_URL = "postgresql://AdminDb:Ngojakwanza@postgres:5432/car_platform"
except socket.gaierror:
    # We're running locally, use localhost
    DATABASE_URL = "postgresql://AdminDb:Ngojakwanza@localhost:5432/car_platform"

def create_admin_role(db: Session):
    """Create the admin role if it doesn't exist"""
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        admin_role = Roles(name="admin")
        db.add(admin_role)
        db.commit()
        db.refresh(admin_role)
        print(f"✅ Created admin role with ID: {admin_role.id}")
    else:
        print(f"✅ Admin role already exists with ID: {admin_role.id}")
    return admin_role

def create_first_admin(db: Session, email: str, name: str = None):
    """Create the first admin user"""
    # Check if any admin already exists
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if admin_role:
        existing_admin = db.query(User_Roles).filter(
            User_Roles.role_id == str(admin_role.id),
            User_Roles.active == True
        ).first()
        
        if existing_admin:
            print("❌ Admin already exists! Use create_additional_admin() instead.")
            return None
    
    # Create or get user
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            name=name or email.split('@')[0],
            verified=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"✅ Created user: {user.email} (ID: {user.id})")
    else:
        print(f"✅ Found existing user: {user.email} (ID: {user.id})")
    
    # Create admin role if it doesn't exist
    admin_role = create_admin_role(db)
    
    # Assign admin role to user
    user_role = User_Roles(
        user_id=user.id,
        role_id=str(admin_role.id),
        active=True
    )
    db.add(user_role)
    db.commit()
    
    print(f"🎉 SUCCESS: {user.email} is now an admin!")
    return user

def create_additional_admin(db: Session, email: str, name: str = None):
    """Create additional admin users (requires existing admin)"""
    # Check if admin role exists
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        print("❌ No admin role found! Run create_first_admin() first.")
        return None
    
    # Check if at least one admin exists
    existing_admin = db.query(User_Roles).filter(
        User_Roles.role_id == str(admin_role.id),
        User_Roles.active == True
    ).first()
    
    if not existing_admin:
        print("❌ No existing admin found! Run create_first_admin() first.")
        return None
    
    # Create or get user
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            name=name or email.split('@')[0],
            verified=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"✅ Created user: {user.email} (ID: {user.id})")
    else:
        print(f"✅ Found existing user: {user.email} (ID: {user.id})")
    
    # Check if user already has admin role
    existing_user_role = db.query(User_Roles).filter(
        User_Roles.user_id == user.id,
        User_Roles.role_id == str(admin_role.id)
    ).first()
    
    if existing_user_role:
        if existing_user_role.active:
            print(f"⚠️  {user.email} is already an admin!")
            return user
        else:
            # Reactivate admin role
            existing_user_role.active = True
            db.commit()
            print(f"✅ Reactivated admin role for {user.email}")
            return user
    
    # Assign admin role to user
    user_role = User_Roles(
        user_id=user.id,
        role_id=str(admin_role.id),
        active=True
    )
    db.add(user_role)
    db.commit()
    
    print(f"🎉 SUCCESS: {user.email} is now an admin!")
    return user

def list_admins(db: Session):
    """List all admin users"""
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        print("❌ No admin role found!")
        return
    
    admin_users = db.query(User_Roles).filter(
        User_Roles.role_id == str(admin_role.id),
        User_Roles.active == True
    ).all()
    
    if not admin_users:
        print("❌ No admin users found!")
        return
    
    print("\n📋 Current Admin Users:")
    print("-" * 50)
    for user_role in admin_users:
        user = db.query(User).filter(User.id == user_role.user_id).first()
        if user:
            print(f"👤 {user.name or 'No name'} ({user.email}) - ID: {user.id}")

def remove_admin(db: Session, email: str):
    """Remove admin privileges from a user"""
    user = db.query(User).filter(User.email == email).first()
    if not user:
        print(f"❌ User {email} not found!")
        return
    
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        print("❌ No admin role found!")
        return
    
    user_role = db.query(User_Roles).filter(
        User_Roles.user_id == user.id,
        User_Roles.role_id == str(admin_role.id)
    ).first()
    
    if not user_role:
        print(f"❌ {email} is not an admin!")
        return
    
    user_role.active = False
    db.commit()
    print(f"✅ Removed admin privileges from {email}")

def main():
    """Main function to run admin creation"""
    print("🔧 DriveOn Admin Management System")
    print("=" * 50)
    
    # Print the database URL being used
    print(f"📡 Database URL: {DATABASE_URL}")
    
    # Create database connection
    engine = create_engine(DATABASE_URL)
    
    with Session(engine) as db:
        if len(sys.argv) < 2:
            print("Usage:")
            print("  python create_admin.py first <email> [name]     - Create first admin")
            print("  python create_admin.py add <email> [name]       - Add additional admin")
            print("  python create_admin.py list                     - List all admins")
            print("  python create_admin.py remove <email>           - Remove admin privileges")
            print("\nExamples:")
            print("  python create_admin.py first bictoriadonovan@gmail.com 'System Admin'")
            print("  python create_admin.py add john@driveon.com 'John Doe'")
            print("  python create_admin.py list")
            print("  python create_admin.py remove john@driveon.com")
            return
        
        command = sys.argv[1].lower()
        
        if command == "first":
            if len(sys.argv) < 3:
                print("❌ Email required for first admin creation")
                return
            email = sys.argv[2]
            name = sys.argv[3] if len(sys.argv) > 3 else None
            create_first_admin(db, email, name)
            
        elif command == "add":
            if len(sys.argv) < 3:
                print("❌ Email required for additional admin creation")
                return
            email = sys.argv[2]
            name = sys.argv[3] if len(sys.argv) > 3 else None
            create_additional_admin(db, email, name)
            
        elif command == "list":
            list_admins(db)
            
        elif command == "remove":
            if len(sys.argv) < 3:
                print("❌ Email required for admin removal")
                return
            email = sys.argv[2]
            remove_admin(db, email)
            
        else:
            print(f"❌ Unknown command: {command}")

if __name__ == "__main__":
    main()
