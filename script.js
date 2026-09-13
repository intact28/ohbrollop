/* ================================================================
   MEDIA DATA
   ================================================================ */

let media = [];

let visibleMedia = [];

let activeFilter = 'all';

let activePhotographerFilter = 'all';


/*
 * Because we are serving the original full-resolution files,
 * don't put every image into the DOM at once.
 */
const ITEMS_PER_BATCH = 24;

let renderedCount = 0;

let isRenderingBatch = false;



/* ================================================================
   DOM REFERENCES
   ================================================================ */

const photoGrid =
    document.getElementById(
        'photo-grid'
    );


const emptyGallery =
    document.getElementById(
        'empty-gallery'
    );


const filterButtons =
    document.querySelectorAll(
        '.filter-button'
    );


const photographerFilterWrapper =
    document.getElementById(
        'photographer-filter-wrapper'
    );


const photographerFilterButtons =
    document.querySelectorAll(
        '.photographer-filter-button'
    );

const albumOrder = {
    photographer: 0,
    guests: 1,
    photobooth: 2
};

const photographerCategoryOrder = {
    forberedelser: 0,
    vigsel: 1,
    brudfolje: 2,
    portratt: 3,
    mingel: 4,
    'gruppbild-familj': 5,
    middag: 6,
    'golden-hour': 7
};


function sortMediaForGallery(items) {

    return [...items].sort(
        (a, b) => {

            const albumDifference =
                albumOrder[a.album] -
                albumOrder[b.album];


            if (albumDifference !== 0) {
                return albumDifference;
            }


            /*
             * Only photographer images need
             * category ordering.
             */
            if (
                a.album === 'photographer' &&
                b.album === 'photographer'
            ) {

                return (
                    photographerCategoryOrder[a.category] -
                    photographerCategoryOrder[b.category]
                );

            }


            /*
             * Keep the existing order within
             * the same category/album.
             */
            return 0;

        }
    );

}



/* ================================================================
   LOAD MEDIA.JSON
   ================================================================ */

async function loadMedia() {

    try {

        const response =
            await fetch('media.json');


        if (!response.ok) {

            throw new Error(
                `HTTP ${response.status}`
            );

        }


        const loadedMedia =
            await response.json();


        media =
            sortMediaForGallery(
                loadedMedia
            );


        console.log(
            `Loaded ${media.length} media items`
        );


        renderGallery();

    }

    catch (error) {

        console.error(
            'Failed to load media.json:',
            error
        );


        emptyGallery.hidden =
            false;


        emptyGallery.textContent =
            'Kunde inte ladda bilderna. Försök igen senare.';

    }

}



/* ================================================================
   FILTER MEDIA
   ================================================================ */

function updateVisibleMedia() {

    /*
     * ALL
     */

    if (
        activeFilter === 'all'
    ) {

        visibleMedia = [
            ...media
        ];

        return;

    }



    /*
     * PHOTOGRAPHER
     */

    if (
        activeFilter ===
        'photographer'
    ) {

        visibleMedia =
            media.filter(item => {

                if (
                    item.album !==
                    'photographer'
                ) {

                    return false;

                }


                if (
                    activePhotographerFilter ===
                    'all'
                ) {

                    return true;

                }


                return (
                    item.category ===
                    activePhotographerFilter
                );

            });


        return;

    }



    /*
     * GUESTS / PHOTOBOOTH
     */

    visibleMedia =
        media.filter(
            item =>
                item.album ===
                activeFilter
        );

}



/* ================================================================
   RENDER GALLERY
   ================================================================ */

function renderGallery() {

    updateVisibleMedia();


    photoGrid.innerHTML =
        '';


    renderedCount =
        0;


    if (
        visibleMedia.length === 0
    ) {

        emptyGallery.hidden =
            false;

        return;

    }


    emptyGallery.hidden =
        true;


    renderNextBatch();

}



function getMediaGroupKey(item) {

    if (item.album === 'photographer') {
        return `photographer-${item.category}`;
    }

    return item.album;
}


