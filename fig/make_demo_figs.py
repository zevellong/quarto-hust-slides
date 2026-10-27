#!/usr/bin/env python
"""生成 template.qmd 的两张示例图（SVG，保留文字以减小体积；字体与幻灯片一致）。
用法：python fig/make_demo_figs.py（需 matplotlib；本机用 Noto Sans CJK 排版，SVG 中字体换成幻灯片字体栈）
"""
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm
from matplotlib.patches import FancyBboxPatch

OUT = Path(__file__).parent
for f in fm.findSystemFonts():
    if "NotoSansCJK-Regular" in f:
        fm.fontManager.addfont(f)
plt.rcParams.update({"font.family": ["Noto Sans CJK JP", "sans-serif"], "svg.fonttype": "none", "font.size": 13,
                     "axes.spines.top": False, "axes.spines.right": False})
STACK = "'HarmonyOS Sans SC', 'PingFang SC', 'Source Han Sans SC', 'Noto Sans CJK SC', 'Microsoft YaHei', sans-serif"
BLUE, RED, INK, INK2, LINE = "#004B84", "#D20B17", "#0F172A", "#475569", "#CBD5E1"


def save(fig, name, **kw):
    p = OUT / name
    fig.savefig(p, transparent=True, **kw)
    plt.close(fig)
    s = re.sub(r"font-family: [^;\"]+", f"font-family: {STACK}", p.read_text())
    p.write_text(s)
    print(name, f"{p.stat().st_size / 1e3:.0f} KB")


# 1. ZymoBIOMICS D6300 理论组成（基因组 DNA，厂商说明书标称值）
taxa = [("Pseudomonas aeruginosa", 12), ("Escherichia coli", 12), ("Salmonella enterica", 12),
        ("Limosilactobacillus fermentum", 12), ("Enterococcus faecalis", 12), ("Staphylococcus aureus", 12),
        ("Listeria monocytogenes", 12), ("Bacillus subtilis", 12), ("Saccharomyces cerevisiae", 2),
        ("Cryptococcus neoformans", 2)]
fig, ax = plt.subplots(figsize=(7.2, 5.8))
names = [t[0] for t in taxa][::-1]
vals = [t[1] for t in taxa][::-1]
ax.barh(names, vals, color=[("#94A3B8" if v == 2 else BLUE) for v in vals], height=0.62)
for i, v in enumerate(vals):
    ax.text(v + 0.3, i, f"{v}%", va="center", color=INK2, fontsize=12)
ax.set_xlim(0, 15)
ax.set_xlabel("理论相对丰度（基因组 DNA，%）", color=INK2)
for lab in ax.get_yticklabels():
    lab.set_color(INK)
ax.tick_params(colors=INK2)
for side in ("left", "bottom"):
    ax.spines[side].set_color(LINE)
fig.text(0.02, 0.965, "ZymoBIOMICS D6300：8 种细菌 + 2 种酵母", fontsize=14, fontweight="bold", color=INK, va="top")
fig.text(0.02, 0.01, "数据：厂商说明书标称值（genomic DNA）", fontsize=10, color="#94A3B8")
fig.tight_layout(rect=(0, 0.03, 1, 0.93))
save(fig, "demo_zymo_composition.svg")

# 2. profiling 流程示意（无数据）
fig, ax = plt.subplots(figsize=(13, 3.3))
ax.set_xlim(0, 13)
ax.set_ylim(-0.2, 3.1)
ax.axis("off")


def box(x, y, w, h, t, sub=None, fc="white", ec=LINE, tc=INK, sc=INK2, fs=14):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.1", fc=fc, ec=ec, lw=1.4))
    ax.text(x + w / 2, y + h / 2 + (0.17 if sub else 0), t, ha="center", va="center", fontsize=fs, fontweight="bold", color=tc)
    if sub:
        ax.text(x + w / 2, y + h / 2 - 0.25, sub, ha="center", va="center", fontsize=11, color=sc)


def arrow(x1, x2, y=1.45):
    ax.annotate("", xy=(x2, y), xytext=(x1, y), arrowprops=dict(arrowstyle="-|>", color=BLUE, lw=1.6))


box(0.1, 0.95, 2.0, 1.0, "测序 reads", "FASTQ")
arrow(2.15, 2.75)
box(2.8, 0.95, 2.0, 1.0, "质控 / 去宿主", "fastp · bowtie2")
arrow(4.85, 5.45)
for i, t in enumerate(["sylph", "Kraken 2 + Bracken", "MetaPhlAn 4", "mOTUs", "Metax"]):
    box(5.5, 2.55 - i * 0.56, 2.6, 0.44, t, fc=BLUE if i == 0 else "white", ec=BLUE, tc="white" if i == 0 else BLUE, fs=13)
ax.text(6.8, -0.2, "物种组成 profiling（任选其一或对比）", ha="center", fontsize=11, color=INK2)
arrow(8.15, 8.75)
box(8.8, 0.95, 2.0, 1.0, "丰度表", "样本 × 物种")
arrow(10.85, 11.45)
box(11.5, 0.95, 1.4, 1.0, "下游", "多样性 · 差异", fc="#FEF3F2", ec=RED, tc=RED, sc="#912018")
save(fig, "demo_profiling_workflow.svg", bbox_inches="tight")
