#!/usr/bin/env bash

#set -euo pipefail

# community.sh
# Bootstrap a minimal Flask-based Quora-style starter with authentication.
# The app stores posts in posts.json and users in users.json.

print_help() {
  cat <<'EOF'
Usage: sh community.sh init [dir]

Creates a minimal Flask app for a Quora-like Question & Answer platform.

Commands:
  init [dir]   Create the project in the current directory or [dir].
  help         Show this help text.

After initialization:
  cd [dir]
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  python app.py
EOF
}

init_project() {
  local target_dir="${1:-.}"
  mkdir -p "$target_dir"
  cd "$target_dir"

  cat > requirements.txt <<'EOF'
Flask>=2.3.0
Werkzeug>=2.3.0
EOF

  cat > app.py <<'PY'
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from flask import Flask, abort, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)
# In production, replace this with a secure random key!
app.secret_key = "super-secret-development-key"

DATA_FILE = Path(__file__).resolve().parent / "posts.json"
USERS_FILE = Path(__file__).resolve().parent / "users.json"


def load_posts() -> dict[str, Any]:
    if not DATA_FILE.exists():
        return {}
    with DATA_FILE.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def save_posts(posts: dict[str, Any]) -> None:
    with DATA_FILE.open("w", encoding="utf-8") as handle:
        json.dump(posts, handle, indent=2, ensure_ascii=False)


def load_users() -> dict[str, Any]:
    if not USERS_FILE.exists():
        return {}
    with USERS_FILE.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def save_users(users: dict[str, Any]) -> None:
    with USERS_FILE.open("w", encoding="utf-8") as handle:
        json.dump(users, handle, indent=2, ensure_ascii=False)


def make_slug(value: str) -> str:
    slug = value.lower().strip()
    slug = slug.replace(" ", "-")
    allowed = "abcdefghijklmnopqrstuvwxyz0123456789-_"
    return "".join(ch for ch in slug if ch in allowed)


@app.route("/", methods=("GET", "POST"))
def index():
    posts = load_posts()

    if request.method == "POST":
        if "username" not in session:
            return redirect(url_for("login"))

        title = request.form.get("title", "").strip()
        content = request.form.get("content", "").strip()
        slug = request.form.get("slug", "").strip() or make_slug(title)

        if not title or not content:
            return render_template("index.html", posts=posts, error="Title and content are required.")

        slug = make_slug(slug)
        if not slug:
            return render_template("index.html", posts=posts, error="Enter a valid slug or title.")
        if slug in posts:
            return render_template("index.html", posts=posts, error="That slug is already in use.")

        posts[slug] = {
            "title": title, 
            "content": content, 
            "author": session["username"]
        }
        save_posts(posts)
        return redirect(f"/{slug}")

    return render_template("index.html", posts=posts)


@app.route("/signup", methods=("GET", "POST"))
def signup():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        if not username or not password:
            return render_template("signup.html", error="Username and password are required.")

        users = load_users()
        if username in users:
            return render_template("signup.html", error="That username is already taken.")

        users[username] = {"password_hash": generate_password_hash(password)}
        save_users(users)

        session["username"] = username
        return redirect(url_for("index"))

    return render_template("signup.html")


@app.route("/login", methods=("GET", "POST"))
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        users = load_users()
        user = users.get(username)

        if user and check_password_hash(user["password_hash"], password):
            session["username"] = username
            return redirect(url_for("index"))

        return render_template("login.html", error="Invalid username or password.")

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.pop("username", None)
    return redirect(url_for("index"))


