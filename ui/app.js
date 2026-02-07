async function generate() {
  const prompt = document.getElementById("prompt").value;

  await fetch("http://localhost:8000/generate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt })
  });

  reload();
}

async function push() {
  await fetch("http://localhost:8000/push", {
    method: "POST"
  });

  alert("Pushed!");
}

function reload() {
  const f = document.getElementById("frame");
  f.src = f.src.split("?")[0] + "?t=" + Date.now();
}
