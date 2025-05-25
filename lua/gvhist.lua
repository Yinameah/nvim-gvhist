local M = {}

-- TODO : make this an option
local hist_max = 10
local hist = require("gvhist.circular_buffer").new(hist_max)

local sel_eql = function(sel1, sel2)
	local dupe = true
	for k, v in pairs(sel1) do
		if sel2[k] ~= v then
			dupe = false
			break
		end
	end
	return dupe
end

local sel_show = function(sel)
	vim.fn.setpos("'<", { 0, sel.beg_lin, sel.beg_col, 0 })
	vim.fn.setpos("'>", { 0, sel.end_lin, sel.end_col, 0 })
	vim.api.nvim_feedkeys("gv", "x", false)
	if vim.fn.mode() ~= sel.mode then
		vim.api.nvim_feedkeys(sel.mode, "x", false)
	end
end

-- Save the current selection in hist while being in visual mode.
-- This function does nothing if not in visual mode, and
-- record occurs only if we are not already browsing.
-- return True if something was saved, false otherwise
M.save_current_visual = function()
	if hist:ongonig_browse() then
		return false
	end
	local mode = vim.fn.mode()
	local sel_mode = mode:match("^[vV\x16]$")
	if not sel_mode then
		return false
	end
	local beg_sel = vim.fn.getpos("v")
	local end_sel = vim.fn.getpos(".")

	local new = {
		mode = sel_mode,
		beg_lin = beg_sel[2],
		beg_col = beg_sel[3],
		end_lin = end_sel[2],
		end_col = end_sel[3],
	}
	local last = hist:peek_last()
	if last and sel_eql(last, new) then
		print("no manual save cause last==new")
		return false
	end
	hist:push(new)
	print("manual store hist @ ", hist.id_last_saved)
	return true
end

M.sel_prev = function()
	if M.save_current_visual() then
		hist:get_prev()
	end
	local last = hist:get_prev()
	if not last then
		print("no selection history")
		return
	end
	sel_show(last)
end

M.sel_next = function()
	M.save_current_visual()
	local next = hist:get_next()
	if not next then
		print("no selection history")
		return
	end
	sel_show(next)
end

M.setup = function(user_options)
	-- TODO : change to reasonnable mappings
	vim.keymap.set({ "v", "n" }, "<c-p>", M.sel_prev)
	vim.keymap.set({ "v", "n" }, "<c-n>", M.sel_next)
	-- vim.keymap.set({ "v" }, "<c-s>", M.save_current_visual)

	-- When leaving Visual mode, save the selection
	vim.api.nvim_create_autocmd("ModeChanged", {
		pattern = { "[vV\x16]*:*" },
		callback = function(ev)
			-- NOTE : getpos returns
			-- [bufnum, lnum, col, off]
			-- "lnum" and "col" are the position in the buffer.  The first column is 1.
			local beg_sel = vim.fn.getpos("'<")
			local end_sel = vim.fn.getpos("'>")
			-- NOTE : \x16 == <c-v>
			local sel_mode = ev.match:match("([vV\x16]):*")
			if not ev.match:match("[ni]$") then
				return
			end
			-- left visual to normal or insert : breaks show selection circle
			hist:reset_show()

			local new = {
				mode = sel_mode,
				beg_lin = beg_sel[2],
				beg_col = beg_sel[3],
				end_lin = end_sel[2],
				end_col = end_sel[3],
			}
			-- avoid saving last sel many times in a row
			local last = hist:peek_last()
			if last and sel_eql(last, new) then
				print("nosave cause last==new")
				return
			end
			hist:push(new)
			print("store hist @ ", hist.id_last_saved, "mode switch was ", ev.match)
		end,
	})

	vim.api.nvim_create_user_command("Gvhist", function(opts)
		local n_hist = tonumber(opts.args)
		if not n_hist then
			print("Gvhist should be called with a number")
			return
		end

		local i = math.floor(n_hist)
		local sel = hist[i]
		vim.fn.setpos("'<", { 0, sel.beg_lin, sel.beg_col, 0 })
		vim.fn.setpos("'>", { 0, sel.end_lin, sel.end_col, 0 })
		vim.cmd("normal! gv")
	end, { nargs = 1 })

	vim.api.nvim_create_user_command("GvhistShow", function()
		vim.print(vim.inspect(hist.data))
	end, {})
end

return M
