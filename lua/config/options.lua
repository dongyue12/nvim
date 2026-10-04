-- 基础选项设置
-- 用 :h option-list 查全部可用选项；:set <选项>? 看当前值
-- 想改某项直接改这里，重开 Neovim 生效

local opt = vim.opt

-- ── 界面 ──────────────────────────────────────────────────────
opt.number = true          -- 行号
opt.relativenumber = false -- 相对行号（想开改 true）
opt.signcolumn = "yes"     -- 始终显示符号列，避免文字左右跳动
opt.termguicolors = true   -- 真彩色（装主题插件必须开）
opt.laststatus = 2         -- 每个窗口都有状态栏
opt.showmode = false       -- 不在底部重复显示 -- INSERT --（状态栏已经够了）
opt.cursorline = false     -- 高亮当前行（想开改 true）

-- ── 编辑手感 ──────────────────────────────────────────────────
opt.mouse = "a"            -- 鼠标全模式可用
opt.clipboard = "unnamedplus" -- 和系统剪贴板互通（Windows 上直接可用）
opt.updatetime = 250       -- 更快触发 CursorHold（诊断/高亮用）
opt.scrolloff = 8          -- 光标上下至少留 8 行（翻页后能看见上下文）
opt.sidescrolloff = 8      -- 光标左右也留 8 列（长行横向滚动时不贴边）

-- 搜索
opt.ignorecase = true      -- 忽略大小写
opt.smartcase = true       -- 但输入大写时区分大小写
opt.hlsearch = true        -- 高亮搜索结果（按 Esc 取消高亮）
opt.incsearch = true       -- 边输入边预览匹配

-- 分屏
opt.splitright = true      -- 垂直分屏开在右边
opt.splitbelow = true      -- 水平分屏开在下边

-- ── 撤销历史持久化 ────────────────────────────────────────────
-- 开了之后，关掉文件再打开仍然能 u 撤销（历史存在 nvim-data/undo 下）。
-- 目录要先建好，否则 Vim 会报 E5108 之类写不进去。
opt.undofile = true
opt.undolevels = 10000     -- 撤销层数（默认 1000，调大点）
opt.undoreload = 10000

local undodir = vim.fn.stdpath("data") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
opt.undodir = undodir

-- ── 缩进：4 空格 ──────────────────────────────────────────────
-- 写 Python / C 都合适；写 Go 建议 tabstop=8 且 expandtab=false
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.autoindent = true      -- 新行沿用上一行缩进
opt.smartindent = true     -- 按语法智能缩进

-- ── 折行显示但不插入真实换行 ──────────────────────────────────
opt.wrap = true
opt.linebreak = true       -- 在单词边界折行，不切断单词

-- ── 按键等待时间 ──────────────────────────────────────────────
-- timeoutlen 是「多键组合的等待时间」。
-- 因为 <leader>q 既是单键又是 qq 的前缀，太长会觉得单键迟钝；
-- 1000 是默认值，这里缩到 500 平衡一下（想更灵敏可以调到 300）。
opt.timeoutlen = 500
opt.ttimeoutlen = 50       -- 终端按键码的等待时间，保持短