@app.route("/<slug>")
def show_post(slug: str):
    posts = load_posts()
    post = posts.get(slug)
    if post is None:
        abort(404)
    return render_template("post.html", post=post, slug=slug)


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
PY

  mkdir -p templates

  cat > templates/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>AYT04 - Q&A Community</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-dark: #09090b;
      --bg-gradient: linear-gradient(135deg, #09090b 0%, #18181b 100%);
      --card-bg: rgba(24, 24, 27, 0.7);
      --card-border: rgba(255, 255, 255, 0.08);
      --text-main: #f4f4f5;
      --text-muted: #a1a1aa;
      --accent: #3b82f6;
      --accent-hover: #60a5fa;
      --accent-glow: rgba(59, 130, 246, 0.4);
      --danger: #ef4444;
      --radius: 16px;
      --shadow: 0 10px 40px -10px rgba(0,0,0,0.5);
      --font: 'Inter', system-ui, -apple-system, sans-serif;
      --input-bg: rgba(0, 0, 0, 0.2);
      --list-hover-bg: rgba(255, 255, 255, 0.05);
      --list-hover-border: rgba(255, 255, 255, 0.15);
      --list-bg: rgba(255, 255, 255, 0.02);
    }
    
    [data-theme="light"] {
      --bg-dark: #f8fafc;
      --bg-gradient: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
      --card-bg: rgba(255, 255, 255, 0.7);
      --card-border: rgba(0, 0, 0, 0.1);
      --text-main: #0f172a;
      --text-muted: #64748b;
      --accent: #2563eb;
      --accent-hover: #1d4ed8;
      --accent-glow: rgba(37, 99, 235, 0.3);
      --shadow: 0 10px 40px -10px rgba(0,0,0,0.1);
      --input-bg: rgba(255, 255, 255, 0.8);
      --list-hover-bg: rgba(0, 0, 0, 0.03);
      --list-hover-border: rgba(0, 0, 0, 0.15);
      --list-bg: rgba(255, 255, 255, 0.5);
    }
    
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: var(--font);
      background: var(--bg-dark);
      background-image: var(--bg-gradient);
      color: var(--text-main);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px;
      line-height: 1.6;
      -webkit-font-smoothing: antialiased;
      transition: background 0.3s ease, color 0.3s ease;
    }

    .navbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 24px;
      margin-bottom: 24px;
      width: 100%;
      max-width: 1000px;
      border-radius: 99px;
    }
    .nav-brand { font-weight: 700; font-size: 1.25rem; color: var(--text-main); text-decoration: none; }
    .nav-links { display: flex; align-items: center; gap: 16px; }
    
    .nav-btn {
      padding: 8px 16px;
      border-radius: 99px;
      text-decoration: none;
      font-weight: 500;
      color: var(--text-main);
      background: var(--input-bg);
      transition: all 0.2s ease;
      font-size: 0.9rem;
    }
    .nav-btn:hover { background: var(--list-hover-bg); }
    .nav-btn.primary { background: var(--accent); color: white; border: none; }
    .nav-btn.primary:hover { background: var(--accent-hover); box-shadow: 0 4px 12px var(--accent-glow); }
    
    .layout-wrapper {
      display: flex;
      gap: 32px;
      max-width: 1000px;
      width: 100%;
      align-items: flex-start;
      position: relative;
    }

    .main-content { flex: 1; display: flex; flex-direction: column; gap: 24px; }
    
    .glass-card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: var(--radius);
      padding: 32px;
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      box-shadow: var(--shadow);
      transition: background 0.3s ease, border-color 0.3s ease;
    }
    
    h1 {
      font-size: 2rem;
      font-weight: 700;
      letter-spacing: -0.02em;
      margin-bottom: 8px;
      background: linear-gradient(to right, var(--text-main), var(--text-muted));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    
    h2, h3 { font-weight: 600; color: var(--text-main); transition: color 0.3s ease; }
    h2 { font-size: 1.25rem; margin-bottom: 16px; }
    
    .error-msg {
      background: rgba(239, 68, 68, 0.1);
      color: var(--danger);
      padding: 12px 16px;
      border-radius: 8px;
      border: 1px solid rgba(239, 68, 68, 0.2);
      font-size: 0.9rem;
      font-weight: 500;
      margin-bottom: 24px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    
    form { display: flex; flex-direction: column; gap: 16px; }
    
    label { font-size: 0.875rem; font-weight: 500; color: var(--text-muted); display: flex; flex-direction: column; gap: 8px; }
    
    input, textarea {
      width: 100%;
      background: var(--input-bg);
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 12px 16px;
      color: var(--text-main);
      font-family: inherit;
      font-size: 0.95rem;
      transition: all 0.2s ease;
    }
    
    input:focus, textarea:focus {
      outline: none;
      border-color: var(--accent);
      box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
    }
    
    textarea { min-height: 120px; resize: vertical; }
    
    button[type="submit"] {
      background: var(--accent);
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 0.95rem;
      cursor: pointer;
      transition: all 0.2s ease;
      align-self: flex-start;
      box-shadow: 0 4px 12px var(--accent-glow);
    }
    
    button[type="submit"]:hover { background: var(--accent-hover); transform: translateY(-1px); box-shadow: 0 6px 16px var(--accent-glow); }
    button[type="submit"]:active { transform: translateY(1px); }
    
    .post-list ul { list-style: none; display: flex; flex-direction: column; gap: 12px; }
    
    .post-list li a {
      display: block;
      padding: 16px 20px;
      background: var(--list-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      color: var(--text-main);
      text-decoration: none;
      font-weight: 500;
      transition: all 0.2s ease;
    }
    
    .post-list li a:hover {
      background: var(--list-hover-bg);
      border-color: var(--list-hover-border);
      transform: translateX(4px);
    }
    
    .sidebar { width: 320px; flex-shrink: 0; }
    .sidebar .glass-card { padding: 24px; }
    .sidebar h2 { margin-bottom: 20px; font-size: 1.1rem; }
    
    .rule-group { margin-bottom: 20px; }
    .rule-group:last-child { margin-bottom: 0; }
    .rule-group h3 { font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); margin-bottom: 10px; }
    .rule-group ul { list-style: none; display: flex; flex-direction: column; gap: 10px; }
    .rule-group li { font-size: 0.875rem; color: var(--text-muted); position: relative; padding-left: 16px; }
    .rule-group li::before { content: "•"; color: var(--accent); position: absolute; left: 0; font-weight: bold; }
    .rule-group li strong { color: var(--text-main); }
    
    .sidebar-footer { margin-top: 24px; padding-top: 16px; border-top: 1px solid var(--card-border); font-size: 0.8rem; color: var(--text-muted); text-align: center; }

    .theme-toggle {
      background: transparent;
      border: none;
      color: var(--text-main);
      width: 36px;
      height: 36px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s ease;
      position: relative;
    }
    .theme-toggle:hover { background: var(--list-hover-bg); }
    .sun-icon, .moon-icon { width: 18px; height: 18px; position: absolute; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    [data-theme="light"] .sun-icon { opacity: 0; transform: rotate(-90deg) scale(0.5); }
    [data-theme="light"] .moon-icon { opacity: 1; transform: rotate(0) scale(1); }
    [data-theme="dark"] .sun-icon, :root:not([data-theme="light"]) .sun-icon { opacity: 1; transform: rotate(0) scale(1); }
    [data-theme="dark"] .moon-icon, :root:not([data-theme="light"]) .moon-icon { opacity: 0; transform: rotate(90deg) scale(0.5); }
    
    @media (max-width: 768px) {
      .layout-wrapper { flex-direction: column; }
      .sidebar { width: 100%; }
      .nav-links span { display: none; }
    }
  </style>
  <script>
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) { document.documentElement.setAttribute('data-theme', savedTheme); } 
    else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) { document.documentElement.setAttribute('data-theme', 'light'); }
  </script>
</head>
<body>
  
  <nav class="navbar glass-card">
    <a href="/" class="nav-brand">AYT04 Q&amp;A</a>
    <div class="nav-links">
      <button id="theme-toggle" class="theme-toggle" aria-label="Toggle theme">
        <svg class="sun-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
        <svg class="moon-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
      </button>
      
      {% if session.get('username') %}
        <span style="font-weight:500; font-size:0.9rem; color:var(--text-muted)">@{{ session.username }}</span>
        <a href="/logout" class="nav-btn">Logout</a>
      {% else %}
        <a href="/login" class="nav-btn">Login</a>
        <a href="/signup" class="nav-btn primary">Sign Up</a>
      {% endif %}
    </div>
  </nav>

  <div class="layout-wrapper">
    <main class="main-content">
      <section class="glass-card">
        <h1>Share your thoughts.</h1>
        <p style="color: var(--text-muted); margin-bottom: 24px; font-size: 0.95rem;">Start a new discussion with the community.</p>
        
        {% if error %}
        <div class="error-msg">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
          {{ error }}
        </div>
        {% endif %}
        
        {% if session.get('username') %}
        <form method="post" autocomplete="off">
          <label>Title <input name="title" required placeholder="What's on your mind?" /></label>
          <label>Optional slug <input name="slug" placeholder="e.g., custom-url-slug" /></label>
          <label>Content <textarea name="content" required placeholder="Provide some details..."></textarea></label>
          <button type="submit">Publish Post</button>
        </form>
        {% else %}
        <div style="padding: 32px 24px; text-align: center; background: var(--input-bg); border-radius: var(--radius); border: 1px solid var(--card-border);">
          <h3 style="margin-bottom: 8px;">Join the Conversation</h3>
          <p style="margin-bottom: 20px; color: var(--text-muted); font-size: 0.95rem;">You must be logged in to post.</p>
          <a href="/login" class="nav-btn primary" style="display: inline-block;">Login to Post</a>
        </div>
        {% endif %}
      </section>

      <section class="glass-card post-list">
        <h2>Recent Discussions</h2>
        <ul>
          {% for slug, post in posts.items() %}
          <li><a href="/{{ slug }}">
            <div style="font-weight: 600; margin-bottom: 4px;">{{ post.title }}</div>
            <div style="font-size: 0.8rem; color: var(--text-muted);">Posted by @{{ post.get('author', 'Anonymous') }}</div>
          </a></li>
          {% else %}
          <li style="color: var(--text-muted); font-size: 0.95rem; text-align: center; padding: 20px;">No posts yet. Be the first to start a discussion!</li>
          {% endfor %}
        </ul>
      </section>
    </main>

    <aside class="sidebar">
      <div class="glass-card">
        <h2>Community Guidelines</h2>
        <div class="rule-group">
          <h3>Be Respectful</h3>
          <ul>
            <li><strong>No harassment:</strong> Personal attacks and threats are strictly forbidden.</li>
            <li><strong>Keep it civil:</strong> Disagree respectfully.</li>
          </ul>
        </div>
        <div class="rule-group">
          <h3>Content</h3>
          <ul>
            <li><strong>No spam:</strong> Self-promotion and referral links are not allowed.</li>
            <li><strong>Stay on-topic:</strong> Keep discussions relevant.</li>
          </ul>
        </div>
        <div class="sidebar-footer">
          By participating you agree to follow these rules. Repeated violations may result in moderation action.
        </div>
      </div>
    </aside>
  </div>

  <script>
    const toggleBtn = document.getElementById('theme-toggle');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
      });
    }
  </script>
