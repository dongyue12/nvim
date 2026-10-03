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
-- 问题：打开文件树后输入 :q 只是关掉「当前窗口」，而文件树是独立窗口，
--       所以树还在，得再输一次 :q 才真正退出。
-- 解决：判断「当前是不是只剩文件树这一个窗口了」——
--       是  -> 整体退出 Neovim
--       不是 -> 正常关闭当前窗口（和原来的 :q 行为一致）
-- 用 nvim-tree 自带的 is_nvim_tree_buf 判断，比手写 filetype 比对可靠。
map("n", "<leader>q", function()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local only_tree_left = true

  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    local ok, utils = pcall(require, "nvim-tree.utils")
    local is_tree = ok and utils.is_nvim_tree_buf(buf) or (vim.bo[buf].filetype == "NvimTree")
    if not is_tree then
      only_tree_left = false
      break
    end
  end

  if only_tree_left then
    vim.cmd("quitall") -- 只剩树了，整个退出
  else
    vim.cmd("quit") -- 还有正常窗口，就关当前这个
  end
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