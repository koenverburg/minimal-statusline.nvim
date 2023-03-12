local M = {}

local builtins = {}
builtins.modified = "%m"
builtins.line = "%l"
builtins.number_of_lines = "%L"
builtins.split = "%="

local utils = {}

Sep = "━"
utils.separator = {
	sep = Sep,
	left = Sep .. " ",
	right = " " .. Sep,
}

function utils.wrap_multiple(elements)
  vim.tbl_filter(function(el)
    return #el > 0
  end, elements)

	local text = table.concat(elements, " ")
	return utils.separator.left .. text .. utils.separator.right
end

function utils.wrap(text)
	return utils.separator.left .. text .. utils.separator.right
end

local function path_sep()
	return vim.loop.os_uname().sysname == "Windows_NT" and "\\" or "/"
end

function utils.highlight(group, properties)
	local fg = properties.fg == nil and "" or "guifg=" .. properties.fg
	local bg = properties.bg == nil and "" or "guibg=" .. properties.bg
	local style = properties.style == nil and "" or "gui=" .. properties.style
	local cmd = table.concat({ "highlight", group, bg, fg, style }, " ")
	vim.cmd(cmd)
end

function utils.set_highlights(groups)
	for hl, col in pairs(groups) do
		utils.highlight(hl, col)
	end
end

function utils.get_icon(name)
	local ok, icons = pcall(require, "nvim-web-devicons")

	if not ok then
		return ""
	end

	local icon, _ = icons.get_icon(name)
	if not icon then
		return ""
	end

	return icon
end

local styler = {}
styler.normal= function(text)
  return "%#MSNormal#" .. text
end
styler.bold = function(text)
  return "%#MSBold#" .. text .. "%#MSNormal#"
end


local provider = {}
provider.lsp = function()
	local buffer = vim.api.nvim_get_current_buf()
	local buffer_clients = vim.lsp.buf_get_clients(buffer)
	local attached_lsps = {}

	for _, v in pairs(buffer_clients) do
		table.insert(attached_lsps, v.name)
	end

	if #attached_lsps == 0 then
		return ""
	end

	local lsps = table.concat(attached_lsps, ",")

	return "lsp (" .. lsps .. ")"
end

provider.get_mode = function()
	local alias = {
		n = "NORMAL",
		i = "INSERT",
		niI = "CTRL-O",
		R = "REPLAC",
		c = "C-LINE",
		v = "VISUAL",
		V = "V-LINE",
		[""] = "VBLOCK",
		s = "SELEKT",
		S = "S-LINE",
		[""] = "SBLOCK",
		t = "TERMNL",
		nt = "NORM-L",
		ntT = "C-\\C-O",
	}

	local org_mode = vim.api.nvim_get_mode().mode
	local mode = alias[org_mode] or alias[string.sub(org_mode, 1, 1)] or "UNK"

  return styler.bold(mode)
end

provider.git_branch = function()
	if not vim.b.gitsigns_status_dict then
		return ""
	end

	local branch = vim.b.gitsigns_status_dict["head"]

	branch = (not branch or branch == 0) and "" or tostring(branch)

	return branch
end

provider.shortend_file = function()
	local fname = vim.api.nvim_buf_get_name(0)
	local sep = path_sep()
	local parts = vim.split(fname, sep, { trimempty = true })
	local index = #parts - 1 <= 0 and 1 or #parts - 1
	fname = table.concat({ unpack(parts, index) }, sep)
	return fname
end

local function isNil(val)
	if val == 0 or not val or val == "" or val == nil then
		return true
	end

	return false
end

provider.filetype = function()
	local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
	if isNil(buf_ft) then
		return " "
	end
	return buf_ft
end

local function render()
	local segments = {
		utils.wrap(provider.get_mode()),

		utils.wrap_multiple({
			utils.get_icon("git"),
			provider.git_branch(),
		}),

		builtins.split,

		utils.wrap_multiple({
			utils.get_icon(provider.filetype()),
			provider.shortend_file(),
      builtins.modified or "",
		}),

		builtins.split,

		utils.wrap(provider.lsp()),

		utils.wrap(provider.filetype()),
		-- utils.wrap(builtins.line .. "/" .. builtins.number_of_lines),
	}

	return styler.normal(table.concat(segments, ""))
end


local colors_keys = {
	Statusline = { fg = "#ffffff", bg = "none", style = "none" },

	MSBold = { fg = "#ffffff", bg = "none", style = "bold" },
	MSNormal = { fg = "#ffffff", bg = "none", style = "none" },
}

function M.setup(opts)
	vim.cmd([[set fillchars+=stl:━]])

	vim.api.nvim_create_autocmd(opts.regenerate_autocmds, {
		callback = function()
			vim.opt.stl = render()
			utils.set_highlights(colors_keys)
		end,
	})

end

M.setup({
	regenerate_autocmds = { "WinEnter", "WinLeave", "ModeChanged", "BufEnter", "BufWritePost" },
})

return M
