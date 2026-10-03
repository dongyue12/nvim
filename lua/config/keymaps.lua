-- 全局快捷键。leader 是空格（在 init.lua 里设置）
local map = vim.keymap.set

-- ── 移动：h/j/k/l 当方向键用 ──────────────────────────────────
-- h/j/k/l 本来就是 Vim 的方向键，这里把它们映射到真正的方向键。
-- 实测结论：Neovim 对「映射到方向键」有特殊处理，会继承 j/k/h/l 的完整语义，
-- 所以数字前缀照样有效（5j = 下移 5 行），行首/行尾等行为也不变，无任何损失。
map({ "n", "v", "o" }, "h", "<Left>",  { desc = "左移" })
map({ "n", "v", "o" }, "j", "<Down>",  { desc = "下移" })
map({ "n", "v", "o" }, "k", "<Up>",    { desc = "上移" })
map({ "n", "v", "o" }, "l", "<Right>", { desc = "右移" })

-- 光标按屏幕行移动（折行时更符合直觉）
map({ "n", "v" }, "gj", "j", { desc = "下移（屏幕行）" })
map({ "n", "v" }, "gk", "k", { desc = "上移（屏幕行）" })

-- ── 保存 / 退出 ───────────────────────────────────────────────
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<cr>", { desc = "保存文件" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "退出全部" })

-- ── 复制当前文件路径 ──────────────────────────────────────────
-- 路径修饰符速查（:h filename-modifiers）：
--   %:p    完整路径        %:p:h  所在目录        %:t    文件名
--   %:.    相对当前目录    %:~    相对 home        %:t:r  文件名（去扩展名）
--
-- 都走系统剪贴板（+ 寄存器）。你的 clipboard 已经是 unnamedplus，
-- 所以 y / p 本来就走系统剪贴板，这里是显式指定，更稳。
local function copy_path(expr, label, empty_msg)
  local value = vim.fn.expand(expr)
  -- 空 buffer / 文件树 / 终端等没有文件名的场合，提示一下而不是复制空字符串
  if value == nil or value == "" then
    vim.notify(empty_msg or "当前 buffer 没有文件路径", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", value) -- 系统剪贴板
  vim.fn.setreg('"', value) -- 无名寄存器，方便 p 粘贴
  vim.notify(label .. "：\n" .. value, vim.log.levels.INFO)
end

map("n", "<leader>yp", function()
  copy_path("%:p", "已复制完整路径")
end, { desc = "复制完整路径" })

map("n", "<leader>yd", function()
  copy_path("%:p:h", "已复制所在目录")
end, { desc = "复制所在目录" })

map("n", "<leader>yn", function()
  copy_path("%:t", "已复制文件名")
end, { desc = "复制文件名" })

map("n", "<leader>yr", function()
  copy_path("%:.", "已复制相对路径")
end, { desc = "复制相对路径" })

-- 想在插入模式直接插入路径的话，取消下面注释。
-- 注意会覆盖插入模式 <C-l>（原本是「光标右移」，比较常用），
-- 所以默认不启用；也可以换成别的键，比如 <C-g>p。
-- map("i", "<C-l>", function()
--   local value = vim.fn.expand("%:p")
--   if value ~= "" then
--     vim.api.nvim_put({ value }, "c", true, true)
--   end
-- end, { desc = "插入当前文件完整路径" })

-- ── 插入模式下移动光标（不用先按 Esc）─────────────────────────
-- 痛点：编辑到一半想挪光标，得 Esc -> 移动 -> 再 i，很打断思路。
--
-- 统一用 Alt 组合，手不用离开主键区：
--   Alt+h / Alt+l    左 / 右
--   Alt+j / Alt+k    下 / 上
--   Alt+a / Alt+e    行首 / 行尾
--
-- ⚠️ Alt 键依赖终端把转义序列正确传给 Neovim。
--    WezTerm 是支持的（已实测 Alt+h 能收到 <M-h>）。
--    如果哪天换成不支持的终端，这几个键会没反应 —— 那就用回方向键
--    （方向键在插入模式本来就能直接移动），或取消下面注释启用 Ctrl 版本。

map("i", "<A-h>", "<Left>",  { desc = "左移（插入模式）" })
map("i", "<A-j>", "<Down>",  { desc = "下移（插入模式）" })
map("i", "<A-k>", "<Up>",    { desc = "上移（插入模式）" })
map("i", "<A-l>", "<Right>", { desc = "右移（插入模式）" })
map("i", "<A-a>", "<Home>",  { desc = "跳到行首（插入模式）" })
map("i", "<A-e>", "<End>",   { desc = "跳到行尾（插入模式）" })

-- 备用：Ctrl 版本（单字节控制字符，任何终端都可靠）。
-- 需要时把下面整段取消注释。
-- 注意不要用 <C-h> / <C-j>：它们在 Neovim 内部就是 <BS> 和 <NL>，
-- 覆盖会破坏退格和换行。
-- map("i", "<C-k>", "<Up>",    { desc = "上移（插入模式）" })
-- map("i", "<C-l>", "<Right>", { desc = "右移（插入模式）" })
-- map("i", "<C-a>", "<Home>",  { desc = "跳到行首（插入模式）" })
-- map("i", "<C-e>", "<End>",   { desc = "跳到行尾（插入模式）" })

-- jj = 退出插入模式（比按 Esc 顺手，手指不用离开主键区）
-- 为什么安全：正常打字里几乎不会出现连续两个 j（"jj" 这种拼写很罕见）。
-- 如果你打中文拼音或某些语言会出现连续 j，把下面这行注释掉即可。
-- 想要更保守可以换成 "jk"。
map("i", "jj", "<Esc>", { desc = "退出插入模式" })

-- 智能退出
-- 目标：输入 :q 就把 Neovim 一次退干净，不用重复输。
--
-- 规则（按顺序判断）：
--   1) 有未保存改动（含其它标签页）      -> 拦住，什么都不关（防止丢工作）
--   2) 当前标签页「没东西可编辑了」      -> 整体退出
--      （只剩文件树，或只剩启动时那个空白 buffer —— 后者才是最常见的坑：
--        打开文件时窗口被顶替，关掉文件后剩下的是空白窗口，看着像卡住）
--   3) 有多个标签页                      -> 整体退出
--   4) 其它情况（还有真实文件窗口）      -> 只关当前窗口，和原生 :q 一致
--
-- 实现注意：
--   - force = true 才能覆盖内置命令
--   - 声明 nargs/range/bang，否则 :q!、:1q、:q a.txt 这类用法会失效
--   - 第 1 条是安全底线：宁可多问一次，也不能悄悄退掉没保存的东西

