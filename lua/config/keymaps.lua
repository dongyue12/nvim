-- 全局快捷键。leader 是空格（在 init.lua 里设置）
--
-- 按键从哪来：
--   · 这个文件      全局快捷键（移动、编辑、窗口、分屏、buffer）
--   · plugins/*.lua 插件自己的 keys 字段（nvim-tree / bufferline / toggleterm）
--   · config/quit.lua  智能退出（:q 的替换逻辑）
--   · 输入 :Help 查看完整速查表（内容读自实际映射，不会过期）

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

-- ── 保存 ──────────────────────────────────────────────────────
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<cr>", { desc = "保存文件" })

-- 取消搜索高亮
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "取消搜索高亮" })

-- ── 退出（逻辑在 config/quit.lua，这里只注册按键）──────────────
-- :q 本身已被替换成智能退出；<leader>q 是备用入口
-- （万一以后某个插件抢走了 :q，还能用这个键）
map("n", "<leader>q", function()
  require("config.quit").smart_quit(false)
end, { desc = "智能退出（没未保存改动时一次退干净）" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "退出全部（无条件）" })

-- ── 复制当前文件路径 ──────────────────────────────────────────
-- 路径修饰符速查（:h filename-modifiers）：
--   %:p    完整路径        %:p:h  所在目录        %:t    文件名
--   %:.    相对当前目录    %:~    相对 home        %:t:r  文件名（去扩展名）
--
-- 都走系统剪贴板（+ 寄存器）。clipboard 已是 unnamedplus，
-- 所以 y / p 本来就走系统剪贴板，这里显式指定，更稳。
local function copy_path(expr, label)
  local value = vim.fn.expand(expr)
  -- 空 buffer / 文件树 / 终端等没有文件名的场合，提示一下而不是复制空字符串
  if value == nil or value == "" then
    vim.notify("当前 buffer 没有文件路径", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", value) -- 系统剪贴板
  vim.fn.setreg('"', value) -- 无名寄存器，方便 p 粘贴
  vim.notify(label .. "：\n" .. value, vim.log.levels.INFO)
end

map("n", "<leader>yp", function() copy_path("%:p", "已复制完整路径") end, { desc = "复制完整路径" })
map("n", "<leader>yd", function() copy_path("%:p:h", "已复制所在目录") end, { desc = "复制所在目录" })
map("n", "<leader>yn", function() copy_path("%:t", "已复制文件名") end, { desc = "复制文件名" })
map("n", "<leader>yr", function() copy_path("%:.", "已复制相对路径") end, { desc = "复制相对路径" })

-- ── 插入模式下移动光标（不用先按 Esc）─────────────────────────
-- 痛点：编辑到一半想挪光标，得 Esc -> 移动 -> 再 i，很打断思路。
--
--   Alt+h / Alt+l    左 / 右
--   Alt+j / Alt+k    下 / 上
--   Alt+a / Alt+e    行首 / 行尾
--
-- ⚠️ Alt 键依赖终端把转义序列正确传给 Neovim。WezTerm 支持。
--    换到不支持的终端时这几个键会没反应 —— 那就用方向键
--    （插入模式本来就能直接用方向键），或启用下面注释里的 Ctrl 版本。
map("i", "<A-h>", "<Left>",  { desc = "左移（插入模式）" })
map("i", "<A-j>", "<Down>",  { desc = "下移（插入模式）" })
map("i", "<A-k>", "<Up>",    { desc = "上移（插入模式）" })
map("i", "<A-l>", "<Right>", { desc = "右移（插入模式）" })
map("i", "<A-a>", "<Home>",  { desc = "跳到行首（插入模式）" })
map("i", "<A-e>", "<End>",   { desc = "跳到行尾（插入模式）" })

-- 备用：Ctrl 版本（单字节控制字符，任何终端都可靠）
-- ⚠️ 不要用 <C-h> / <C-j>：它们内部就是 <BS> 和 <NL>，覆盖会破坏退格和换行
-- map("i", "<C-k>", "<Up>",    { desc = "上移（插入模式）" })
-- map("i", "<C-l>", "<Right>", { desc = "右移（插入模式）" })
-- map("i", "<C-a>", "<Home>",  { desc = "跳到行首（插入模式）" })
-- map("i", "<C-e>", "<End>",   { desc = "跳到行尾（插入模式）" })

-- jj = 退出插入模式（比按 Esc 顺手，手指不用离开主键区）
-- 正常打字几乎不会出现连续两个 j；若你打拼音会出现，注释掉这行或改成 "jk"
map("i", "jj", "<Esc>", { desc = "退出插入模式" })

-- ── 命令行模式（输入框里）的移动 ──────────────────────────────
-- 为什么需要：重命名文件、:s/.../ 等弹出的输入框走的是「命令行模式」(c)，
-- 和插入模式(i)是两套按键表。光映射插入模式的话，在这些输入框里
-- Alt+hjkl 是不生效的 —— 本文件上面的插入模式映射管不到这里。
--
-- 这里补上同样的 Alt 组合，让两种输入场景手感一致：
--   Alt+h / Alt+l    左 / 右
--   Alt+j / Alt+k    下 / 上（命令行只有一行，实际等同无效，保留是为了手感统一）
--   Alt+a / Alt+e    行首 / 行尾
map("c", "<A-h>", "<Left>",  { desc = "左移（输入框）" })
map("c", "<A-l>", "<Right>", { desc = "右移（输入框）" })
map("c", "<A-a>", "<Home>",  { desc = "跳到行首（输入框）" })
map("c", "<A-e>", "<End>",   { desc = "跳到行尾（输入框）" })
map("c", "<A-k>", "<Home>",  { desc = "跳到行首（输入框）" })
map("c", "<A-j>", "<End>",   { desc = "跳到行尾（输入框）" })

-- 删词的常用键（命令行里按 Ctrl+W 删掉光标前一个词，改路径时很好用）
map("c", "<C-w>", "<C-w>", { desc = "删掉前面一个词（输入框）" })

-- 命令行模式的其它常用原生键（不需要映射，这里只作记录）：
--   Ctrl+A / Ctrl+E   行首 / 行尾
--   Ctrl+B / Ctrl+F   左移 / 右移一个字符（不是翻页）
--   Ctrl+W            删掉前面一个词
--   Ctrl+U            删到行首
--   Ctrl+Left/Right   按词移动
--   方向键 / Home / End  都能用

-- ── 分屏 ──────────────────────────────────────────────────────
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "左右分屏" })
map("n", "<leader>sh", "<cmd>split<cr>",  { desc = "上下分屏" })
map("n", "<leader>sc", "<cmd>close<cr>",  { desc = "关闭当前分屏" })
map("n", "<leader>sx", "<cmd>only<cr>",   { desc = "只保留当前分屏" })

-- 窗口间切换 / 调整大小
map("n", "<C-h>", "<C-w>h", { desc = "切到左窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "切到下窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "切到上窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "切到右窗口" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "加高窗口" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "减矮窗口" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "缩窄窗口" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "加宽窗口" })

-- ── buffer 切换（顶部标签）────────────────────────────────────
-- 完整的开关/跳转键在 plugins/bufferline.lua，这里是常用补充
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "下一个 buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "上一个 buffer" })

-- ── 缩进与移动选中行 ──────────────────────────────────────────
map("v", "<", "<gv", { desc = "左缩进" })
map("v", ">", ">gv", { desc = "右缩进" })
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "下移选中行" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "上移选中行" })

-- ── 排序 ──────────────────────────────────────────────────────
-- Vim 的 :sort 默认按「字典序」，文件名带数字前缀时会乱：
--   1.a  10.b  11.c  2.e    <- 默认 :sort 的结果（10 排在 2 前面）
-- 数字开头要按数值排，必须加 n：
--   1.a  2.e  10.b  11.c    <- :sort n 的结果
-- 本机版本不支持 :sort natural（试过，会报 E474）。
map("v", "<leader>so", ":sort n<cr>", { desc = "数字排序（选中行）" })
map("v", "<leader>sO", ":sort<cr>", { desc = "字典排序（选中行）" })
