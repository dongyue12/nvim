-- 快捷键速查表
--
-- 用法：输入 :Help（无参数）弹出这份表。
--   :Help lsp      带参数时查真正的帮助
--   :HelpReal      打开帮助文档首页
--   :Cheat         备用入口
--   :h <主题>      原生帮助仍然可用（例如 :h lsp）
--
-- ⚠️ 为什么不是 :help：
--   Neovim 硬性规定自定义命令必须大写开头，:help 无法覆盖
--   （试过，报 "Invalid command name (must start with uppercase)"）。
--   所以按 Vim 惯例用大写变体 :Help。
--
-- 表格内容是从「真实注册的按键映射」里读出来的，所以不会和配置脱节。

local M = {}

-- 模式代号 -> 显示名
local MODE_NAMES = {
  n = "普通",
  v = "可视",
  x = "可视块",
  i = "插入",
  t = "终端",
  o = "操作符",
  c = "命令行",
}

-- 从所有模式里收集带 desc 的按键
local function collect()
  local items, seen = {}, {}

  for _, mode in ipairs({ "n", "v", "x", "i", "t", "o" }) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      local desc = m.desc
      if desc and desc ~= "" and desc ~= "which_key_ignore" then
        -- 直接用 m.lhs：它已经是可读形式（如 <C-Down>、<C-Bslash>）。
        -- 别用 vim.fn.keytrans()，那会多一层 <lt> 转义（变成 <lt>C-Down>）。
        local lhs = m.lhs
        -- leader 是字面空格，显示成 <leader> 更直观（比较逻辑仍用原始 lhs）
        local display = (lhs:gsub("^ ", "<leader>"))

        local key = mode .. "\1" .. lhs .. "\1" .. desc
        if not seen[key] then
          seen[key] = true
          items[#items + 1] = { mode = mode, lhs = lhs, display = display, desc = desc }
        end
      end
    end
  end
  return items
end

-- 把 <leader>xx 按第二段字母分组
local function group_of(display)
  -- display 里 leader 已经显示成 <leader>，这里只需兜底处理带尖括号的写法
  local normalized = display:gsub("^<[Ss]pace>", "<leader>")

  if normalized:find("^<leader>%d") then
    return "<leader>1-9", "编号跳转"
  end
  local g = normalized:match("^<leader>(%a)")
  if g then
    return "<leader>" .. g, nil
  end
  if normalized:match("^<[Cc]%-") or normalized:find("^<C") then
    return "Ctrl 组合", nil
  end
  if normalized:match("^<[Ss]%-") or normalized:match("^<[Aa]%-") then
    return "Shift / Alt 组合", nil
  end
  return "其它", nil
end

-- 组的显示顺序和中文名
local GROUP_LABEL = {
  ["<leader>1-9"] = "① 空格 + 数字：跳到第 N 个 buffer",
  ["<leader>b"] = "② 空格 b：buffer（顶部标签）操作",
  ["<leader>s"] = "③ 空格 s：分屏 / 排序",
  ["<leader>t"] = "④ 空格 t：终端",
  ["<leader>e"] = "⑤ 空格 e：文件树",
  ["<leader>o"] = "⑥ 空格 o：文件树聚焦",
  ["<leader>f"] = "⑦ 空格 f：查找",
  ["<leader>q"] = "⑧ 空格 q：退出",
  ["Ctrl 组合"] = "⑨ Ctrl 组合键：窗口 / 编辑",
  ["Shift / Alt 组合"] = "⑩ Shift / Alt 组合",
  ["其它"] = "⑪ 其它（插件自带）",
}

-- 生成表格内容
function M.build()
  local items = collect()
  local groups, order = {}, {}

  for _, it in ipairs(items) do
    local g = group_of(it.display)
    if not groups[g] then
      groups[g] = {}
      order[#order + 1] = g
    end
    table.insert(groups[g], it)
  end

  -- 排序：按 GROUP_LABEL 里的编号顺序，未知的排最后
  table.sort(order, function(a, b)
    local la, lb = GROUP_LABEL[a], GROUP_LABEL[b]
    if la and lb then return la < lb end
    if la then return true end
    return false
  end)

  local lines = {}
  local function add(s) lines[#lines + 1] = s end

  add("  Neovim 快捷键速查表")
  add("")
  add("  leader 键 = 空格          <leader>e 就是「按空格，再按 e」")
  add("  关闭本窗口 = q 或 Esc")
  add("  真正的帮助文档 = :HelpReal（或 :h <主题>，例如 :h lsp）")
  add(string.rep("─", 72))

  for _, g in ipairs(order) do
    local label = GROUP_LABEL[g] or g
    local list = groups[g]
    table.sort(list, function(x, y) return x.display < y.display end)

    add("")
    add("  " .. label .. "    (" .. #list .. ")")
    for i, it in ipairs(list) do
      local mode_tag = (it.mode == "n") and "" or ("  [" .. (MODE_NAMES[it.mode] or it.mode) .. "]")
      add(("    %-22s %s%s"):format(it.display, it.desc, mode_tag))
      -- 大类每 12 行插一条分隔线，否则一百多个键挤在一起没法看
      if #list > 20 and i % 12 == 0 and i < #list then
        add("    " .. string.rep("·", 60))
      end
    end
  end

  add("")
  add(string.rep("─", 72))
  add("  提示：按 :Lazy 管理插件、:Mason 装 LSP、:checkhealth 体检")
  add("       本表由 lua/config/cheatsheet.lua 生成，内容取自实际按键映射")

  return lines
end

-- 打开浮窗显示
local function open_float()
  local lines = M.build()

  local width = 0
  for _, l in ipairs(lines) do
    local w = vim.fn.strdisplaywidth(l)
    if w > width then width = w end
  end
  width = math.min(width + 2, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 6)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(1, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " 帮助 / 快捷键速查 ",
    title_pos = "center",
  })

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].scrolloff = 2

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, desc = "关闭速查表" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = "关闭速查表" })
end

function M.setup()
  -- ⚠️ Neovim 硬性规定：自定义命令必须大写开头，
  --    所以 :help 没法被覆盖（试过，报 "must start with uppercase"）。
  --    按 Vim 惯例用大写变体：:Help = 速查表，查文档用 :h / :h <主题>。
  vim.api.nvim_create_user_command("Help", function(opts)
    if opts.args ~= "" then
      -- 带参数时按原意查帮助，例如 :Help lsp
      vim.cmd("help " .. opts.args)
      return
    end
    open_float()
  end, {
    nargs = "*",
    bang = true,
    force = true,
    desc = "快捷键速查表（带参数时查帮助，如 :Help lsp）",
  })

  -- 保留一个明确的名字给真正的帮助文档
  vim.api.nvim_create_user_command("HelpReal", function(opts)
    if opts.args ~= "" then
      vim.cmd("help " .. opts.args)
    else
      vim.cmd("help")
    end
  end, { nargs = "*", bang = true, force = true, desc = "打开真正的 Neovim 帮助文档" })

  -- 备用入口（万一 :Help 被别的东西占了）
  vim.api.nvim_create_user_command("Cheat", open_float, { desc = "快捷键速查表" })
end

return M
