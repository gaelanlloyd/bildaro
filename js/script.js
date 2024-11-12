function modal_open( e ) {

    const modal = document.getElementById("modal");
    const modal_image = document.getElementById("modal-image");
    const modal_download_link_full = document.getElementById("modal-download-link-full");
    const modal_download_link_medium = document.getElementById("modal-download-link-medium");

    const image_medium = e.getAttribute('data-medium');
    const image_full = e.getAttribute('data-full');

    // Set download URLs

    modal_download_link_full.setAttribute( 'href', image_full );
    modal_download_link_medium.setAttribute( 'href', image_medium );

    // Load the medium sized image

    let img = document.createElement('img');
    img.src = image_medium;

    modal_image.appendChild( img );

    // Show the modal

    modal.style.display = '';

}

function modal_close() {

    const modal = document.getElementById("modal");
    const modal_image = document.getElementById("modal-image");

    modal.style.display = 'none';
    modal_image.innerHTML = '';

}

