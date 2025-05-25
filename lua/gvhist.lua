local M = {}

local opts

local hist_win_map = {}
local current_hist = {}

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
	if current_hist:ongonig_browse() then
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
	local last = current_hist:peek_last()
	if last and sel_eql(last, new) then
		print("no manual save cause last==new")
		return false
	end
	current_hist:push(new)
	print("manual store hist @ ", current_hist.id_last_saved)
	return true
end

M.sel_prev = function()
	if M.save_current_visual() then
		current_hist:get_prev()
	end
	local last = current_hist:get_prev()
	if not last then
		print("no selection history")
		return
	end
	sel_show(last)
end

M.sel_next = function()
	M.save_current_visual()
	local next = current_hist:get_next()
	if not next then
		print("no selection history")
		return
	end
	sel_show(next)
end

M.setup = function(user_options)
	opts = vim.tbl_deep_extend("force", require("gvhist.config"), user_options or {})

	-- WinEnter is not triggered for the first window, but it always has id 1000,
	hist_win_map[1000] = require("gvhist.circular_buffer").new(opts.hist_max)
	current_hist = hist_win_map[1000]

	-- Each window has his own history, and we just swap the current one on WinEnter
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function(ev)
			local winid = vim.api.nvim_get_current_win()
			current_hist = hist_win_map[winid]
			if current_hist == nil then
				hist_win_map[winid] = require("gvhist.circular_buffer").new(opts.hist_max)
				current_hist = hist_win_map[winid]
			end
		end,
	})

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
			current_hist:reset_show()

			local new = {
				mode = sel_mode,
				beg_lin = beg_sel[2],
				beg_col = beg_sel[3],
				end_lin = end_sel[2],
				end_col = end_sel[3],
			}
			-- avoid saving last sel many times in a row
			local last = current_hist:peek_last()
			if last and sel_eql(last, new) then
				print("nosave cause last==new")
				return
			end
			current_hist:push(new)
			print("store hist @ ", current_hist.id_last_saved, "mode switch was ", ev.match)
		end,
	})

	-- Commands

	vim.api.nvim_create_user_command("GvhistShow", function()
		vim.print(vim.inspect(current_hist.data))
	end, { desc = "Print current selection history for debug purposes" })

	vim.api.nvim_create_user_command("GvhistClear", function()
		current_hist:clear()
	end, { desc = "erase the current window selection history" })

	-- Mapping

	if opts.default_mapping then
		vim.keymap.set({ "v" }, "<c-p>", M.sel_prev)
		vim.keymap.set({ "v" }, "<c-n>", M.sel_next)
	end
end

return M
