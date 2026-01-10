"""
Sync blog posts from .md files to database
Only creates minimal entries for linking comments to posts via slug
"""
import os
import glob
import frontmatter
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import BlogPost, User
from datetime import datetime

# Path to mounted content
CONTENT_DIR = os.getenv("CONTENT_DIR", "/app/content_blog")

def sync_posts():
    print(f"🔄 Starting post synchronization from {CONTENT_DIR}...")
    
    if not os.path.exists(CONTENT_DIR):
        print(f"❌ Content directory {CONTENT_DIR} not found!")
        return

    db: Session = SessionLocal()
    
    try:
        # Get default admin user
        admin = db.query(User).filter(User.username == "admin").first()
        admin_id = admin.id if admin else None
        
        # Find all .md files
        md_files = glob.glob(os.path.join(CONTENT_DIR, "*.md"))
        print(f"📄 Found {len(md_files)} markdown files.")

        for file_path in md_files:
            try:
                post = frontmatter.load(file_path)
                data = post.metadata
                
                # Get slug from frontmatter or filename
                filename_slug = os.path.splitext(os.path.basename(file_path))[0]
                slug = data.get('slug', filename_slug)
                
                print(f"  Checking: {slug}")

                # Check if exists
                existing = db.query(BlogPost).filter(BlogPost.slug == slug).first()
                
                if existing:
                    print(f"  ⏭️  {slug} exists. Skipping.")
                    continue

                # Create minimal post entry
                new_post = BlogPost(
                    slug=slug,
                    author="KGR33N",
                    author_id=admin_id,
                    created_at=data.get('pubDate', datetime.now()),
                    category="general"
                )
                db.add(new_post)
                
                print(f"  ✅ Created: {slug}")
                
            except Exception as e:
                print(f"  ❌ Error with {file_path}: {e}")

        db.commit()
        print("✅ Sync complete.")

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    sync_posts()
