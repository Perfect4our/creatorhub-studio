// Dashboard JS moved from inline scripts
// ... (content to be filled in next step) ... 

document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('.progress-bar[data-width], .event-fill[data-width]').forEach(function(el) {
    el.style.width = el.dataset.width + '%';
  });
}); 