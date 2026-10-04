-- nvim-tree : 左侧文件树
--
-- 快捷键：<leader>e 开关 / <leader>o 聚焦（leader = 空格）
--         <leader>h 切到文件树 / <leader>l 切回代码区
--         这些都定义在下面的 keys 里，用于按需加载这个插件。
--         树窗口内的按键见 on_attach。
--         <leader>h / <leader>l 的实际逻辑在 lua/config/tree_nav.lua
--         （不能写在本文件里：lua/plugins/ 下的文件被 lazy 当作 spec，
--          require 本文件拿到的是 spec 表，不是模块）
-- 行为：目录里只有 1 个文件时不自动开树，多个文件才开（见下面的 init）
return {
  "nvim-tree/nvim-tree.lua",
  version = "*", -- 跟 v1.x 正式发版（当前 v1.18.0）

  -- 按需加载：第一次按 <leader>e / <leader>o 时才加载，不拖慢启动。
  -- 这要求 keys 里注册同名按键（下面 keys 段）。
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeOpen", "NvimTreeClose" },

  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "开关文件树" },
    { "<leader>o", "<cmd>NvimTreeFocus<cr>", desc = "聚焦文件树" },
    {
      "<leader>h",
      function()
        require("config.tree_nav").focus_tree()
      end,
      desc = "切到文件树（没开会自动开）",
    },
    {
      "<leader>l",
      function()
        require("config.tree_nav").focus_editor()
      end,
      desc = "切回代码区",
    },
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

    -- ── 排序：数字感知（自然排序）──────────────────────────────
    -- nvim-tree 内置的 "name" 是字典序，文件带数字前缀时会乱：
    --   1.a  10.b  11.c  2.e    <- 内置 :sort / name 排序的结果
    -- 下面这个自定义 sorter 把名字切成「文字段 / 数字段」逐段比较：
    --   1.a  2.e  10.b  11.c    <- 符合直觉
    -- 大小写不敏感，目录仍然排在文件前面。
    --
    -- 原理：把 "a10b2" 拆成 { "a", 10, "b", 2 }；
    --       数字段按数值比（2 < 10），文字段按小写字符串比；
    --       前缀全部相同时，短的在前。
    sort = {
      sorter = function(nodes)
        -- 把一个名字拆成可比较的片段列表：{ {num=10}, {str="abc"}, ... }
        local function pieces(s)
          local out = {}
          local i, len = 1, #s
          while i <= len do
            local ch = s:sub(i, i)
            local is_digit = ch >= "0" and ch <= "9"
            local j = i
            while j <= len do
              local c = s:sub(j, j)
              if (c >= "0" and c <= "9") ~= is_digit then break end
              j = j + 1
            end
            local seg = s:sub(i, j - 1)
            if is_digit then
              out[#out + 1] = { num = tonumber(seg) }
            else
              out[#out + 1] = { str = seg:lower() }
            end
            i = j
          end
          return out
        end

        local cache = {}
        local function keyf(name)
          if cache[name] == nil then cache[name] = pieces(name) end
          return cache[name]
        end

        -- a 是否应排在 b 前面（名字层面）
        local function less_name(a, b)
          local pa, pb = keyf(a), keyf(b)
          for i = 1, math.min(#pa, #pb) do
            local x, y = pa[i], pb[i]
            if x.num ~= nil and y.num ~= nil then
              if x.num ~= y.num then return x.num < y.num end
            elseif x.str ~= nil and y.str ~= nil then
              if x.str ~= y.str then return x.str < y.str end
            else
              -- 类型不同（一个是数字段一个是文字段）：数字段排前面，保证顺序稳定
              return x.num ~= nil
            end
          end
          return #pa < #pb
        end

        -- 整体排序：先比「目录/文件」，再比名字
        local function before(a, b)
          local ad, bd = a.type == "directory", b.type == "directory"
          if ad ~= bd then return ad end -- 目录优先
          return less_name(a.name, b.name)
        end

        -- 用 table.sort 排序。目录里条目一般不多，性能足够；
        -- 比较函数里对每个名字做了 cache，避免重复拆分。
        table.sort(nodes, before)
      end,
      folders_first = true,
    },

    -- ├─ 回收站（trash）───────────────────────────────────────
    -- nvim-tree 的「移到回收站」依赖一个外部命令，Windows 上默认没有
    -- （默认值 "trash" 是 Linux/macOS 的东西，所以 D 键原本会失败）。
    -- 这里改用仓库里的 trash.vbs，通过 cscript 调用 Windows 回收站。
    --
    -- ⚠️ 三个写法上的坑（都实测踩过）：
    --   1) 必须写成「解释器 + 脚本路径」，不能只写脚本路径——
    --      nvim-tree 会先跑 vim.fn.executable(命令的第一个词)，
    --      而 executable("C:/.../trash.vbs") = 0（它不处理引号，.vbs 也不直接可执行）
    --   2) 脚本路径不能加引号，否则 binary 变成 '"C:/..."' 一样判断失败。
    --      好在配置目录路径里没有空格，所以不加引号是安全的。
    --   3) 脚本路径必须是反斜杠。Neovim 的 stdpath 返回的是正斜杠，
    --      cscript 拿到混合斜杠（C:\...\nvim/trash.vbs）会执行失败。
    trash = {
      cmd = "cscript.exe //nologo "
        .. (vim.fn.stdpath("config"):gsub("/", "\\"))
        .. "\\trash.vbs",
    },

    -- 关掉一些默认警告
    hijack_directories = { enable = false },

    -- 自动定位：切换 buffer 时让树跳到该文件所在目录。
    -- 已关闭，原因有两个：
    --   1) 在别的项目里 :Help 看速查表，树会被「拐」到配置目录
    --   2) 在多个目录间切文件时，树会跟着跳来跳去，容易迷失位置
    -- 关掉后树的根目录就固定在你打开的地方，只有你主动改（:cd / 用树里的
    -- 目录操作）才会变。想恢复就改成 enable = true。
    update_focused_file = { enable = false },

    -- 文件树窗口里的按键（都是 nvim-tree 窗口内生效，不影响普通编辑）
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      local function o(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- 用官方推荐的默认按键集合，再覆盖几个
      api.config.mappings.default_on_attach(bufnr)

      -- 打开（查）
      vim.keymap.set("n", "l", api.node.open.edit, o("打开"))
      vim.keymap.set("n", "<CR>", api.node.open.edit, o("打开"))
      vim.keymap.set("n", "o", api.node.open.edit, o("打开"))
      vim.keymap.set("n", "v", api.node.open.vertical, o("垂直分屏打开"))
      vim.keymap.set("n", "s", api.node.open.horizontal, o("水平分屏打开"))
      vim.keymap.set("n", "h", api.node.navigate.parent_close, o("折叠父目录"))

      -- 增删改
      vim.keymap.set("n", "a", api.fs.create, o("新建文件 / 文件夹"))
      -- r 用「全路径」模式，这样才能改位置。
      -- 注意不能用 fs.rename / fs.rename_node（它们是 :t 模式，
      -- 只让你改文件名，目录会被自动拼回去，所以挪不动）。
      vim.keymap.set("n", "r", api.fs.rename_full, o("重命名 / 移动（改完整路径）"))
      vim.keymap.set("n", "e", api.fs.rename_basename, o("只改文件名（保留扩展名）"))
      vim.keymap.set("n", "d", api.fs.trash, o("移到回收站"))
      vim.keymap.set("n", "D", api.fs.trash, o("移到回收站"))
      vim.keymap.set("n", "<Del>", api.fs.remove, o("彻底删除（不进回收站）"))
      vim.keymap.set("n", "x", api.fs.cut, o("剪切"))
      vim.keymap.set("n", "c", api.fs.copy.node, o("复制文件"))
      vim.keymap.set("n", "p", api.fs.paste, o("粘贴"))

      -- 复制路径（gy 符合 Vim 的 g 前缀惯例）
      vim.keymap.set("n", "y", api.fs.copy.filename, o("复制文件名"))
      vim.keymap.set("n", "Y", api.fs.copy.relative_path, o("复制相对路径"))
      vim.keymap.set("n", "gy", api.fs.copy.absolute_path, o("复制绝对路径"))

      -- 其它
      vim.keymap.set("n", "P", api.tree.close, o("关闭但不切换焦点"))
      vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, o("显示/隐藏点文件"))
      vim.keymap.set("n", "R", api.tree.reload, o("刷新"))
      vim.keymap.set("n", "S", api.tree.search_node, o("在树里搜索文件"))
      vim.keymap.set("n", "f", api.live_filter.start, o("实时过滤"))
      vim.keymap.set("n", "g?", api.tree.toggle_help, o("帮助"))
    end,
  },

  -- ── 按项目规模自动开文件树 ───────────────────────────────────
  -- 规则：
  --   目录里只有 1 个文件  -> 不开树，直接编辑，界面更干净
  --   有多个文件          -> 自动打开树
  -- 手动控制随时可用：<leader>e 开关 / <leader>o 聚焦
  init = function()
    -- 计数时忽略这些目录，否则 node_modules / .git 会让计数虚高，
    -- 明明只有一两个源文件却被判定成「多文件项目」
    local IGNORE = {
      ".git", "node_modules", ".venv", "venv", "__pycache__",
      "target", "dist", "build", ".next", ".cache",
    }

    -- 递归数文件。max_depth 用来限制深度，避免在大仓库上拖慢启动
    local function count_files(dir, max_depth)
      local n = 0
      local ok, iter = pcall(vim.fs.dir, dir, { depth = max_depth or 3 })
      if not ok or not iter then return 0 end
      for name, typ in iter do
        local rel = name:gsub("\\", "/")
        local skip = false
        for _, ig in ipairs(IGNORE) do
          -- 路径里任意一层是忽略目录就跳过
          if rel:find("/" .. ig .. "/", 1, true) or rel:sub(1, #ig + 1) == ig .. "/" then
            skip = true
            break
          end
        end
        if not skip and typ == "file" then n = n + 1 end
      end
      return n
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if count_files(vim.fn.getcwd(), 3) <= 1 then
          return -- 只有一个文件，不开树
        end
        -- 延迟到窗口布局稳定后再处理
        vim.schedule(function()
          -- 这个插件是 cmd/keys 惰性加载的，此时通常还没加载。
          -- 直接用 require("nvim-tree.api") 会因为插件不在 runtimepath 而失败，
          -- 被 pcall 静默吞掉、树就打不开了。所以先显式加载插件。
          if not package.loaded["nvim-tree"] then
            pcall(vim.cmd, "Lazy load nvim-tree.lua")
          end
          local ok, api = pcall(require, "nvim-tree.api")
          if ok and not api.tree.is_visible() then
            api.tree.open()
          end
        end)
      end,
    })
  end,
}
