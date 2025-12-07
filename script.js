document.querySelectorAll('nav a').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        
        // Remove active class from all pages
        document.querySelectorAll('.page').forEach(page => {
            page.classList.remove('active');
        });
        
        // Remove active class from all nav links
        document.querySelectorAll('nav a').forEach(navLink => {
            navLink.classList.remove('active');
        });
        
        // Add active class to the target page
        const targetId = link.getAttribute('href').substring(1);
        document.getElementById(targetId).classList.add('active');
        
        // Add active class to clicked nav link
        link.classList.add('active');
    });
});