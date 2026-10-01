-- tokyonight : 配色主题
-- 换了主题后，`:colorscheme tokyonight` 可临时预览；
-- 想换样式改下面 style 为 storm / night / day，或换 catppuccin。
return {
  "folke/tokyonight.nvim",

  -- 优先级要高：lazy.nvim 会用它作为启动配色，避免先闪一下默认配色
  lazy = false,
  priority = 1000,

  opts = {
    style = "moon",      -- night / storm / moon / day
    transparent = true, -- 想透明背景改 true
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      sidebars = "dark",
      floats = "dark",
    },
    on_highlights = function(hl, c)
      -- 行号列弱化一点，视觉上更清爽（不想要可删）
      hl.LineNr = { fg = c.dark5 }
      hl.CursorLineNr = { fg = c.orange, bold = true }
    end,
  },

  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
