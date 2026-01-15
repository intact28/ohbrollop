// Google Apps Script URL
const GOOGLE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbxf9esQgeQ9PyWsCocpMmiPD_xpbjg_wJUU1eBxredJIp1at1B5exwAy7hJu28v3xlG0A/exec';

// Accordion functionality
document.querySelectorAll('.accordion-header').forEach(button => {
    button.addEventListener('click', () => {
        const item = button.parentElement;
        item.classList.toggle('open');
    });
});

// Countdown timer (only runs on home page)
const daysEl = document.getElementById('days');
if (daysEl) {
    const weddingDate = new Date('2026-07-25T15:00:00');

    function updateCountdown() {
        const now = new Date();
        const diff = weddingDate - now;
        
        if (diff <= 0) {
            document.getElementById('days').textContent = '0';
            document.getElementById('hours').textContent = '0';
            document.getElementById('minutes').textContent = '0';
            document.getElementById('seconds').textContent = '0';
            return;
        }
        
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));
        const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((diff % (1000 * 60)) / 1000);
        
        document.getElementById('days').textContent = days;
        document.getElementById('hours').textContent = hours;
        document.getElementById('minutes').textContent = minutes;
        document.getElementById('seconds').textContent = seconds;
    }

    updateCountdown();
    setInterval(updateCountdown, 1000);
}

// RSVP Form
const rsvpForm = document.getElementById('rsvp-form');

