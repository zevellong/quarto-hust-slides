# hust 扩展 · 使用与 md → qmd 转换约定

本文件夹是华科幻灯片模板的样式与素材（由模板 `tools/new_deck.sh` / `tools/update_ext.sh` 复制，**不要手改**；要改请改模板后同步）。
模板仓库：quarto-hust-slides（完整说明见模板根目录 README.md）。

## 幻灯片目录

```
doc/
├── slides.qmd        # 内容（由 md 转换而来）
├── config.yml        # 姓名、单位、日期（默认渲染当天）、照片设置
├── deck.css          # 可选：本次专用样式（qmd 中 format: hust-revealjs: css: deck.css）
├── fig/              # 图
├── _extensions/hust/ # 本文件夹
└── slides.html / slides.pdf / slides.pptx   # 生成物
```

渲染：`bash <模板>/tools/render.sh doc/slides.qmd [--pptx]`

## md → qmd 转换约定（给 agent）

1. **头部**只写 `title`、`subtitle`、`title-slide-attributes: data-short-title`、`metadata-files: [config.yml]`、`format`；
   姓名 / 单位不写（在 config.yml）；**日期**仅在固定场合（答辩、会议）写 `date: YYYY-MM-DD`，否则不写（默认渲染当天）。
2. 头部之后第一行是 `## 目录 {.toc}`；**第一个 `##` 之前不能有任何 HTML 块或注释**（会多出空白页）。
3. md 的一级标题 → `# 一 部分名`（分节页，中文序号会自动去掉）；二级标题 → `## 结论式标题`（内容页）。
4. 状态：标题后加 `[✅]{.status}`（已完成）/ `[⏳]{.status}`（进行中）/ `[📋]{.status}`（待补）。
5. 要点列表包进 `::: {.points}`；每页 2–5 条，每条尽量 20 字以内；关键数字写 `[提升 12%]{.hl}`。
6. 图文并排：
   ```
   :::: {.columns}
   ::: {.column width="62%"}
   ![](fig/x.png){height="640"}
   :::
   ::: {.column width="38%" .points}
   - 要点
   :::
   ::::
   ```
   图片只写 `height` 或 `width` 之一（宽图 `height≈300–420` 上图下文；方图 / 树图 `height≈600–680` 左图右文）。
7. 指标卡：`::: {.stats}` 内放若干 `::: {.stat}` + `[8]{.num} 说明`；`{.stat .red}` 红色数字。
8. 提示框：`::: {.key}` 结论（红）、`::: {.note}` 说明（蓝）、`::: {.todo}` 待补（琥珀）；参考文献 `::: {.refs}`（页底小字）。
9. 演讲稿 / 口头补充 → `::: {.notes}`（只在讲者视图与 PPTX 备注栏显示）。
10. 最后一页 `## 谢谢 {.end}`，下一行可写一句小字（如“欢迎批评指正”）；右上角分享卡片由 config.yml 的 `end-link` / `end-link-label` 与目录中的 `share_enable.png`（二维码图片，存在即显示）控制。
11. 单个分节换照片：`# 标题 {photo="36"}`；整体照片设置改 config.yml，不在 qmd 里写。
12. 转换后渲染并检查 PDF 页数是否等于幻灯片数（多出页 = 某页内容溢出，删减文字或缩小图片）。
13. **只排版，不改内容**：不要编造原稿里没有的数字、结论或参考文献；原稿写“待补 / TODO”的地方用 `::: {.todo}`，并把该页状态设为 `[📋]{.status}`。
14. 原稿是纯文本也可以：按段落主题拆页，每页标题改写成一句结论，细节放要点或 `::: {.notes}`。
