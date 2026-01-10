// Comment replies functionality  
import type { Comment } from '../types/blog.ts'; // Upewnij się, że masz ten typ lub zdefiniuj go tutaj
import { AuthHelper } from '../utils/authHelper.ts';
import { API_CONFIG } from '../config/api.ts';

interface User {
  id: number;
  username: string;
  email: string;
  rank?: string | {
    id: number;
    name: string;
    display_name: string;
    icon: string;
    color: string;
    level: number;
  } | null;
}

interface Translations {
  [key: string]: string;
}

interface ApiUrls {
  getPostComments: string;
  createPostComment: string;
  likeCommentTemplate: string;
  updateCommentTemplate: string;
  deleteCommentTemplate: string;
}

// Main reply handler function
export function handleReply(
  commentId: number,
  postId: string,
  currentUser: User | null,
  translations: Translations,
  showError: (message: string) => void,
  showSuccess?: (message: string) => void,
  loadComments?: () => Promise<void>,
  isLoadingComments?: boolean,
  addRealReply?: (reply: Comment, parentId: number) => void
): void {
  console.log('💬 Reply button clicked for comment:', commentId);

  // 1. Sprawdź autoryzację
  if (!currentUser) {
    const loginRequiredText = translations['comments.loginRequired'] || 'Please login to reply';
    showError(loginRequiredText);
    return;
  }

  // 2. Znajdź dedykowany kontener na formularz (zdefiniowany w comments.ts renderComment)
  // Szukamy po ID, bo jest unikalne i szybsze
  const replyContainer = document.getElementById(`reply-form-${commentId}`);

  if (!replyContainer) {
    console.error('❌ Reply container not found for ID:', `reply-form-${commentId}`);
    // Fallback: Jeśli nie ma kontenera, spróbujmy znaleźć element komentarza (stara metoda)
    const commentElement = document.querySelector(`[data-comment-id="${commentId}"]`);
    if (!commentElement) {
      console.error('❌ Comment element also not found');
      return;
    }
    console.warn('⚠️ Using fallback appending method');
    // ... tutaj ewentualnie stara logika, ale skupmy się na naprawie głównej
    return;
  }

  // 3. Jeśli formularz już jest otwarty (ma zawartość), to go zamknij (toggle)
  if (replyContainer.innerHTML.trim() !== '' && replyContainer.style.display !== 'none') {
    replyContainer.style.display = 'none';
    replyContainer.innerHTML = '';
    return;
  }

  // 4. Znajdź nazwę użytkownika, któremu odpowiadamy (dla UI)
  const commentElement = document.querySelector(`[data-comment-id="${commentId}"]`);
  let replyToUsername = 'user';
  if (commentElement) {
    const usernameEl = commentElement.querySelector('h4, h5'); // Szukamy autora w nagłówku komentarza
    if (usernameEl) replyToUsername = usernameEl.textContent || 'user';
  }

  // 5. Generuj HTML formularza
  // Używamy innerHTML kontenera zamiast tworzyć nowy element
  replyContainer.innerHTML = `
    <div class="reply-form bg-gray-50 dark:bg-gray-900 rounded-xl p-4 border border-gray-200 dark:border-gray-700 fade-in">
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0">
          <div class="w-7 h-7 bg-gradient-to-br from-green-500 to-blue-600 rounded-full flex items-center justify-center text-white text-xs font-semibold">
            ${currentUser.username ? currentUser.username.charAt(0).toUpperCase() : (currentUser.email ? currentUser.email.charAt(0).toUpperCase() : 'U')}
          </div>
        </div>
        
        <div class="flex-1">
          <form class="reply-form-content">
            <div class="mb-3">
              <textarea 
                name="reply-content" 
                rows="3" 
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 text-sm resize-none placeholder-gray-500 dark:placeholder-gray-400"
                placeholder="${translations['comments.writeReply'] || 'Write your reply...'}"
                required
              ></textarea>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex space-x-2">
                <button 
                  type="submit" 
                  class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-1"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
                  </svg>
                  <span>${translations['comments.submitReply'] || 'Reply'}</span>
                </button>
                <button 
                  type="button" 
                  class="cancel-reply bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                >
                  ${translations['comments.cancel'] || 'Cancel'}
                </button>
              </div>
              <div class="text-xs text-gray-500 dark:text-gray-400">
                ${translations['comments.replyTo'] || 'Replying to'} <strong>${replyToUsername}</strong>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  `;

  // 6. Pokaż kontener
  replyContainer.style.display = 'block';

  // 7. Podepnij Event Listenery
  const form = replyContainer.querySelector('.reply-form-content') as HTMLFormElement;
  const cancelBtn = replyContainer.querySelector('.cancel-reply') as HTMLButtonElement;

  if (form) {
    form.addEventListener('submit', (e) => {
      handleSubmitReply(e, commentId, postId, translations, showError, showSuccess, loadComments, isLoadingComments, addRealReply);
    });
  }

  if (cancelBtn) {
    cancelBtn.addEventListener('click', () => {
      replyContainer.style.display = 'none';
      replyContainer.innerHTML = ''; // Wyczyść formularz
    });
  }

  // 8. Skupienie na polu tekstowym i przewinięcie do widoku
  const textarea = replyContainer.querySelector('textarea') as HTMLTextAreaElement;
  if (textarea) {
    textarea.focus();
    // Przewiń do formularza, żeby użytkownik widział gdzie pisze
    replyContainer.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
}

// Submit reply handler
export async function handleSubmitReply(
  e: Event,
  parentCommentId: number,
  post_slug: string,
  translations: Translations,
  showError: (message: string) => void,
  showSuccess?: (message: string) => void,
  loadComments?: () => Promise<void>,
  isLoadingComments?: boolean,
  addRealReply?: (reply: Comment, parentId: number) => void
): Promise<void> {
  e.preventDefault();

  const form = e.target as HTMLFormElement;
  const formData = new FormData(form);
  const content = (formData.get('reply-content') as string)?.trim();

  if (!content) {
    const requiredText = translations['comments.required'] || 'Reply content is required';
    showError(requiredText);
    return;
  }

  // Disable submit button during request
  const submitBtn = form.querySelector('button[type="submit"]') as HTMLButtonElement;
  const originalText = submitBtn?.textContent || '';
  const postingText = translations['comments.posting'] || 'Posting...';

  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = postingText;
  }

  try {
    // URL: /api/comments/{post_slug} - ten sam co przy dodawaniu głównego komentarza
    // Backend rozróżnia odpowiedź po polu parent_id w body
    const url = `${API_CONFIG.comments}/${post_slug}`;
    console.log('🚀 Posting reply to:', url, 'Parent ID:', parentCommentId);

    const response = await AuthHelper.makeAuthenticatedRequest(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        content: content,
        parent_id: parentCommentId // KLUCZOWE: to mówi backendowi, że to odpowiedź
      })
    });

    if (!response.ok) {
      let errorMsg = `HTTP ${response.status}`;
      try {
        const errData = await response.json();
        errorMsg = errData.detail || errData.message || errorMsg;
      } catch { }
      throw new Error(errorMsg);
    }

    const result = await response.json();
    console.log('✅ Reply created:', result);

    // Sukces!
    if (showSuccess) showSuccess(translations['comments.replySuccess'] || 'Reply added successfully');

    // Ukryj formularz po sukcesie
    const replyContainer = document.getElementById(`reply-form-${parentCommentId}`);
    if (replyContainer) {
      replyContainer.style.display = 'none';
      replyContainer.innerHTML = '';
    }

    // Dodaj odpowiedź do widoku (Optymistycznie lub z odpowiedzi API)
    if (result && (result.id || result.reply) && addRealReply) {
      const replyObj = result.reply || result;
      addRealReply(replyObj, parentCommentId);
    } else if (loadComments) {
      // Fallback: przeładuj wszystkie komentarze
      await loadComments();
    }

  } catch (error: any) {
    console.error('❌ Error posting reply:', error);
    showError(error.message || translations['comments.error'] || 'Error adding reply');
  } finally {
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.textContent = originalText;
    }
  }
}