---
name: quarto-hust-slides
description: Build academic slide decks (组会 / 开题 / 答辩 / 学术汇报) with the quarto-hust-slides Quarto revealjs template — turn a user's Markdown or plain-text outline into slides.qmd, render single-file HTML + clickable PDF + PPTX, check the output, and re-skin the template for another university or company (colors, logo, photos). Use whenever the user wants to make, convert, fix, render or restyle a presentation / 幻灯片 / PPT / 汇报 with Quarto or this template, or mentions slides.qmd, hust-revealjs, new_deck.sh or render.sh.
---

# quarto-hust-slides

The user writes **content only**; you do the layout. One `slides.qmd` → single-file HTML (present, touch nav, speaker view), PDF (clickable nav), PPTX (page images + speaker notes). The look is HUST (华中科技大学) by default and can be re-skinned for any institution.

## Locate the template

The template root (`TPL`) contains `tools/`, `_extensions/hust/`, `template.qmd`. This skill lives at `TPL/skills/quarto-hust-slides/`, so:

```bash
TPL=$(cd "$(dirname "$(readlink -f "<this skill dir>/SKILL.md")")/../.." && pwd)   # skill dir = TPL/skills/quarto-hust-slides
ls "$TPL/tools/render.sh" || git clone https://github.com/zevellong/quarto-hust-slides.git   # fallback
```

Requirements: Quarto ≥ 1.4, Chromium/Chrome, poppler (`pdftoppm`, `pdfinfo`); PPTX also needs Python with `python-pptx` + `beautifulsoup4`. Tested on Linux only (Windows: use WSL).

## Workflow 1 — New deck

```bash
bash "$TPL/tools/new_deck.sh" <deck_dir> slides     # creates slides.qmd (demo), config.yml, fig/, _extensions/hust/
```

Then edit `<deck_dir>/config.yml`: `author`, `institute` (ask the user if unknown — never invent a name). Leave `date: today` unless the event has a fixed date (defense, conference) — then put `date: YYYY-MM-DD` in the qmd header. Replace the demo body of `slides.qmd` with the user's content (Workflow 2).

Deck layout (do not add other files unless needed): `slides.qmd`, `config.yml`, `fig/`, `_extensions/hust/` (never hand-edit), optional `deck.css`, outputs.

## Workflow 2 — Markdown / plain text → slides.qmd (the core task)

Read **`references/md2qmd.md`** before converting; use **`references/layouts.md`** for exact syntax. Essentials:

1. Header: `title`, `subtitle`, `title-slide-attributes: data-short-title`, `metadata-files: [config.yml]`, `format: hust-revealjs`. No author/institute in the qmd.
2. First line after the header: `## 目录 {.toc}`. **Nothing (no HTML, no comment) before the first `##`** — it creates a blank slide.
3. Source H1 → `# 一 部分名` (section page); H2 → `## 结论式标题` (content slide, title states the finding).
4. Lists → `::: {.points}` (2–5 bullets, ≤ ~20 汉字 each); key numbers `[12%]{.hl}`; image + text → `:::: {.columns}`; a row of numbers → `::: {.stats}`; TODO → `::: {.todo}` + `[📋]{.status}`; conclusion → `::: {.key}`; spoken remarks → `::: {.notes}`.
5. Images: only `height` **or** `width`, never both. Wide figure: height ≈ 300–420 above text; square/tree: height ≈ 600–680 left of text.
6. Last slide `## 谢谢 {.end}`.
7. **Layout only — never invent numbers, conclusions or references** that are not in the source. If something is missing, use a `.todo` box.

## Workflow 3 — Render and verify

```bash
bash "$TPL/tools/render.sh" <deck_dir>/slides.qmd [--pptx] [--no-pdf]
```

`render.sh` renders HTML, strips an unused 3 MB font, exports PDF with Chromium (auto-retry) and optionally PPTX. Always verify:

- **PDF pages == number of slides** (cover + toc + sections + content + end). More pages ⇒ a slide overflows → shorten bullets, split the slide, or reduce image height. Count with `pdfinfo slides.pdf | grep Pages`.
- Look at the pages (`pdftoppm -png -r 50 slides.pdf /tmp/p`) — check overflow, image distortion, empty slides.
- Numbers and claims match the source.

Report the output paths and sizes. Use `render.sh`, not bare `quarto render` (bare output is ~3 MB larger).

## Workflow 4 — Re-skin for another institution

Follow **`references/rebrand.md`**: colors are SCSS variables at the top of `_extensions/hust/hust.scss`; logos/names are SVGs in `_extensions/hust/assets/` referenced by `title-slide.html` and the `.hust-assets` list; photos live in `photos/` with `photos/来源.tsv` (ids `NNN_名称.jpg`). Edit the template (or a fork), then `bash "$TPL/tools/update_ext.sh" <deck_dir>` and re-render.

## Options cheat sheet (config.yml → `hust:`)

| Key | Values |
|---|---|
| `photos` | `true` (default) / `false` (no-photo mode: centered white cover & end) |
| `cover-photo` / `section-photo` / `end-photo` | id (`11`), `none`, `random`, list `[22, 25]`; defaults 11 / none / 13 |
| `photo-order`, `photo-seed` | `random` / `cycle`; integer for reproducible picks |
| `end-link`, `end-link-label` | share card on the end slide; QR image = `share_enable.png` in deck dir or `fig/` (present ⇒ shown) |

Per-section override: `# 标题 {photo="36"}`. Bundled photos: 011, 013, 022; others need `bash "$TPL/tools/fetch_photos.sh"`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Blank slide | something before the first `##` |
| PDF has 1 page | render.sh retries; rerun once |
| PDF pages > slides | a slide overflows — trim it |
| Photo missing | id not bundled → `fetch_photos.sh`; template moved → `update_ext.sh <deck_dir>` |
| `quarto` not found | set `QUARTO_ENV=<conda env>` or add quarto to PATH |
| No Chromium | set `CHROME=/path/to/chrome` |
