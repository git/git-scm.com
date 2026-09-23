document.addEventListener('DOMContentLoaded', function() {
  const sidebarBtn = document.querySelector('.sidebar-btn');
  const sidebar = document.getElementById('sidebar');

  if (sidebarBtn && sidebar) {
    // Set initial ARIA state
    sidebarBtn.setAttribute('aria-expanded', 'false');
    
    // Toggle sidebar when button is clicked
    sidebarBtn.addEventListener('click', function() {
      const isExpanded = this.getAttribute('aria-expanded') === 'true';
      this.setAttribute('aria-expanded', !isExpanded);
      sidebar.classList.toggle('active');
    });

    // Close sidebar when clicking outside
    document.addEventListener('click', function(e) {
      if (!sidebar.contains(e.target) && !sidebarBtn.contains(e.target)) {
        sidebar.classList.remove('active');
        sidebarBtn.setAttribute('aria-expanded', 'false');
      }
    });

    // Close sidebar when pressing Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && sidebar.classList.contains('active')) {
        sidebar.classList.remove('active');
        sidebarBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }
});