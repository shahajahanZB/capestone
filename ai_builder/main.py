import os
import json
from pathlib import Path

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from git import Repo

#test word

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent.parent

# ✅ correct folder
FRONTEND_DIR = BASE_DIR / "frontend" / "public"
UI_DIR = BASE_DIR / "ui"

GROQ_API_KEY = os.getenv("GROQ_API_KEY")


# =====================================================
# HELPERS
# =====================================================

def clean(text: str) -> str:
    """
    SAFE newline fix only.
    DO NOT use unicode_escape (breaks Café, emojis, etc)
    """
    return text.replace("\\n", "\n").replace("\\t", "\t")


def safe_json_extract(raw: str):
    """
    Safely extract JSON from LLM output.
    Never crashes.
    """
    if not raw:
        return None

    raw = raw.replace("```json", "").replace("```", "").strip()

    start = raw.find("{")
    end = raw.rfind("}") + 1

    if start == -1 or end <= start:
        print("❌ Could not find JSON in model output:\n", raw)
        return None

    try:
        return json.loads(raw[start:end])
    except Exception:
        print("❌ JSON parse failed:\n", raw)
        return None


# =====================================================
# API ROUTES
# =====================================================

@app.post("/generate")
async def generate(payload: dict):
    prompt = payload.get("prompt")

    if not prompt:
        return {"error": "Prompt missing"}

    system = """
You are a frontend static website generator.

RULES:
- CSS only in style.css
- JS only in script.js
- Do NOT inline CSS or JS
- Use ONLY https://source.unsplash.com images
- NEVER use local images
- Return ONLY JSON

Format:

{
  "html": "...",
  "css": "...",
  "js": "..."
}
"""

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "openai/gpt-oss-20b",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.3,
                },
            )

        data = r.json()

        if "choices" not in data:
            print("❌ GROQ ERROR:", data)
            return {"error": data}

        content = data["choices"][0]["message"]["content"]

        if not content:
            print("❌ Empty model response")
            return {"error": "Empty response from model"}

        files = safe_json_extract(content)

        if not files:
            return {"error": "Model returned invalid JSON"}

        FRONTEND_DIR.mkdir(parents=True, exist_ok=True)

        (FRONTEND_DIR / "index.html").write_text(clean(files["html"]), encoding="utf-8")
        (FRONTEND_DIR / "style.css").write_text(clean(files["css"]), encoding="utf-8")
        (FRONTEND_DIR / "script.js").write_text(clean(files["js"]), encoding="utf-8")

        print("✅ Files written to:", FRONTEND_DIR)

        return {"success": True}

    except Exception as e:
        print("GENERATION ERROR:", e)
        return {"error": str(e)}


@app.post("/push")
def push():
    repo = Repo(BASE_DIR)

    repo.index.add([
        "frontend/public/index.html",
        "frontend/public/style.css",
        "frontend/public/script.js",
    ])

    repo.index.commit("AI generated frontend update")
    repo.remote(name="origin").push()

    return {"success": True}


# =====================================================
# STATIC FILES
# =====================================================

app.mount("/site", StaticFiles(directory=FRONTEND_DIR), name="site")
app.mount("/", StaticFiles(directory=UI_DIR, html=True), name="ui")
