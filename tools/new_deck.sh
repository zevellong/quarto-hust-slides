#!/usr/bin/env bash
# 新建一套华科风格幻灯片
# 用法：bash new_deck.sh <目标目录> [文件名，默认 slides]
#   例：bash /path/to/quarto-hust-slides/tools/new_deck.sh ~/proj_x/doc report
# 生成：<文件名>.qmd（内容）、config.yml（姓名 / 单位 / 日期 / 照片）、fig/、_extensions/hust/（模板样式与素材，不用管）
set -euo pipefail
TPL="$(cd "$(dirname "$0")/.." && pwd)"   # 模板根目录
DEST="${1:?用法: new_deck.sh <目标目录> [文件名]}"
NAME="${2:-slides}"
mkdir -p "$DEST/fig"
if [ -e "$DEST/_extensions/hust" ]; then
  echo "已存在 $DEST/_extensions/hust，跳过（如需更新：bash $TPL/tools/update_ext.sh $DEST）"
else
  bash "$TPL/tools/update_ext.sh" "$DEST" >/dev/null
fi
[ -e "$DEST/config.yml" ] && echo "已存在 $DEST/config.yml，未覆盖" || cp "$TPL/config.yml" "$DEST/"
# 示例图与结尾分享二维码（fig/share_enable.png 指向模板仓库；不需要就删掉它并注释 config.yml 的 end-link）
for f in "$TPL"/fig/*; do case "$f" in *.py) ;; *) cp -n "$f" "$DEST/fig/" ;; esac; done   # 不复制画图脚本
[ -e "$DEST/$NAME.qmd" ] && echo "已存在 $DEST/$NAME.qmd，未覆盖" || cp "$TPL/template.qmd" "$DEST/$NAME.qmd"
echo "完成。改 $DEST/config.yml 中的姓名 / 单位，然后："
echo "  bash $TPL/tools/render.sh $DEST/$NAME.qmd [--pptx]"
