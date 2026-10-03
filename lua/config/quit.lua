-- 智能退出
--
-- 目标：输入 :q 就把 Neovim 一次退干净，不用重复输。
--
-- 规则（按顺序判断）：
--   1) 有未保存改动（含其它标签页）      -> 拦住，什么都不关（防止丢工作）
--   2) 当前标签页「没东西可编辑了」      -> 整体退出
--      （只剩文件树，或只剩启动时那个空白 buffer —— 后者才是最常见的坑：
--        打开文件时窗口被顶替，关掉文件后剩下的是空白窗口，看着像卡住）
--   3) 有多个标签页                      -> 整体退出
--   4) 其它情况（还有真实文件窗口）      -> 只关当前窗口，和原生 :q 一致
--
-- 实现注意：
--   - force = true 才能覆盖内置命令
--   - 声明 nargs/range/bang，否则 :q!、:1q、:q a.txt 这类用法会失效
--   - 第 1 条是安全底线：宁可多问一次，也不能悄悄退掉没保存的东西

local M = {}

-- 收集所有「已加载且有未保存改动」的 buffer，跨标签页
function M.unsaved_buffers()
  local bad = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      table.insert(bad, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"))
    end
  end
  return bad
end

-- 这个 buffer 是不是「空的无名 scratch」
-- Neovim 启动时自带一个这种 buffer；nvim-tree 也用它做占位。
-- 关掉文件后如果只剩它，界面上就是个空白窗口，看着像卡住了 —— 应该一起退掉。
local function is_blank(buf)
  return vim.api.nvim_buf_get_name(buf) == ""
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].filetype == ""
    and not vim.bo[buf].modified
end

-- 当前标签页里是不是只剩「文件树 + 空窗口」这类没有实际内容的窗口
-- 判断依据：没有任何一个窗口承载着真实的文件
local function nothing_to_edit_in_tab()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(w)
    local ok, utils = pcall(require, "nvim-tree.utils")
    local is_tree = ok and utils.is_nvim_tree_buf(buf) or (vim.bo[buf].filetype == "NvimTree")
    if not is_tree and not is_blank(buf) then
      return false -- 有个真实文件窗口，不能退
    end
  end
  return true
end

function M.smart_quit(bang)
  -- bang(:q!) 表示「我知道自己在干什么」，直接按原生语义走
  if bang then
    vim.cmd("quit!")
    return
  end

  -- 1) 有未保存改动 -> 交给原生 quit 报 E37，用户自己决定保存还是加 !
  if #M.unsaved_buffers() > 0 then
    vim.cmd("quit")
    return
  end

  -- 2) 没东西可编辑了（只剩树 / 空窗口），或开了多个标签页 -> 一次退干净
  if nothing_to_edit_in_tab() or #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("quitall")
    return
  end

  -- 3) 普通情况：关当前窗口
  vim.cmd("quit")
end

function M.setup()
  -- 覆盖内置的 :q
  vim.api.nvim_create_user_command("Q", function(opts)
    M.smart_quit(opts.bang)
  end, {
    desc = "智能退出（没未保存改动时一次退干净）",
    nargs = "*",
    range = true,
    bang = true,
    force = true,
  })
end

return M
