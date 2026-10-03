-- C 语言一键编译 / 运行
--
-- 按键（在 keymaps.lua 里注册）：
--   <leader>rr    编译当前文件并运行
--   <leader>rc    只编译（用来看错误）
--   <leader>ro    只运行上次编译出的 exe
--
-- 编译细节：
--   编译器   C:\mingw64\bin\gcc.exe（MinGW-W64 16.2.0）
--   警告     -Wall -Wextra（能提前发现很多笔误）
--   标准     -std=c17
--   输出     和源文件同目录、同名的 .exe
--
-- 交互式程序支持：
--   scanf 这类需要键盘输入的程序，用 toggleterm 的浮动终端运行，
--   这样能直接在终端里输入，输出也不会一闪而过。

local M = {}

local GCC = "C:/mingw64/bin/gcc.exe"

-- 取当前 buffer 对应的文件信息；不是 C/C++ 源文件就返回 nil
local function current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  if ext ~= "c" and ext ~= "cpp" and ext ~= "cc" and ext ~= "cxx" then
    return nil
  end
  return {
    path = path,
    dir = vim.fn.fnamemodify(path, ":p:h"),
    -- 不带扩展名的文件名，同时也当终端名用（每个源文件一个独立终端）
    base = vim.fn.fnamemodify(path, ":t:r"),
    exe = vim.fn.fnamemodify(path, ":p:r") .. ".exe",
  }
end

-- 前置检查：编译器在不在、是不是 C 文件、未保存的先存盘
local function prepare()
  if vim.fn.executable(GCC) ~= 1 then
    vim.notify("找不到编译器：" .. GCC, vim.log.levels.ERROR)
    return nil
  end

  local f = current_file()
  if not f then
    vim.notify("当前文件不是 C/C++ 源文件（或还没有文件名）", vim.log.levels.WARN)
    return nil
  end

  -- 先保存再编译 —— 否则编译的是旧版本，这是最容易踩的坑
  if vim.bo.modified then
    vim.cmd("silent! write")
  end

  return f
end

-- 编译。返回 exe 路径（失败返回 nil）
function M.compile()
  local f = prepare()
  if not f then
    return nil
  end

  -- 删掉旧的 exe，避免编译失败时误运行上次的产物
  vim.fn.delete(f.exe)

  local cmd = {
    GCC,
    f.path,
    "-o", f.exe,
    "-std=c17",
    "-Wall",
    "-Wextra",
    -- 不要 ANSI 颜色码，否则 quickfix 里会混进转义字符
    "-fdiagnostics-color=never",
  }

  local result = vim.system(cmd, { cwd = f.dir, text = true }):wait()

  local output = (result.stderr or "") .. (result.stdout or "")

  if result.code == 0 then
    vim.notify("编译成功：" .. vim.fn.fnamemodify(f.exe, ":t"), vim.log.levels.INFO)
    return f.exe
  end

  -- ── 编译失败：把错误塞进 quickfix ──────────────────────────
  -- gcc 的错误格式分三种：
  --   bad.c:4:13: error: ...          真正的错误位置（要保留）
  --   bad.c: In function 'main':      上下文，没有行列号（丢掉）
  --       4 |     int x = "...";      源码引用（丢掉）
  --         |             ^~~~~~~     指示符（丢掉）
  -- 只留第一种，否则 quickfix 里全是行0 列0 的噪音，没法用 :cnext 跳。
  local qf = {}
  for _, line in ipairs(vim.split(output, "\n")) do
    local file, lnum, col, msg = line:match("^(.-):(%d+):(%d+):%s*(.*)$")
    if file and msg and tonumber(lnum) > 0 then
      qf[#qf + 1] = { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = msg }
    end
  end

  if #qf > 0 then
    vim.fn.setqflist(qf)
    vim.cmd("copen")
    vim.notify("编译失败，错误已放进 quickfix（:cnext / :cprev 跳转）", vim.log.levels.ERROR)
  else
    vim.notify("编译失败：\n" .. output, vim.log.levels.ERROR)
  end
  return nil
end

-- 运行 exe。目录用源文件所在目录，这样程序里的相对路径才对
function M.run(exe, f)
  f = f or current_file()
  if not f then
    return
  end
  exe = exe or f.exe

  if vim.fn.filereadable(exe) ~= 1 then
    vim.notify("还没有可执行文件，先按 <leader>rr 或 <leader>rc 编译", vim.log.levels.WARN)
    return
  end

  local ok, toggleterm = pcall(require, "toggleterm")
  if not ok then
    vim.notify("toggleterm 没加载，无法开终端运行", vim.log.levels.ERROR)
    return
  end

  -- 用 M.exec 是官方推荐入口：它会复用同名终端，没有就新建
  -- 参数：cmd, num, size, dir, direction, name, go_back, open
  -- 终端名用文件名，这样一个源文件对应一个终端，互不干扰
  toggleterm.exec(
    vim.fn.fnameescape(exe),
    nil,
    18,        -- 浮动终端高度
    f.dir,     -- 工作目录 = 源文件目录
    "float",
    f.base
  )
end

-- 编译 + 运行
function M.compile_and_run()
  local f = prepare()
  if not f then
    return
  end
  -- compile() 会再跑一次 prepare（无害，只是重复几次检查）
  local exe = M.compile()
  if exe then
    M.run(exe, f)
  end
end

-- 只运行上次编译的 exe
function M.run_only()
  local f = prepare()
  if f then
    M.run(nil, f)
  end
end

return M
