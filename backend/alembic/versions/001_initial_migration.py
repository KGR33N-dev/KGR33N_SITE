"""Initial migration - create all tables

Revision ID: 001_initial
Revises: 
Create Date: 2026-01-11 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '001_initial'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ==========================================================================
    # USER ROLES TABLE
    # ==========================================================================
    op.create_table('user_roles',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.Enum('USER', 'MODERATOR', 'ADMIN', name='userroleenum'), nullable=False),
        sa.Column('display_name', sa.String(length=50), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('color', sa.String(length=7), nullable=True, server_default='#6c757d'),
        sa.Column('permissions', sa.JSON(), nullable=True, server_default='[]'),
        sa.Column('level', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_user_roles_id'), 'user_roles', ['id'], unique=False)
    op.create_index(op.f('ix_user_roles_name'), 'user_roles', ['name'], unique=True)

    # ==========================================================================
    # USER RANKS TABLE
    # ==========================================================================
    op.create_table('user_ranks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.Enum('NEWBIE', 'REGULAR', 'TRUSTED', 'STAR', 'LEGEND', 'VIP', name='userrankenum'), nullable=False),
        sa.Column('display_name', sa.String(length=50), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('icon', sa.String(length=10), nullable=True, server_default='👤'),
        sa.Column('color', sa.String(length=7), nullable=True, server_default='#28a745'),
        sa.Column('requirements', sa.JSON(), nullable=True, server_default='{}'),
        sa.Column('level', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_user_ranks_id'), 'user_ranks', ['id'], unique=False)
    op.create_index(op.f('ix_user_ranks_name'), 'user_ranks', ['name'], unique=True)

    # ==========================================================================
    # USERS TABLE
    # ==========================================================================
    op.create_table('users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(length=50), nullable=False),
        sa.Column('email', sa.String(length=100), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=100), nullable=True),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default='true'),
        sa.Column('role_id', sa.Integer(), nullable=True),
        sa.Column('rank_id', sa.Integer(), nullable=True),
        sa.Column('total_comments', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('total_likes_received', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('total_posts', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('reputation_score', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('email_verified', sa.Boolean(), nullable=True, server_default='false'),
        sa.Column('verification_code_hash', sa.String(length=255), nullable=True),
        sa.Column('verification_token', sa.String(length=500), nullable=True),
        sa.Column('verification_expires_at', sa.DateTime(), nullable=True),
        sa.Column('failed_login_attempts', sa.Integer(), nullable=True, server_default='0'),
        sa.Column('account_locked_until', sa.DateTime(), nullable=True),
        sa.Column('last_login', sa.DateTime(), nullable=True),
        sa.Column('password_reset_token', sa.String(length=500), nullable=True),
        sa.Column('password_reset_expires_at', sa.DateTime(), nullable=True),
        sa.Column('account_expires_at', sa.DateTime(), nullable=True),
        sa.Column('two_factor_enabled', sa.Boolean(), nullable=True, server_default='false'),
        sa.Column('two_factor_secret', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['rank_id'], ['user_ranks.id'], ),
        sa.ForeignKeyConstraint(['role_id'], ['user_roles.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

    # ==========================================================================
    # BLOG POSTS TABLE
    # ==========================================================================
    op.create_table('blog_posts',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('slug', sa.String(length=200), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('author', sa.String(length=100), nullable=True, server_default='KGR33N'),
        sa.Column('author_id', sa.Integer(), nullable=True),
        sa.Column('category', sa.String(length=50), nullable=True, server_default='general'),
        sa.Column('featured_image', sa.String(length=500), nullable=True),
        sa.ForeignKeyConstraint(['author_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_blog_posts_id'), 'blog_posts', ['id'], unique=False)
    op.create_index(op.f('ix_blog_posts_slug'), 'blog_posts', ['slug'], unique=True)

    # ==========================================================================
    # BLOG TAGS TABLE
    # ==========================================================================
    op.create_table('blog_tags',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('post_id', sa.Integer(), nullable=True),
        sa.Column('tag_name', sa.String(length=50), nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['blog_posts.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_blog_tags_id'), 'blog_tags', ['id'], unique=False)

    # ==========================================================================
    # API KEYS TABLE
    # ==========================================================================
    op.create_table('api_keys',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('key_hash', sa.String(length=255), nullable=False),
        sa.Column('key_preview', sa.String(length=20), nullable=False),
        sa.Column('permissions', sa.JSON(), nullable=True, server_default='["read"]'),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('expires_at', sa.DateTime(), nullable=True),
        sa.Column('last_used', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_api_keys_id'), 'api_keys', ['id'], unique=False)
    op.create_index(op.f('ix_api_keys_key_hash'), 'api_keys', ['key_hash'], unique=True)

    # ==========================================================================
    # VOTES TABLE
    # ==========================================================================
    op.create_table('votes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('poll_name', sa.String(length=100), nullable=False),
        sa.Column('option', sa.String(length=200), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_votes_id'), 'votes', ['id'], unique=False)

    # ==========================================================================
    # COMMENTS TABLE
    # ==========================================================================
    op.create_table('comments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('post_slug', sa.String(length=200), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('parent_id', sa.Integer(), nullable=True),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=True, server_default='false'),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['parent_id'], ['comments.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_comments_id'), 'comments', ['id'], unique=False)
    op.create_index(op.f('ix_comments_post_slug'), 'comments', ['post_slug'], unique=False)

    # ==========================================================================
    # COMMENT LIKES TABLE
    # ==========================================================================
    op.create_table('comment_likes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('comment_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('is_like', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['comment_id'], ['comments.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('comment_id', 'user_id', name='uq_comment_user_like')
    )
    op.create_index(op.f('ix_comment_likes_comment_id'), 'comment_likes', ['comment_id'], unique=False)
    op.create_index(op.f('ix_comment_likes_id'), 'comment_likes', ['id'], unique=False)
    op.create_index(op.f('ix_comment_likes_user_id'), 'comment_likes', ['user_id'], unique=False)

    # ==========================================================================
    # SEED DEFAULT ROLES
    # ==========================================================================
    op.execute("""
        INSERT INTO user_roles (name, display_name, description, color, permissions, level)
        VALUES 
            ('USER', 'User', 'Regular user with standard permissions', '#6c757d', '["read", "comment", "like"]', 1),
            ('MODERATOR', 'Moderator', 'Moderator with content moderation permissions', '#ffc107', '["read", "comment", "like", "moderate", "delete_comments"]', 5),
            ('ADMIN', 'Administrator', 'Full administrative access', '#dc3545', '["read", "comment", "like", "moderate", "delete_comments", "manage_users", "admin"]', 10)
        ON CONFLICT (name) DO NOTHING;
    """)

    # ==========================================================================
    # SEED DEFAULT RANKS
    # ==========================================================================
    op.execute("""
        INSERT INTO user_ranks (name, display_name, description, icon, color, requirements, level)
        VALUES 
            ('NEWBIE', 'Newbie', 'New member of the community', '🌱', '#6c757d', '{}', 1),
            ('REGULAR', 'Regular', 'Active community member', '⭐', '#28a745', '{"comments": 10}', 2),
            ('TRUSTED', 'Trusted', 'Trusted community contributor', '💎', '#17a2b8', '{"comments": 50, "likes_received": 100}', 3),
            ('STAR', 'Star', 'Community star', '🌟', '#ffc107', '{"comments": 100, "likes_received": 500}', 4),
            ('LEGEND', 'Legend', 'Community legend', '👑', '#fd7e14', '{"comments": 500, "likes_received": 2000}', 5),
            ('VIP', 'VIP', 'Very Important Person', '💜', '#6f42c1', '{}', 10)
        ON CONFLICT (name) DO NOTHING;
    """)


def downgrade() -> None:
    # Drop tables in reverse order (respecting foreign keys)
    op.drop_table('comment_likes')
    op.drop_table('comments')
    op.drop_table('votes')
    op.drop_table('api_keys')
    op.drop_table('blog_tags')
    op.drop_table('blog_posts')
    op.drop_table('users')
    op.drop_table('user_ranks')
    op.drop_table('user_roles')
    
    # Drop enums
    op.execute('DROP TYPE IF EXISTS userroleenum')
    op.execute('DROP TYPE IF EXISTS userrankenum')
