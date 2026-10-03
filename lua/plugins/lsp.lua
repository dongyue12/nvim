-- LSP 接线：nvim-lspconfig
--
-- 分工：
--   mason.nvim     负责「下载安装」LSP 服务器（如 clangd）
--   lspconfig      负责「告诉 Neovim 怎么启动它」← 本文件
--   blink.cmp      负责「补全菜单」← lua/plugins/blink.lua
--
-- 目前配了哪些语言：
--   C / C++     clangd（由 mason 装好）
--
-- 加别的语言：在下面的 servers 表里加一项，例如
--   pyright = {}        -- Python（先 :MasonInstall pyright）
--   lua_ls = {}         -- Lua
--   rust_analyzer = {}  -- Rust（需先装 rustup）

return {
  "neovim/nvim-lspconfig",
  -- 打开这些文件类型时才加载，不拖慢启动
  ft = { "c", "cpp", "objc", "objcpp", "cuda" },
  dependencies = {
    "mason-org/mason.nvim",
    "saghen/blink.cmp",
  },

  config = function()
    -- ── 通用按键（只在有 LSP 的 buffer 里生效）────────────────
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local function map(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
        end
        local buf = vim.lsp.buf

        map("gd", buf.definition, "跳转到定义")
        map("gD", buf.declaration, "跳转到声明")
        map("gr", buf.references, "查看所有引用")
        map("gi", buf.implementation, "跳转到实现")
        map("gt", buf.type_definition, "跳转到类型定义")
        map("K", vim.lsp.buf.hover, "查看文档")
        map("<leader>lr", buf.rename, "重命名符号")
        map("<leader>la", vim.lsp.buf.code_action, "代码操作（快速修复）")
        map("<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, "格式化")
        map("<leader>ld", vim.diagnostic.open_float, "查看当前行诊断")
        map("[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, "上一个诊断")
        map("]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, "下一个诊断")
      end,
    })

    -- ── 诊断显示方式 ──────────────────────────────────────────
    vim.diagnostic.config({
      virtual_text = { prefix = "●", spacing = 2 },
      severity_sort = true,
      float = { border = "rounded", source = true },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "E",
          [vim.diagnostic.severity.WARN] = "W",
          [vim.diagnostic.severity.INFO] = "I",
          [vim.diagnostic.severity.HINT] = "H",
        },
      },
    })

    -- ── 把 blink.cmp 的补全能力交给所有 LSP ───────────────────
    local caps = require("blink.cmp").get_lsp_capabilities()

    -- ── 顺带把 mason 的 bin 注入 PATH ─────────────────────────
    -- 方便用 clang-format 等工具；mason 自己不会永久写系统 PATH。
    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
    if vim.fn.isdirectory(mason_bin) == 1 then
      local path = vim.env.PATH or ""
      if not path:lower():find("mason", 1, true) then
        vim.env.PATH = mason_bin .. ";" .. path
      end
    end

    -- ── 找 clangd 的绝对路径 ──────────────────────────────────
    -- 为什么不用裸命令 "clangd"：
    --   实测 vim.fn.executable("clangd") == 0 —— mason 装的东西不在系统 PATH 里。
    --   显式给绝对路径，不依赖 lspconfig 内部的 PATH 注入（那个机制比较隐晦）。
    local function find_clangd()
      local data = vim.fn.stdpath("data")
      -- 1) 真正的 exe（mason 的 packages 目录，版本号在路径里所以要 glob）
      local hits = vim.fn.glob(data .. "/mason/packages/clangd/clangd_*/bin/clangd.exe", false, true)
      if #hits > 0 then
        return hits[1]
      end
      -- 2) mason 的 shim（.cmd）
      local shim = data .. "/mason/bin/clangd.cmd"
      if vim.fn.filereadable(shim) == 1 then
        return shim
      end
      -- 3) 兜底：系统 PATH 里另有 clangd（例如自己装过 LLVM）
      if vim.fn.executable("clangd") == 1 then
        return "clangd"
      end
      return nil
    end

    -- ── 每个 LSP 服务器的配置 ─────────────────────────────────
    -- 用 vim.lsp.config（Neovim 0.11+ 写法）。注意它是「可调用表」，
    -- type() 返回 "table"，但能直接当函数调用。
    local servers = {}

    local clangd_path = find_clangd()
    if clangd_path then
      servers.clangd = {
        cmd = {
          clangd_path,
          "--background-index",          -- 后台建索引，跳转更准
          "--clang-tidy",                -- 静态检查
          "--completion-style=detailed", -- 补全带函数签名
          "--header-insertion=iwyu",     -- 补全时自动插头文件
          "--fallback-style=LLVM",       -- 找不到 .clang-format 时的风格
        },
        capabilities = caps,
        init_options = {
          -- clangd 不看编译器路径，靠这些默认参数推断标准库位置
          fallbackFlags = { "-std=c17" },
        },
      }
    else
      vim.notify("没找到 clangd，请先执行 :MasonInstall clangd", vim.log.levels.WARN)
    end

    for name, cfg in pairs(servers) do
      vim.lsp.config(name, cfg)
      vim.lsp.enable(name)
    end
  end,
}