</body>
</html>
HTML

  cat > templates/login.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Login - AYT04</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-dark: #09090b; --bg-gradient: linear-gradient(135deg, #09090b 0%, #18181b 100%);
      --card-bg: rgba(24, 24, 27, 0.7); --card-border: rgba(255, 255, 255, 0.08);
      --text-main: #f4f4f5; --text-muted: #a1a1aa;
      --accent: #3b82f6; --accent-hover: #60a5fa; --accent-glow: rgba(59, 130, 246, 0.4);
      --danger: #ef4444; --radius: 16px; --font: 'Inter', system-ui, -apple-system, sans-serif;
      --input-bg: rgba(0, 0, 0, 0.2); --shadow: 0 10px 40px -10px rgba(0,0,0,0.5);
    }
    [data-theme="light"] {
      --bg-dark: #f8fafc; --bg-gradient: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
      --card-bg: rgba(255, 255, 255, 0.7); --card-border: rgba(0, 0, 0, 0.1);
      --text-main: #0f172a; --text-muted: #64748b;
      --accent: #2563eb; --accent-hover: #1d4ed8; --accent-glow: rgba(37, 99, 235, 0.3);
      --input-bg: rgba(255, 255, 255, 0.8); --shadow: 0 10px 40px -10px rgba(0,0,0,0.1);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font); background: var(--bg-dark); background-image: var(--bg-gradient); color: var(--text-main); min-height: 100vh; display: flex; flex-direction: column; align-items: center; padding: 60px 20px; -webkit-font-smoothing: antialiased; }
    
    .glass-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: var(--radius); padding: 40px; backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); box-shadow: var(--shadow); width: 100%; max-width: 400px; }
    h1 { font-size: 1.8rem; font-weight: 700; margin-bottom: 24px; text-align: center; }
    
    .error-msg { background: rgba(239, 68, 68, 0.1); color: var(--danger); padding: 12px 16px; border-radius: 8px; border: 1px solid rgba(239, 68, 68, 0.2); font-size: 0.9rem; margin-bottom: 24px; }
    form { display: flex; flex-direction: column; gap: 16px; }
    label { font-size: 0.875rem; font-weight: 500; color: var(--text-muted); display: flex; flex-direction: column; gap: 8px; }
    input { width: 100%; background: var(--input-bg); border: 1px solid var(--card-border); border-radius: 10px; padding: 12px 16px; color: var(--text-main); font-family: inherit; font-size: 0.95rem; transition: all 0.2s ease; }
    input:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15); }
    button[type="submit"] { background: var(--accent); color: white; border: none; padding: 12px 24px; border-radius: 10px; font-weight: 600; font-size: 0.95rem; cursor: pointer; transition: all 0.2s ease; width: 100%; margin-top: 8px; }
    button[type="submit"]:hover { background: var(--accent-hover); transform: translateY(-1px); box-shadow: 0 4px 12px var(--accent-glow); }
    .back-link { margin-top: 24px; text-align: center; display: block; color: var(--text-muted); text-decoration: none; font-size: 0.9rem; }
    .back-link:hover { color: var(--text-main); }
  </style>
  <script>
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) { document.documentElement.setAttribute('data-theme', savedTheme); }
    else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) { document.documentElement.setAttribute('data-theme', 'light'); }
  </script>
