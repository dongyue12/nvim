-- 插件管理器：lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "lazy.nvim 克隆失败:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" }, -- lua/plugins/ 下每个文件都会被自动加载
  },
  install = { colorscheme = { "habamax" } }, -- 首次安装时用的临时配色
  checker = { enabled = false },             -- 想自动检查更新改 true
  change_detection = { notify = false },
})
