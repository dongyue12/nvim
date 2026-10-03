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

-- 智能退出
-- 目标：输入 :q 就把 Neovim 一次退干净，不用重复输。
--
-- 规则（按顺序判断）：
--   1) 有未保存改动（含其它标签页）        -> 拦住，什么都不关（防止丢工作）
--   2) 当前标签页只剩文件树                -> 整体退出
--   3) 有多个标签页                        -> 整体退出（这就是本次新增的）
--   4) 其它情况（单标签、还有文件窗口）    -> 只关当前窗口，和原生 :q 一致
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

-- 当前标签页是不是只剩文件树窗口
local function only_tree_in_tab()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(w)
    -- 用 nvim-tree 自带判断，没有插件时退回 filetype 比对
    local ok, utils = pcall(require, "nvim-tree.utils")
    local is_tree = ok and utils.is_nvim_tree_buf(buf) or (vim.bo[buf].filetype == "NvimTree")
    if not is_tree then
      return false
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

  -- 2)/3) 只剩树，或开了多个标签页 -> 一次退干净
  if only_tree_in_tab() or #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("quitall")
    return
  end

  -- 4) 普通情况：关当前窗口
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

-- ── 文件树 nvim-tree ──────────────────────────────────────────
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "开关文件树" })
map("n", "<leader>o", "<cmd>NvimTreeFocus<cr>", { desc = "聚焦文件树" })