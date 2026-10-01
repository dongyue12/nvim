-- leader 必须在 lazy.nvim 和任何 <leader> 映射之前设置，否则会绑到默认的反斜杠上
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.lazy")
