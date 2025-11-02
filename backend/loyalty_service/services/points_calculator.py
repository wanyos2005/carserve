# backend/loyalty_service/services/points_calculator.py
from sqlalchemy.orm import Session
from typing import Optional, Dict, Any
from datetime import datetime, timezone
from crud import loyalty as crud
from models.loyalty import LoyaltyAccount


class PointsCalculator:
    """Calculate points based on rules and context"""
    
    # Default tier multipliers
    DEFAULT_TIER_MULTIPLIERS = {
        "bronze": 1.0,
        "silver": 1.5,
        "gold": 2.0,
        "platinum": 2.5,
    }
    
    def __init__(self, db: Session):
        self.db = db
    
    def calculate_points(
        self,
        amount_spent: int,
        user_id: int,
        provider_id: Optional[str] = None,
        provider_category_id: Optional[int] = None,
        service_id: Optional[str] = None,
        service_category_id: Optional[int] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Calculate points to award based on rules and context.
        Returns dict with points, rule used, and calculation details.
        """
        
        # Get applicable rules (already filtered and sorted by priority)
        rules = crud.get_active_rules(
            db=self.db,
            provider_id=provider_id,
            provider_category_id=provider_category_id,
            service_id=service_id,
            service_category_id=service_category_id,
        )
        
        # If no specific rules, use default
        if not rules:
            return self._calculate_default_points(amount_spent, user_id)
        
        # Find first matching rule (already sorted by priority)
        for rule in rules:
            if self._rule_matches(rule, amount_spent, metadata):
                return self._calculate_with_rule(rule, amount_spent, user_id)
        
        # If no rule matched but rules exist, use default from first rule
        if rules:
            return self._calculate_default_points(amount_spent, user_id)
        
        return self._calculate_default_points(amount_spent, user_id)
    
    def _rule_matches(
        self,
        rule: Any,
        amount_spent: int,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Check if rule matches the transaction"""
        
        # Check minimum amount
        if rule.min_amount and amount_spent < rule.min_amount:
            return False
        
        # Check additional conditions
        if rule.conditions:
            conditions = rule.conditions
            # Day of week check
            if "day_of_week" in conditions:
                current_day = datetime.now(timezone.utc).strftime("%A").lower()
                if current_day != conditions["day_of_week"].lower():
                    return False
            
            # Time range check
            if "time_range" in conditions:
                hour = datetime.now(timezone.utc).hour
                time_range = conditions["time_range"]
                if "start" in time_range and hour < time_range["start"]:
                    return False
                if "end" in time_range and hour > time_range["end"]:
                    return False
            
            # Custom metadata checks
            if "metadata" in conditions and metadata:
                for key, value in conditions["metadata"].items():
                    if metadata.get(key) != value:
                        return False
        
        return True
    
    def _calculate_with_rule(
        self,
        rule: Any,
        amount_spent: int,
        user_id: int
    ) -> Dict[str, Any]:
        """Calculate points using a specific rule"""
        
        # Get user tier for multiplier
        account = crud.get_account(self.db, user_id)
        user_tier = account.tier if account else "bronze"
        
        # Base points calculation
        base_points = float(amount_spent) * float(rule.base_points_per_kes)
        
        # Apply rule multiplier
        points = base_points * float(rule.multiplier)
        
        # Apply tier multiplier if available
        tier_multiplier = 1.0
        if rule.tier_multipliers:
            tier_multiplier = rule.tier_multipliers.get(user_tier, 1.0)
        elif user_tier in self.DEFAULT_TIER_MULTIPLIERS:
            tier_multiplier = self.DEFAULT_TIER_MULTIPLIERS[user_tier]
        
        points = points * tier_multiplier
        
        # Apply cap if specified
        if rule.max_points_per_transaction:
            points = min(points, rule.max_points_per_transaction)
        
        # Round to integer
        points = int(round(points))
        
        return {
            "points": points,
            "rule_id": rule.id,
            "rule_name": rule.name,
            "calculation": {
                "base_points": base_points,
                "rule_multiplier": float(rule.multiplier),
                "tier_multiplier": tier_multiplier,
                "final_points": points,
            }
        }
    
    def _calculate_default_points(
        self,
        amount_spent: int,
        user_id: int
    ) -> Dict[str, Any]:
        """Calculate points using default rate (1 point per KES 100)"""
        
        account = crud.get_account(self.db, user_id)
        user_tier = account.tier if account else "bronze"
        
        # Default: 1 point per KES 100 (0.01 points per KES)
        base_points = amount_spent * 0.01
        
        # Apply tier multiplier
        tier_multiplier = self.DEFAULT_TIER_MULTIPLIERS.get(user_tier, 1.0)
        points = base_points * tier_multiplier
        
        points = int(round(points))
        
        return {
            "points": points,
            "rule_id": None,
            "rule_name": "Default Rule",
            "calculation": {
                "base_points": amount_spent * 0.01,
                "rule_multiplier": 1.0,
                "tier_multiplier": tier_multiplier,
                "final_points": points,
            }
        }
    
    def calculate_tier(
        self,
        account: LoyaltyAccount
    ) -> Dict[str, Any]:
        """Calculate tier based on points balance"""
        
        TIER_THRESHOLDS = {
            "bronze": 0,
            "silver": 1000,
            "gold": 5000,
            "platinum": 20000,
        }
        
        current_points = account.points_balance
        
        # Determine current tier
        current_tier = "bronze"
        for tier, threshold in sorted(TIER_THRESHOLDS.items(), key=lambda x: x[1], reverse=True):
            if current_points >= threshold:
                current_tier = tier
                break
        
        # Determine next tier
        next_tier = None
        points_to_next = None
        tier_order = ["bronze", "silver", "gold", "platinum"]
        current_index = tier_order.index(current_tier)
        if current_index < len(tier_order) - 1:
            next_tier = tier_order[current_index + 1]
            points_to_next = TIER_THRESHOLDS[next_tier] - current_points
        
        return {
            "current_tier": current_tier,
            "current_points": current_points,
            "next_tier": next_tier,
            "points_to_next_tier": points_to_next,
            "tier_benefits": self._get_tier_benefits(current_tier),
        }
    
    def _get_tier_benefits(self, tier: str) -> Dict[str, Any]:
        """Get benefits for a tier"""
        benefits = {
            "bronze": {
                "points_multiplier": 1.0,
                "description": "Earn points on every purchase",
            },
            "silver": {
                "points_multiplier": 1.5,
                "description": "1.5x points on all purchases",
            },
            "gold": {
                "points_multiplier": 2.0,
                "description": "2x points, exclusive rewards",
            },
            "platinum": {
                "points_multiplier": 2.5,
                "description": "2.5x points, priority support, VIP rewards",
            },
        }
        return benefits.get(tier, benefits["bronze"])

