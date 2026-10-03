-- blink.cmp : 补全引擎
--
-- 为什么需要它：nvim-lspconfig 只负责让 clangd 能回答「这个位置有哪些补全」，
-- 但**弹出补全菜单、接受选择**需要另一个插件。blink.cmp 就是这个角色。
--
-- 用法（插入模式下）：
--   Ctrl+Space   手动触发补全
--   Ctrl+n / Ctrl+p   下一个 / 上一个候选
--   Ctrl+y       接受选中的候选
--   Ctrl+e       取消/关闭补全
--   Tab          如果 snippet 有占位符，跳到下一个占位符
--
-- 它自带 Rust 编译的模糊匹配（比纯 Lua 快很多），首次安装会编译一下。

return {
  "saghen/blink.cmp",
  version = "1.*", -- 跟 v1.x（不用 "*"，那会被当成 shell 命令）
  event = "InsertEnter",
  -- 没有额外依赖。不用加 saghen/blink.lib —— 那是同作者的通用库，
  -- blink.cmp 内部并不引用它（实测 grep 无结果）。

  opts = {
    -- 按键预设："default" 提供 Ctrl+n/p/y/e 这套
    keymap = {
      preset = "default",
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
    },

    appearance = {
      nerd_font_variant = "mono", -- 你是 Maple Mono NF，带 Nerd Font 图标
    },

    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      ghost_text = { enabled = false }, -- 想开改成 true
      menu = {
        border = "rounded",
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind" },
          },
        },
      },
    },

    -- 补全来源：LSP（clangd）+ 当前 buffer 里的词 + 路径
    sources = {
      default = { "lsp", "path", "buffer" },
    },

    -- 模糊匹配用 Rust 实现，性能最好；编译失败会自动回退到 Lua
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },

  opts_extend = { "sources.default" },
}
