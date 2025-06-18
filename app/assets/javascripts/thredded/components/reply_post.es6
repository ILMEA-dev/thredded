//= require thredded/core/thredded
//= require thredded/core/on_page_load

(() => {
  const Thredded = window.Thredded;

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll('[data-thredded-reply-post]'), (el) => {
      el.addEventListener('click', onClick);
    });
  });

  function onClick(evt) {
    // Handle only left clicks with no modifier keys
    if (evt.button !== 0 || evt.ctrlKey || evt.altKey || evt.metaKey || evt.shiftKey) return;
    evt.preventDefault();
    const target = document.getElementById('post_content');
    target.scrollIntoView();
    target.focus();
  }
})(); 