if (rsvpForm) {
    const nameInput = document.getElementById('name');
    const emailInput = document.getElementById('email');
    const phoneInput = document.getElementById('phone');
    const attendingRadios = document.querySelectorAll('input[name="attending"]');
    const attendingGroup = document.getElementById('attending-group');
    const attendingFields = document.getElementById('attending-fields');
    const pizzaRadios = document.querySelectorAll('input[name="pizza"]');
    const pizzaYes = document.getElementById('pizza-yes');
    const pizzaNo = document.getElementById('pizza-no');
    const pizzaGroup = document.getElementById('pizza-group');
    const pizzaFields = document.getElementById('pizza-fields');
    const guestNames = document.getElementById('guest-names');
    const guestCount = document.getElementById('guest-count');
    const dietary = document.getElementById('dietary');
    const pizzaCount = document.getElementById('pizza-count');
    const songRequest = document.getElementById('song-request');
    const message = document.getElementById('message');
    const submitBtn = document.getElementById('submit-btn');
    
    let isAttending = null;

    // Validation helpers
    function isValidName(name) {
        return name.trim().length >= 2;
    }

    function isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    function isValidPhone(phone) {
        const digits = phone.replace(/\D/g, '');
        return digits.length >= 8;
    }

    // Update field validation UI
    function setFieldInvalid(input, isInvalid) {
        const formGroup = input.closest('.form-group');
        if (formGroup) {
            if (isInvalid) {
                formGroup.classList.add('invalid');
            } else {
                formGroup.classList.remove('invalid');
            }
        }
    }

    // Update radio group validation UI
    function setRadioGroupInvalid(group, isInvalid) {
        if (group) {
            if (isInvalid) {
                group.classList.add('invalid');
            } else {
                group.classList.remove('invalid');
            }
        }
    }

    // Validate form and update submit button state
    function validateForm() {
        const nameValid = isValidName(nameInput.value);
        const emailValid = isValidEmail(emailInput.value);
        const phoneValid = isValidPhone(phoneInput.value);
        const attendingSelected = isAttending !== null;

        setFieldInvalid(nameInput, !nameValid);
        setFieldInvalid(emailInput, !emailValid);
        setFieldInvalid(phoneInput, !phoneValid);
        setRadioGroupInvalid(attendingGroup, !attendingSelected);

        if (isAttending === null) {
            submitBtn.disabled = true;
            return false;
        }

        if (!isAttending) {
            setFieldInvalid(guestNames, false);
            setRadioGroupInvalid(pizzaGroup, false);
            
            const isValid = nameValid && emailValid && phoneValid;
            submitBtn.disabled = !isValid;
            return isValid;
        }

        const namesValid = guestNames.value.trim().length > 0;
        const pizzaSelected = pizzaYes.checked || pizzaNo.checked;

        setFieldInvalid(guestNames, !namesValid);
        setRadioGroupInvalid(pizzaGroup, !pizzaSelected);

        const isValid = nameValid && emailValid && phoneValid && namesValid && pizzaSelected;
        submitBtn.disabled = !isValid;
        return isValid;
    }

    // Attending radio change
    attendingRadios.forEach(radio => {
        radio.addEventListener('change', (e) => {
            isAttending = e.target.value === 'yes';
            setRadioGroupInvalid(attendingGroup, false);
            
            if (isAttending) {
                attendingFields.classList.remove('hidden');
            } else {
                attendingFields.classList.add('hidden');
                pizzaFields.classList.add('hidden');
                pizzaYes.checked = false;
                pizzaNo.checked = false;
                guestNames.value = '';
                setFieldInvalid(guestNames, false);
                setRadioGroupInvalid(pizzaGroup, false);
            }
            
            validateForm();
        });
    });

    // Pizza radio change
    pizzaRadios.forEach(radio => {
        radio.addEventListener('change', () => {
            setRadioGroupInvalid(pizzaGroup, false);
            
            if (pizzaYes.checked) {
                pizzaFields.classList.remove('hidden');
            } else {
                pizzaFields.classList.add('hidden');
            }
            validateForm();
        });
    });

    // Input event listeners
    nameInput.addEventListener('input', validateForm);
    emailInput.addEventListener('input', validateForm);
    phoneInput.addEventListener('input', validateForm);
    guestNames.addEventListener('input', validateForm);

    // Form submission
    rsvpForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        if (!validateForm()) {
            const firstError = rsvpForm.querySelector('.invalid');
            if (firstError) {
                firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
            return;
        }

        // Store values before disabling form
        const submittedName = nameInput.value;
        const submittedEmail = emailInput.value;
        const submittedAttending = isAttending;

        // Disable button and show loading state
        submitBtn.disabled = true;
        submitBtn.textContent = 'Skickar...';

        const data = {
            name: nameInput.value,
            email: emailInput.value,
            phone: phoneInput.value,
            attending: isAttending ? 'yes' : 'no',
            guestCount: guestCount.value,
            guestNames: guestNames.value,
            dietary: dietary.value,
            pizza: pizzaYes.checked ? 'yes' : 'no',
            pizzaCount: pizzaCount.value,
            songRequest: songRequest.value,
            message: message.value
        };

        try {
            const response = await fetch(GOOGLE_SCRIPT_URL, {
                method: 'POST',
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.success) {
                showConfirmation(true, submittedName, submittedEmail, submittedAttending);
            } else if (result.error === 'already_submitted') {
                showAlreadySubmitted(submittedEmail);
            } else {
                throw new Error(result.message || 'Unknown error');
            }
        } catch (error) {
            console.error('Error:', error);
            showConfirmation(false, submittedName, submittedEmail, submittedAttending);
        }
    });

    // Show confirmation message
    function showConfirmation(success, name, email, attending) {
        const section = document.getElementById('rsvp');
        
        if (success) {
            section.innerHTML = `
                <div class="heading-group">
                    <h2>Tack för ditt svar!</h2>
                    <img src="images/divider.svg" alt="" class="divider">
                </div>
                <div class="confirmation-message">
                    <p class="confirmation-icon">♥</p>
                    <p><strong>${name}</strong>, vi har tagit emot din anmälan.</p>
                    ${attending 
                        ? `<p>Vi ser fram emot att fira tillsammans med dig!</p>`
                        : `<p>Tack för att du meddelade oss. Vi hoppas vi ses en annan gång!</p>`
                    }
                    <p class="confirmation-details">En bekräftelse har skickats till dig och till oss.</p>
                </div>
            `;
        } else {
            submitBtn.disabled = false;
            submitBtn.textContent = 'Skicka';
            
            let errorDiv = rsvpForm.querySelector('.submit-error');
            if (!errorDiv) {
                errorDiv = document.createElement('div');
                errorDiv.className = 'submit-error';
                rsvpForm.insertBefore(errorDiv, submitBtn);
            }
            errorDiv.innerHTML = `
                <p>Något gick fel när anmälan skulle skickas.</p>
                <p>Vänligen försök igen eller kontakta oss direkt på <a href="mailto:hannaoskarbrollop2026@gmail.com">hannaoskarbrollop2026@gmail.com</a></p>
            `;
        }
    }

    // Show already submitted message
    function showAlreadySubmitted(email) {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Skicka';
        
        let errorDiv = rsvpForm.querySelector('.submit-error');
        if (!errorDiv) {
            errorDiv = document.createElement('div');
            errorDiv.className = 'submit-error';
            rsvpForm.insertBefore(errorDiv, submitBtn);
        }
        errorDiv.innerHTML = `
            <p>E-postadressen <strong>${email}</strong> har redan skickat in en anmälan.</p>
            <p>Om du behöver ändra din anmälan, vänligen kontakta oss på <a href="mailto:hannaoskarbrollop2026@gmail.com">hannaoskarbrollop2026@gmail.com</a></p>
        `;
    }

    // Run initial validation
    validateForm();
}

// Lightbox functionality for map images
const lightbox = document.getElementById('lightbox');

if (lightbox) {
    const lightboxImg = document.getElementById('lightbox-img');
    const lightboxClose = document.querySelector('.lightbox-close');
    const mapImages = document.querySelectorAll('.map-figure img');

    // Open lightbox when clicking a map image
    mapImages.forEach(img => {
        img.addEventListener('click', () => {
            lightboxImg.src = img.src;
            lightboxImg.alt = img.alt;
            lightbox.classList.add('active');
            document.body.style.overflow = 'hidden'; // Prevent scrolling
        });
    });

    // Close lightbox when clicking the X
    lightboxClose.addEventListener('click', (e) => {
        e.stopPropagation();
        closeLightbox();
    });

    // Close lightbox when clicking outside the image
    lightbox.addEventListener('click', (e) => {
        if (e.target === lightbox) {
            closeLightbox();
        }
    });

    // Close lightbox with Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && lightbox.classList.contains('active')) {
            closeLightbox();
        }
    });

    function closeLightbox() {
        lightbox.classList.remove('active');
        document.body.style.overflow = ''; // Restore scrolling
    }
}