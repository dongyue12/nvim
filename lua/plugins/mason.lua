-- mason : LSP / 格式化工具等的安装管理器
--
-- 用途：不用手动去官网下载 clangd 之类的工具，用 :Mason 面板一键装。
--   :Mason          打开面板（i 装 / X 卸载 / U 更新）
--   :MasonInstall clangd   直接装某个工具
--
-- 装了哪些：
--   clangd                 C / C++ 的 LSP 服务器（补全、跳转、诊断）
--   clang-format           C / C++ 格式化
--
-- 注意：mason 只负责「下载安装」，让 Neovim 用起来还需要
--       lua/plugins/lsp.lua 里的 nvim-lspconfig 接线。

return {
  "mason-org/mason.nvim",
  build = ":MasonUpdate", -- 更新 mason 自己的注册表
  cmd = "Mason",
  keys = {
    { "<leader>cm", "<cmd>Mason<cr>", desc = "打开 Mason（装 LSP / 格式化工具）" },
  },

  opts = {
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  },

  config = function(_, opts)
    require("mason").setup(opts)

    -- 装完工具后自动让 lspconfig 知道（不需要重启 Neovim）
    local mr = require("mason-registry")
    mr:on("package:install:success", function()
      vim.defer_fn(function()
        require("lazy.core.handler.event").trigger({
          event = "LspAttach",
          buf = vim.api.nvim_get_current_buf(),
        })
      end, 100)
    end)

    mr.refresh(function()
      -- 启动时自动补装缺失的工具（已经装了会跳过，不会重复下载）
      for _, tool in ipairs({ "clangd", "clang-format" }) do
        local ok, pkg = pcall(mr.get_package, tool)
        if ok and not pkg:is_installed() then
          pkg:install()
        end
      end
    end)
  end,
}