-- 收集所有「已加载且有未保存改动」的 buffer，跨标签页
local function unsaved_buffers()
  local bad = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      table.insert(bad, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"))
    end
  end
  return bad
end

-- 这个 buffer 是不是「空的无名 scratch」
-- Neovim 启动时自带一个这种 buffer；nvim-tree 也用它做占位。
-- 关掉文件后如果只剩它，界面上就是个空白窗口，看着像卡住了 —— 应该一起退掉。
local function is_blank(buf)
  return vim.api.nvim_buf_get_name(buf) == ""
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].filetype == ""
    and not vim.bo[buf].modified
end

-- 当前标签页里是不是只剩「文件树 + 空窗口」这类没有实际内容的窗口
-- 判断依据：没有任何一个窗口承载着真实的文件
local function nothing_to_edit_in_tab()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(w)
    local ok, utils = pcall(require, "nvim-tree.utils")
    local is_tree = ok and utils.is_nvim_tree_buf(buf) or (vim.bo[buf].filetype == "NvimTree")
    if not is_tree and not is_blank(buf) then
      return false -- 有个真实文件窗口，不能退
    end
  end
  return true
end

local function smart_quit(bang)
  -- bang(:q!) 表示「我知道自己在干什么」，直接按原生语义走
  if bang then
    vim.cmd("quit!")
    return
  end

  -- 1) 有未保存改动 -> 交给原生 quit 报 E37，用户自己决定保存还是加 !
  local bad = unsaved_buffers()
  if #bad > 0 then
    vim.cmd("quit")
    return
  end

  -- 2) 没东西可编辑了（只剩树 / 空窗口），或开了多个标签页 -> 一次退干净
  if nothing_to_edit_in_tab() or #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("quitall")
    return
  end

  -- 3) 普通情况：关当前窗口
  vim.cmd("quit")
end

vim.api.nvim_create_user_command("Q", function(opts)
  smart_quit(opts.bang)
end, {
  desc = "智能退出（没未保存改动时一次退干净）",
  nargs = "*",
  range = true,
  bang = true,
  force = true,
})

-- <leader>q 保留作为备用（比如 :q 被别的插件抢走时）
map("n", "<leader>q", function()
  smart_quit(false)
end, { desc = "智能退出（只剩文件树时整体退出）" })

-- 取消搜索高亮
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "取消搜索高亮" })

-- ── 分屏 ──────────────────────────────────────────────────────
-- 创建分屏
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "左右分屏" })
map("n", "<leader>sh", "<cmd>split<cr>",  { desc = "上下分屏" })

-- 关闭分屏
--   <leader>sc 只关当前这个分屏（有未保存改动会被拦住）
--   <leader>sx 只保留当前分屏，关掉其它所有
--   注意不要用 <leader>so —— 那个已经是「数字排序」了
map("n", "<leader>sc", "<cmd>close<cr>", { desc = "关闭当前分屏" })
map("n", "<leader>sx", "<cmd>only<cr>",  { desc = "只保留当前分屏" })

-- ── 窗口间切换 ────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "切到左窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "切到下窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "切到上窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "切到右窗口" })

-- 窗口大小调整
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "加高窗口" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "减矮窗口" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "缩窄窗口" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "加宽窗口" })

-- ── buffer 切换（顶部标签）────────────────────────────────────
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "下一个 buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "上一个 buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "关闭当前 buffer" })

-- 可视化模式下缩进后保持选中
map("v", "<", "<gv", { desc = "左缩进" })
map("v", ">", ">gv", { desc = "右缩进" })

-- 移动选中行
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "下移选中行" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "上移选中行" })

-- ── 排序 ──────────────────────────────────────────────────────
-- Vim 的 :sort 默认按「字典序」，所以文件名带数字前缀时会乱：
--   1.a  10.b  11.c  2.e    <- 默认 :sort 的结果（10 排在 2 前面）
-- 数字开头要按数值排，必须加 n：
--   1.a  2.e  10.b  11.c    <- :sort n 的结果
-- 本机版本不支持 :sort natural（试过，会报 E474）。
--
-- 用 :'<,'>sort n 手动排序，或选中行后按下面的键
map("v", "<leader>so", ":sort n<cr>", { desc = "数字排序（选中行）" })
map("v", "<leader>sO", ":sort<cr>", { desc = "字典排序（选中行）" })

-- ── 文件树 nvim-tree ──────────────────────────────────────────
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "开关文件树" })
map("n", "<leader>o", "<cmd>NvimTreeFocus<cr>", { desc = "聚焦文件树" })