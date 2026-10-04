# Neovim 配置

自己手写的配置，插件管理器用 [lazy.nvim](https://github.com/folke/lazy.nvim)。
没有用 LazyVim 之类的发行版，所有东西都在下面这几个文件里。

> 装了什么、怎么改：往下看。**看快捷键最快的方式是在 Neovim 里输入 `:Help`。**

## 目录结构

```
📂 AppData\Local\nvim            （Windows 上的配置目录）
├── 📄 init.lua                  <-- 入口，按顺序 require 下面这些
├── 📄 lazy-lock.json            <-- 插件版本锁（要提交，换机器能还原）
├── 📂 lua
│   ├── 📂 config                <-- 基础设置
│   │   ├── options.lua          <-- vim.opt 设置
│   │   ├── keymaps.lua          <-- 全局快捷键
│   │   ├── lazy.lua             <-- 插件管理器自举
│   │   ├── quit.lua             <-- 智能退出（:q 的替换逻辑）
│   │   ├── compile.lua          <-- C/C++ 一键编译运行
│   │   ├── tree_nav.lua         <-- 文件树 ↔ 代码区切换
│   │   ├── cheatsheet.lua       <-- 速查表功能（:Help 等命令）
│   │   └── cheatsheet.md        <-- ★ 你自己写的速查表内容，:Help 打开它
│   └── 📂 plugins               <-- 插件列表（每个文件一个插件）
│       ├── nvim-tree.lua        <-- 左侧文件树
│       ├── bufferline.lua       <-- 顶部标签栏
│       ├── toggleterm.lua       <-- 内置终端
│       ├── tokyonight.lua       <-- 主题配色
│       ├── mason.lua            <-- LSP / 工具安装器
│       ├── lsp.lua              <-- LSP 接线（clangd 等）
│       ├── blink.lua            <-- 补全菜单
│       └── pairs.lua            <-- 自动配对括号
```

`init.lua` 的加载顺序（**顺序有讲究**）：

```
1. 设 leader（必须是第一个，否则 <leader> 映射会绑到反斜杠）
2. config.options     基础设置
3. config.keymaps     全局快捷键
4. config.lazy        插件管理器 → 加载 lua/plugins/ 下所有插件
5. config.quit        智能退出（覆盖 :q）
6. config.cheatsheet  速查表（必须最后，要等插件注册完按键）
```

## 装的插件

| 插件 | 作用 | 版本策略 |
|---|---|---|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | 插件管理器 | 最新 |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | 文件树 | `version = "*"` |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | 文件图标 | 最新 |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | 顶部标签栏 | `version = "*"` |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | 内置终端 | `version = "*"` |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | 主题 | 最新 |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | 装 LSP / 格式化工具 | 最新 |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP 接线（clangd） | 最新 |
| [blink.cmp](https://github.com/Saghen/blink.cmp) | 补全菜单 | `version = "1.*"` |
| [mini.pairs](https://github.com/echasnovski/mini.pairs) | 自动配对括号引号 | main 分支 |

LSP 服务器由 mason 装到 `nvim-data/mason/`，目前在用的是 **clangd**（C/C++）。
注意 mason 装的东西**不在系统 PATH 里**，所以 `lsp.lua` 里用绝对路径找 clangd。

## 一些自己实现的逻辑（不太常见，改之前先看懂）

| 功能 | 文件 | 说明 |
|---|---|---|
| **`:q` 智能退出** | `config/quit.lua` | 没未保存改动时一次退干净；有改动则拦住 |
| **C/C++ 一键编译运行** | `config/compile.lua` | 空格 r r 编译并运行，错误进 quickfix |
| **速查表** | `config/cheatsheet.lua` | `:Help` 打开 `cheatsheet.md` 编辑 |
| **按项目规模开文件树** | `plugins/nvim-tree.lua` | 单文件不开树，多文件自动开 |
| **数字感知排序** | `plugins/nvim-tree.lua` | 文件树里 `1,2,10` 而不是 `1,10,2` |
| **回收站** | `trash.vbs` + `plugins/nvim-tree.lua` | Windows 没有 `trash` 命令，用 COM 自己实现 |
| **h/j/k/l 当方向键** | `config/keymaps.lua` | 保留 Vim 语义，数字前缀仍有效 |

## 常用命令

```vim
:Help           打开我自己的速查表（可直接编辑，:w 保存）
:HelpReal       真正的 Neovim 帮助文档
:h <主题>       如 :h lsp

:Lazy           插件管理（I 装 / U 更新 / S 同步 / X 清理）
:Mason          装 LSP / 格式化工具（目前还没装 LSP）
:checkhealth    体检
:Lazy log       插件出错看这里
```

## 改配置的注意事项

1. **改完要重开 Neovim**，或在里面执行 `:source $MYVIMRC`
2. **改了 `lua/plugins/` 里的 spec**（增删插件）要执行 `:Lazy sync`
3. **`:q` 已经被替换**，想看原始行为用 `:q!`
4. **配置目录已用 git 管理**，改坏了可以 `git restore <文件>` 退回来
   ```
   cd $env:LOCALAPPDATA\nvim
   git status          看改了什么
   git restore 文件名   撤销单个文件的改动
   git log --oneline   看历史
   ```

## 遇到过的问题（记录一下，免得重复踩）

- **Neovim 自定义命令必须大写开头** → 所以 `:help` 无法覆盖，只能用 `:Help`
- **`<leader>` 必须在所有映射之前设置** → 否则会绑到默认的反斜杠
- **惰性加载的插件在启动时不可用** → `pcall(require(...))` 会把失败静默吞掉，
  要先 `Lazy load <插件名>`
- **`clipboard = unnamedplus` 时 `d` 删除也会进系统剪贴板** → 不想污染就用 `"_dd`
- **swap 文件里可能有未保存内容** → 看到 swap 警告选 `R` 恢复，别直接 `D` 删除
