local utils = {}

local _sep = "━"

utils.separator = {
  sep = _sep,
  left = _sep .. " ",
  right = " " .. _sep,
}

function utils.wrap(text)
  return utils.separator.left .. text .. utils.separator.right
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
  local ok, icons = pcall(require, 'nvim-web-devicons')

  if not ok then
    return ""
  end

  local icon, _ = icons.get_icon(name)
  return icon
end

return utils
