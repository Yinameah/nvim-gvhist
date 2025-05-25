-- Poor's man unitests : just run with luafile %
-- too lazy to setup something more fancy.

local buf = require("gvhist.circular_buffer").new(3)

assert(buf.data[1] == nil, "empty init")
assert(buf:get_prev() == nil, "empty get null")
assert(buf:get_next() == nil, "empty get null")
assert(buf:peek_last() == nil, "empty get null")

buf:push(42)

assert(buf:ongonig_browse() == false)

assert(buf.data[1] == 42, "pushed one")
assert(buf:ongonig_browse() == false)
assert(buf:peek_last() == 42 and buf:peek_last() == 42, "peek wors")
assert(buf:ongonig_browse() == false)

buf:push({ key = "value" })
assert(buf:ongonig_browse() == false)

assert(buf.data[2]["key"] == "value", "can push table")
assert(buf:get_prev()["key"] == "value" and buf:get_prev() == 42, "get_prev works")
assert(buf:get_next()["key"] == "value", "get_next works")
assert(buf:ongonig_browse() == true)

buf:push(43)
buf:push(44)
buf:push(45)
assert(buf:ongonig_browse() == false)

assert(buf.data[1] == 44 and buf.data[2] == 45 and buf.data[3] == 43, "push wraps")

assert(
	buf:get_prev() == 45 and buf:get_prev() == 44 and buf:get_prev() == 43 and buf:get_prev() == 45,
	"get_prev wraps"
)
assert(
	buf:get_next() == 43 and buf:get_next() == 44 and buf:get_next() == 45 and buf:get_next() == 43,
	"get_next wraps"
)
assert(buf:get_prev() == 45 and buf:get_next() == 43, "back and forth works")
assert(buf:ongonig_browse() == true)
buf:reset_show()
assert(buf:ongonig_browse() == false)

buf:push(46)

assert(buf:get_prev() == 46, "push reset get")

buf:push(47)

assert(buf:get_next() == 45, "push reset and next wraps")

print("all good")
