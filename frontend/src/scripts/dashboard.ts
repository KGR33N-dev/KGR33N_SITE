import { AdminAuth } from '../utils/adminAuth';
import { API_URLS } from '../config/api';

declare global {
  interface Window {
    AdminAuth: typeof AdminAuth;
    API_URLS: typeof API_URLS;
  }
}

interface DashboardTranslations {
  loadingPosts: string;
  noPostsYet: string;
  errorLoadingData: string;
  connected: string;
  disconnected: string;
  edit: string;
  checking: string;
}

interface Post {
  id: number;
  title: string;
  slug: string;
  created_at: string;
  comment_count?: number;
}

interface DashboardData {
  posts?: Post[];
  items?: Post[];
}

export class DashboardManager {
  private translations: DashboardTranslations;
  private isDev: boolean;

  constructor(translations: DashboardTranslations, isDev: boolean = false) {
    this.translations = translations;
    this.isDev = isDev;
  }

  async init(): Promise<void> {
    if (this.isDev) console.log('Dashboard: Starting initialization');

    // Check auth first via HTTP-only cookies
    try {
      const user = await AdminAuth.verifyUser();
      if (!user || !AdminAuth.isUserAdmin(user)) {
        this.showAccessDenied();
        return;
      }

      if (this.isDev) console.log('Dashboard: Auth verified, loading data');

      // Load dashboard data once
      await this.loadDashboardData();

      // Load admin stats
      await this.loadStats();

      // Check API status
      this.checkAPIStatus();

    } catch (error) {
      if (this.isDev) console.error('Dashboard init failed:', error);
      this.redirectToLogin();
    }
  }

  private async loadDashboardData(): Promise<void> {
    try {
      if (this.isDev) {
        console.log('🔄 Loading dashboard data...');
        console.log('🎯 Using endpoint:', API_URLS.getAdminPosts({ per_page: 100 }));
      }

      // Load ALL posts (published and drafts) for admin dashboard using authenticated admin endpoint
      const response = await AdminAuth.makeAuthenticatedRequest(
        API_URLS.getAdminPosts({ per_page: 100 })
      );

      if (!response.ok) {
        const errorText = await response.text();
        if (this.isDev) {
          console.error('❌ API Response failed:', {
            status: response.status,
            statusText: response.statusText,
            error: errorText
          });
        }
        throw new Error(`Failed to fetch posts: ${response.status} ${response.statusText}`);
      }

      const data: DashboardData = await response.json();
      const posts = data.posts || data.items || (Array.isArray(data) ? data : []) as Post[];

      if (this.isDev) {
        console.log('📊 Dashboard data loaded successfully:', {
          dataStructure: Object.keys(data),
          postsCount: posts.length,
          samplePost: posts[0] ? {
            id: posts[0].id,
            title: posts[0].title,
            slug: posts[0].slug,
            created_at: posts[0].created_at,
          } : 'No posts found'
        });
      }

      // Update stats
      this.updateStats(posts);



      // Show all posts
      this.showAllPosts(posts);

    } catch (error) {
      if (this.isDev) console.error('❌ Failed to load dashboard data:', error);
      this.showError();
    }
  }

  private updateStats(posts: Post[]): void {
    const total = posts.length;

    const totalElement = document.getElementById('total-posts');

    if (totalElement) totalElement.textContent = total.toString();

    // If any elements are missing, log warning
    if (!totalElement) {
      if (this.isDev) console.warn('Some stats elements not found in DOM');
    }
  }

