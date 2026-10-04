-- 代码格式化
--
-- 按键：<leader>lf
--
-- 为什么要单独包一层（而不是直接 vim.lsp.buf.format）：
--   clang-format 的默认风格是「2 个空格缩进」，会把 C 代码里的 tab 全换成空格，
--   和 config/options.lua 里给 C/C++ 设的 tab 缩进打架。
--
--   解决办法是给它一份 .clang-format 配置（放在配置目录，含 UseTab: Always）。
--   但 clangd 只会从「源文件所在目录逐级向上」找这个文件 ——
--   项目在 D:\backup\programming\ 下，那儿没有配置，
--   所以这里在格式化前把配置临时复制到源文件目录，格式化完删掉。
--   如果源文件目录里**已经有** .clang-format，就尊重它，不覆盖。
--
-- ⚠️ 用同步格式化（不传 async）：
--   vim.lsp.buf.format **不支持 callback 参数**（只有 async / filter /
--   timeout_ms / range 几个选项，实测传 callback 不会被执行）。
--   要保证「格式化完再删临时文件」，就得用同步方式，时序才确定。

local M = {}

-- 配置目录里的模板
local function template()
  return vim.fn.stdpath("config") .. "/.clang-format"
end

-- 当前 buffer 对应文件所在目录
local function buffer_dir()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":p:h")
end

---临时把 .clang-format 放到源文件目录（如果那里没有的话）
---@return string|nil 放进去的文件路径（用于格式化后删除）；没放则返回 nil
local function ensure_clang_format()
  local src = template()
  if vim.fn.filereadable(src) ~= 1 then
    return nil -- 没有模板就不折腾，让 clangd 用默认风格
  end

  local dir = buffer_dir()
  if not dir then
    return nil
  end

  local dst = dir .. "/.clang-format"
  if vim.fn.filereadable(dst) == 1 then
    return nil -- 项目里已有自己的配置，尊重它
  end

  local ok = vim.fn.writefile(vim.fn.readfile(src), dst)
  if ok ~= 0 then
    vim.notify("写 .clang-format 失败：" .. dst, vim.log.levels.WARN)
    return nil
  end
  return dst
end

---格式化当前 buffer。C/C++ 会先确保 .clang-format 就位。
function M.format()
  local ft = vim.bo.filetype
  local is_c = ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" or ft == "cuda"

  -- 有 LSP 在跑吗？没有就直接说清楚，别静默失败
  if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
    vim.notify("当前文件没有 LSP，无法格式化", vim.log.levels.WARN)
    return
  end

  -- 记录光标，格式化后回到原来的行
  local cursor = vim.api.nvim_win_get_cursor(0)

  local cleanup = nil
  if is_c then
    local dst = ensure_clang_format()
    if dst then
      cleanup = function()
        pcall(vim.fn.delete, dst)
      end
    end
  end

  -- 同步格式化：函数返回时格式化已经完成
  local ok, err = pcall(vim.lsp.buf.format, {
    timeout_ms = 5000,
  })

  -- 无论成功失败都要清理临时文件
  if cleanup then
    cleanup()
  end

  if not ok then
    vim.notify("格式化失败：" .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- 回到原来的行（列不强求，格式化会改变列位置）
  local lnum = math.min(cursor[1], vim.api.nvim_buf_line_count(0))
  pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })

  vim.notify("格式化完成", vim.log.levels.INFO)
end

return M