function renderNextBatch() {

    if (isRenderingBatch) {
        return;
    }

    if (
        renderedCount >=
        visibleMedia.length
    ) {
        return;
    }


    isRenderingBatch = true;


    /*
     * Determine which category/album this batch belongs to.
     *
     * A batch is NEVER allowed to contain media from
     * two different groups.
     */
    const firstItem =
        visibleMedia[renderedCount];

    const currentGroup =
        getMediaGroupKey(firstItem);


    let batchEnd =
        renderedCount;


    /*
     * Add up to ITEMS_PER_BATCH items,
     * but stop immediately if the next item belongs
     * to another category/album.
     */
    while (
        batchEnd < visibleMedia.length &&
        batchEnd < renderedCount + ITEMS_PER_BATCH &&
        getMediaGroupKey(
            visibleMedia[batchEnd]
        ) === currentGroup
    ) {

        batchEnd++;

    }


    const batch =
        document.createElement('div');

    batch.className =
        'photo-batch';


    for (
        let index = renderedCount;
        index < batchEnd;
        index++
    ) {

        const item =
            visibleMedia[index];


        const card =
            createMediaCard(
                item,
                index
            );


        batch.appendChild(
            card
        );

    }


    photoGrid.appendChild(
        batch
    );


    renderedCount =
        batchEnd;


    isRenderingBatch =
        false;

}



/* ================================================================
   CREATE MEDIA CARD
   ================================================================ */

function createMediaCard(
    item,
    index
) {

    const button =
        document.createElement(
            'button'
        );


    button.className =
        'photo-card';


    button.type =
        'button';



    /*
     * =============================================================
     * IMAGE
     * =============================================================
     */

    if (item.type === 'image') {

        button.setAttribute(
            'aria-label',
            `Öppna bild ${index + 1}`
        );


        if (
            item.width &&
            item.height
        ) {
            button.style.aspectRatio =
                `${item.width} / ${item.height}`;
        }


        const image =
            document.createElement('img');


        image.src =
            item.thumb || item.src;


        image.alt =
            item.alt || '';


        image.loading =
            'lazy';


        image.decoding =
            'async';


        image.width =
            item.width;


        image.height =
            item.height;


        button.appendChild(image);
    }



    /*
     * =============================================================
     * VIDEO
     * =============================================================
     */

    else if (item.type === 'video') {

        button.classList.add(
            'video-card'
        );


        button.setAttribute(
            'aria-label',
            `Spela video ${index + 1}`
        );


        if (
            item.width &&
            item.height
        ) {
            button.style.aspectRatio =
                `${item.width} / ${item.height}`;
        }


        const poster =
            document.createElement('img');


        poster.src =
            item.thumb || item.poster;


        poster.alt =
            'Videoförhandsvisning';


        poster.loading =
            'lazy';


        poster.decoding =
            'async';


        poster.width =
            item.width;


        poster.height =
            item.height;


        button.appendChild(
            poster
        );


        const overlay =
            document.createElement('span');


        overlay.className =
            'video-play-overlay';


        const playButton =
            document.createElement('span');


        playButton.className =
            'video-play-button';


        playButton.setAttribute(
            'aria-hidden',
            'true'
        );


        playButton.textContent =
            '▶';


        overlay.appendChild(
            playButton
        );


        button.appendChild(
            overlay
        );
    }



    button.addEventListener(
        'click',
        () => {

            openLightbox(
                index
            );

        }
    );


    return button;

}



/* ================================================================
   LOAD MORE WHILE SCROLLING
   ================================================================ */

let scrollTicking =
    false;


window.addEventListener(
    'scroll',

    () => {

        if (
            scrollTicking
        ) {

            return;

        }


        scrollTicking =
            true;


        window.requestAnimationFrame(
            () => {

                const distanceFromBottom =
                    document.documentElement.scrollHeight
                    -
                    (
                        window.scrollY +
                        window.innerHeight
                    );


                /*
                 * Start loading another batch before the visitor
                 * actually reaches the bottom.
                 */

                if (
                    distanceFromBottom <
                    2000
                ) {

                    renderNextBatch();

                }


                scrollTicking =
                    false;

            }
        );

    },

    {
        passive: true
    }
);



