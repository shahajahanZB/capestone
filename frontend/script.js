document.addEventListener('DOMContentLoaded', function() {
  const btn = document.querySelector('.btn');
  btn.addEventListener('click', function(e) {
    e.preventDefault();
    document.querySelector('#menu').scrollIntoView({behavior:'smooth'});
  });
});