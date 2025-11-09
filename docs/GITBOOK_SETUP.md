# GitBook Setup Guide

This guide will help you publish the Aruna documentation to GitBook.

## Quick Setup (GitBook Cloud - Recommended)

GitBook Cloud automatically renders Mermaid diagrams and provides the best user experience.

### Step 1: Create GitBook Account

1. Go to [https://www.gitbook.com](https://www.gitbook.com)
2. Sign up with GitHub (recommended for easy integration)
3. Create a new organization (or use personal account)

### Step 2: Create New Space

1. Click "New Space"
2. Choose "Import from GitHub"
3. Select your repository: `yeheskieltame/Aruna`
4. Set the documentation path: `/docs`
5. Click "Import"

### Step 3: Configure

GitBook will automatically:
- Detect `SUMMARY.md` for navigation
- Use `README.md` as the home page
- Render all Mermaid diagrams
- Apply default theme

### Step 4: Publish

1. Click "Publish" in the top right
2. Choose visibility (Public recommended for open-source)
3. Your docs are live!

**URL Format:** `https://your-org.gitbook.io/aruna-protocol`

---

## Alternative: GitBook CLI (Local Testing)

For local preview before publishing:

### Installation

```bash
npm install -g gitbook-cli
```

### Install Plugins

```bash
cd docs
gitbook install
```

This will install:
- `mermaid-gb3` - For Mermaid diagram rendering
- `search-plus` - Enhanced search functionality

### Local Preview

```bash
gitbook serve
```

Open browser to `http://localhost:4000`

### Build Static Site

```bash
gitbook build
```

Output in `_book/` directory, ready for deployment to:
- GitHub Pages
- Netlify
- Vercel
- Any static hosting

---

## Mermaid Diagram Support

All Mermaid diagrams in the documentation use simplified syntax for maximum compatibility:

✅ **Supported:**
- Flowcharts (`graph TD`, `graph LR`)
- Sequence diagrams (`sequenceDiagram`)
- Simple styling
- Standard nodes and edges

❌ **Avoided:**
- Emoji in node labels (causes rendering issues)
- Complex classDef styling
- Advanced subgraph features
- Custom themes

**All diagrams tested and working in GitBook Cloud.**

---

## Customization

### Update Links

Links are already configured for:
- Live App: `https://aruna-defi.vercel.app`
- GitHub: `https://github.com/yeheskieltame/Aruna`

To update, edit:
- `README.md` - Support section
- `use-cases.md` - Getting Started section
- `book.json` - Sidebar links

### Update Branding

Edit `book.json`:
```json
{
  "title": "Your Title",
  "description": "Your Description",
  "author": "Your Name"
}
```

### Change Theme

GitBook Cloud provides theme customization in:
- Settings → Appearance
- Choose colors, fonts, logos
- No code changes needed

---

## Deployment Options

### Option 1: GitBook Cloud (Recommended)
- **Pros**: Auto-updates, Mermaid support, search, analytics
- **Cons**: Requires GitBook account
- **Best for**: Production documentation

### Option 2: GitHub Pages
```bash
gitbook build
cd _book
git init
git add .
git commit -m "Deploy docs"
git push origin gh-pages
```

### Option 3: Vercel
1. Connect repository to Vercel
2. Set build command: `cd docs && gitbook build`
3. Set output directory: `docs/_book`
4. Deploy

### Option 4: Netlify
1. Connect repository to Netlify
2. Set base directory: `docs`
3. Set build command: `gitbook build`
4. Set publish directory: `_book`
5. Deploy

---

## Troubleshooting

### Mermaid Diagrams Not Rendering

**GitBook Cloud:**
- Diagrams should render automatically
- If not, check syntax in live editor: https://mermaid.live

**GitBook CLI:**
- Ensure `mermaid-gb3` plugin is installed
- Run `gitbook install` in docs folder
- Check `book.json` has correct plugin config

### Navigation Not Working

- Verify `SUMMARY.md` format is correct
- Check all file paths are relative to `docs/` folder
- Ensure no broken links

### Search Not Working

- GitBook Cloud: Built-in search works automatically
- GitBook CLI: Install `search-plus` plugin via `gitbook install`

---

## Maintenance

### Updating Documentation

1. Edit files in `docs/` folder
2. Commit and push to GitHub
3. GitBook Cloud auto-syncs (if connected)
4. Or rebuild manually: `gitbook build`

### Adding New Pages

1. Create new `.md` file in `docs/`
2. Add entry to `SUMMARY.md`
3. Link from other pages as needed

### Updating Diagrams

- Edit Mermaid code blocks directly in markdown
- Test at https://mermaid.live
- Avoid emoji and complex styling
- Keep syntax simple for compatibility

---

## Resources

- GitBook Documentation: https://docs.gitbook.com
- Mermaid Documentation: https://mermaid.js.org
- Mermaid Live Editor: https://mermaid.live
- GitBook Plugins: https://www.npmjs.com/search?q=gitbook-plugin

---

## Support

If you encounter issues:
1. Check GitBook docs: https://docs.gitbook.com
2. Review this setup guide
3. Test diagrams at https://mermaid.live
4. Check GitHub Issues: https://github.com/yeheskieltame/Aruna/issues
