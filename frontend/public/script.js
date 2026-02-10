let cartCount = 0;
const cartDisplay = document.getElementById('cart-count');

document.querySelectorAll('.add-to-cart').forEach(button => {
  button.addEventListener('click', () => {
    cartCount++;
    cartDisplay.textContent = `Cart: ${cartCount}`;
  });
});