"""
Utilities for automatic rank management
"""

from sqlalchemy.orm import Session, joinedload
from .models import User, UserRank

def auto_check_rank_upgrade(user_id: int, db: Session) -> dict:
    """
    Automatycznie sprawdź i awansuj użytkownika jeśli spełnia warunki XP
    Zwraca info o awansie lub braku zmian
    """
    try:
        # Pobierz użytkownika z obecną rangą
        user = db.query(User).options(joinedload(User.rank)).filter(User.id == user_id).first()
        if not user:
            return {"success": False, "message": "User not found"}
        
        # Pobierz wszystkie aktywne rangi (od najwyższej)
        available_ranks = db.query(UserRank).filter(
            UserRank.is_active == True
        ).order_by(UserRank.level.desc()).all()
        
        # Aktualny XP użytkownika
        user_xp = user.reputation_score or 0
        
        # Sprawdź czy użytkownik kwalifikuje się do wyższej rangi
        for rank in available_ranks:
            requirements = rank.requirements or {}
            xp_req = requirements.get("xp", 0)
            
            # Sprawdź czy spełnia wymagania XP
            if user_xp >= xp_req:
                # Sprawdź czy to wyższa ranga niż obecna
                if not user.rank or rank.level > user.rank.level:
                    old_rank_name = user.rank.display_name if user.rank else "No rank"
                    
                    # Awansuj
                    user.rank_id = rank.id
                    db.commit()
                    
                    return {
                        "success": True,
                        "upgraded": True,
                        "old_rank": old_rank_name,
                        "new_rank": rank.display_name,
                        "new_rank_icon": rank.icon,
                        "message": f"🎉 Upgraded from {old_rank_name} to {rank.display_name}!"
                    }
                else:
                    # Już ma tę rangę lub wyższą
                    break
        
        # Brak awansu
        return {
            "success": True,
            "upgraded": False,
            "current_rank": user.rank.display_name if user.rank else "No rank",
            "current_xp": user_xp,
            "message": "No upgrade yet - keep earning XP!"
        }
        
    except Exception as e:
        return {"success": False, "message": f"Error checking rank: {str(e)}"}

def update_user_stats(user_id: int, db: Session, action: str = "comment") -> dict:
    """
    Aktualizuj statystyki użytkownika i sprawdź awans
    action: 'comment' (dodaj komentarz) lub 'like_received' (otrzymał lajka)
    """
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return {"success": False, "message": "User not found"}
        
        # Aktualizuj statystyki i reputation_score
        if action == "comment":
            user.total_comments += 1
            user.reputation_score = (user.reputation_score or 0) + 2  # +2 XP za komentarz
        elif action == "like_received":
            user.total_likes_received += 1
            user.reputation_score = (user.reputation_score or 0) + 1  # +1 XP za like
        
        db.commit()
        
        # Sprawdź awans po aktualizacji statystyk
        rank_result = auto_check_rank_upgrade(user_id, db)
        
        return {
            "success": True,
            "stats_updated": True,
            "action": action,
            "new_reputation": user.reputation_score,
            "rank_check": rank_result
        }
        
    except Exception as e:
        return {"success": False, "message": f"Error updating stats: {str(e)}"}