/* ================================================================
   MAIN FILTER BUTTONS
   ================================================================ */

filterButtons.forEach(
    button => {

        button.addEventListener(
            'click',
            () => {

                activeFilter =
                    button.dataset.filter;



                filterButtons.forEach(
                    otherButton => {

                        const isActive =
                            otherButton ===
                            button;


                        otherButton
                            .classList
                            .toggle(
                                'active',
                                isActive
                            );


                        otherButton
                            .setAttribute(
                                'aria-pressed',
                                String(
                                    isActive
                                )
                            );

                    }
                );



                /*
                 * Show photographer subcategories.
                 */

                if (
                    activeFilter ===
                    'photographer'
                ) {

                    photographerFilterWrapper
                        .hidden =
                        false;


                    /*
                     * Reset to Alla bilder every time
                     * Fotografen is selected.
                     */

                    activePhotographerFilter =
                        'all';


                    photographerFilterButtons
                        .forEach(
                            photographerButton => {

                                const isAll =
                                    photographerButton
                                        .dataset
                                        .photographerFilter ===
                                    'all';


                                photographerButton
                                    .classList
                                    .toggle(
                                        'active',
                                        isAll
                                    );


                                photographerButton
                                    .setAttribute(
                                        'aria-pressed',
                                        String(
                                            isAll
                                        )
                                    );

                            }
                        );

                }

                else {

                    photographerFilterWrapper
                        .hidden =
                        true;

                }


                renderGallery();

            }
        );

    }
);



/* ================================================================
   PHOTOGRAPHER SUBFILTERS
   ================================================================ */

photographerFilterButtons.forEach(
    button => {

        button.addEventListener(
            'click',
            () => {

                activePhotographerFilter =
                    button
                        .dataset
                        .photographerFilter;



                photographerFilterButtons
                    .forEach(
                        otherButton => {

                            const isActive =
                                otherButton ===
                                button;


                            otherButton
                                .classList
                                .toggle(
                                    'active',
                                    isActive
                                );


                            otherButton
                                .setAttribute(
                                    'aria-pressed',
                                    String(
                                        isActive
                                    )
                                );

                        }
                    );


                renderGallery();

            }
        );

    }
);



/* ================================================================
   LIGHTBOX DOM
   ================================================================ */

const lightbox =
    document.getElementById(
        'lightbox'
    );


const lightboxImage =
    document.getElementById(
        'lightbox-image'
    );


const lightboxVideo =
    document.getElementById(
        'lightbox-video'
    );


const lightboxClose =
    document.getElementById(
        'lightbox-close'
    );


const lightboxPrevious =
    document.getElementById(
        'lightbox-previous'
    );


const lightboxNext =
    document.getElementById(
        'lightbox-next'
    );


const lightboxCounter =
    document.getElementById(
        'lightbox-counter'
    );

const lightboxDownload =
    document.getElementById(
        'lightbox-download'
    );


let currentMediaIndex =
    0;



/* ================================================================
   OPEN LIGHTBOX
   ================================================================ */

function openLightbox(index) {

    if (
        visibleMedia.length === 0
    ) {

        return;

    }


    currentMediaIndex =
        index;


    updateLightboxMedia();


    lightbox
        .classList
        .add(
            'active'
        );


    lightbox
        .setAttribute(
            'aria-hidden',
            'false'
        );


    document.body
        .classList
        .add(
            'lightbox-open'
        );

}



/* ================================================================
   CLOSE LIGHTBOX
   ================================================================ */

function closeLightbox() {

    stopVideo();

    lightboxDownload.hidden =
        true;

    lightboxDownload.removeAttribute(
        'href'
    );
    lightboxImage.removeAttribute(
        'src'
    );


    lightbox
        .classList
        .remove(
            'active'
        );


    lightbox
        .setAttribute(
            'aria-hidden',
            'true'
        );


    document.body
        .classList
        .remove(
            'lightbox-open'
        );

}



