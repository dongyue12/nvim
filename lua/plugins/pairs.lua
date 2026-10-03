-- mini.pairs : 自动配对括号和引号
--
-- 效果：
--   打 (   -> 自动补 )，光标停在中间
--   打 "   -> 自动补 "
--   打 {   -> 自动补 }
--   已有右括号时再打右括号 -> 直接跳过（不会重复插入）
--   选中一段文字后打 ( -> 用括号把选区包起来
--
-- 为什么不用 nvim-autopairs：
--   功能更专注、代码量小、无依赖、维护活跃。
--
-- 与 blink.cmp 的分工（两者互补，不冲突）：
--   blink.cmp    负责「接受补全项时补上函数括号」，例如补全 printf -> printf()
--   mini.pairs   负责「手打括号时自动配对」
--
-- 用默认配置，不覆盖 mappings。mini.pairs 的默认规则对 C 很合适，尤其是：
--   单引号在字母后面不配对（neigh_pattern = '^[^%a\\]'），
--   所以 'a' 这种字符常量不会被打成 'a''。

return {
  "echasnovski/mini.pairs",
  version = false, -- mini 系列不打版本 tag，用 main 分支
  event = "InsertEnter",
  opts = {},
}
