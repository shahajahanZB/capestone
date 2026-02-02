AI Today — Frontend

Local preview
1. Serve the `frontend/public` directory:
   - Python: `cd frontend/public && python -m http.server 8080`
   - Node: `cd frontend/public && npx http-server -p 8080`
2. Open: http://localhost:8080
3. Use the **Ping Backend** button to test connectivity. The site prefers a build-injected API URL (CI), otherwise it falls back to `http://localhost:8000`.

What changed
- New polished AI-focused site with sections on NLP, Computer Vision, Generative Models, MLOps, Ethics and Reinforcement Learning.
- Interactive cards with details, theme toggle, and basic backend ping for quick checks.

Deployment
- Pushing to `main` will trigger the existing frontend deploy workflow. The CI replaces `%%API_BASE_URL%%` or `%API_URL%` during deploy to point the site at your live backend.