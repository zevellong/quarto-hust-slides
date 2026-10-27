# Markdown / 纯文本 → slides.qmd 转换约定

目标：用户只写内容，你负责排版。**只排版，不改内容。**

## 规则

1. **头部**只写以下字段（姓名、单位、日期默认在 config.yml）：
   ```yaml
   ---
   title: "一句话标题（≤ 16 字最佳）"
   subtitle: "项目名称 · 阶段进展"
   title-slide-attributes:
     data-short-title: "短标题"      # 节外页面的眉题
   metadata-files: [config.yml]
   format: hust-revealjs              # 有 deck.css 时：format: hust-revealjs: css: deck.css
   ---
   ```
   固定日期（答辩、会议）才加 `date: YYYY-MM-DD`。
2. 头部之后第一行：`## 目录 {.toc}`。**第一个 `##` 之前不能有任何 HTML 块或注释**（会多出空白页）。
3. **分节**：原稿一级标题 → `# 一 部分名`（中文序号会自动去掉，显示为 01、02…）。没有一级标题时，按主题自行分 2–5 节。
4. **内容页**：原稿二级标题或每个主题 → `## 结论式标题`。标题写发现或结论，而不是“结果”“方法”这类名词。
5. **状态**（进度汇报时）：标题末尾加 `[✅]{.status}` 已完成 / `[⏳]{.status}` 进行中 / `[📋]{.status}` 待补。原稿写“进行中”“TODO”“待补”时照此标注。
6. **要点**：列表放进 `::: {.points}`；每页 2–5 条，每条尽量 ≤ 20 个汉字；超出就拆页或把细节移到 `::: {.notes}`。
7. **关键数字**：`[12%]{.hl}`（华科红加粗），每页最多 1–2 处。
8. **图**：只写 `height` 或 `width` 之一。宽图 → 上图下文（height 300–420，下方 `:::: {.columns .points}` 两栏）；方图 / 树图 → 左图右文（height 600–680）。图片路径保持原稿写法（通常 `fig/xxx`）。
9. **一组数字**（3–4 个指标）→ `::: {.stats}` + 若干 `::: {.stat}`，`[数字]{.num} 说明`；需强调的一个用 `{.stat .red}`。
10. **框**：结论 → `::: {.key}`；说明 / 口径 → `::: {.note}`；待补 → `::: {.todo}`；参考文献 → `::: {.refs}`（页底小字）。
11. **口头补充 / 演讲稿** → `::: {.notes}`（只在讲者视图和 PPTX 备注栏出现）。
12. 最后一页：`## 谢谢 {.end}`，下一行可写“欢迎批评指正”。
13. **不编造**：原稿没有的数字、结论、参考文献、图片一律不加；缺的地方用 `::: {.todo}`。
14. 纯文本原稿：按段落主题拆页，每页标题改写成一句结论，细节放要点或备注。
15. 转换后渲染（`render.sh`），检查 **PDF 页数 = 幻灯片数**；多出的页说明某页溢出，精简后重渲染。

## 示例

**输入（用户写的 talk.md）**

```markdown
# 背景
## profiling 工具结果不一致
- 方法：k-mer、标记基因、比对
- 用模拟群落（ZymoBIOMICS D6300）检验准确度
- 图：fig/zymo.svg

# 结果
## Metax 低丰度检出更稳定（进行中）
- 8 种细菌各 12%，2 种酵母各 2%
- 待补：假阳性统计
演讲时提一句：标称值是基因组 DNA 口径
```

**输出（slides.qmd）**

```markdown
---
title: "宏基因组 profiling 工具评测"
subtitle: "课题组组会 · 阶段进展"
title-slide-attributes:
  data-short-title: "profiling 评测"
metadata-files: [config.yml]
format: hust-revealjs
---

## 目录 {.toc}

# 一 背景

## 不同 profiling 工具的结果并不一致 [✅]{.status}

:::: {.columns}
::: {.column width="56%"}
![](fig/zymo.svg){height="600"}
:::
::: {.column width="44%" .points}
- 方法各异：k-mer、标记基因、比对
- 用模拟群落 ZymoBIOMICS D6300 检验准确度
:::
::::

# 二 结果

## Metax 在低丰度酵母上的检出更稳定 [⏳]{.status}

::: {.stats}
::: {.stat}
[12%]{.num} 每种细菌（8 种）
:::
::: {.stat .red}
[2%]{.num} 每种酵母（2 种）
:::
:::

::: {.todo}
待补：假阳性统计。
:::

::: {.notes}
标称值是基因组 DNA 口径。
:::

## 谢谢 {.end}

欢迎批评指正
```

注意：示例里没有新增任何原稿之外的数字；“进行中”变成 `[⏳]`，“待补”变成待补框，“演讲时提一句”变成备注。
