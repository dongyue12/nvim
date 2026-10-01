-- bufferline : 顶部显示打开的 buffer（标签页）
-- Neovim 0.8+；需要 nvim-web-devicons 显示文件图标
return {
  "akinsho/bufferline.nvim",
  version = "*", -- 官方建议：跟当前大版本的 tag，避免 breaking change

  -- 有文件打开后才加载，不拖慢启动
  event = "VeryLazy",

  dependencies = { "nvim-tree/nvim-web-devicons" },

  keys = {
    { "<leader>bn", "<cmd>BufferLineCycleNext<cr>", desc = "下一个 buffer" },
    { "<leader>bp", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个 buffer" },
    { "<leader>bd", "<cmd>bdelete<cr>", desc = "关闭当前 buffer" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "关闭其它 buffer" },
    { "<leader>bl", "<cmd>BufferLineCloseRight<cr>", desc = "关闭右侧 buffer" },
    { "<leader>bh", "<cmd>BufferLineCloseLeft<cr>", desc = "关闭左侧 buffer" },
  },

  opts = {
    options = {
      mode = "buffers",       -- 显示 buffer 而不是 tab（更符合日常习惯）
      numbers = "ordinal",    -- 标签上显示序号，可用 <leader>1..9 跳转
      close_command = "bdelete! %d",
      diagnostics = "nvim_lsp", -- 标签上显示 LSP 诊断图标
      diagnostics_indicator = function(_, _, diag)
        local icons = { error = " ", warning = " " }
        local ret = (diag.error and icons.error .. diag.error .. " " or "")
          .. (diag.warning and icons.warning .. diag.warning or "")
        return vim.trim(ret)
      end,
      offsets = {
        -- 让 bufferline 避开左侧的 nvim-tree，否则会重叠
        {
          filetype = "NvimTree",
          text = "文件树",
          highlight = "Directory",
          text_align = "left",
          separator = true,
        },
      },
      show_buffer_close_icons = true,
      show_close_icon = false,
      separator_style = "thin",
      always_show_bufferline = false,
    },
  },

  -- 数字快捷键：<leader>1 跳到第 1 个 buffer，依此类推
  config = function(_, opts)
    require("bufferline").setup(opts)
    for i = 1, 9 do
      vim.keymap.set("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<cr>",
        { desc = "跳到第 " .. i .. " 个 buffer" })
    end
  end,
}
