-- Neovim 配置入口
-- 加载顺序有讲究，改动请看每行后面的说明

-- leader 必须在 lazy.nvim 和任何 <leader> 映射之前设置，否则会绑到默认的反斜杠上
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")        -- vim.opt 基础设置
require("config.keymaps")        -- 全局快捷键
require("config.lazy")           -- 插件管理器（会加载 lua/plugins/ 下所有插件）
require("config.quit").setup()   -- 智能退出：把 :q 换成一次退干净的逻辑

-- 快捷速查表：:Help 打开 lua/config/cheatsheet.md 编辑
-- 必须放在 config.lazy 之后 —— 它要在 bufferline / nvim-tree 等插件
-- 注册完按键之后再执行，否则自动生成的表格读不到那些插件的快捷键
require("config.cheatsheet").setup()
