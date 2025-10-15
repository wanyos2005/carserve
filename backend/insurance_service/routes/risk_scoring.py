# insurance_service/routes/risk_scoring.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
import httpx
import asyncio
from datetime import datetime

from core.db import get_db
from models.insurance import Risk_Score
from schemas.insurance import RiskScoreCreate, RiskScoreRead

router = APIRouter()

class RiskScoringEngine:
    """Risk scoring engine for vehicles and drivers"""
    
    def __init__(self):
        self.vehicle_service_url = "http://vehicle-service:8002"
        self.booking_service_url = "http://booking-service:8004"
    
    async def calculate_vehicle_risk_score(self, vehicle_id: str) -> dict:
        """Calculate vehicle risk score based on vehicle data and service history"""
        
        try:
            # Get vehicle data
            async with httpx.AsyncClient() as client:
                vehicle_response = await client.get(f"{self.vehicle_service_url}/vehicles/{vehicle_id}")
                if vehicle_response.status_code != 200:
                    raise HTTPException(status_code=404, detail="Vehicle not found")
                
                vehicle_data = vehicle_response.json()
                
                # Get service logs for the vehicle
                service_response = await client.get(f"{self.booking_service_url}/service-logs/vehicle/{vehicle_id}")
                service_logs = service_response.json() if service_response.status_code == 200 else []
            
            # Calculate risk factors
            risk_factors = {}
            total_risk_score = 100  # Start with perfect score
            
            # Age factor (0-30 points risk)
            current_year = datetime.now().year
            vehicle_age = current_year - vehicle_data.get('yom', current_year)
            age_risk = min(30, vehicle_age * 2)  # 2 points per year #min is used to ensure that the age risk is not greater than 30
            risk_factors['age_risk'] = age_risk
            total_risk_score -= age_risk
            
            # Mileage factor (0-25 points risk)
            mileage = vehicle_data.get('mileage', 0)
            mileage_risk = min(25, mileage / 2000)  # 1 point per 2000km
            risk_factors['mileage_risk'] = mileage_risk
            total_risk_score -= mileage_risk
            
            # Service history factor (0-25 points risk)
            service_risk = self._calculate_service_risk(service_logs)
            risk_factors['service_risk'] = service_risk
            total_risk_score -= service_risk
            
            # Fuel type factor (0-10 points risk)
            fuel_type = vehicle_data.get('fuel_type', '').lower()
            fuel_risk = 0
            if fuel_type in ['diesel']:
                fuel_risk = 5  # Diesel vehicles slightly higher risk
            elif fuel_type in ['electric', 'hybrid']:
                fuel_risk = -5  # Electric/hybrid vehicles lower risk
            risk_factors['fuel_type_risk'] = fuel_risk
            total_risk_score -= fuel_risk
            
            # Ensure score is between 0 and 100
            vehicle_risk_score = max(0, min(100, total_risk_score))
            
            return {
                'vehicle_risk_score': int(vehicle_risk_score),
                'risk_factors': risk_factors,
                'data_points_used': {
                    'vehicle_age': vehicle_age,
                    'mileage': mileage,
                    'fuel_type': fuel_type,
                    'service_logs_count': len(service_logs)
                }
            }
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error calculating vehicle risk: {str(e)}")
    
    def _calculate_service_risk(self, service_logs: list) -> int:
        """Calculate service-related risk based on service history"""
        
        if not service_logs:
            return 25  # High risk if no service history
        
        # Analyze service patterns
        total_services = len(service_logs)
        recent_services = 0
        overdue_services = 0
        
        current_date = datetime.now()
        
        for log in service_logs:
            service_date = datetime.fromisoformat(log.get('performed_at', '').replace('Z', '+00:00'))
            
            # Check if service was recent (within last 6 months)
            if (current_date - service_date).days <= 180:
                recent_services += 1
            
            # Check for overdue services
            next_service_date = log.get('next_service_date')
            if next_service_date:
                next_date = datetime.fromisoformat(next_service_date.replace('Z', '+00:00'))
                if next_date < current_date:
                    overdue_services += 1
        
        # Calculate service risk
        service_risk = 0
        
        # Risk for lack of recent services
        if recent_services == 0:
            service_risk += 15
        elif recent_services < total_services * 0.3:  # Less than 30% recent
            service_risk += 10
        
        # Risk for overdue services
        service_risk += min(10, overdue_services * 2)
        
        return service_risk
    
    async def calculate_driver_risk_score(self, user_id: int) -> dict:
        """Calculate driver risk score based on service punctuality and behavior"""
        
        try:
            # Get user's service history
            async with httpx.AsyncClient() as client:
                service_response = await client.get(f"{self.booking_service_url}/service-logs/user/{user_id}")
                service_logs = service_response.json() if service_response.status_code == 200 else []
            
            # Get user's claims history
            # TODO: Implement claims history query when available
            
            risk_factors = {}
            total_risk_score = 100  # Start with perfect score
            
            # Service punctuality factor (0-30 points risk)
            punctuality_risk = self._calculate_punctuality_risk(service_logs)
            risk_factors['punctuality_risk'] = punctuality_risk
            total_risk_score -= punctuality_risk
            
            # Service frequency factor (0-20 points risk)
            frequency_risk = self._calculate_frequency_risk(service_logs)
            risk_factors['frequency_risk'] = frequency_risk
            total_risk_score -= frequency_risk
            
            # Claims history factor (0-25 points risk)
            claims_risk = 0  # TODO: Implement when claims data is available
            risk_factors['claims_risk'] = claims_risk
            total_risk_score -= claims_risk
            
            # Vehicle maintenance factor (0-25 points risk)
            maintenance_risk = self._calculate_maintenance_risk(service_logs)
            risk_factors['maintenance_risk'] = maintenance_risk
            total_risk_score -= maintenance_risk
            
            # Ensure score is between 0 and 100
            driver_risk_score = max(0, min(100, total_risk_score))
            
            return {
                'driver_risk_score': int(driver_risk_score),
                'risk_factors': risk_factors,
                'data_points_used': {
                    'total_services': len(service_logs),
                    'recent_services': len([s for s in service_logs if self._is_recent_service(s)]),
                    'claims_count': 0  # TODO: Update when claims data is available
                }
            }
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error calculating driver risk: {str(e)}")
    
    def _calculate_punctuality_risk(self, service_logs: list) -> int:
        """Calculate risk based on service punctuality"""
        
        if not service_logs:
            return 30  # High risk if no service history
        
        on_time_services = 0
        total_services = len(service_logs)
        
        for log in service_logs:
            # Check if service was performed on time
            # This is a simplified calculation - in reality, you'd compare
            # scheduled vs actual service dates
            if log.get('performed_at'):
                on_time_services += 1  # Simplified: assume all performed services are "on time"
        
        punctuality_rate = on_time_services / total_services
        
        if punctuality_rate >= 0.9:
            return 0  # Excellent punctuality
        elif punctuality_rate >= 0.7:
            return 10  # Good punctuality
        elif punctuality_rate >= 0.5:
            return 20  # Fair punctuality
        else:
            return 30  # Poor punctuality
    
    def _calculate_frequency_risk(self, service_logs: list) -> int:
        """Calculate risk based on service frequency"""
        
        if not service_logs:
            return 20  # High risk if no service history
        
        # Calculate average time between services
        if len(service_logs) < 2:
            return 10  # Medium risk for single service
        
        # Simplified calculation - in reality, you'd analyze actual service intervals
        return 5  # Low risk for regular service history
    
    def _calculate_maintenance_risk(self, service_logs: list) -> int:
        """Calculate risk based on maintenance quality"""
        
        if not service_logs:
            return 25  # High risk if no maintenance history
        
        # Analyze maintenance quality indicators
        quality_indicators = 0
        
        for log in service_logs:
            # Check for comprehensive service items
            service_items = log.get('service_items', [])
            if len(service_items) >= 3:  # Comprehensive service
                quality_indicators += 1
            
            # Check for proper documentation
            if log.get('notes') and len(log.get('notes', '')) > 10:
                quality_indicators += 1
        
        quality_rate = quality_indicators / (len(service_logs) * 2)  # 2 indicators per service
        
        if quality_rate >= 0.8:
            return 0  # Excellent maintenance
        elif quality_rate >= 0.6:
            return 10  # Good maintenance
        elif quality_rate >= 0.4:
            return 20  # Fair maintenance
        else:
            return 25  # Poor maintenance
    
    def _is_recent_service(self, service_log: dict) -> bool:
        """Check if service was performed recently (within 6 months)"""
        
        service_date = service_log.get('performed_at')
        if not service_date:
            return False
        
        try:
            service_date_obj = datetime.fromisoformat(service_date.replace('Z', '+00:00'))
            current_date = datetime.now()
            return (current_date - service_date_obj).days <= 180
        except:
            return False

