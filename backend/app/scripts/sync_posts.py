"""
Sync blog posts from .md files to database
Only creates minimal entries for linking comments to posts via slug
Supports multilingual structure: content_blog/en/*.md, content_blog/pl/*.md

NOTE: Both en/hello-world.md and pl/hello-world.md map to ONE database entry
with slug "hello-world" - comments are shared across language versions.
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
        
        # Find all .md files recursively (supports en/*.md, pl/*.md structure)
        md_files = glob.glob(os.path.join(CONTENT_DIR, "**", "*.md"), recursive=True)
        print(f"📄 Found {len(md_files)} markdown files.")

        # Track processed slugs to avoid duplicates (en/hello-world and pl/hello-world = same post)
        processed_slugs = set()

        for file_path in md_files:
            try:
                post = frontmatter.load(file_path)
                data = post.metadata
                
                # Get base slug from filename (without language prefix)
                # en/hello-world.md -> hello-world
                # pl/hello-world.md -> hello-world
                filename_slug = os.path.splitext(os.path.basename(file_path))[0]
                base_slug = data.get('slug', filename_slug)
                
                # Skip if we already processed this base slug
                if base_slug in processed_slugs:
                    print(f"  ⏭️  {base_slug} already processed (other language version). Skipping.")
                    continue
                
                processed_slugs.add(base_slug)
                print(f"  Checking: {base_slug}")

                # Check if exists in database
                existing = db.query(BlogPost).filter(BlogPost.slug == base_slug).first()
                
                if existing:
                    print(f"  ⏭️  {base_slug} exists in database. Skipping.")
                    continue

                # Create minimal post entry with base slug (no language prefix)
                # Comments will be linked to this slug regardless of language
                new_post = BlogPost(
                    slug=base_slug,
                    author="KGR33N",
                    author_id=admin_id,
                    created_at=data.get('pubDate', datetime.now()),
                    category="general"
                )
                db.add(new_post)
                
                print(f"  ✅ Created: {base_slug}")
                
            except Exception as e:
                print(f"  ❌ Error with {file_path}: {e}")

        db.commit()
        print(f"✅ Sync complete. Processed {len(processed_slugs)} unique posts.")

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    sync_posts()


