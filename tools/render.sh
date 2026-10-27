#!/usr/bin/env bash
# 渲染幻灯片：HTML（单文件）→ PDF（自动重试，直到页数 > 1）→ 可选 PPTX
# 用法：bash <模板>/tools/render.sh <幻灯片目录>/slides.qmd [--no-pdf] [--pptx]
#   quarto：PATH 中有则直接用；否则用 conda 环境 QUARTO_ENV（默认 proj_16s_quarto）
#   CHROME：默认依次找 chromium / google-chrome / chrome；PPTX_PYTHON：含 python-pptx 的 python（默认 python3）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
QMD="${1:?用法: render.sh <slides.qmd> [--no-pdf] [--pptx]}"; shift
PDF=1; PPTX=0
for a in "$@"; do case "$a" in --no-pdf) PDF=0 ;; --pptx) PPTX=1 ;; *) echo "未知参数：$a" >&2; exit 1 ;; esac; done
CONDA="${CONDA_EXE:-$HOME/anaconda3/bin/conda}"
if [ -z "${QUARTO_ENV:-}" ] && command -v quarto >/dev/null; then QUARTO=(quarto)
else QUARTO=("$CONDA" run -n "${QUARTO_ENV:-proj_16s_quarto}" quarto); fi   # 本机 quarto 装在 conda 环境中，须 conda run
if [ -z "${CHROME:-}" ]; then
  for c in chromium chromium-browser google-chrome google-chrome-stable chrome; do command -v "$c" >/dev/null && { CHROME="$c"; break; }; done
fi
PY="${PPTX_PYTHON:-}"
[ -z "$PY" ] && { [ -x "$HOME/anaconda3/envs/zwml/bin/python" ] && PY="$HOME/anaconda3/envs/zwml/bin/python" || PY=python3; }
cd "$(dirname "$QMD")"
BASE="$(basename "$QMD" .qmd)"
"${QUARTO[@]}" render "$BASE.qmd" 2>&1 | grep -E "Output created|WARN|ERROR|Error" || true
[ "$PDF" = 1 ] || exit 0
[ -n "${CHROME:-}" ] || { echo "未找到 Chromium / Chrome，无法导出 PDF（可设 CHROME=浏览器路径）" >&2; exit 1; }
ok=0
for t in 1 2 3 4 5 6 7 8; do
  timeout 300 "$CHROME" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=60000 --run-all-compositor-stages-before-draw \
    --no-pdf-header-footer --print-to-pdf="$BASE.pdf" "file://$PWD/$BASE.html?print-pdf" >/dev/null 2>&1 || true
  n=$(pdfinfo "$BASE.pdf" 2>/dev/null | awk '/Pages/{print $2}')
  echo "PDF 第 $t 次导出：${n:-0} 页"
  [ "${n:-0}" -gt 1 ] && { ok=1; break; }
done
[ "$ok" = 1 ] || { echo "PDF 导出页数异常，请检查 $BASE.html" >&2; exit 1; }
[ "$PPTX" = 1 ] && "$PY" -I "$HERE/make_pptx.py" "$BASE.html"
exit 0
