/**
 * API Configuration
 * 
 * Automatically detects environment and returns correct API URL.
 * 
 * USAGE:
 * import { getApiUrl } from '~/utils/api';
 * const response = await fetch(`${getApiUrl()}/blog/${slug}`);
 * 
 * ENVIRONMENTS:
 * - Development (localhost): http://localhost:8080/api
 * - Production: /api (relative, same domain via Ingress)
 */

/**
 * Get the base API URL based on current environment
 */
export function getApiUrl(): string {
    // Check if we're in browser
    if (typeof window !== 'undefined') {
        const hostname = window.location.hostname;

        // Development environments
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            // In dev, backend runs on port 8080
            return 'http://localhost:8080/api';
        }

        // Production - use relative URL (Ingress handles routing)
        // /api/* is routed to backend by Nginx Ingress Controller
        return '/api';
    }

    // Server-side rendering (build time) - use relative path
    // This will be replaced at runtime in browser
    return '/api';
}

/**
 * Get API URL for a specific endpoint
 */
export function apiEndpoint(path: string): string {
    const base = getApiUrl();
    // Ensure path starts with /
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    return `${base}${cleanPath}`;
}

/**
 * Fetch wrapper with error handling
 */
export async function apiFetch<T>(
    endpoint: string,
    options: RequestInit = {}
): Promise<T> {
    const url = apiEndpoint(endpoint);

    const defaultOptions: RequestInit = {
        credentials: 'include', // Include cookies for auth
        headers: {
            'Content-Type': 'application/json',
            ...options.headers,
        },
    };

    const response = await fetch(url, { ...defaultOptions, ...options });

    if (!response.ok) {
        const error = await response.json().catch(() => ({ message: 'Unknown error' }));
        throw new Error(error.message || `HTTP ${response.status}`);
    }

    return response.json();
}

// Default export for convenience
export default {
    getApiUrl,
    apiEndpoint,
    apiFetch,
};
