local Job = require("plenary.job")

local p = require("minimal-statusline.provider")
local b = require("minimal-statusline.builtins")

local M = {}

local styler = {}
styler.normal = function(text)
	return "%#MSNormal#" .. text
end
styler.bold = function(text)
	return "%#MSBold#" .. text .. "%#MSNormal#"
end

local function render()
	local segments = {
    p.start,
		b.space,
		p.mode(),
		p.git_branch(),
		b.space,
		p.filename(),
		p.dim(b.modified),
    b.space,
		p.git_changes(),
		b.split,
		p.diagnostic(),
		p.lsp_or_filetype(),
		b.file_info,
		b.space,
	}
	-- local segments = {
	-- 	p.start,
	-- 	p.mode(),
	-- 	p.git_branch(),
	-- 	b.space,
	-- 	p.filename(),
	-- 	p.dim(b.modified),
	-- 	b.space,
	-- 	p.git_changes(),
	-- 	b.space,
	-- 	p.diagnostic(),
	-- 	b.split,
	-- 	p.lsp_or_filetype(),
	-- 	b.file_info,
	-- }

	return styler.normal(table.concat(segments, ""))
end

local colors_keys = {
	Statusline = { fg = "#ffffff", bg = "gray", style = "none" },
	-- MSBold = { fg = "#ffffff", bg = "none", style = "bold" },
	-- MSNormal = { fg = "#ffffff", bg = "none", style = "none" },
}

function M.setup()
	-- vim.cmd([[set fillchars+=stl:━]])

	local regenerate_autocmds = {
    "ModeChanged",

		"WinEnter",
		"WinLeave",

    "InsertEnter",
    "InsertLeave",

		"BufEnter",
		"BufWritePost",

    "LspAttach",
		"DiagnosticChanged",
	}

	vim.opt.stl = render()
	vim.o.stl = render()

	vim.api.nvim_create_autocmd(regenerate_autocmds, {
		callback = function()
			vim.opt.stl = render()
		end,
	})
  M.update_statusline()
end

function M.update_statusline()
	coroutine.wrap(function()
		while true do
			-- Simulate an asynchronous task (e.g., getting data)
			vim.fn.timer_start(1000, function()
				-- Update statusline values here
        vim.opt.stl = render()
        vim.api.nvim_command("redrawstatus!")

				-- Yield the coroutine to wait for the next update
				-- coroutine.yield()
			end)

			coroutine.yield()
		end
	end)()
end

M.setup()

return M
