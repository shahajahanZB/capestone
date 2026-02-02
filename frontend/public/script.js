// Interactions: theme toggle, topic modal, and API ping (local fallback)
(() => {
  const pingBtn = document.getElementById('pingBtn');
  const pingResult = document.getElementById('pingResult');
  const themeToggle = document.getElementById('themeToggle');
  const exploreBtn = document.getElementById('exploreBtn');
  const modal = document.getElementById('modal');
  const modalTitle = document.getElementById('modalTitle');
  const modalBody = document.getElementById('modalBody');
  const modalClose = document.getElementById('modalClose');

  // Default to light theme; toggle will switch to dark
  if (!document.documentElement.getAttribute('data-theme')) {
    document.documentElement.setAttribute('data-theme', 'light');
  }

  // Determine API base (support multiple placeholders)
  const rawBase = (window.API_BASE_URL || '').trim() || (window.API_URL || '').trim();
  const apiBase = (rawBase && rawBase !== '%%API_BASE_URL%%' && rawBase !== '%API_URL%') ? rawBase.replace(/\/$/, '') : 'http://localhost:8000';

  function showPing(status){ pingResult.textContent = status }

  async function ping() {
    showPing('Pinging...');
    try {
      const res = await fetch(apiBase + '/health', { method: 'GET' });
      const txt = await res.text();
      showPing(`Status: ${res.status} ${txt || ''} (url: ${apiBase})`);
    } catch (err) {
      showPing(`Error: ${err.message} (tried ${apiBase})`);
    }
  }

  pingBtn.addEventListener('click', ping);

  themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    document.documentElement.setAttribute('data-theme', isDark ? 'light' : 'dark');
  });

  exploreBtn.addEventListener('click', () => {
    document.getElementById('topics').scrollIntoView({behavior:'smooth'});
  });

  // Card details handling
  document.querySelectorAll('.card').forEach(card => {
    card.querySelector('.card-btn').addEventListener('click', () => {
      const topic = card.getAttribute('data-topic');
      modalTitle.textContent = card.querySelector('h4').textContent;
      modalBody.innerHTML = getTopicDetail(topic);
      modal.setAttribute('aria-hidden', 'false');
    });
  });

  modalClose.addEventListener('click', () => modal.setAttribute('aria-hidden', 'true'));
  modal.addEventListener('click', (e) => { if (e.target === modal) modal.setAttribute('aria-hidden', 'true') });

  function getTopicDetail(topic){
    const docs = {
      nlp: `NLP uses large language models (LLMs), RAG, and fine-tuning to power search, summarization, and conversation. Practical considerations include prompt engineering, context length, and retrieval systems.`,
      cv: `Computer Vision includes classification, object detection, segmentation, and image generation. Common approaches are convolutional models, transformers, and diffusion-based generators.`,
      gen: `Generative models produce text, code, images and audio. They enable creative tools, but require guards for safety, hallucinations, and misuse.`,
      mlops: `MLOps covers reproducible training, CI/CD for models, monitoring, drift detection, and automated rollouts. Infrastructure and observability are key.`,
      ethics: `Ethics & Safety focuses on fairness, transparency, privacy, and robust evaluation. Societal impacts and stakeholder governance are essential.`,
      rl: `Reinforcement Learning optimizes decision-making through interaction and feedback; it is used in robotics, games, and control systems.`
    };
    return `<p>${docs[topic] || 'More info coming soon.'}</p>`;
  }

  // Auto-check backend health once on load
  (function(){ ping(); })();
})();