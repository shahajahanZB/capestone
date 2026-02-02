(() => {
  const themeToggle = document.getElementById('themeToggle');
  const exploreBtn = document.getElementById('exploreBtn');
  const modal = document.getElementById('modal');
  const modalTitle = document.getElementById('modalTitle');
  const modalBody = document.getElementById('modalBody');
  const modalClose = document.getElementById('modalClose');

  // Theme
  document.documentElement.setAttribute('data-theme', 'light');

  themeToggle.addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme');
    document.documentElement.setAttribute(
      'data-theme',
      current === 'dark' ? 'light' : 'dark'
    );
  });

  // Scroll
  exploreBtn.addEventListener('click', () => {
    document.getElementById('topics').scrollIntoView({ behavior: 'smooth' });
  });

  // Modal content
  const topics = {
    nlp: 'NLP enables machines to understand and generate human language using large language models.',
    cv: 'Computer Vision allows machines to interpret images and video for recognition and generation.',
    gen: 'Generative models create new text, images, audio, and code.',
    mlops: 'MLOps ensures ML systems are reliable, monitored, and reproducible.',
    ethics: 'Ethics & Safety focuses on fairness, accountability, and responsible AI use.',
    rl: 'Reinforcement Learning trains agents through rewards and interaction.'
  };

  document.querySelectorAll('.card').forEach(card => {
    card.querySelector('.card-btn').addEventListener('click', () => {
      const key = card.dataset.topic;
      modalTitle.textContent = card.querySelector('h4').textContent;
      modalBody.innerHTML = `<p>${topics[key]}</p>`;
      modal.setAttribute('aria-hidden', 'false');
    });
  });

  modalClose.addEventListener('click', () =>
    modal.setAttribute('aria-hidden', 'true')
  );

  modal.addEventListener('click', e => {
    if (e.target === modal) modal.setAttribute('aria-hidden', 'true');
  });
})();
