
import os
import glob
import frontmatter
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import BlogPost, User, BlogPostTranslation
from datetime import datetime

# Path to mounted content
CONTENT_DIR = os.getenv("CONTENT_DIR", "/app/content_blog")

def sync_posts():
    print(f"🔄 Starting post synchronization from {CONTENT_DIR}...")
    
    if not os.path.exists(CONTENT_DIR):
        print(f"❌ Content directory {CONTENT_DIR} not found inside container!")
        return

    db: Session = SessionLocal()
    
    try:
        # Get default admin user as author fallback
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
                
                print(f"  Checking post: {slug}")

                # Check if exists
                existing_post = db.query(BlogPost).filter(BlogPost.slug == slug).first()
                
                if existing_post:
                    print(f"  ⏭️  Post {slug} already exists. Skipping.")
                    continue

                # Create new post
                new_post = BlogPost(
                    slug=slug,
                    author="KGR33N", # Default or from frontmatter
                    author_id=admin_id,
                    is_published=True,
                    published_at=data.get('pubDate', datetime.now()),
                    created_at=data.get('pubDate', datetime.now()),
                    featured_image=data.get('heroImage', ''),
                    category="general"
                )
                db.add(new_post)
                db.flush() # Get ID

                # Create translation entry (minimal metadata, NO content)
                # We assume the content is managed by static files/Astro.
                # However, for the 'Comment' relationship to work, we just need the BlogPost entry.
                # The translation entry is technically optional for comments, but required if the old system expects it for listing.
                # Since we replaced the listing logic in Astro to use 'getCollection', the DB translation entries are 
                # mainly unused unless there's some legacy backend Admin UI dependency.
                # We'll populate minimal data for consistency.
                
                translation = BlogPostTranslation(
                    post_id=new_post.id,
                    language_code="pl", # Defaulting to PL
                    title=data.get('title', 'No Title'),
                    content="", # User requested NO content in DB
                    excerpt=data.get('description', ''),
                    meta_title=data.get('title', ''),
                    meta_description=data.get('description', '')
                )
                db.add(translation)
                
                print(f"  ✅ Created post slug: {slug}")
                
            except Exception as e:
                print(f"  ❌ Error processing {file_path}: {e}")

        db.commit()
        print("✅ Synchronization complete.")

    except Exception as e:
        print(f"❌ Fatal error during sync: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    sync_posts()
