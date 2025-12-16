/* ============================================
   CONFIGURATION CONSTANTS
   Magic numbers and configuration values
   ============================================ */

   const SCROLL_OFFSET_NAVBAR = 80; // Offset to account for fixed navbar height
   const SCROLL_THRESHOLD_SHADOW = 100; // Scroll position threshold to show navbar shadow
   const SECTION_OFFSET_ACTIVE = 100; // Offset for determining active section on scroll
   
   const ANIMATION_STAGGER_DELAY = 0.1; // Delay between staggered animations (seconds)
   const ANIMATION_DURATION = 0.6; // Base animation duration (seconds)
   const PHONE_ANIMATION_STAGGER = 0.2; // Stagger delay for phone mockups (seconds)
   
   const INTERSECTION_THRESHOLD = 0.1; // Intersection Observer threshold (10% visibility)
   const INTERSECTION_ROOT_MARGIN = '0px 0px -50px 0px'; // Margin for Intersection Observer
   const ANIMATION_TRANSLATE_Y = '20px'; // Initial translateY value for fade-in animations
   
   /* ============================================
      DOM UTILITY FUNCTIONS
      Helper functions for DOM manipulation
      ============================================ */
   
   /**
    * Initializes smooth scrolling for all anchor links on the page
    * Accounts for fixed navbar by applying offset to scroll position
    */
   function initializeSmoothScrolling() {
       document.querySelectorAll('a[href^="#"]').forEach(anchor => {
           anchor.addEventListener('click', function (e) {
               e.preventDefault();
               const target = document.querySelector(this.getAttribute('href'));
               if (target) {
                   const offsetTop = target.offsetTop - SCROLL_OFFSET_NAVBAR;
                   window.scrollTo({
                       top: offsetTop,
                       behavior: 'smooth'
                   });
               }
           });
       });
   }
   
   /**
    * Applies navbar shadow effect based on scroll position
    * Shows shadow when scrolled past threshold for visual depth
    */
   function handleNavbarScrollEffect() {
       let lastScroll = 0;
       const navbar = document.querySelector('.navbar');
       
       if (!navbar) return;
       
       window.addEventListener('scroll', () => {
           const currentScroll = window.pageYOffset;
           
           if (currentScroll > SCROLL_THRESHOLD_SHADOW) {
               navbar.style.boxShadow = '0 4px 6px -1px rgb(0 0 0 / 0.1)';
           } else {
               navbar.style.boxShadow = 'none';
           }
           
           lastScroll = currentScroll;
       });
   }
   
   /**
    * Sets up animation delays for phone mockup elements
    * Creates staggered animation effect for multiple phone elements
    * @param {NodeList} phoneElements - Collection of phone mockup elements
    */
   function setupPhoneMockupAnimations(phoneElements) {
       if (phoneElements.length === 0) return;
       
       phoneElements.forEach((phone, index) => {
           phone.style.animationDelay = `${index * PHONE_ANIMATION_STAGGER}s`;
       });
   }
   
   /**
    * Initializes Lucide icons throughout the page
    * Must be called after DOM is fully loaded
    */
   function initializeLucideIcons() {
       if (typeof lucide !== 'undefined') {
           lucide.createIcons();
       }
   }
   
   /* ============================================
      EVENT HANDLERS
      Functions that handle user interactions
      ============================================ */
   
   /**
    * Handles form submission for the signup form
    * Validates email input and shows feedback to user
    * @param {Event} e - Form submit event
    */
   function handleSignupFormSubmit(e) {
       e.preventDefault();
       const emailInput = this.querySelector('input[type="email"]');
       const email = emailInput?.value;
       
       // Basic email validation
       if (email && email.includes('@')) {
           // In production, this would send data to a server
           alert('Thank you! We\'ll be in touch soon.');
           this.reset();
       } else {
           alert('Please enter a valid email address.');
       }
   }
   
   /**
    * Sets up form submission handler for the signup form
    */
   function initializeSignupForm() {
       const signupForm = document.getElementById('signup-form');
       if (signupForm) {
           signupForm.addEventListener('submit', handleSignupFormSubmit);
       }
   }
   
   /**
    * Updates active navigation link based on current scroll position
    * Highlights the navigation link corresponding to the visible section
    */
   function updateActiveNavigation() {
       const sections = document.querySelectorAll('section[id]');
       const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');
       
       if (sections.length === 0 || navLinks.length === 0) return;
       
       let currentSectionId = '';
       
       sections.forEach(section => {
           const sectionTop = section.offsetTop;
           // Check if current scroll position is past this section's top
           if (window.pageYOffset >= sectionTop - SECTION_OFFSET_ACTIVE) {
               currentSectionId = section.getAttribute('id');
           }
       });
       
       // Update active state on navigation links
       navLinks.forEach(link => {
           link.classList.remove('active');
           if (link.getAttribute('href') === `#${currentSectionId}`) {
               link.classList.add('active');
           }
       });
   }
   
   /* ============================================
      ANIMATION FUNCTIONS
      Functions for scroll animations and transitions
      ============================================ */
   
   /**
    * Creates and configures Intersection Observer for fade-in animations
    * Observes elements and triggers fade-in when they enter viewport
    * @returns {IntersectionObserver} Configured observer instance
    */
   function createIntersectionObserver() {
       const observerOptions = {
           threshold: INTERSECTION_THRESHOLD,
           rootMargin: INTERSECTION_ROOT_MARGIN
       };
       
       const observer = new IntersectionObserver((entries) => {
           entries.forEach(entry => {
               if (entry.isIntersecting) {
                   entry.target.style.opacity = '1';
                   entry.target.style.transform = 'translateY(0)';
               }
           });
       }, observerOptions);
       
       return observer;
   }
   
   /**
    * Sets up fade-in animations for feature and pricing cards
    * Uses Intersection Observer to trigger animations when elements scroll into view
    */
   function initializeScrollAnimations() {
       const animatedElements = document.querySelectorAll('.feature-card, .pricing-card');
       
       if (animatedElements.length === 0) return;
       
       const observer = createIntersectionObserver();
       
       animatedElements.forEach((el, index) => {
           // Set initial hidden state
           el.style.opacity = '0';
           el.style.transform = `translateY(${ANIMATION_TRANSLATE_Y})`;
           el.style.transition = `opacity ${ANIMATION_DURATION}s ease-out ${index * ANIMATION_STAGGER_DELAY}s, transform ${ANIMATION_DURATION}s ease-out ${index * ANIMATION_STAGGER_DELAY}s`;
           
           // Start observing element
           observer.observe(el);
       });
   }
   
   /* ============================================
      INITIALIZATION
      Main initialization function called on page load
      ============================================ */
   
   /* ============================================
      CAROUSEL FUNCTIONS
      Image carousel navigation and controls
      ============================================ */
   
   /**
    * Initializes the horizontal scrollable gallery
    * Dynamically creates carousel items from screenshot files and handles scroll-based navigation
    */
   function initializeCarousel() {
       const track = document.getElementById('carousel-track');
       const wrapper = document.getElementById('carousel-wrapper');
       
       if (!track || !wrapper) return;
       
       // Define screenshot files with their catchy titles and descriptions
       const screenshots = [
           { 
               file: '01-auth-signup.png', 
               title: 'Get Started in Seconds',
               subtitle: 'Simple, secure signup',
               alt: 'User Registration - Sign up screen showing email, password, and username input fields' 
           },
           { 
               file: '04-unread-badges.png', 
               title: 'Never Miss a Message',
               subtitle: 'Stay on top of conversations',
               alt: 'Unread Message Tracking - Chat list showing unread message badges' 
           },
           { 
               file: '07-typing-indicator.png', 
               title: 'Real-Time Conversations',
               subtitle: 'See when friends are typing',
               alt: 'Typing Indicators - Chat screen showing typing indicator when user is composing' 
           },
           { 
               file: '11-image-message.png', 
               title: 'Share Moments Instantly',
               subtitle: 'Photos, videos, and more',
               alt: 'Image Sharing - Chat screen displaying an image message in a message bubble' 
           },
           { 
               file: '12-contact-profile.png', 
               title: 'Stay Connected',
               subtitle: 'Rich contact profiles',
               alt: 'Contact Information - Contact profile screen showing user avatar, username, and bio' 
           },
           { 
               file: '13-profile-edit.png', 
               title: 'Make It Yours',
               subtitle: 'Customize your profile',
               alt: 'Profile Customization - Profile editing screen with fields for username, bio, and profile picture' 
           },
           { 
               file: '20-chat-assist-command.png', 
               title: 'AI-Powered Messaging',
               subtitle: 'Send messages with natural language',
               alt: 'Natural Language Input - Chat Assist screen showing a typed natural language command' 
           },
           { 
               file: '22-chat-assist-success.png', 
               title: 'Send with One Command',
               subtitle: 'AI handles the rest',
               alt: 'AI Message Success - Chat Assist screen showing success message confirming message was sent' 
           }
       ];
       
       // Create carousel items dynamically
       screenshots.forEach((screenshot) => {
           const item = document.createElement('div');
           item.className = 'carousel-item';
           
           // Create image container
           const imageContainer = document.createElement('div');
           imageContainer.className = 'carousel-image-container';
           
           const img = document.createElement('img');
           img.src = `screenshots/${screenshot.file}`;
           img.alt = screenshot.alt;
           img.className = 'carousel-image';
           
           // Create overlay with title
           const overlay = document.createElement('div');
           overlay.className = 'carousel-overlay';
           
           const titleElement = document.createElement('h3');
           titleElement.className = 'carousel-title';
           titleElement.textContent = screenshot.title;
           
           const subtitleElement = document.createElement('p');
           subtitleElement.className = 'carousel-subtitle';
           subtitleElement.textContent = screenshot.subtitle;
           
           overlay.appendChild(titleElement);
           overlay.appendChild(subtitleElement);
           
           imageContainer.appendChild(img);
           imageContainer.appendChild(overlay);
           item.appendChild(imageContainer);
           track.appendChild(item);
       });
       
       /**
        * Updates edge fade gradients based on scroll position
        * Shows/hides left and right fade gradients like App Store
        */
       function updateEdgeFades() {
           const scrollLeft = wrapper.scrollLeft;
           const scrollWidth = wrapper.scrollWidth;
           const clientWidth = wrapper.clientWidth;
           const maxScroll = scrollWidth - clientWidth;
           
           // Update left fade (show when scrolled right)
           if (scrollLeft > 10) {
               wrapper.classList.add('scrolled-left');
           } else {
               wrapper.classList.remove('scrolled-left');
           }
           
           // Update right fade (hide when scrolled to end)
           if (scrollLeft < maxScroll - 10) {
               wrapper.classList.add('scrolled-right');
           } else {
               wrapper.classList.remove('scrolled-right');
           }
       }
       
       // Initial check for edge fades
       updateEdgeFades();
       
       // Update edge fades on scroll
       wrapper.addEventListener('scroll', updateEdgeFades);
       
       // Update on resize (in case layout changes)
       let resizeTimeout;
       window.addEventListener('resize', () => {
           clearTimeout(resizeTimeout);
           resizeTimeout = setTimeout(updateEdgeFades, 100);
       });
   }
   
   /**
    * Main initialization function
    * Sets up all event listeners and initializes components when DOM is ready
    */
   function init() {
       // Initialize smooth scrolling
       initializeSmoothScrolling();
       
       // Set up navbar scroll effects
       handleNavbarScrollEffect();
       
       // Initialize form handlers
       initializeSignupForm();
       
       // Set up scroll-based navigation highlighting
       window.addEventListener('scroll', updateActiveNavigation);
       
       // Initialize scroll animations
       initializeScrollAnimations();
       
       // Set up phone mockup animations
       const phoneMockups = document.querySelectorAll('.phone');
       setupPhoneMockupAnimations(phoneMockups);
       
       // Initialize carousel
       initializeCarousel();
       
       // Initialize Lucide icons
       initializeLucideIcons();
   }
   
   // Initialize when DOM is fully loaded
   document.addEventListener('DOMContentLoaded', init);
   
   