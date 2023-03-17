local M = {}

local builtins = {}
builtins.modified = "%m"
builtins.line = "%l"
builtins.number_of_lines = "%L"
builtins.split = "%="
builtins.space = " "

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
	if not text or text == "" then
		return
	end

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

function utils.get_icon_by_filetype(name)
	local ok, icons = pcall(require, "nvim-web-devicons")

	if not ok then
		return ""
	end

	local icon, color = icons.get_icon_by_filetype(name)
	if not icon then
		return ""
	end

	return "%#" ..color .. "#" .. icon .. "%#Normal#"
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
styler.normal = function(text)
	return "%#MSNormal#" .. text
end
styler.bold = function(text)
	return "%#MSBold#" .. text .. "%#MSNormal#"
end

local provider = {}
provider.lsp_enabled = function()
	local buffer = vim.api.nvim_get_current_buf()
	local buffer_clients = vim.lsp.buf_get_clients(buffer)
	local attached_lsps = {}

	for _, v in pairs(buffer_clients) do
		table.insert(attached_lsps, v.name)
	end

	if #attached_lsps == 0 then
		return false
	end

  return true
end

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

  local icon = utils.get_icon_by_filetype("git")

	if not icon then
		return branch
	end

	return icon .. " " .. branch
end

provider.file_name = function()
	local icon = utils.get_icon_by_filetype(provider.filetype())

	return icon .. " " .. "%f" .. builtins.modified
end

local function isNil(val)
	if val == 0 or not val or val == "" or val == nil then
		return true
	end

	return false
end

provider.git = function()
	if not vim.b.gitsigns_head or not vim.b.gitsigns_git_status then
		return ""
	end

	local git_status = vim.b.gitsigns_status_dict

	local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
	local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
	local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
	local icon = utils.get_icon("git")
	local branch_name = icon .. git_status.head

	return branch_name .. added .. changed .. removed
end

provider.filetype = function()
	local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")

	if isNil(buf_ft) then
		return ""
	end

	return buf_ft
end

local function lsp_or_filetype()
  if provider.lsp_enabled() then
    return provider.lsp()
  else
    return provider.filetype()
  end
end

local function render()
	local segments = {
		provider.get_mode(),
    builtins.space,
		-- utils.wrap(provider.get_mode()),

		provider.git_branch(),
    builtins.space,
		-- utils.wrap(provider.git_branch()),

		builtins.split,
    builtins.space,
		provider.file_name(),
    builtins.space,
		-- utils.wrap(provider.file_name()),

		builtins.split,
    builtins.space,
    lsp_or_filetype(),
    builtins.space,
    -- builtins.space,
		-- utils.wrap(provider.filetype()),
		-- provider.filetype(),
		-- utils.wrap(builtins.line .. "/" .. builtins.number_of_lines), -- move to winline
	}

	return styler.normal(table.concat(segments, ""))
end

local colors_keys = {
	Statusline = { fg = "#ffffff", bg = "none", style = "none" },

	MSBold = { fg = "#ffffff", bg = "none", style = "bold" },
	MSNormal = { fg = "#ffffff", bg = "none", style = "none" },
}

function M.setup()
	vim.cmd([[set fillchars+=stl:━]])

	local regenerate_autocmds =
		{ "WinEnter", "WinLeave", "ModeChanged", "BufEnter", "BufWritePost" }

		vim.api.nvim_create_autocmd(regenerate_autocmds, {
			callback = function()
				vim.opt.stl = render()
				utils.set_highlights(colors_keys)
			end,
		})
end

M.setup()

return M
