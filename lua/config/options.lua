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

-- ── 缩进 ──────────────────────────────────────────────────────
-- 全局默认：4 个空格（Python、Lua 之类的常规写法）
-- C / C++ 单独改成用真正的 tab 缩进，见文件末尾的 FileType 自动命令
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.autoindent = true      -- 新行沿用上一行缩进
opt.smartindent = true     -- 按语法智能缩进

-- 让 tab 和行尾空格「看得见」。
-- list 默认关着（不然满屏都是符号太吵），
-- 需要时随时用 :set list 打开、:set nolist 关掉。
opt.listchars = {
  tab = "▸ ",     -- tab 显示成一个箭头 + 空格（一个 tab = 4 列宽，所以两个字符一组）
  trail = "·",    -- 行尾多余的空格
  nbsp = "␣",     -- 不换行空格
  extends = "›",  -- 行尾被截断
  precedes = "‹", -- 行首被截断
}

-- ── 折行显示但不插入真实换行 ──────────────────────────────────
opt.wrap = true
opt.linebreak = true       -- 在单词边界折行，不切断单词

-- ── 按键等待时间 ──────────────────────────────────────────────
-- timeoutlen 是「多键组合的等待时间」。
-- 因为 <leader>q 既是单键又是 qq 的前缀，太长会觉得单键迟钝；
-- 1000 是默认值，这里缩到 500 平衡一下（想更灵敏可以调到 300）。
opt.timeoutlen = 500
opt.ttimeoutlen = 50       -- 终端按键码的等待时间，保持短

-- ── C / C++ 用真正的 tab 缩进 ─────────────────────────────────
-- 为什么要单独设：
--   全局是 expandtab=true（空格），但 C 代码习惯用 tab。
--   你现有的 C 练习文件（3.hourl.c / 4.sum.c / 7.switch.c 等）
--   本来就是 tab 缩进的，之前也是靠手动敲 tab —— 但会被全局设置
--   转成空格，所以有的文件混进了空格。这里明确按文件类型切过来。
--
-- 各项含义：
--   noexpandtab   按 Tab 键插入真正的 tab 字符，不转成空格
--   tabstop=4     一个 tab 显示成 4 列宽（和你现有文件一致，
--                 不是最常见的 8 —— 因为你的文件就是按 4 列写的，
--                 改成 8 会让现有代码看起来缩进翻倍）
--   shiftwidth=4  自动缩进 / >> << 的宽度 = 1 个 tab
--   softtabstop=0 让 Tab 和 shiftwidth 统一按 tab 走，不插空格
--   list          打开不可见字符显示，这样 tab 会显示成 ▸，
--                 一眼能看出用的是 tab 还是空格
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserIndentC", { clear = true }),
  pattern = { "c", "cpp", "objc", "objcpp", "cuda", "h", "hpp" },
  callback = function()
    -- 缩进相关的都是 buffer 局部选项
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 0
    -- ⚠️ list 是**窗口**选项，不能用 opt_local（会报
    --    "'buf' cannot be passed for window-local option 'list'"），
    --    要用 vim.wo
    vim.wo.list = true
  end,
  desc = "C/C++ 用 tab 缩进，并显示不可见字符",
})

