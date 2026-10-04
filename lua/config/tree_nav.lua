-- 在「文件树」和「代码区」之间切换
--
-- 为什么单独一个文件：
--   lua/plugins/ 下的文件被 lazy.nvim 当作「插件声明」处理，
--   require("plugins.nvim-tree") 拿到的会是那份 spec 表，
--   而不是你想调用的模块 —— 所以辅助逻辑必须放在别处。
--
-- 按键（在 plugins/nvim-tree.lua 的 keys 里注册）：
--   <leader>h   切到文件树（没开会自动打开）
--   <leader>l   切回代码区
--
-- 为什么不用 <C-h> / <C-l>：
--   那两个是通用的「切到左/右窗口」，分屏多的时候更有用。
--   这里是一对专属于「树 ↔ 代码」的键，行为更确定。

local M = {}

-- 找出文件树窗口和「代码区」窗口
-- 返回 (tree_win, code_win)，任一个可能为 nil
local function locate()
  local tree_win, code_win
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "NvimTree" then
        tree_win = win
      elseif vim.bo[buf].buftype == "" then
        -- buftype 为空 = 正常文件 buffer，也就是写代码的地方
        code_win = code_win or win
      end
    end
  end
  return tree_win, code_win
end

---切到文件树。树没开就先打开。
function M.focus_tree()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    vim.notify("文件树还没加载，先按 <leader>e 打开", vim.log.levels.WARN)
    return
  end

  if not api.tree.is_visible() then
    api.tree.open()
    -- open 之后窗口才存在，排到下一个事件循环再设焦点
    vim.schedule(function()
      local tree_win = locate() -- 只要第一个返回值
      if tree_win then
        vim.api.nvim_set_current_win(tree_win)
      end
    end)
    return
  end

  local tree_win = locate()
  if tree_win then
    vim.api.nvim_set_current_win(tree_win)
  else
    api.tree.focus()
  end
end

---切回代码区。一个代码窗口都没有时开一个空的，避免被困在树里。
function M.focus_editor()
  local _, code_win = locate()
  if code_win then
    vim.api.nvim_set_current_win(code_win)
    return
  end
  -- 只剩树（或树 + 别的非文件窗口）—— 开个空 buffer 当编辑区
  vim.cmd("enew")
end

return M
