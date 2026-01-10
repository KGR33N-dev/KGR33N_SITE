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


