-- 基础选项设置
-- 用 :h option-list 查全部可用选项；:set <选项>? 看当前值
-- 想改某项直接改这里，重开 Neovim 生效

local opt = vim.opt

opt.number = true          -- 行号
opt.relativenumber = false -- 相对行号（想开改 true）
opt.mouse = "a"            -- 鼠标全模式可用
opt.clipboard = "unnamedplus" -- 和系统剪贴板互通（Windows 上直接可用）
opt.ignorecase = true      -- 搜索忽略大小写
opt.smartcase = true       -- 但输入大写时区分大小写
opt.termguicolors = true   -- 真彩色（装主题插件必须开）
opt.signcolumn = "yes"     -- 始终显示符号列，避免文字左右跳动
opt.updatetime = 250       -- 更快触发 CursorHold（诊断/高亮用）
opt.splitright = true      -- 垂直分屏开在右边
opt.splitbelow = true      -- 水平分屏开在下边
opt.scrolloff = 4          -- 光标上下至少留 4 行

-- 缩进：4 空格（写 Python 的话这个正合适；写 Go 建议改 tabstop=4 且 expandtab=false）
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

-- 折行显示但不插入真实换行
opt.wrap = true
opt.linebreak = true
