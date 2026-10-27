#!/usr/bin/env bash
# 按 photos/来源.tsv 从华中科技大学官网下载校园照片原图，并生成内嵌用压缩版（photos/web/）
# 仓库只内置默认搭配的 3 张压缩版（011 / 013 / 022）；要用其他照片时运行一次。已存在的文件跳过。
# 用法：bash tools/fetch_photos.sh
set -euo pipefail
P="$(cd "$(dirname "$0")/.." && pwd)/photos"
n=0
# 只取 文件名、原图地址 两列（作者可能为空，bash read 会把连续 Tab 合并，故用 awk）
while IFS=$'\t' read -r fn url; do
  [ -s "$P/$fn" ] && continue
  echo "下载 $fn"
  curl -fsSL --retry 3 --max-time 120 -o "$P/$fn.part" "$url" && mv "$P/$fn.part" "$P/$fn" && n=$((n + 1)) \
    || { rm -f "$P/$fn.part"; echo "  失败：$url" >&2; }
done < <(awk -F'\t' 'NR > 1 && $5 != "" { print $2 "\t" $5 }' "$P/来源.tsv")
echo "新下载 $n 张"
bash "$(dirname "$0")/prepare_photos.sh"
