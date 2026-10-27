#!/usr/bin/env bash
# 生成可公开分享的干净副本（排除规则同 .gitignore：照片原图 / 压缩版、预览 HTML、渲染中间文件）
#   <输出目录>/quarto-hust-slides_upload/        → 把其中全部内容拖进 GitHub 仓库网页（Add file → Upload files）
#   <输出目录>/quarto-hust-slides_<日期>.zip     → 直接发给别人
# 用法：bash tools/make_share.sh [输出目录，默认模板的上一级目录]
set -euo pipefail
TPL="$(cd "$(dirname "$0")/.." && pwd)"   # 模板根目录
OUT="$(cd "${1:-$(dirname "$TPL")}" && pwd)"
UP="$OUT/quarto-hust-slides_upload"
rm -rf "${UP:?}"
rsync -a --exclude '.git/' --exclude '.quarto/' --exclude '*_files/' \
  --include 'photos/索引.jpg' --exclude 'photos/*.jpg' --exclude 'photos/*.JPG' \
  --include 'photos/web/' --include 'photos/web/011_*.jpg' --include 'photos/web/013_*.jpg' --include 'photos/web/022_*.jpg' \
  --exclude 'photos/web/*' --exclude 'preview/*.html' \
  --exclude '_extensions/hust/photo-dir' \
  "$TPL/" "$UP/"
ZIP="$OUT/quarto-hust-slides_$(date +%Y%m%d).zip"
rm -f "$ZIP"; (cd "$UP" && zip -qr "$ZIP" .)
echo "上传文件夹：$UP（$(find "$UP" -type f | wc -l) 个文件，$(du -sh "$UP" | cut -f1)；最大文件 $(find "$UP" -type f -printf '%s %p\n' | sort -n | tail -1 | awk '{printf "%.1f MB %s", $1/1e6, $2}')）"
echo "压缩包：$ZIP"
