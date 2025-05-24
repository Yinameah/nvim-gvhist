local M = {}

-- Store index to last saved selection
local last_save_id = 0
-- Store index to current shown previous sel
local last_shown_id = 0
-- Avoid temporary mode switch to trigger selection storage
local store = true

-- TODO : make this an option
local hist_max = 10

-- list storing previous selections. Acts as circular buffer (see hist_max)
local hist = {}

-- TODO : I will rely on gv not being re-mapped in visual, mention in the docs

local sel_show = function(sel)
	store = false
	vim.fn.setpos("'<", { 0, sel.beg_lin, sel.beg_col, 0 })
	vim.fn.setpos("'>", { 0, sel.end_lin, sel.end_col, 0 })
	vim.api.nvim_feedkeys("gv", "n", false)
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
	vim.keymap.set({ "v", "n" }, "<c-p>", M.sel_prev)
	vim.keymap.set({ "v", "n" }, "<c-n>", M.sel_next)
	vim.keymap.set({ "v", "n" }, "<c-a>", function()
		vim.fn.setpos("'<", { 0, 1, 1, 0 })
	end)

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
			if not store then
				-- Prevent to store when applying the selection
				-- FIXME : this should be more clever.
				-- Should store the selection that is restored, and
				-- if the selection changed compared to restoration...
				-- Let me think about this :
				-- when I circle around the history :
				-- 1) exit visual
				-- 2) replace <> marks
				-- 3) enter visual again

				store = true
				return
			else
				-- Quit visual and store : end of showing circle
				last_shown_id = 0
			end
			-- NOTE : getpos returns
			-- [bufnum, lnum, col, off]
			-- "lnum" and "col" are the position in the buffer.  The first column is 1.
			local beg_sel = vim.fn.getpos("'<")
			local end_sel = vim.fn.getpos("'>")
			-- NOTE : \x16 == <c-v>
			local mode = ev.match:match("([vV\x16]):*")

			local new = {
				mode = mode,
				beg_lin = beg_sel[2],
				beg_col = beg_sel[3],
				end_lin = end_sel[2],
				end_col = end_sel[3],
			}
			if last_save_id > 0 then
				local last = hist[last_save_id]
				local dupe = true
				for k, v in pairs(new) do
					if last[k] ~= v then
						dupe = false
						break
					end
				end
				if dupe then
					return
				end
			end
			last_save_id = last_save_id + 1
			if last_save_id > hist_max then
				last_save_id = 1
			end
			hist[last_save_id] = new
			print("store hist @ ", last_save_id)
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
