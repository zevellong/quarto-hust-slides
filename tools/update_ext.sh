#!/usr/bin/env bash
# 把模板里最新的扩展同步到已有幻灯片目录（整体替换 _extensions/hust，不动 qmd、config.yml、图和其他文件）
# 用法：bash update_ext.sh <幻灯片目录>
set -euo pipefail
TPL="$(cd "$(dirname "$0")/.." && pwd)"   # 模板根目录
DEST="${1:?用法: update_ext.sh <幻灯片目录>}"
[ -d "$DEST" ] || { echo "目录不存在：$DEST"; exit 1; }
[ -f "$TPL/_extensions/hust/_extension.yml" ] || { echo "模板扩展缺失"; exit 1; }
mkdir -p "$DEST/_extensions"
rm -rf "${DEST:?}/_extensions/hust"
cp -r "$TPL/_extensions/hust" "$DEST/_extensions/"
echo "$TPL/photos/web" > "$DEST/_extensions/hust/photo-dir"   # 图片模式从模板读照片
echo "已更新 $DEST/_extensions/hust"
