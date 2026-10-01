-- 全局快捷键。leader 是空格（在 init.lua 里设置）
local map = vim.keymap.set

-- 光标按屏幕行移动（折行时更符合直觉）
map({ "n", "v" }, "gj", "j", { desc = "下移（屏幕行）" })
map({ "n", "v" }, "gk", "k", { desc = "上移（屏幕行）" })

-- ── 保存 / 退出 ───────────────────────────────────────────────
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<cr>", { desc = "保存文件" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "退出全部" })

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
