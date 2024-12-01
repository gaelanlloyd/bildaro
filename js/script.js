function modal_open( e ) {

    const modal = document.getElementById("modal");

    // Update the modal based on the ID of the clicked image
    modal_update( e.id );

    // Load the key listener
    load_keylistener();

    // Show the modal
    modal.style.display = '';

}

function modal_update(id) {

    // console.log( 'modal_update: ' + id );

    const actualImage = document.getElementById(id);

    if ( !actualImage ) {
        console.log( 'Error: Unable to find image with id' + id );
    }

    const modal_image = document.getElementById("modal-image");
    const modal_download_link_full = document.getElementById("modal-download-link-full");
    const modal_download_link_medium = document.getElementById("modal-download-link-medium");

    const modal_link_next = document.getElementById("modal-next");
    const modal_link_prev = document.getElementById("modal-prev");

    const image_medium = actualImage.getAttribute('data-medium');
    const image_full = actualImage.getAttribute('data-full');

    // Set download URLs

    modal_download_link_full.setAttribute( 'href', image_full );
    modal_download_link_medium.setAttribute( 'href', image_medium );

    // Set next/prev links

    const item_prev = actualImage.getAttribute('data-prev');
    const item_next = actualImage.getAttribute('data-next');

    // DEBUG
    // console.log( 'item_prev = ' + item_prev );
    // console.log( 'item_next = ' + item_next );

    if ( item_prev ) {
        modal_link_prev.onclick = () => modal_update(item_prev);
        modal_link_prev.disabled = false;
    } else {
        modal_link_prev.onclick = null;
        modal_link_prev.disabled = true;
    }

    if ( item_next ) {
        modal_link_next.onclick = () => modal_update(item_next);
        modal_link_next.disabled = false;
    } else {
        modal_link_next.onclick = null;
        modal_link_next.disabled = true;
    }

    // Load the medium sized image
    // If the image element already exists, update it. Otherwise, create it.

    let modal_image_actual = document.getElementById('modal-image-actual');

    if ( modal_image_actual ) {

        modal_image_actual.src = image_medium;

    } else {

        let img = document.createElement('img');
        img.id = 'modal-image-actual';
        img.src = image_medium;
        modal_image.appendChild( img );

    }

}

function modal_close() {

    stop_keylistener();

    const modal = document.getElementById("modal");
    const modal_image = document.getElementById("modal-image");

    modal.style.display = 'none';
    modal_image.innerHTML = '';

}

function load_keylistener() {
    // console.log( 'Load keylistener' );
    document.addEventListener( 'keydown', modal_keyhandler );
}

function stop_keylistener() {
    // console.log( 'Stop keylistener' );
    document.removeEventListener( 'keydown', modal_keyhandler );
}

function modal_keyhandler(event) {

    if ( event.key == "ArrowLeft" ) {
        document.getElementById("modal-prev").click();
    }

    if ( event.key == "ArrowRight" ) {
        document.getElementById("modal-next").click();
    }

}
