"""
Simplified Blog Router - posts content is in .md files
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from datetime import datetime, timezone
import re

from ..database import get_db
from ..models import BlogPost, BlogTag, User, Comment
from ..schemas import (BlogPostPublic, APIResponse, PaginatedResponse)
from ..security import get_current_admin_user

router = APIRouter()


@router.get("/admin/posts", response_model=PaginatedResponse)
async def get_admin_blog_posts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    category: Optional[str] = Query(None),
):
    """Admin endpoint: Pobierz wszystkie posty z dodatkowymi informacjami"""
    
    query = db.query(BlogPost).options(
        joinedload(BlogPost.tags)
    )
    
    # Filter by category
    if category:
        query = query.filter(BlogPost.category == category)
    
    # Order by creation date (newest first)
    query = query.order_by(BlogPost.created_at.desc())
    
    # Calculate pagination
    total = query.count()
    posts = query.offset((page - 1) * per_page).limit(per_page).all()
    
    # Convert posts to response format with admin details
    posts_data = []
    for post in posts:
        # Count comments for this post by slug
        comment_count = db.query(Comment).filter(Comment.post_slug == post.slug).count()
        
        post_dict = {
            "id": post.id,
            "slug": post.slug,
            "author": post.author,
            "author_id": post.author_id,
            "category": post.category,
            "created_at": post.created_at,
            "updated_at": post.updated_at,
            "comment_count": comment_count,
            "tags": [tag.tag_name for tag in post.tags] if post.tags else [],
        }
        posts_data.append(post_dict)
    
    return PaginatedResponse(
        items=posts_data,
        total=total,
        page=page,
        pages=(total + per_page - 1) // per_page,
        per_page=per_page
    )

@router.get("/posts", response_model=PaginatedResponse)
async def get_blog_posts(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
):
    """Get all posts with minimal data (content is in .md files)"""
    
    query = db.query(BlogPost)
    # Order by creation date
    query = query.order_by(BlogPost.created_at.desc())
    
    # Pagination
    total = query.count()
    posts = query.offset((page - 1) * per_page).limit(per_page).all()
    
    # Build response
    posts_data = []
    for post in posts:
        comment_count = db.query(Comment).filter(Comment.post_slug == post.slug).count()
        
        posts_data.append({
            "id": post.id,
            "slug": post.slug,
            "created_at": post.created_at,
            "updated_at": post.updated_at,
            "comment_count": comment_count,
        })
    
    return PaginatedResponse(
        items=posts_data,
        total=total,
        page=page,
        pages=(total + per_page - 1) // per_page,
        per_page=per_page
    )

@router.get("/{slug}")
async def get_post_by_slug(
    slug: str,
    db: Session = Depends(get_db)
):
    """Public: Get post metadata by slug"""
    post = db.query(BlogPost).filter(BlogPost.slug == slug).first()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    return {
        "id": post.id,
        "slug": post.slug,
        "created_at": post.created_at,
    }
