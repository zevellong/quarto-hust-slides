-- HUST 照片模式：渲染时按配置选定照片，把 <img> 写进文档（embed-resources 时内嵌，只嵌用到的几张）
--
-- qmd front matter 或 metadata-files 引用的 yaml 中：
--   hust:
--     photos: true              # 图片模式（默认）；false = 无图模式
--     cover-photo: 11           # 封面右侧（默认 011 南大门鸟瞰）
--     section-photo: none       # 分节页左侧窄条（默认 none：华科蓝窄条；可写 22 校大门秋）
--     end-photo: 13             # 结尾页 ## 谢谢 {.end}（默认 013 喻家湖上红嘴鸥）
--     photo-order: random       # 多张时：random（打乱后轮换，尽量不重复）/ cycle（按列表顺序轮换）
--     photo-seed: 7             # 固定随机结果；不写则每次渲染不同
--     photo-dir: path/to/web    # 照片目录（相对 qmd）；一般不用写
-- 每个 *-photo 可写：编号（11 / "011"）、none、random（全部照片中随机）、编号列表 [13, 26, 31]（其中随机）
-- 单个分节覆盖：# 标题 {photo="26"} 或 {photo="none"}
--
-- 结尾页右上角的链接卡片（与是否图片模式无关）：
--     end-link: https://...     # 网址（显示为文字，HTML / PDF 中可点击）
--     end-link-label: 使用此模板 # 卡片标题（默认“扫码访问”）
-- 分享图（二维码等，可指向模板仓库、网盘分享链接……）：幻灯片目录或 fig/ 中有 share_enable.png 就放进卡片，没有就不放

local function str(v)
  if v == nil then return nil end
  if type(v) == 'boolean' then return tostring(v) end
  return pandoc.utils.stringify(v)
end

local function norm_id(s)
  local n = tonumber(s)
  return n and string.format('%03d', n) or nil
end

local function read_file(p)
  local f = io.open(p, 'r'); if not f then return nil end
  local s = f:read('*a'); f:close(); return s
end

local function exists_dir(p)
  local ok = pcall(pandoc.system.list_directory, p)
  return ok
end

-- 照片目录：hust.photo-dir > 环境变量 HUST_PHOTO_DIR > 扩展内 photo-dir 文件（new_deck/update_ext 写入）> 模板自身 photos/web
local function photo_dir(cfg)
  local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
  local doc_dir = (quarto and quarto.doc and quarto.doc.input_file) and pandoc.path.directory(quarto.doc.input_file) or '.'
  local cands = {}
  local m = str(cfg['photo-dir'])
  if m and m ~= '' then table.insert(cands, pandoc.path.is_absolute(m) and m or pandoc.path.join({doc_dir, m})) end
  local e = os.getenv('HUST_PHOTO_DIR'); if e and e ~= '' then table.insert(cands, e) end
  local f = read_file(pandoc.path.join({script_dir, 'photo-dir'}))
  if f then f = f:gsub('%s+$', ''); if f ~= '' then table.insert(cands, f) end end
  table.insert(cands, pandoc.path.join({script_dir, '..', '..', 'photos', 'web'}))
  for _, c in ipairs(cands) do if exists_dir(c) then return c end end
  return nil
end

-- 编号 -> {path, credit}；作者从上一级 来源.tsv 读（作品类照片需署名）
local function load_index(dir)
  local idx, ids = {}, {}
  for _, fn in ipairs(pandoc.system.list_directory(dir)) do
    local id = fn:match('^(%d%d%d)_.+%.jpe?g$')
    if id then idx[id] = { path = pandoc.path.join({dir, fn}), credit = '' }; table.insert(ids, id) end
  end
  table.sort(ids)
  local tsv = read_file(pandoc.path.join({dir, '..', '来源.tsv'}))
  if tsv then
    for line in tsv:gmatch('[^\n]+') do
      local cols = {}
      for c in (line .. '\t'):gmatch('([^\t]*)\t') do table.insert(cols, c) end
      if idx[cols[1]] and cols[4] and cols[4] ~= '' then idx[cols[1]].credit = cols[4] end
    end
  end
  return idx, ids
end

local function shuffle(t)
  for i = #t, 2, -1 do local j = math.random(i); t[i], t[j] = t[j], t[i] end
  return t
end

