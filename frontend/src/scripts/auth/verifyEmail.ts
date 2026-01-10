import { AdminAuth } from '../../utils/adminAuth';
import pageLifecycle from '../../utils/pageLifecycle';
import { notifications } from '~/utils/notifications';

// Global flags to prevent double initialization
let isVerifyEmailInitialized = false;

export function initVerifyEmailPage(_lang: string) {
  console.log('🚀 initVerifyEmailPage called, isInitialized:', isVerifyEmailInitialized);

  // Prevent double initialization
  if (isVerifyEmailInitialized) {
    console.warn('⚠️ VerifyEmail page already initialized, skipping...');
    return;
  }

  // Check if already logged in
  if (AdminAuth.isAuthenticated()) {
    const currentLang = window.location.pathname.split('/')[1];
    window.location.href = `/${currentLang}/blog`;
    return;
  }

  isVerifyEmailInitialized = true;
  console.log('✅ VerifyEmail page initialization started');

  // Reset initialization flag on page navigation
  document.addEventListener('astro:before-swap', () => {
    console.log('🔄 Page navigation detected, resetting initialization flag');
    isVerifyEmailInitialized = false;
  }, { once: true });

  const verifyForm = document.getElementById('verify-form') as HTMLFormElement;
  const emailInput = document.getElementById('email') as HTMLInputElement;
  const codeInput = document.getElementById('verification-code') as HTMLInputElement;
  const verifyButton = document.getElementById('verify-button') as HTMLButtonElement;
  const verifyButtonText = document.getElementById('verify-button-text') as HTMLSpanElement;
  const verifySpinner = document.getElementById('verify-loading-spinner') as HTMLElement;
  const resendButton = document.getElementById('resend-button') as HTMLButtonElement;
  const resendButtonText = document.getElementById('resend-button-text') as HTMLSpanElement;
  const emailDisplay = document.getElementById('email-display') as HTMLParagraphElement;

  // Auto-format verification code input
  if (codeInput) {
    const formatCodeInput = (e: Event) => {
      const target = e.target as HTMLInputElement;
      target.value = target.value.replace(/\D/g, '').slice(0, 6);
    };

    pageLifecycle.addEventListener(codeInput, 'input', formatCodeInput);
  }

  const urlParams = new URLSearchParams(window.location.search);
  const emailFromUrl = urlParams.get('email');
  const codeFromUrl = urlParams.get('code');
  const emailFromStorage = localStorage.getItem('pending_verification_email');

  // Auto-fill email from URL or storage
  if (emailFromUrl && emailInput && emailDisplay) {
    emailInput.value = emailFromUrl;
    emailDisplay.textContent = `Verification code sent to ${emailFromUrl}`;
    localStorage.setItem('pending_verification_email', emailFromUrl);
  } else if (emailFromStorage && emailInput && emailDisplay) {
    emailInput.value = emailFromStorage;
    emailDisplay.textContent = `Verification code sent to ${emailFromStorage}`;
  }

  // Auto-fill code from URL if present
  if (codeFromUrl && codeInput) {
    codeInput.value = codeFromUrl;
  }

  // Verification form submission
  if (verifyForm) {
    const handleVerifySubmit = async (e: Event) => {
      e.preventDefault();

      // Prevent double submission
      if (verifyButton.disabled) return;

      const email = emailInput.value.trim();
      const code = codeInput.value.trim();

      if (!email || !code) {
        notifications.errorKey('verifyEmail.enterEmailAndCode');
        return;
      }

      if (code.length !== 6) {
        notifications.errorKey('verifyEmail.verificationCodeLength');
        return;
      }

      // Show loading state
      verifyButton.disabled = true;
      verifyButtonText.textContent = 'Verifying...';
      verifySpinner.classList.remove('hidden');

      try {
        const response = await AdminAuth.verifyEmail(email, code);

        // Show success notification using translation_code if available, otherwise fallback
        if (response.translation_code) {
          notifications.successKey(response.translation_code, 'api.');
        } else {
          // Fallback to hardcoded key if API doesn't provide translation_code
          notifications.successKey('EMAIL_VERIFICATION_SUCCESS', 'api.');
        }

        // Clear pending email from storage
        localStorage.removeItem('pending_verification_email');

        // Show success UI instead of immediate redirect
        const currentLang = window.location.pathname.split('/')[1];
        const formContainer = verifyForm.closest('.bg-white, .dark\\:bg-slate-900');
        if (formContainer) {
          formContainer.innerHTML = `
            <div class="text-center py-8">
              <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100 dark:bg-green-900/20 mb-6">
                <svg class="h-8 w-8 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                ✅ Email Verified!
              </h3>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                Your account has been successfully verified. You can now log in.
              </p>
              <a href="/${currentLang}/login" 
                 class="inline-flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200">
                Go to Login
                <svg class="ml-2 w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"></path>
                </svg>
              </a>
            </div>
          `;
        }

      } catch (error) {
        const message = error instanceof Error ? error.message : 'Verification failed';
        notifications.errorKey(message, 'api.');

        // Reset button state only on error
        verifyButton.disabled = false;
        verifyButtonText.textContent = 'Verify Email';
        verifySpinner.classList.add('hidden');
      }
    };

    pageLifecycle.addEventListener(verifyForm, 'submit', handleVerifySubmit);

    // Auto-submit if both email and code are present in URL
    if (emailFromUrl && codeFromUrl) {
      console.log('🚀 Auto-verifying with code from URL...');
      // Small delay to ensure page is fully loaded and show user what's happening
      setTimeout(() => {
        emailDisplay.textContent = `Automatically verifying ${emailFromUrl}...`;
        verifyForm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
      }, 500);
    }
  }

  // Resend verification code
  if (resendButton) {
    const handleResendClick = async (e: Event) => {
      e.preventDefault();
      e.stopPropagation();

      console.log('🔄 Resend button clicked, disabled state:', resendButton.disabled);

      // Immediate protection against double clicks
      if (resendButton.disabled) {
        console.log('❌ Button already disabled, preventing execution');
        return;
      }

      const email = emailInput.value.trim();

      if (!email) {
        console.log('❌ No email provided');
        notifications.errorKey('verifyEmail.enterEmail');
        return;
      }

      console.log('✅ Starting resend process for email:', email);

      // Disable button immediately and change text
      resendButton.disabled = true;
      resendButtonText.textContent = 'Sending...';
      console.log('🔒 Button disabled, text changed to "Sending..."');

      try {
        // Get current language from URL
        const currentLang = window.location.pathname.split('/')[1] || 'en';

        console.log('📤 Making API call to resendVerification...');
        const response = await AdminAuth.resendVerification(email, currentLang);
        console.log('✅ API call successful, response:', response);

        // Show success notification using translation_code if available, otherwise fallback
        if (response.translation_code) {
          notifications.successKey(response.translation_code, 'api.');
        } else {
          // Fallback to hardcoded key if API doesn't provide translation_code
          notifications.successKey('VERIFICATION_CODE_SENT', 'api.');
        }

        // Permanently disable button and change text
        resendButtonText.textContent = 'Code Sent';
        console.log('✅ Button permanently disabled with "Code Sent" text');

      } catch (error) {
        console.log('❌ API call failed, error:', error);

        // Check if this is an info message (like EMAIL_ALREADY_VERIFIED)
        if (error instanceof Error && 'type' in error && (error as Error & { type: string }).type === 'info') {
          console.log('📧 Handling as info message');
          // For info messages, show as info notification and keep button disabled
          notifications.infoKey(error.message, 'api.');
          resendButtonText.textContent = 'Already Verified';
        } else {
          // Re-enable button only on actual errors
          resendButton.disabled = false;
          resendButtonText.textContent = 'Resend Code';
          notifications.errorKey(error, 'api.');
          console.log('🔓 Button re-enabled due to error');
        }
      }
    };

    console.log('🎯 Adding click event listener to resend button');
    pageLifecycle.addEventListener(resendButton, 'click', handleResendClick);
  }  // Auto-focus code input if email is prefilled
  if (emailInput && emailInput.value && codeInput) {
    codeInput.focus();
  } else if (emailInput) {
    emailInput.focus();
  }
}
