#!/usr/bin/env bash
# 生成内嵌用的压缩照片：photos/NNN_名称.jpg -> photos/web/NNN_名称.jpg（长边 1600 px，JPEG q80，去元数据）
# 新增照片：按 NNN_名称.jpg 命名放进 photos/，在 来源.tsv 登记后重跑本脚本（已存在的不重复生成）
set -euo pipefail
P="$(cd "$(dirname "$0")/.." && pwd)/photos"
mkdir -p "$P/web"
shopt -s nullglob
for f in "$P"/[0-9][0-9][0-9]_*.jpg; do
  o="$P/web/$(basename "$f")"
  [ -s "$o" ] && [ "$o" -nt "$f" ] && continue
  magick "$f" -auto-orient -resize '1600x1600>' -strip -sampling-factor 4:2:0 -quality 80 "$o"
done
du -sh "$P/web"; ls "$P/web" | wc -l
