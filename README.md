# Neovim 配置

自己手写的配置，插件管理器用 [lazy.nvim](https://github.com/folke/lazy.nvim)。
没有用 LazyVim 之类的发行版，所有东西都在下面这几个文件里。

> **看快捷键最快的方式**：在 Neovim 里输入 `:Help`（会打开 `lua/config/cheatsheet.md`，可以直接编辑保存）。
> 本文档是「配置说明」，`:Help` 是「日常速查」。

## 目录结构

```
📂 AppData\Local\nvim            （Windows 上的配置目录）
├── 📄 init.lua                  <-- 入口，按顺序 require 下面这些
├── 📄 lazy-lock.json            <-- 插件版本锁（要提交，换机器能还原）
├── 📄 trash.vbs                 <-- Windows 回收站脚本（见下文说明）
├── 📂 lua
│   ├── 📂 config                <-- 基础设置
│   │   ├── options.lua          <-- vim.opt 设置
│   │   ├── keymaps.lua          <-- 全局快捷键
│   │   ├── lazy.lua             <-- 插件管理器自举
│   │   ├── quit.lua             <-- 智能退出（:q 的替换逻辑）
│   │   ├── compile.lua          <-- C/C++ 一键编译运行
│   │   ├── tree_nav.lua         <-- 文件树 ↔ 代码区切换
│   │   ├── cheatsheet.lua       <-- 速查表功能（:Help 等命令）
│   │   └── cheatsheet.md        <-- ★ 日常速查表内容，:Help 打开它
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

## 快捷键总表（`<leader>` 键）

leader 键 = **空格**。`空格 x` 就是「先按空格，再按 x」。
这张表是从真实注册的映射导出的，共 **37 个**。

| 按键 | 作用 |
|---|---|
| `空格 1` ~ `空格 9` | 跳到第 1~9 个 buffer |
| `空格 bn` / `空格 bp` | 下一个 / 上一个 buffer |
| `空格 bd` | 关闭当前 buffer |
| `空格 bo` | 关闭其它 buffer（只留当前） |
| `空格 bl` / `空格 bh` | 关闭右侧 / 左侧的 buffer |
| `空格 e` | 开关文件树 |
| `空格 o` | 聚焦文件树 |
| `空格 h` | 切到文件树（没开会自动打开） |
| `空格 l` | 切回代码区 |
| `空格 sv` / `空格 sh` | 左右 / 上下分屏 |
| `空格 sc` / `空格 sx` | 关闭当前分屏 / 只保留当前分屏 |
| `空格 so` / `空格 sO` | 数字排序 / 字典排序（选中行，可视模式） |
| `空格 tf` / `空格 th` / `空格 tv` | 浮动 / 横向 / 纵向终端 |
| `空格 tq` | 彻底关闭终端（结束 shell 进程） |
| `空格 rr` | 编译并运行（C/C++） |
| `空格 rc` / `空格 ro` | 只编译 / 只运行上次的 exe |
| `空格 yp` / `空格 yd` / `空格 yn` / `空格 yr` | 复制完整路径 / 目录 / 文件名 / 相对路径 |
| `空格 cm` | 打开 Mason（装 LSP / 格式化工具） |
| `空格 q` | 智能退出（没未保存改动时一次退干净） |
| `空格 qq` | 退出全部（无条件） |

**其它模式（不是 `<leader>` 开头，但很常用）**

| 按键 | 模式 | 作用 |
|---|---|---|
| `h` `j` `k` `l` | 普通/可视 | 方向键（已映射，数字前缀仍有效，如 `5j`） |
| `gj` / `gk` | 普通/可视 | 按屏幕行下移 / 上移（长折行时用） |
| `Ctrl+s` | 普通/插入/可视 | 保存 |
| `jj` | 插入 | 退出插入模式（代替 Esc） |
| `Alt+h/j/k/l` | 插入 | 左 / 下 / 上 / 右（不用先按 Esc） |
| `Alt+a` / `Alt+e` | 插入 | 跳到行首 / 行尾 |
| `Alt+h/j/k/l/a/e` | 命令行 | 同上（重命名等输入框里有效） |
| `Ctrl+h/j/k/l` | 普通 | 切到左/下/上/右窗口 |
| `Ctrl+方向键` | 普通 | 调整窗口大小 |
| `Ctrl+\` | 普通/插入 | 开关终端 |
| `Esc` | 终端 | 退出终端模式回普通模式 |
| `Ctrl+^` | 普通 | 切到上一个编辑过的 buffer |
| `gd` `gr` `K` 等 | 普通 | LSP 功能（见下节） |

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

## LSP（代码提示）

打开 `.c` / `.cpp` 文件后 clangd 自动生效（首次要建索引，跳转可能几秒后才准）。

| 按键 | 作用 |
|---|---|
| `gd` / `gD` | 跳转到定义 / 声明 |
| `gr` | 查看所有引用 |
| `gi` / `gt` | 跳转到实现 / 类型定义 |
| `K` | 查看文档（函数签名、注释） |
| `空格 lr` | 重命名符号 |
| `空格 la` | 代码操作 / 快速修复 |
| `空格 lf` | 格式化 |
| `空格 ld` | 查看当前行诊断 |
| `]d` / `[d` | 下一个 / 上一个错误 |

**注意**：`空格 l` 既是「切回代码区」又是 LSP 那 4 个键的前缀。
在非 C 文件里没有歧义（立刻切回代码区）；在 C 文件里按 `空格 l` 要等 `timeoutlen`（500ms）才生效。

## 一些自己实现的逻辑（不太常见，改之前先看懂）

| 功能 | 文件 | 说明 |
|---|---|---|
| **`:q` 智能退出** | `config/quit.lua` | 没未保存改动时一次退干净；有改动则拦住 |
| **C/C++ 一键编译运行** | `config/compile.lua` | 空格 rr 编译并运行，错误进 quickfix |
| **文件树 ↔ 代码区切换** | `config/tree_nav.lua` | 空格 h / 空格 l |
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
:Mason          装 LSP / 格式化工具（i 装 / X 卸载）
:checkhealth    体检（LSP 出问题先看这个）
:Lazy log       插件出错看这里
```

## 改配置的注意事项

1. **改完要重开 Neovim**，或在里面执行 `:source $MYVIMRC`
2. **改了 `lua/plugins/` 里的 spec**（增删插件）要执行 `:Lazy sync`
3. **`:q` 已经被替换成智能退出**，想看原始行为用 `:q!`
4. **配置目录已用 git 管理**，改坏了可以退回来：
   ```powershell
   cd C:\Users\Legion\AppData\Local\nvim
   git status          看改了什么
   git restore 文件名   撤销单个文件的改动
   git log --oneline   看历史
   git push            推到远程（git@github.com:dongyue12/nvim.git）
   ```
   > 在 **cmd** 里要用 `cd /d %LOCALAPPDATA%\nvim`；
   > 在 **PowerShell** 里用 `cd $env:LOCALAPPDATA\nvim`。
   > 分不清就**直接用完整路径**，两种 shell 都能用。

## 遇到过的问题（记录一下，免得重复踩）

- **Neovim 自定义命令必须大写开头** → 所以 `:help` 无法覆盖，只能用 `:Help`
- **`<leader>` 必须在所有映射之前设置** → 否则会绑到默认的反斜杠
- **`lua/plugins/` 下的文件被 lazy 当作插件声明** → `require` 它拿到的是 spec 表，
  不是模块。所以辅助逻辑要放 `lua/config/`（踩过：`require("plugins.nvim-tree").focus_tree` 是 nil）
- **惰性加载的插件在启动时不可用** → `pcall(require(...))` 会把失败静默吞掉，
  要先 `Lazy load <插件名>`
- **不要在终端模式映射 `<C-\>`** → 它是 Neovim 的终端转义前缀，
  覆盖掉 `<C-\><C-n>` 这条逃生通道会卡在终端里出不来
- **`clipboard = unnamedplus` 时 `d` 删除也会进系统剪贴板** → 不想污染就用 `"_dd`
- **`<S-h>` 和 `H` 是同一个键** → 映射 `<S-h>` 就等于占用原生 `H`（跳屏幕顶部）。
  所以切 buffer 用 `空格 bn/bp`，把 `H`/`M`/`L` 留给原生动能
- **swap 文件里可能有未保存内容** → 看到 swap 警告选 `R` 恢复，别直接 `D` 删除。
  提示里如果写着 `NEWER than swap file`，说明磁盘版本更新，这时才该按 `D`
