-- nvim-tree : 左侧文件树
--     <leader>e  开关文件树（leader = 空格）
--     <leader>o  聚焦到文件树
return {
  "nvim-tree/nvim-tree.lua",
  version = "*", -- 跟 v1.x 正式发版（当前 v1.18.0）

  -- 按需加载：第一次按 <leader>e / <leader>o 时才加载，不拖慢启动。
  -- 这要求 keys 里注册同名按键（下面 keys 段）。
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeOpen", "NvimTreeClose" },

  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "开关文件树" },
    { "<leader>o", "<cmd>NvimTreeFocus<cr>", desc = "聚焦文件树" },
  },

  dependencies = {
    -- 可选：文件类型图标。需要终端配了 Nerd Font，否则图标会显示成方块。
    -- 不想折腾字体就删掉这一段，nvim-tree 会退化成纯文字（功能不受影响）。
    "nvim-tree/nvim-web-devicons",
  },

  opts = {
    -- 关掉「文件已被外部修改」之类的弹窗打扰，会显示在底部提示
    notify = { threshold = vim.log.levels.INFO },

    -- 视图
    view = {
      width = 35,             -- 树宽度
      side = "left",          -- 放左边
      preserve_window_proportions = true,
    },

    -- 渲染
    renderer = {
      root_folder_label = false, -- 不显示根目录的完整路径，标题只留目录名
      indent_markers = { enable = true }, -- 缩进连线，层级更清楚
      icons = {
        show = { file = true, folder = true, git = true },
      },
    },

    -- 过滤
    filters = {
      dotfiles = false, -- 显示 .gitignore 之类的点文件（按 H 可临时隐藏）
    },

    -- 关掉一些默认警告
    hijack_directories = { enable = false },
    update_focused_file = { enable = true }, -- 切换 buffer 时自动定位到对应文件

    -- 文件树窗口里的按键（都是 nvim-tree 窗口内生效，不影响普通编辑）
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      local function o(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- 用官方推荐的默认按键集合，再覆盖几个
      api.config.mappings.default_on_attach(bufnr)
      vim.keymap.set("n", "l", api.node.open.edit, o("打开"))
      vim.keymap.set("n", "<CR>", api.node.open.edit, o("打开"))
      vim.keymap.set("n", "h", api.node.navigate.parent_close, o("折叠父目录"))
      vim.keymap.set("n", "v", api.node.open.vertical, o("垂直分屏打开"))
      vim.keymap.set("n", "s", api.node.open.horizontal, o("水平分屏打开"))
      vim.keymap.set("n", "P", api.tree.close, o("关闭但不切换焦点"))
      vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, o("显示/隐藏点文件"))
      vim.keymap.set("n", "R", api.tree.reload, o("刷新"))
      vim.keymap.set("n", "a", api.fs.create, o("新建文件"))
      vim.keymap.set("n", "d", api.fs.remove, o("删除"))
      vim.keymap.set("n", "r", api.fs.rename, o("重命名"))
      vim.keymap.set("n", "y", api.fs.copy.filename, o("复制文件名"))
      vim.keymap.set("n", "g?", api.tree.toggle_help, o("帮助"))
    end,
  },
}