  private async loadStats(): Promise<void> {
    try {
      if (this.isDev) console.log('📊 Loading admin stats...');

      const response = await AdminAuth.makeAuthenticatedRequest(
        API_URLS.stats()
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch stats: ${response.status}`);
      }

      const stats = await response.json();

      if (this.isDev) {
        console.log('📈 Stats loaded:', stats);
      }

      // Update stats cards
      const usersEl = document.getElementById('stat-users');
      const usersNewEl = document.getElementById('stat-users-new');
      const postsEl = document.getElementById('stat-posts');
      const commentsEl = document.getElementById('stat-comments');
      const commentsNewEl = document.getElementById('stat-comments-new');
      const likesEl = document.getElementById('stat-likes');
      const likesNewEl = document.getElementById('stat-likes-new');

      if (usersEl && stats.users) {
        usersEl.textContent = stats.users.total.toString();
      }
      if (usersNewEl && stats.users) {
        usersNewEl.textContent = `+${stats.users.new_24h} (24h) | ${stats.users.verified} verified`;
      }
      if (postsEl && stats.posts) {
        postsEl.textContent = stats.posts.total.toString();
      }
      if (commentsEl && stats.comments) {
        commentsEl.textContent = stats.comments.total.toString();
      }
      if (commentsNewEl && stats.comments) {
        commentsNewEl.textContent = `+${stats.comments.last_24h} (24h)`;
      }
      if (likesEl && stats.reactions) {
        likesEl.textContent = stats.reactions.total.toString();
      }
      if (likesNewEl && stats.reactions) {
        likesNewEl.textContent = `+${stats.reactions.last_24h} (24h)`;
      }

      // Update recent users list
      this.updateRecentUsers(stats.recent_users || []);

    } catch (error) {
      if (this.isDev) console.error('❌ Failed to load stats:', error);
      // Stats are optional - don't show error UI
    }
  }

  private updateRecentUsers(users: Array<{
    id: number;
    username: string;
    email: string;
    created_at: string;
    verified: boolean;
    rank?: { name: string; level: number; color?: string };
    reputation_score?: number;
  }>): void {
    const container = document.getElementById('recent-users-list');
    if (!container) return;

    if (users.length === 0) {
      container.innerHTML = `
        <p class="text-gray-500 dark:text-gray-400 text-sm text-center py-4">No recent registrations</p>
      `;
      return;
    }

    container.innerHTML = users.map(user => {
      const rankBadge = user.rank ? `
        <span class="px-2 py-0.5 text-xs rounded-full" style="background-color: ${user.rank.color || '#6B7280'}20; color: ${user.rank.color || '#6B7280'}">
          ${user.rank.name} (${user.reputation_score || 0} XP)
        </span>
      ` : '';

      return `
        <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <span class="text-blue-600 dark:text-blue-400 text-sm font-medium">${user.username.charAt(0).toUpperCase()}</span>
            </div>
            <div>
              <div class="flex items-center gap-2">
                <p class="text-sm font-medium text-gray-900 dark:text-white">${user.username}</p>
                ${rankBadge}
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 truncate max-w-[200px]">${user.email}</p>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <span class="px-2 py-1 text-xs rounded-full ${user.verified ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' : 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'}">
              ${user.verified ? '✓ Verified' : 'Pending'}
            </span>
            <span class="text-xs text-gray-400">${user.created_at ? new Date(user.created_at).toLocaleDateString() : ''}</span>
          </div>
        </div>
      `;
    }).join('');
  }


  private showAllPosts(posts: Post[]): void {
    const container = document.getElementById('all-posts-list');
    if (!container) return;

    if (posts.length === 0) {
      container.innerHTML = `
        <div class="text-center py-8">
          <p class="text-gray-600 dark:text-gray-400">${this.translations.noPostsYet}</p>
        </div>
      `;
      return;
    }

    if (this.isDev) {
      console.log('📄 Rendering all posts:', posts.map(post => ({ id: post.id, title: post.title })));
    }

    const currentLang = window.location.pathname.split('/')[1] || 'pl';
    container.innerHTML = posts.map(post => {
      if (!post.id) {
        console.error('❌ Post missing ID:', post);
        return '';
      }
      const commentCount = post.comment_count ?? 0;
      return `
        <div class="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
          <a href="/${currentLang}/blog/${post.slug}" class="flex-1 group">
            <h4 class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">${post.slug}</h4>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              ${post.title || 'Untitled'} • ${new Date(post.created_at).toLocaleDateString()}
            </p>
          </a>
          <div class="flex items-center space-x-4">
            <!-- Comment count -->
            <div class="flex items-center text-gray-500 dark:text-gray-400" title="Comments">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
              </svg>
              <span class="text-sm">${commentCount}</span>
            </div>
          </div>
        </div>
      `;
    }).filter(html => html !== '').join('');
  }

  private async checkAPIStatus(): Promise<void> {
    const icon = document.getElementById('api-status-icon');
    const text = document.getElementById('api-status-text');

    try {
      const response = await fetch(API_URLS.health(), { cache: 'no-store' });
      if (response.ok) {
        if (icon) icon.className = 'w-3 h-3 rounded-full bg-green-500 mr-2';
        if (text) {
          text.textContent = this.translations.connected;
          text.className = 'text-sm font-medium text-green-600 ml-1';
        }
      } else {
        throw new Error('API not responding');
      }
    } catch (error) {
      if (this.isDev) console.error('API status check failed:', error);
      if (icon) icon.className = 'w-3 h-3 rounded-full bg-red-500 mr-2';
      if (text) {
        text.textContent = this.translations.disconnected;
        text.className = 'text-sm font-medium text-red-600 ml-1';
      }
    }
  }

  private showAccessDenied(): void {
    const element = document.getElementById('access-denied');
    if (element) {
      element.classList.remove('hidden');
    }

    // Hide main content
    const mainContent = document.getElementById('dashboard-content');
    if (mainContent) {
      mainContent.style.display = 'none';
    }
  }

  private redirectToLogin(): void {
    const currentLang = window.location.pathname.split('/')[1];
    window.location.href = `/${currentLang}/login`;
  }

  private showError(): void {
    // Show error in all posts container
    const container = document.getElementById('all-posts-list');
    if (container) {
      container.innerHTML = `
        <div class="text-center py-8">
          <p class="text-red-600 dark:text-red-400">${this.translations.errorLoadingData}</p>
        </div>
      `;
    }
  }

  // Notification helper functions
  private showInfo(message: string): void {
    // Simple console log for now - can be enhanced with toast notifications later
    console.info('Dashboard Info:', message);
  }

  private showSuccess(message: string): void {
    // Simple console log for now - can be enhanced with toast notifications later
    console.info('Dashboard Success:', message);
  }

  private showErrorNotification(message: string): void {
    // Simple console log for now - can be enhanced with toast notifications later
    console.error('Dashboard Error:', message);
  }
}


