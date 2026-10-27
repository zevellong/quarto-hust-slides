# 换皮肤：改成其他学校 / 公司

模板与“华科”相关的东西全部集中在 4 处，内容（qmd）完全不用动。建议先 fork 或复制整个模板目录再改。

## 1. 颜色（`_extensions/hust/hust.scss` 顶部变量）

| 变量 | 默认（华科） | 作用 |
|---|---|---|
| `$hust-blue` | `#004B84` | 主色：眉题、列表方块、表头线、分节窄条、编号 |
| `$hust-blue-dark` | `#002D52` | 主色深色：分节窄条渐变起点 |
| `$hust-blue-soft` | `#EBF3FA` | 主色浅底：表头、说明框背景 |
| `$hust-red` | `#D20B17` | 点缀色：关键数字、短竖线、结论框 |
| `$canvas` / `$card` | `#F4F6F9` / `#FFFFFF` | 画布 / 卡片 |
| `$ink` / `$ink-2` / `$ink-3` / `$line` | 深灰系 | 文字与细线，一般不用改 |

原则：主色只作结构色，点缀色只用于少量强调；从对方 VI 手册取“标准色”，深色 / 浅底可用主色加黑 / 加白得到。字体在 `$font-family-sans-serif`。

## 2. 校徽 / Logo 与名称（`_extensions/hust/assets/`）

| 文件 | 用在 | 替换要求 |
|---|---|---|
| `hust-emblem-color.svg` | 封面左上、分节页右上、无图结尾页 | 彩色标志，透明背景 |
| `hust-emblem-white.svg` | 图片模式结尾页（深色照片上） | 反白标志 |
| `hust-name-cn-blue.svg` / `hust-name-en-blue.svg` | 封面校名（中 / 英） | 横排名称；没有英文名可删掉 `title-slide.html` 中对应 `<img>` |
| `hust-pattern.png` | 分节窄条、无图结尾页的淡底纹 | 平铺纹理；没有可放一张透明 PNG |
| `hust-mountain.svg` | 分节页右下淡色图形 | 任意简洁辅助图形 |

做法：**保持文件名不变直接覆盖**最省事（引用处不用改）。若改名，同步修改 `title-slide.html`（封面与 `.hust-assets` 列表）和 `hust.html`（`asset('key', 'file')`）。
转矢量：`inkscape logo.pdf --export-plain-svg --export-area-drawing -o out.svg && svgo out.svg`；位图纹理：`magick in.png -colors 16 out.png`。

## 3. 照片（`photos/`）

- 文件命名 `NNN_名称.jpg`，在 `photos/来源.tsv` 登记（编号、文件名、说明、作者、原图地址），运行 `bash tools/prepare_photos.sh` 生成 `photos/web/`。
- 在 `config.yml` 改默认编号：`cover-photo`（横幅，主体居中偏右）、`end-photo`（横幅，左下留暗区放白字）、`section-photo`（竖幅）。
- 默认编号写在 `_extensions/hust/hust-photos.lua` 的 `picker(... '11' ...)` / `'13'`，换成新编号或改 config。
- 没有合适照片：`photos: false`（无图模式，整体居中）。

## 4. 文字与默认值

- `config.yml`：`author`、`institute`、`end-link`。
- `_extensions/hust/_extension.yml`：格式名 `hust-revealjs` 可保留（改名需同步所有 qmd 的 `format:`）。
- `fig/share_enable.png`：换成指向新仓库 / 主页的二维码，或删除。
- README / 示例中的“华科”字样按需替换。

## 5. 验证

```bash
bash tools/new_deck.sh /tmp/rebrand_test demo
bash tools/render.sh /tmp/rebrand_test/demo.qmd
bash tools/render.sh /tmp/rebrand_test/demo.qmd   # 再把 config.yml 改 photos: false 测一次无图模式
```

逐页检查：封面标志与名称、目录、分节窄条颜色与标志、表格表头色、结尾页（两种模式）、PDF 页数 = 幻灯片数。已有幻灯片同步：`bash tools/update_ext.sh <deck_dir>`。
注意对方 VI 规范的版权与使用范围。
