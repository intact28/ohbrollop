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

// RSVP Form conditional fields and validation
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

        // Always show validation state
        setFieldInvalid(nameInput, !nameValid);
        setFieldInvalid(emailInput, !emailValid);
        setFieldInvalid(phoneInput, !phoneValid);
        setRadioGroupInvalid(attendingGroup, !attendingSelected);

        // If attending not selected yet, disable submit
        if (isAttending === null) {
            submitBtn.disabled = true;
            return false;
        }

        // If not attending, only need name, email and phone
        if (!isAttending) {
            // Hide errors for attending-specific fields when not attending
            setFieldInvalid(guestNames, false);
            setRadioGroupInvalid(pizzaGroup, false);
            
            const isValid = nameValid && emailValid && phoneValid;
            submitBtn.disabled = !isValid;
            return isValid;
        }

        // If attending, validate additional fields
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
                // Reset fields when switching to No
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
    rsvpForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        if (!validateForm()) {
            // Scroll to first error
            const firstError = rsvpForm.querySelector('.invalid');
            if (firstError) {
                firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
            return;
        }

        // For now, just log the data - replace with actual submission
        const formData = new FormData(rsvpForm);
        console.log('Form submitted:', Object.fromEntries(formData));
        alert('Tack för din anmälan!');
    });

    // Run initial validation to show required fields
    validateForm();
}