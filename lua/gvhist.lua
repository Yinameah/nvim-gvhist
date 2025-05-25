local M = {}

-- Store index to last saved selection
local last_save_id = 0
-- Store index to current shown previous sel
local last_shown_id = 0
local last_shown = nil
-- Avoid temporary mode switch to trigger selection storage
local store = true

-- TODO : make this an option
local hist_max = 10

-- list storing previous selections. Acts as circular buffer (see hist_max)
local hist = {}

-- TODO : I will rely on gv not being re-mapped in visual, mention in the docs

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
	last_shown = sel
end

M.sel_prev = function()
	if last_shown_id == 0 then
		-- new show selection circle, start at last save
		last_shown_id = last_save_id
	else
		-- currently circling selections, go one before
		last_shown_id = last_shown_id - 1
		-- If reaching end of buffer, circle
		if last_shown_id < 1 then
			last_shown_id = #hist
		end
	end
	local last = hist[last_shown_id]
	if not last then
		print("no selection history")
		return
	end
	sel_show(last)
end

M.sel_next = function()
	if last_shown_id == 0 then
		-- new show selection circle, start at oldest save, accounting for wrapping
		if last_save_id < #hist then
			if last_save_id == 1 then
				last_shown_id = #hist
			else
				last_shown_id = last_save_id - 1
			end
		else
			last_shown_id = 1
		end
	else
		-- currently circling selections, go one after
		last_shown_id = last_shown_id + 1
		-- If reaching end of buffer, circle
		if last_shown_id > #hist then
			last_shown_id = 1
		end
	end
	local next = hist[last_shown_id]
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

	-- other get sel approach
	-- v is where cursor goes when doing `o` in visual, . is where it is now.
	-- this is updated directly, not only when leaving the visual mode like '< '>
	--function get_visual_selection()
	-- return table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos(".")), "\n")
	-- end

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
			last_shown_id = 0

			local new = {
				mode = sel_mode,
				beg_lin = beg_sel[2],
				beg_col = beg_sel[3],
				end_lin = end_sel[2],
				end_col = end_sel[3],
			}
			-- Don't save obvious duplicates
			if last_save_id > 0 then
				local last = hist[last_save_id]
				if sel_eql(last, new) then
					print("nosave cause last==new")
					return
				end
			end
			if last_shown then
				if sel_eql(last_shown, new) then
					print("nosave cause last_shown==new")
					return
				end
			end
			last_save_id = last_save_id + 1
			if last_save_id > hist_max then
				last_save_id = 1
			end
			hist[last_save_id] = new
			print("store hist @ ", last_save_id, "mode switch was ", ev.match)
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
		vim.print(vim.inspect(hist))
	end, {})
end

return M
