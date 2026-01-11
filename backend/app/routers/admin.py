"""
Admin dashboard router - statistics and management
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timezone, timedelta

from ..database import get_db
from ..models import User, BlogPost, Comment, CommentLike
from ..security import get_current_admin_user
from ..schemas import APIResponse

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats", response_model=dict)
async def get_dashboard_stats(
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics (admin only)"""
    
    # Current time for calculations
    now = datetime.now(timezone.utc)
    last_24h = now - timedelta(hours=24)
    last_7d = now - timedelta(days=7)
    last_30d = now - timedelta(days=30)
    
    # User stats
    total_users = db.query(func.count(User.id)).scalar() or 0
    verified_users = db.query(func.count(User.id)).filter(User.email_verified == True).scalar() or 0
    active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar() or 0
    new_users_24h = db.query(func.count(User.id)).filter(User.created_at >= last_24h).scalar() or 0
    new_users_7d = db.query(func.count(User.id)).filter(User.created_at >= last_7d).scalar() or 0
    new_users_30d = db.query(func.count(User.id)).filter(User.created_at >= last_30d).scalar() or 0
    
    # Post stats
    total_posts = db.query(func.count(BlogPost.id)).scalar() or 0
    
    # Comment stats
    total_comments = db.query(func.count(Comment.id)).scalar() or 0
    comments_24h = db.query(func.count(Comment.id)).filter(Comment.created_at >= last_24h).scalar() or 0
    comments_7d = db.query(func.count(Comment.id)).filter(Comment.created_at >= last_7d).scalar() or 0
    
    # Like stats
    total_likes = db.query(func.count(CommentLike.id)).scalar() or 0
    likes_24h = db.query(func.count(CommentLike.id)).filter(CommentLike.created_at >= last_24h).scalar() or 0
    
    # Most active users (by comment count)
    top_commenters = db.query(
        User.username,
        func.count(Comment.id).label('comment_count')
    ).join(Comment, Comment.user_id == User.id)\
     .group_by(User.id, User.username)\
     .order_by(func.count(Comment.id).desc())\
     .limit(5).all()
    
    # Recent registrations with rank info
    recent_users = db.query(User).order_by(User.created_at.desc()).limit(5).all()
    
    # Reactions per post (for posts with comments)
    posts_with_reactions = db.query(
        BlogPost.slug,
        func.count(CommentLike.id).label('reaction_count')
    ).outerjoin(Comment, Comment.post_slug == BlogPost.slug)\
     .outerjoin(CommentLike, CommentLike.comment_id == Comment.id)\
     .group_by(BlogPost.id, BlogPost.slug)\
     .order_by(func.count(CommentLike.id).desc())\
     .limit(10).all()
    
    return {
        "users": {
            "total": total_users,
            "verified": verified_users,
            "active": active_users,
            "unverified": total_users - verified_users,
            "new_24h": new_users_24h,
            "new_7d": new_users_7d,
            "new_30d": new_users_30d,
        },
        "posts": {
            "total": total_posts,
        },
        "comments": {
            "total": total_comments,
            "last_24h": comments_24h,
            "last_7d": comments_7d,
        },
        "reactions": {
            "total": total_likes,
            "last_24h": likes_24h,
        },
        "likes": {
            "total": total_likes,
            "last_24h": likes_24h,
        },
        "top_commenters": [
            {"username": u.username, "count": u.comment_count}
            for u in top_commenters
        ],
        "posts_reactions": [
            {"slug": p.slug, "reactions": p.reaction_count}
            for p in posts_with_reactions
        ],
        "recent_users": [
            {
                "id": u.id,
                "username": u.username,
                "email": u.email,
                "created_at": u.created_at.isoformat() if u.created_at else None,
                "verified": u.email_verified,
                "rank": {
                    "name": u.rank.display_name if u.rank else None,
                    "level": u.rank.level if u.rank else 1,
                    "color": u.rank.color if u.rank else None,
                } if u.rank else None,
                "reputation_score": u.reputation_score or 0
            }
            for u in recent_users
        ],
        "timestamp": now.isoformat()
    }


@router.get("/users", response_model=dict)
async def get_all_users(
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
    page: int = 1,
    limit: int = 20
):
    """Get all users with pagination (admin only)"""
    
    offset = (page - 1) * limit
    
    total = db.query(func.count(User.id)).scalar() or 0
    users = db.query(User).order_by(User.created_at.desc()).offset(offset).limit(limit).all()
    
    return {
        "users": [
            {
                "id": u.id,
                "username": u.username,
                "email": u.email,
                "full_name": u.full_name,
                "is_active": u.is_active,
                "email_verified": u.email_verified,
                "created_at": u.created_at.isoformat() if u.created_at else None,
                "role": u.role.name.value if u.role else None,
                "rank": u.rank.name.value if u.rank else None,
            }
            for u in users
        ],
        "pagination": {
            "page": page,
            "limit": limit,
            "total": total,
            "pages": (total + limit - 1) // limit
        }
    }