# Initialize risk scoring engine
risk_engine = RiskScoringEngine()

@router.post("/calculate/{vehicle_id}", response_model=RiskScoreRead)
async def calculate_risk_score(
    vehicle_id: str,
    user_id: int,
    db: Session = Depends(get_db),
):
    """Calculate comprehensive risk score for a vehicle and driver"""
    
    try:
        # Calculate vehicle risk score
        vehicle_risk_data = await risk_engine.calculate_vehicle_risk_score(vehicle_id)
        
        # Calculate driver risk score
        driver_risk_data = await risk_engine.calculate_driver_risk_score(user_id)
        
        # Calculate combined risk score (weighted average)
        vehicle_weight = 0.6  # Vehicle risk is 60% of total
        driver_weight = 0.4   # Driver risk is 40% of total
        
        combined_risk_score = int(
            (vehicle_risk_data['vehicle_risk_score'] * vehicle_weight) +
            (driver_risk_data['driver_risk_score'] * driver_weight)
        )
        
        # Combine risk factors
        combined_risk_factors = {
            'vehicle_factors': vehicle_risk_data['risk_factors'],
            'driver_factors': driver_risk_data['risk_factors'],
            'combined_score_breakdown': {
                'vehicle_contribution': vehicle_risk_data['vehicle_risk_score'] * vehicle_weight,
                'driver_contribution': driver_risk_data['driver_risk_score'] * driver_weight
            }
        }
        
        # Combine data points
        combined_data_points = {
            'vehicle_data': vehicle_risk_data['data_points_used'],
            'driver_data': driver_risk_data['data_points_used']
        }
        
        # Create or update risk score record
        existing_score = db.query(Risk_Score).filter(
            Risk_Score.vehicle_id == vehicle_id,
            Risk_Score.user_id == user_id
        ).first()
        
        if existing_score:
            # Update existing record
            existing_score.vehicle_risk_score = vehicle_risk_data['vehicle_risk_score']
            existing_score.driver_risk_score = driver_risk_data['driver_risk_score']
            existing_score.combined_risk_score = combined_risk_score
            existing_score.risk_factors = combined_risk_factors
            existing_score.data_points_used = combined_data_points
            existing_score.last_updated = datetime.now()
            
            db.commit()
            db.refresh(existing_score)
            return existing_score
        else:
            # Create new record
            risk_score = Risk_Score(
                vehicle_id=vehicle_id,
                user_id=user_id,
                vehicle_risk_score=vehicle_risk_data['vehicle_risk_score'],
                driver_risk_score=driver_risk_data['driver_risk_score'],
                combined_risk_score=combined_risk_score,
                risk_factors=combined_risk_factors,
                data_points_used=combined_data_points
            )
            
            db.add(risk_score)
            db.commit()
            db.refresh(risk_score)
            return risk_score
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating risk score: {str(e)}")

@router.get("/{vehicle_id}", response_model=RiskScoreRead)
def get_risk_score(
    vehicle_id: str,
    user_id: int,
    db: Session = Depends(get_db),
):
    """Get current risk score for a vehicle and driver"""
    
    risk_score = db.query(Risk_Score).filter(
        Risk_Score.vehicle_id == vehicle_id,
        Risk_Score.user_id == user_id
    ).first()
    
    if not risk_score:
        raise HTTPException(status_code=404, detail="Risk score not found")
    
    return risk_score

@router.get("/user/{user_id}", response_model=list[RiskScoreRead])
def get_user_risk_scores(
    user_id: int,
    db: Session = Depends(get_db),
):
    """Get all risk scores for a user"""
    
    risk_scores = db.query(Risk_Score).filter(Risk_Score.user_id == user_id).all()
    return risk_scores

@router.post("/update/{vehicle_id}")
async def update_risk_score(
    vehicle_id: str,
    user_id: int,
    db: Session = Depends(get_db),
):
    """Manually trigger risk score update"""
    
    # This will recalculate and update the risk score
    return await calculate_risk_score(vehicle_id, user_id, db)
