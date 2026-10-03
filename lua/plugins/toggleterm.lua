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

    -- 内置终端用 PowerShell 7（pwsh）
    -- ⚠️ 必须写完整路径：你装的是 Store 版，pwsh.exe 是个「应用执行别名」，
    --    vim.fn.executable("pwsh") 返回 0，直接写 "pwsh" 会启动失败。
    shell = (vim.env.LOCALAPPDATA or "")
      .. "\\Microsoft\\WindowsApps\\Microsoft.PowerShell_8wekyb3d8bbwe\\pwsh.exe",

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

    -- ── 快速关闭当前终端 ──────────────────────────────────────
    -- 效果：关掉终端窗口但不杀 shell 进程 —— 下次按 <C-\> 打开是
    --       瞬时的，之前敲过的命令和当前目录都还在。
    -- 想彻底结束 shell 用 exit（close_on_exit = true 会自动关窗），
    -- 或者用下面的 <leader>tq。
    local function close_terminal()
      local ok, terms = pcall(require, "toggleterm.terminal")
      local id = ok and terms.get_focused_id() or nil
      local term = id and terms.get(id, true) or nil
      local win = vim.api.nvim_get_current_win()

      if term and term:is_open() then
        -- 先切到别的 buffer。终端窗口不是唯一的窗口时会因此自动关闭，
        -- 也不会留下隐藏的终端 buffer（否则 Neovim 会拦一下说
        -- "Terminal buffer N is still running"）。
        pcall(vim.cmd, "bprevious")
        -- bprevious 没关掉（或本来就是最后一个窗口）时，再显式关一次
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == term.bufnr then
          term:close()
        end
      else
        -- 不在终端里（比如普通分屏），退化成关闭当前窗口
        pcall(vim.cmd, "close")
      end
    end

    -- 终端模式下的便捷键
    -- （终端里按 Esc 回普通模式，避免 <C-\><C-n> 这么绕）
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出终端模式" })

    -- 关闭终端窗口（保留 shell 进程，下次打开还在）
    vim.keymap.set({ "n", "t" }, "<C-q>", close_terminal, { desc = "关闭终端（保留 shell）" })

    -- 彻底结束终端（杀 shell 进程，下次打开是全新的）
    vim.keymap.set({ "n", "t" }, "<leader>tq", function()
      local ok, terms = pcall(require, "toggleterm.terminal")
      if not ok then return end
      local id = terms.get_focused_id()
      local term = id and terms.get(id, true)
      if term then term:shutdown() end
    end, { desc = "彻底关闭终端（结束 shell 进程）" })

    -- 窗口切换
    vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<cr>]], { desc = "切到左窗口" })
    vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<cr>]], { desc = "切到下窗口" })
    vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<cr>]], { desc = "切到上窗口" })
    vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<cr>]], { desc = "切到右窗口" })
  end,
}
