-- toggleterm : 内置终端（浮动 / 分屏都能开）
-- 官方说明：Neovim 0.7+，建议用 version = "*" 跟当前大版本
return {
  "akinsho/toggleterm.nvim",
  version = "*",

  -- 敲 :ToggleTerm 才加载，或按下面的快捷键触发
  cmd = { "ToggleTerm", "TermExec" },
  --
  -- ⚠️ <C-\> 的 mode 只保留 n 和 i，**故意不含 t**：
  --   在终端模式里 <C-\> 是 Neovim 的「转义前缀」，
  --   原生的 <C-\><C-n> 用来退出终端模式回普通模式。
  --   一旦在 t 模式把它映射成开关终端，这条逃生通道就断了，
  --   人会卡在终端里出不来（踩过这个坑）。
  --   终端里想关终端，用 <C-\><C-n> 之后 :q，或者 <C-q>、<leader>tq。
  keys = {
    { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "开关终端", mode = { "n", "i" } },
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

    -- ── 安全关闭当前终端 ──────────────────────────────────────
    -- 设计原则：**绝不把人困住**。
    --   如果终端窗口关了之后没有别的地方可去（它是唯一窗口），
    --   那就宁可不关，只退出终端模式，也不留一个死局。
    --
    -- 关窗但保留 shell 进程，所以下次打开是瞬时的、历史还在。
    local function close_terminal()
      local cur_win = vim.api.nvim_get_current_win()
      local cur_buf = vim.api.nvim_get_current_buf()
      local is_term = vim.bo[cur_buf].buftype == "terminal"

      -- 先确保退出终端输入模式，否则后面 wincmd 可能不生效
      if vim.api.nvim_get_mode().mode == "t" then
        vim.cmd("stopinsert")
      end

      -- 找另一个「非终端」的普通窗口
      local target
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= cur_win then
          local b = vim.api.nvim_win_get_buf(win)
          if vim.bo[b].buftype == "" then
            target = win
            break
          end
        end
      end

      if target then
        -- 有地方可去：切过去，再关掉终端窗口
        vim.api.nvim_set_current_win(target)
        if vim.api.nvim_win_is_valid(cur_win) then
          pcall(vim.api.nvim_win_close, cur_win, false)
        end
      elseif #vim.api.nvim_list_wins() > 1 then
        -- 只剩终端和其它非普通窗口（比如文件树）：关掉当前窗口就行
        pcall(vim.api.nvim_win_close, cur_win, false)
      else
        -- 终端是唯一窗口 —— 关了就没地方去了，只退出终端模式并提示
        vim.cmd("stopinsert")
        vim.notify(
          "终端是当前唯一窗口，已退出终端模式。\n再按 <C-q> 一次就会关闭它。",
          vim.log.levels.INFO
        )
      end
    end

    -- 终端里的便捷键
    -- Esc 退出终端模式 —— 比原生的 <C-\><C-n> 好按
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出终端模式（回普通模式）" })

    -- Ctrl+q 关闭终端窗口（关两次可关掉唯一窗口）
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