/* ================================================================
   STOP VIDEO
   ================================================================ */

function stopVideo() {

    lightboxVideo.pause();


    lightboxVideo.removeAttribute(
        'src'
    );


    lightboxVideo.load();

}



/* ================================================================
   UPDATE LIGHTBOX
   ================================================================ */

function updateLightboxMedia() {

    stopVideo();


    const item =
        visibleMedia[
        currentMediaIndex
        ];



    if (item.type === 'image') {

        lightboxVideo.hidden =
            true;


        lightboxImage.hidden =
            false;


        lightboxImage.src =
            item.src;


        lightboxImage.alt =
            item.alt || '';

        if (item.original) {

            lightboxDownload.hidden =
                false;


            lightboxDownload.href =
                item.original;


            /*
             * This is also useful as a filename hint.
             *
             * GitHub's release asset response itself normally
             * handles the actual download.
             */
            lightboxDownload.setAttribute(
                'download',
                item.name || ''
            );

        }
        else {

            lightboxDownload.hidden =
                true;

        }
    }



    else if (item.type === 'video') {

        lightboxDownload.hidden =
            true;
        lightboxImage.hidden =
            true;


        lightboxImage.removeAttribute(
            'src'
        );


        lightboxVideo.hidden =
            false;


        lightboxVideo.poster =
            item.poster || item.thumb || '';


        lightboxVideo.src =
            item.src;


        lightboxVideo.load();
    }



    lightboxCounter.textContent =
        `${currentMediaIndex + 1} / ${visibleMedia.length}`;

}



/* ================================================================
   PREVIOUS
   ================================================================ */

function showPreviousMedia() {

    currentMediaIndex--;


    if (
        currentMediaIndex < 0
    ) {

        currentMediaIndex =
            visibleMedia.length - 1;

    }


    updateLightboxMedia();

}



/* ================================================================
   NEXT
   ================================================================ */

function showNextMedia() {

    currentMediaIndex++;


    if (
        currentMediaIndex >=
        visibleMedia.length
    ) {

        currentMediaIndex =
            0;

    }


    updateLightboxMedia();

}



/* ================================================================
   LIGHTBOX BUTTONS
   ================================================================ */

lightboxClose.addEventListener(
    'click',
    closeLightbox
);


lightboxPrevious.addEventListener(
    'click',
    showPreviousMedia
);


lightboxNext.addEventListener(
    'click',
    showNextMedia
);



/* ================================================================
   KEYBOARD CONTROLS
   ================================================================ */

document.addEventListener(
    'keydown',
    event => {

        if (
            !lightbox
                .classList
                .contains(
                    'active'
                )
        ) {

            return;

        }


        if (
            event.key ===
            'Escape'
        ) {

            closeLightbox();

        }


        if (
            event.key ===
            'ArrowLeft'
        ) {

            showPreviousMedia();

        }


        if (
            event.key ===
            'ArrowRight'
        ) {

            showNextMedia();

        }

    }
);



/* ================================================================
   MOBILE SWIPE
   ================================================================ */

let touchStartX =
    0;


let touchEndX =
    0;



lightbox.addEventListener(
    'touchstart',

    event => {

        /*
         * Don't interfere with native video controls.
         */

        if (
            event.target ===
            lightboxVideo
        ) {

            return;

        }


        touchStartX =
            event
                .changedTouches[0]
                .screenX;

    },

    {
        passive: true
    }
);



lightbox.addEventListener(
    'touchend',

    event => {

        if (
            event.target ===
            lightboxVideo
        ) {

            return;

        }


        touchEndX =
            event
                .changedTouches[0]
                .screenX;


        const distance =
            touchEndX -
            touchStartX;


        if (
            Math.abs(
                distance
            ) < 50
        ) {

            return;

        }


        if (
            distance > 0
        ) {

            showPreviousMedia();

        }

        else {

            showNextMedia();

        }

    },

    {
        passive: true
    }
);



/* ================================================================
   INITIAL LOAD
   ================================================================ */

loadMedia();