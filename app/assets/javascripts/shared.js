// Shared JS for sidebar and partials
function showComingSoon(feature) {
  if (window.notificationController) {
    window.notificationController.showNotification(`${feature} feature coming soon!`, 'info');
  } else {
    alert(`${feature} feature coming soon!`);
  }
}

function showConnectPrompt(platform) {
  if (window.notificationController) {
    window.notificationController.showNotification(`Connect your ${platform} account to view platform-specific data.`, 'info');
  } else {
    alert(`Connect your ${platform} account to view platform-specific data.`);
  }
}

document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('[data-shared-action="coming-soon"]').forEach(el => {
    el.addEventListener('click', function(e) {
      e.preventDefault();
      showComingSoon(this.dataset.feature);
    });
  });
  document.querySelectorAll('[data-shared-action="connect-prompt"]').forEach(el => {
    el.addEventListener('click', function(e) {
      e.preventDefault();
      showConnectPrompt(this.dataset.platform);
    });
  });
}); 