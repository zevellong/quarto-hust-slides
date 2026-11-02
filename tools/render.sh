#!/usr/bin/env bash
# 渲染幻灯片：HTML（单文件）→ PDF（自动重试，直到页数 > 1）→ PPTX
# 用法：bash <模板>/tools/render.sh <幻灯片目录>/slides.qmd [--format html,pdf,pptx] [--no-pdf] [--pptx]
#   输出格式（可多选：html / pdf / pptx），优先级：命令行 > qmd 头部 > config.yml > 默认 [html]
#     config.yml / qmd 头部写在 hust 下：  output: [html, pdf]
#     HTML 是 PDF、PPTX 的中间产物，PDF 是 PPTX 的中间产物；清单里没有的中间文件渲染后删除
#     旧参数仍可用：--no-pdf（去掉 pdf）、--pptx（加上 pptx）
#   quarto：PATH 中有则直接用；否则用 conda 环境 QUARTO_ENV（默认 proj_16s_quarto）
#   CHROME：默认依次找 chromium / google-chrome / chrome；PPTX_PYTHON：含 python-pptx 的 python（默认 python3）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
QMD="${1:?用法: render.sh <slides.qmd> [--format html,pdf,pptx] [--no-pdf] [--pptx]}"; shift
# 从 YAML 的 hust: 段读 output（[a, b] 列表或单个值）；qmd 只看头部 --- ... ---
read_output() {
  awk 'NR == 1 && FILENAME ~ /\.qmd$/ && $0 != "---" {exit}
       FILENAME ~ /\.qmd$/ && NR > 1 && $0 == "---" {exit}
       /^hust:/ {h = 1; next} /^[^ #]/ {h = 0}
       h && /^[ ]+output:/ {sub(/^[ ]+output:[ ]*/, ""); sub(/[ ]+#.*$/, ""); gsub(/[][" '"'"']/, ""); print; exit}' "$1" 2>/dev/null
}
FMT=""
for a in "$@"; do case "$a" in --format=*) FMT="${a#--format=}" ;; esac; done
prev=""; for a in "$@"; do [ "$prev" = "--format" ] && FMT="$a"; prev="$a"; done
[ -z "$FMT" ] && FMT="$(read_output "$QMD")"
[ -z "$FMT" ] && FMT="$(read_output "$(dirname "$QMD")/config.yml")"
[ -z "$FMT" ] && FMT=html
skip=0
for a in "$@"; do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  case "$a" in
    --no-pdf) FMT="$(tr ',' '\n' <<< "$FMT" | grep -vx pdf | paste -sd, -)" ;;
    --pptx) FMT="$FMT,pptx" ;;
    --format) skip=1 ;;
    --format=*) ;;
    *) echo "未知参数：$a" >&2; exit 1 ;;
  esac
done
has() { tr ',' '\n' <<< "$FMT" | grep -qx "$1"; }
for f in $(tr ',' ' ' <<< "$FMT"); do case "$f" in html|pdf|pptx) ;; *) echo "未知输出格式：$f（可选 html / pdf / pptx）" >&2; exit 1 ;; esac; done
PDF=0; PPTX=0
has pdf && PDF=1
has pptx && { PDF=1; PPTX=1; }
echo "输出格式：$FMT"
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
# 瘦身：Quarto revealjs 的主题 CSS 开头内联了 Source Sans Pro 字体（约 3 MB），本模板不用它；
# 只删掉主题 CSS 里这几段 @font-face，其余样式原样保留
python3 - "$BASE.html" <<'PY'
import re, sys
from urllib.parse import quote, unquote
f = sys.argv[1]; s = open(f, encoding="utf-8").read(); n0 = len(s.encode())
def slim(m):
    css = unquote(m.group(2))
    css2 = re.sub(r"@font-face\s*\{[^}]*Source Sans Pro[^}]*\}", "", css)
    return m.group(1) + (quote(css2, safe="") if css2 != css else m.group(2)) + m.group(3)
s = re.sub(r'(href="data:text/css,)([^"]*)(")', slim, s)
open(f, "w", encoding="utf-8").write(s)
print(f"HTML 瘦身：{n0 / 1e6:.1f} MB → {len(s.encode()) / 1e6:.1f} MB")
PY
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
# 清单里没有的中间产物删掉
has pdf || rm -f "$BASE.pdf"
has html || rm -f "$BASE.html"
exit 0
