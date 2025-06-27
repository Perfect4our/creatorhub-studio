// Billing page functionality
document.addEventListener('DOMContentLoaded', function() {
  // First-time viewing billing page functionality
  if (document.getElementById('firstTimeWelcome')) {
    // Scroll to welcome message after page loads
    setTimeout(function() {
      const welcomeAlert = document.getElementById('firstTimeWelcome');
      if (welcomeAlert) {
        welcomeAlert.scrollIntoView({ 
          behavior: 'smooth', 
          block: 'start',
          inline: 'nearest' 
        });
        
        // Add a gentle bounce effect
        welcomeAlert.style.animation = 'welcome-bounce 1s ease-out 0.5s';
      }
    }, 500);
    
    // Auto-dismiss the welcome message after 30 seconds (optional)
    setTimeout(function() {
      const welcomeAlert = document.getElementById('firstTimeWelcome');
      if (welcomeAlert && !welcomeAlert.classList.contains('show')) {
        const alertInstance = bootstrap.Alert.getOrCreateInstance(welcomeAlert);
        alertInstance.close();
      }
    }, 30000);
  }
});

// Pricing page functionality - Development bypass
function initializePricingBypass() {
  const bypassInput = document.getElementById('bypassCode');
  const applyBtn = document.getElementById('applyBypass');
  
  if (bypassInput && applyBtn) {
    // Handle Enter key in input
    bypassInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        applyBypass();
      }
    });
    
    // Handle button click
    applyBtn.addEventListener('click', applyBypass);
    
    function applyBypass() {
      const code = bypassInput.value.trim();
      
      if (code === 'dev2025') {
        // Show loading state
        applyBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Applying...';
        applyBtn.disabled = true;
        
        // Send request to bypass endpoint
        fetch('/billing/dev_bypass', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ code: code })
        })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            // Show success and redirect
            applyBtn.innerHTML = '<i class="fas fa-check me-1"></i>Success!';
            applyBtn.className = 'btn btn-success';
            
            setTimeout(() => {
              window.location.href = '/dashboard';
            }, 1500);
          } else {
            throw new Error(data.message || 'Invalid code');
          }
        })
        .catch(error => {
          // Show error
          applyBtn.innerHTML = '<i class="fas fa-times me-1"></i>Error';
          applyBtn.className = 'btn btn-danger';
          
          setTimeout(() => {
            applyBtn.innerHTML = '<i class="fas fa-unlock me-1"></i>Apply';
            applyBtn.className = 'btn btn-info';
            applyBtn.disabled = false;
          }, 2000);
        });
      } else {
        // Invalid code
        bypassInput.style.borderColor = '#dc3545';
        bypassInput.focus();
        
        setTimeout(() => {
          bypassInput.style.borderColor = '';
        }, 2000);
      }
    }
  }
}

// PostHog Analytics for pricing page
function initializePricingAnalytics(config = {}) {
  if (window.posthog) {
    // Track pricing page view
    posthog.capture('pricing_page_viewed', {
      user_authenticated: config.userAuthenticated || false,
      user_id: config.userId || null,
      has_existing_subscription: config.hasExistingSubscription || false,
      page_location: 'pricing',
      stripe_configured: config.stripeConfigured || false
    });
    
    // Track plan button clicks
    document.querySelectorAll('form[action*="create_checkout_session"]').forEach(form => {
      form.addEventListener('submit', function(e) {
        const planInput = this.querySelector('input[name="plan"]');
        const planType = planInput ? planInput.value : 'unknown';
        
        posthog.capture('subscription_plan_selected', {
          plan_type: planType,
          user_id: config.userId || null,
          user_email: config.userEmail || null,
          page_location: 'pricing',
          conversion_step: 'checkout_initiated'
        });
      });
    });
    
    // Track sign-in link clicks for unauthenticated users
    document.querySelectorAll('a[href*="sign_in"]').forEach(link => {
      link.addEventListener('click', function() {
        posthog.capture('pricing_signin_clicked', {
          page_location: 'pricing',
          conversion_step: 'authentication_required'
        });
      });
    });
    
    // Track FAQ interactions
    document.querySelectorAll('.accordion-button').forEach(button => {
      button.addEventListener('click', function() {
        const faqTitle = this.textContent.trim();
        posthog.capture('pricing_faq_opened', {
          faq_question: faqTitle,
          page_location: 'pricing'
        });
      });
    });
    
    // Track development bypass usage
    const bypassBtn = document.getElementById('applyBypass');
    if (bypassBtn && config.isDevelopment) {
      bypassBtn.addEventListener('click', function() {
        posthog.capture('dev_bypass_attempted', {
          page_location: 'pricing',
          environment: 'development'
        });
      });
    }
  }
}

// Initialize on DOMContentLoaded
document.addEventListener('DOMContentLoaded', function() {
  initializePricingBypass();
}); 