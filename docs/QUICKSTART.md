# GitBook Quick Start - Mermaid Working ✅

## ⚡ 5-Minute Setup

### 1. Go to GitBook

→ https://www.gitbook.com

### 2. Sign Up with GitHub

**IMPORTANT:** Must use GitHub login for auto-sync!

### 3. Import Repository

```
New Space → Import → GitHub
Repository: yeheskieltame/Aruna
```

### 4. Set Monorepo Path

**⚠️ CRITICAL - Don't skip this!**

```
Space Settings → GitHub Sync
Monorepo root path: docs
Save → Sync with GitHub
```

### 5. Verify Mermaid

Open "How It Works" page → Should see diagrams, not code ✅

---

## If Mermaid Still Shows as Code

### Quick Fix 1: Force Re-Process

1. Click any page with diagram
2. Click "Edit" button
3. Don't change anything
4. Click "Save"
5. Diagram should render ✅

### Quick Fix 2: Wait

Sometimes takes 1-2 minutes to process. Refresh page.

### Quick Fix 3: Re-Sync

```
Settings → GitHub Sync → Sync with GitHub button
```

### Quick Fix 4: Re-Import

```
Delete space → Re-import → Set monorepo path FIRST
```

---

## Checklist

- [ ] Using GitBook Cloud (not CLI)
- [ ] Signed up with GitHub account
- [ ] Repository imported: `yeheskieltame/Aruna`
- [ ] Monorepo path set to: `docs`
- [ ] Waited 1-2 minutes after import
- [ ] Clicked "Sync with GitHub"

If all checked and still not working → See MERMAID_FIX.md

---

## URLs

After setup:
- **Live docs:** `https://your-org.gitbook.io/aruna`
- **Edit:** GitBook dashboard
- **Sync:** Automatic from GitHub

---

## That's It!

GitBook Cloud natively supports Mermaid. No plugins, no config files needed (besides .gitbook.yaml which is already there).

The ONLY important setting: **Monorepo path = `docs`**
