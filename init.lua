-- leader 必须在 lazy.nvim 和任何 <leader> 映射之前设置，否则会绑到默认的反斜杠上
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.lazy")

-- 快捷键速查表：把 :help 换成速查表
-- 必须放在 config.lazy 之后 —— 它要在 bufferline / nvim-tree 等插件
-- 注册完按键之后再执行，否则表格里读不到那些插件的快捷键
require("config.cheatsheet").setup()