-- 解析一个 *-photo 设置，返回取图函数（每调用一次给出下一张）；nil = 不放照片
local function picker(v, default, idx, all_ids, order)
  local pool = {}
  local function add(s)
    s = str(s)
    if s == nil or s == '' then return end
    s = s:lower()
    if s == 'none' or s == 'false' then return end
    if s == 'random' then for _, id in ipairs(all_ids) do table.insert(pool, id) end; return end
    local id = norm_id(s)
    if id and idx[id] then table.insert(pool, id)
    else quarto.log.warning('[hust] 找不到照片编号：' .. s) end
  end
  if v == nil then v = default end
  if pandoc.utils.type(v) == 'List' then   -- YAML 列表（单个值是 Inlines / string）
    for _, x in ipairs(v) do add(x) end
    if order ~= 'cycle' then shuffle(pool) end
  else
    local s = str(v)
    add(v)
    if s and s:lower() == 'random' then shuffle(pool) end
  end
  if #pool == 0 then return nil end
  local i = 0
  return function() i = i + 1; return idx[pool[(i - 1) % #pool + 1]] end
end

local function img_html(cls, p)
  local credit = (p.credit ~= '') and ('<div class="photo-credit ' .. cls .. '-credit">摄影：' .. p.credit .. '</div>') or ''
  return '<img class="' .. cls .. ' no-frame" src="' .. p.path .. '" alt="" aria-hidden="true">' .. credit
end

local function esc(t) return (t:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;')) end

-- 结尾页链接卡片：插在 ## ... {.end} 之后
local function add_end_link(doc, cfg)
  local url = str(cfg['end-link']); if url == '' then url = nil end
  local doc_dir = (quarto and quarto.doc and quarto.doc.input_file) and pandoc.path.directory(quarto.doc.input_file) or '.'
  local qr
  for _, rel in ipairs({ 'share_enable.png', 'fig/share_enable.png' }) do
    local f = io.open(pandoc.path.join({ doc_dir, rel }), 'rb')
    if f then f:close(); qr = rel; break end
  end
  if not url and not qr then return end
  local label = str(cfg['end-link-label']) or '扫码访问'
  local tag = url and ('<a class="end-link no-frame" href="' .. esc(url) .. '">') or '<div class="end-link no-frame">'
  local html = tag
    .. (qr and ('<img class="end-qr no-frame" src="' .. qr .. '" alt="二维码">') or '')
    .. '<span class="end-link-label">' .. esc(label) .. '</span>'
    .. (url and ('<span class="end-link-url">' .. esc((url:gsub('^https?://', ''))) .. '</span></a>') or '</div>')
  local out = {}
  for _, b in ipairs(doc.blocks) do
    table.insert(out, b)
    if b.t == 'Header' and b.level == 2 and b.classes:includes('end') then table.insert(out, pandoc.RawBlock('html', html)) end
  end
  doc.blocks = out
end

function Pandoc(doc)
  local cfg = doc.meta.hust or {}
  add_end_link(doc, cfg)
  local on = cfg.photos   -- 不写即开启（默认图片模式）
  if on == false or (on ~= nil and on ~= true and str(on):lower() == 'false') then return doc end
  doc.meta['hust-photos'] = true   -- 封面模板据此才内嵌反白校徽（仅图片模式结尾页用）

  local dir = photo_dir(cfg)
  if not dir then quarto.log.warning('[hust] 图片模式已开启，但找不到照片目录（photos/web；运行 tools/fetch_photos.sh 下载）'); return doc end
  local idx, all_ids = load_index(dir)
  local seed = tonumber(str(cfg['photo-seed']) or '')
  math.randomseed(seed or os.time())
  local order = (str(cfg['photo-order']) or 'random'):lower()

  local cover = picker(cfg['cover-photo'], '11', idx, all_ids, order)
  local section = picker(cfg['section-photo'], 'none', idx, all_ids, order)
  local ending = picker(cfg['end-photo'], '13', idx, all_ids, order)

  if cover then
    local p = cover()
    doc.meta['hust-cover-photo'] = pandoc.MetaString(p.path)
    if p.credit ~= '' then doc.meta['hust-cover-credit'] = pandoc.MetaString(p.credit) end
  end

  local out, seen, nseen = {}, {}, 0
  for _, b in ipairs(doc.blocks) do
    table.insert(out, b)
    if b.t == 'Header' and b.level == 1 then
      local own = b.attributes.photo
      local p
      if own then
        local f = picker(own, nil, idx, all_ids, order); p = f and f()
      elseif section then p = section() end
      if p then
        -- 同一张照片只内嵌一次：首次放图并编号，之后的分节页只放引用（脚本按引用取图）
        local ref = seen[p.path]
        if ref then
          table.insert(out, pandoc.RawBlock('html', '<span class="sec-photo-ref" data-ref="' .. ref .. '" hidden></span>'
            .. ((p.credit ~= '') and ('<div class="photo-credit sec-photo-src-credit">摄影：' .. p.credit .. '</div>') or '')))
        else
          nseen = nseen + 1; seen[p.path] = 'sp' .. nseen
          table.insert(out, pandoc.RawBlock('html', (img_html('sec-photo-src', p):gsub('<img ', '<img data-photo-id="sp' .. nseen .. '" ', 1))))
        end
      end
    elseif b.t == 'Header' and b.level == 2 and b.classes:includes('end') and ending then
      table.insert(out, pandoc.RawBlock('html', img_html('end-photo-src', ending())))
    end
  end
  doc.blocks = out
  return doc
end
