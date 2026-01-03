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
    const attendingRadios = document.querySelectorAll('input[name="attending"]');
    const attendingFields = document.getElementById('attending-fields');
    const pizzaRadios = document.querySelectorAll('input[name="pizza"]');
    const pizzaYes = document.getElementById('pizza-yes');
    const pizzaNo = document.getElementById('pizza-no');
    const pizzaFields = document.getElementById('pizza-fields');
    const guestNames = document.getElementById('guest-names');
    const submitBtn = document.getElementById('submit-btn');
    
    let isAttending = false;

    // Validate form and update submit button state
    function validateForm() {
        if (!isAttending) {
            submitBtn.disabled = false;
            return true;
        }

        const namesValid = guestNames.value.trim().length > 0;
        const pizzaSelected = pizzaYes.checked || pizzaNo.checked;

        // Update UI for names field
        const namesError = guestNames.parentElement.querySelector('.field-error');
        if (namesValid) {
            guestNames.classList.remove('invalid');
            namesError.classList.add('hidden');
        } else {
            guestNames.classList.add('invalid');
            namesError.classList.remove('hidden');
        }

        // Update UI for pizza field
        const pizzaError = document.querySelector('.pizza-group .field-error');
        if (pizzaSelected) {
            pizzaError.classList.add('hidden');
        } else {
            pizzaError.classList.remove('hidden');
        }

        const isValid = namesValid && pizzaSelected;
        submitBtn.disabled = !isValid;
        return isValid;
    }

    // Attending radio change
    attendingRadios.forEach(radio => {
        radio.addEventListener('change', (e) => {
            isAttending = e.target.value === 'yes';
            
            if (isAttending) {
                attendingFields.classList.remove('hidden');
            } else {
                attendingFields.classList.add('hidden');
                // Reset fields when switching to No
                pizzaFields.classList.add('hidden');
                pizzaYes.checked = false;
                pizzaNo.checked = false;
                guestNames.value = '';
                guestNames.classList.remove('invalid');
                guestNames.parentElement.querySelector('.field-error').classList.add('hidden');
                document.querySelector('.pizza-group .field-error').classList.add('hidden');
            }
            
            validateForm();
        });
    });

    // Pizza radio change
    pizzaRadios.forEach(radio => {
        radio.addEventListener('change', () => {
            if (pizzaYes.checked) {
                pizzaFields.classList.remove('hidden');
            } else {
                pizzaFields.classList.add('hidden');
            }
            validateForm();
        });
    });

    // Guest names input
    guestNames.addEventListener('input', validateForm);

    // Form submission
    rsvpForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        if (!validateForm()) {
            return;
        }

        // For now, just log the data - replace with actual submission
        const formData = new FormData(rsvpForm);
        console.log('Form submitted:', Object.fromEntries(formData));
        alert('Tack för din anmälan!');
    });
}