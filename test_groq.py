import os
import httpx
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GROQ_API_KEY")

print("KEY FOUND:", bool(API_KEY))

if not API_KEY:
    print("❌ GROQ_API_KEY missing in .env")
    exit()


url = "https://api.groq.com/openai/v1/chat/completions"

payload = {
    "model": "openai/gpt-oss-20b",
    "messages": [
        {"role": "user", "content": "Say hello in one sentence"}
    ]
}

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}


print("Calling Groq API...\n")

r = httpx.post(url, json=payload, headers=headers, timeout=60)

print("Status Code:", r.status_code)
print("\nFull Response:\n")
print(r.json())