</head>
<body>
  <div class="glass-card">
    <h1>Login</h1>
    {% if error %} <div class="error-msg">{{ error }}</div> {% endif %}
    <form method="post" autocomplete="off">
      <label>Username <input name="username" required autofocus /></label>
      <label>Password <input type="password" name="password" required /></label>
      <button type="submit">Log In</button>
    </form>
    <p style="margin-top: 24px; text-align: center; color: var(--text-muted); font-size: 0.9rem;">
      Don't have an account? <a href="/signup" style="color: var(--accent); text-decoration: none; font-weight: 500;">Sign up</a>
    </p>
  </div>
  <a href="/" class="back-link">← Back to Home</a>
</body>
</html>
HTML

  cat > templates/signup.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sign Up - AYT04</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    /* Using same styles as login for brevity */
    :root { --bg-dark: #09090b; --bg-gradient: linear-gradient(135deg, #09090b 0%, #18181b 100%); --card-bg: rgba(24, 24, 27, 0.7); --card-border: rgba(255, 255, 255, 0.08); --text-main: #f4f4f5; --text-muted: #a1a1aa; --accent: #3b82f6; --accent-hover: #60a5fa; --accent-glow: rgba(59, 130, 246, 0.4); --danger: #ef4444; --radius: 16px; --font: 'Inter', system-ui, -apple-system, sans-serif; --input-bg: rgba(0, 0, 0, 0.2); --shadow: 0 10px 40px -10px rgba(0,0,0,0.5); }
    [data-theme="light"] { --bg-dark: #f8fafc; --bg-gradient: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%); --card-bg: rgba(255, 255, 255, 0.7); --card-border: rgba(0, 0, 0, 0.1); --text-main: #0f172a; --text-muted: #64748b; --accent: #2563eb; --accent-hover: #1d4ed8; --accent-glow: rgba(37, 99, 235, 0.3); --input-bg: rgba(255, 255, 255, 0.8); --shadow: 0 10px 40px -10px rgba(0,0,0,0.1); }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font); background: var(--bg-dark); background-image: var(--bg-gradient); color: var(--text-main); min-height: 100vh; display: flex; flex-direction: column; align-items: center; padding: 60px 20px; -webkit-font-smoothing: antialiased; }
    .glass-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: var(--radius); padding: 40px; backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); box-shadow: var(--shadow); width: 100%; max-width: 400px; }
    h1 { font-size: 1.8rem; font-weight: 700; margin-bottom: 24px; text-align: center; }
    .error-msg { background: rgba(239, 68, 68, 0.1); color: var(--danger); padding: 12px 16px; border-radius: 8px; border: 1px solid rgba(239, 68, 68, 0.2); font-size: 0.9rem; margin-bottom: 24px; }
    form { display: flex; flex-direction: column; gap: 16px; }
    label { font-size: 0.875rem; font-weight: 500; color: var(--text-muted); display: flex; flex-direction: column; gap: 8px; }
    input { width: 100%; background: var(--input-bg); border: 1px solid var(--card-border); border-radius: 10px; padding: 12px 16px; color: var(--text-main); font-family: inherit; font-size: 0.95rem; transition: all 0.2s ease; }
    input:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15); }
    button[type="submit"] { background: var(--accent); color: white; border: none; padding: 12px 24px; border-radius: 10px; font-weight: 600; font-size: 0.95rem; cursor: pointer; transition: all 0.2s ease; width: 100%; margin-top: 8px; }
    button[type="submit"]:hover { background: var(--accent-hover); transform: translateY(-1px); box-shadow: 0 4px 12px var(--accent-glow); }
    .back-link { margin-top: 24px; text-align: center; display: block; color: var(--text-muted); text-decoration: none; font-size: 0.9rem; }
    .back-link:hover { color: var(--text-main); }
  </style>
  <script>
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) { document.documentElement.setAttribute('data-theme', savedTheme); }
    else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) { document.documentElement.setAttribute('data-theme', 'light'); }
  </script>
