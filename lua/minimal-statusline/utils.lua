local utils = {}

function utils.wrap(text)
	if not text or text == "" then
		return
	end

	return builtins.space .. text .. builtins.space
end

function utils.hide(size, value)
	if vim.api.nvim_win_get_width(0) >= size then
		return value
	end

	return ""
end

local function path_sep()
	return vim.loop.os_uname().sysname == "Windows_NT" and "\\" or "/"
end

function utils.isNil(val)
  if val == 0 or not val or val == "" or val == nil then
    return true
  end

  return false
end

function utils.dim(text)
  if text == "" then
    return
  end
  return "%#Comment#" .. text .. "%#Normal#"
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

	return "%#" .. color .. "#" .. icon .. "%#Normal#", color
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

return utils
