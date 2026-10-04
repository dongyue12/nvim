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

    -- 终端里的便捷键
    --
    -- ⚠️ 为什么这里要单独配一遍 jj：
    --   终端里的 shell 处于「终端模式」(t)，而编辑文件时是「插入模式」(i)，
    --   这是两套独立的按键表。config/keymaps.lua 里的 jj 只映射了 i 模式，
    --   所以终端里按 jj 没有任何反应（不是 bug）。
    --   这里给 t 模式也加上，两边手感就一致了。
    --
    -- Esc 退出终端模式 —— 比原生的 <C-\><C-n> 好按
    -- （<C-\> 本身不做映射，见上面 keys 里的说明：它是终端转义前缀）
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出终端模式（回普通模式）" })
    vim.keymap.set("t", "jj", [[<C-\><C-n>]], { desc = "退出终端模式（同 Esc）" })

    -- 彻底结束终端（杀 shell 进程，下次打开是全新的）
    -- 日常开关终端用 <C-\> 就够了，这个只在终端卡住 / 想重置环境时才用
    vim.keymap.set({ "n", "t" }, "<leader>tq", function()
      local has_term = false
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "terminal" then
          has_term = true
          break
        end
      end
      if not has_term then
        vim.notify("当前没有打开的终端", vim.log.levels.INFO)
        return
      end

      local ok, terms = pcall(require, "toggleterm.terminal")
      if not ok then return end
      local id = terms.get_focused_id()
      local term = id and terms.get(id, true)
      if term then
        term:shutdown()
        vim.notify("终端已彻底关闭", vim.log.levels.INFO)
      else
        -- 没聚焦在终端上（比如已经用 <C-\> 关掉了），就整体清理
        for _, t in ipairs(terms.get_all()) do
          t:shutdown()
        end
        vim.notify("已清理全部终端", vim.log.levels.INFO)
      end
    end, { desc = "彻底关闭终端（结束 shell 进程）" })

    -- 窗口切换
    vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<cr>]], { desc = "切到左窗口" })
    vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<cr>]], { desc = "切到下窗口" })
    vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<cr>]], { desc = "切到上窗口" })
    vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<cr>]], { desc = "切到右窗口" })
  end,
}