</head>
<body>
  <div class="glass-card">
    <h1>Create an Account</h1>
    {% if error %} <div class="error-msg">{{ error }}</div> {% endif %}
    <form method="post" autocomplete="off">
      <label>Username <input name="username" required autofocus /></label>
      <label>Password <input type="password" name="password" required /></label>
      <button type="submit">Sign Up</button>
    </form>
    <p style="margin-top: 24px; text-align: center; color: var(--text-muted); font-size: 0.9rem;">
      Already have an account? <a href="/login" style="color: var(--accent); text-decoration: none; font-weight: 500;">Log in</a>
    </p>
  </div>
  <a href="/" class="back-link">← Back to Home</a>
</body>
</html>
HTML

  cat > templates/post.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{{ post.title }} - AYT04</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-dark: #09090b; --bg-gradient: linear-gradient(135deg, #09090b 0%, #18181b 100%);
      --card-bg: rgba(24, 24, 27, 0.7); --card-border: rgba(255, 255, 255, 0.08);
      --text-main: #f4f4f5; --text-muted: #a1a1aa;
      --accent: #3b82f6; --accent-hover: #60a5fa; --radius: 16px;
      --font: 'Inter', system-ui, -apple-system, sans-serif;
      --list-hover-bg: rgba(255, 255, 255, 0.05); --shadow: 0 20px 40px -20px rgba(0,0,0,0.7);
    }
    [data-theme="light"] {
      --bg-dark: #f8fafc; --bg-gradient: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
      --card-bg: rgba(255, 255, 255, 0.7); --card-border: rgba(0, 0, 0, 0.1);
      --text-main: #0f172a; --text-muted: #64748b;
      --accent: #2563eb; --accent-hover: #1d4ed8; --list-hover-bg: rgba(0, 0, 0, 0.03); --shadow: 0 20px 40px -20px rgba(0,0,0,0.1);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font); background: var(--bg-dark); background-image: var(--bg-gradient); color: var(--text-main); min-height: 100vh; display: flex; flex-direction: column; align-items: center; padding: 60px 20px; line-height: 1.7; -webkit-font-smoothing: antialiased; }
    
    .navbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 24px;
      margin-bottom: 32px;
      width: 100%;
      max-width: 760px;
      border-radius: 99px;
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
    }
    
    .back-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      color: var(--text-main);
      text-decoration: none;
      font-weight: 500;
      font-size: 0.9rem;
      transition: all 0.2s ease;
    }
    .back-btn:hover { color: var(--accent); }

    .theme-toggle {
      background: transparent; border: none; color: var(--text-main); width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s ease; position: relative;
    }
    .theme-toggle:hover { background: var(--list-hover-bg); }
    .sun-icon, .moon-icon { width: 18px; height: 18px; position: absolute; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    [data-theme="light"] .sun-icon { opacity: 0; transform: rotate(-90deg) scale(0.5); }
    [data-theme="light"] .moon-icon { opacity: 1; transform: rotate(0) scale(1); }
    [data-theme="dark"] .sun-icon, :root:not([data-theme="light"]) .sun-icon { opacity: 1; transform: rotate(0) scale(1); }
    [data-theme="dark"] .moon-icon, :root:not([data-theme="light"]) .moon-icon { opacity: 0; transform: rotate(90deg) scale(0.5); }
    
    .article-container { width: 100%; max-width: 760px; background: var(--card-bg); border: 1px solid var(--card-border); border-radius: var(--radius); padding: 48px; backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); box-shadow: var(--shadow); animation: fadeUp 0.4s ease-out forwards; }
    @keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
    
    h1 { font-size: 2.5rem; font-weight: 700; letter-spacing: -0.02em; margin-bottom: 24px; line-height: 1.2; background: linear-gradient(to right, var(--text-main), var(--text-muted)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    
    .post-meta { display: flex; align-items: center; gap: 12px; margin-bottom: 32px; padding-bottom: 24px; border-bottom: 1px solid var(--card-border); font-size: 0.9rem; color: var(--text-muted); }
    .avatar { width: 32px; height: 32px; border-radius: 50%; background: linear-gradient(135deg, var(--accent), #8b5cf6); display: flex; align-items: center; justify-content: center; font-weight: 600; color: white; font-size: 0.8rem; text-transform: uppercase; }
    
    .content { color: var(--text-main); font-size: 1.05rem; white-space: pre-wrap; }
    
    @media (max-width: 640px) { body { padding: 20px 16px; } .article-container { padding: 32px 24px; } h1 { font-size: 2rem; } }
  </style>
  <script>
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) { document.documentElement.setAttribute('data-theme', savedTheme); }
    else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) { document.documentElement.setAttribute('data-theme', 'light'); }
  </script>
</head>
<body>
  <nav class="navbar">
    <a href="/" class="back-btn">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
      Back to Home
    </a>
    <button id="theme-toggle" class="theme-toggle" aria-label="Toggle theme">
      <svg class="sun-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
      <svg class="moon-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
    </button>
  </nav>

  <main class="article-container">
    <h1>{{ post.title }}</h1>
    <div class="post-meta">
      <div class="avatar">{{ post.get('author', 'A')[0] }}</div>
      <div>Posted by <strong>@{{ post.get('author', 'Anonymous') }}</strong></div>
    </div>
    <div class="content">{{ post.content }}</div>
  </main>
  
  <script>
    const toggleBtn = document.getElementById('theme-toggle');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
      });
    }
  </script>
</body>
</html>
HTML

  cat > README.md <<'EOF'
# Community Quora Clone

I made this Quora / UserVoice platform for any small organization
to setup and use for their community. This is light, doesn't require
much maintence, just follow the steps below, and your in!

This simple Flask app stores posts with root-level slugs.

Run:

    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    python app.py

Then visit `http://127.0.0.1:5000/`.
EOF

  echo "Project initialized in $(pwd)."
  echo "Run: cd $target_dir && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python app.py"
}

main() {
  if [[ $# -eq 0 ]]; then
    print_help
    exit 0
  fi

  case "$1" in
    init)
      init_project "${2:-.}"
      ;;
    help|--help|-h)
      print_help
      ;;
    *)
      echo "Unknown command: $1"
      print_help
      exit 1
      ;;
  esac
}

main "$@"
