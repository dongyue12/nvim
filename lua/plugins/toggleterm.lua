-- toggleterm : 内置终端（浮动 / 分屏都能开）
-- 官方说明：Neovim 0.7+，建议用 version = "*" 跟当前大版本
return {
  "akinsho/toggleterm.nvim",
  version = "*",

  -- 敲 :ToggleTerm 才加载，或按下面的快捷键触发
  cmd = { "ToggleTerm", "TermExec" },
  keys = {
    { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "开关终端", mode = { "n", "t", "i" } },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "浮动终端" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "横向终端" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=60<cr>", desc = "纵向终端" },
  },

  opts = {
    size = 15,          -- 分屏终端高度/宽度
    open_mapping = nil, -- 关掉插件自带的 <C-\>，用上面 keys 里那份（带 desc 便于 :which-key 查看）
    hide_numbers = true,
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,   -- 打开终端直接进插入模式
    persist_size = true,
    direction = "horizontal", -- 默认方向：horizontal / vertical / float / tab
    close_on_exit = true,     -- shell 退出后自动关窗
    shell = vim.o.shell,      -- 用系统默认 shell（Windows 上是 pwsh/cmd）

    -- 浮动终端的外观
    float_opts = {
      border = "rounded",
      width = function() return math.floor(vim.o.columns * 0.9) end,
      height = function() return math.floor(vim.o.lines * 0.85) end,
      winblend = 0,
      title_pos = "center",
    },
  },

  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- 终端模式下的便捷键（终端里按 Esc 回普通模式，避免 <C-\><C-n> 这么绕）
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出终端模式" })
    vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<cr>]], { desc = "切到左窗口" })
    vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<cr>]], { desc = "切到下窗口" })
    vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<cr>]], { desc = "切到上窗口" })
    vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<cr>]], { desc = "切到右窗口" })
  end,
}
