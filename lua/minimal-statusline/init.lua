local Job = require'plenary.job'

local M = {}

local builtins = {}
builtins.modified = "%m"
builtins.line = "%l"
builtins.number_of_lines = "%L"
builtins.split = "%="
builtins.space = " "

local utils = {}

utils.wrap = function(text)
  if not text or text == "" then
    return
  end

  return builtins.space .. text .. builtins.space
end

utils.hide = function(size, value)
  if vim.api.nvim_win_get_width(0) >= size then
    return value
  end

  return ""
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

provider._get_git_status = function(type)
  local chars = {
    added = "",
    changed = "~",
    removed = "",
  }

  local colors = {
    added = "%#GitSignsAdd#",
    changed = "%#GitSignsChange#",
    removed = "%#GitSignsDelete#",
  }

  if not vim.b.gitsigns_status_dict then
    return ""
  end

  if not vim.b.gitsigns_status_dict[type] then
    return ""
  end

  if vim.b.gitsigns_status_dict[type] > 0 then
    return colors[type] .. chars[type] .. vim.b.gitsigns_status_dict[type] .. "%#Normal#" .. " "
  end

  return ""

  -- {
  --   added = 4,
  --   changed = 0,
  --   removed = 0,
  --   head = "main",
  --   gitdir = "/Users/koenverburg/code/github/dotfiles/.git",
  --   root = "/Users/koenverburg/code/github/dotfiles"
  -- }
end

provider.git_changes = function()
  local chars = {
    added = "",
    files = "f",
    changed = "~",
    removed = "",
  }

  local colors = {
    added = "%#GitSignsAdd#",
    files = "%#GitSignsChange#",
    changed = "%#GitSignsChange#",
    removed = "%#GitSignsDelete#",
  }

  local result = {}
  Job:new({
    command = 'git',
    args = { 'diff', '--shortstat' },
    on_exit = function(j, _)
      result = j:result()
    end,
  }):sync() -- or start()

  local changes = {}
  if #result > 0 then
    changes = vim.split(result[1], ",", { trimempty = true })
  else
    return ""
  end

  local extractNumberValue = function(val)
    if not val then
      return ""
    end
    local parts = vim.split(val, " ", {trimempty = true})
    if not parts then return "" end
    if #parts > 0 then
      return parts[1]
    end
    return ""
  end

  local style = function(type, value)
    if value == '' or value == nil then
      return ""
    end
    return colors[type] .. chars[type] .. value .. "%#Normal#" .. " "
  end

  local files = extractNumberValue(changes[1])
  local inserts = extractNumberValue(changes[2])
  local removed = extractNumberValue(changes[3])

  return style('files', files) .. style('changed', inserts) .. style('removed', removed)
end

-- provider.git_changes()

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

  local icon, color = utils.get_icon_by_filetype("git")

  if not icon then
    return branch
  end

  return icon .. " " .. "%#" .. color .. "#" .. branch .. "%#Normal#"
end

provider.file_name = function()
  local home = vim.env.HOME
  local projectsDir = '/code/github/'
  local fname = vim.api.nvim_buf_get_name(0)
  local icon = utils.get_icon_by_filetype(provider.filetype())

  if fname == "[Scratch]" then
    return ""
  end

  fname = fname:gsub(home, "", 1)
  fname = fname:gsub(projectsDir, "", 1)

  local sep = path_sep()
  local parts = vim.split(fname, sep, { trimempty = true })
  local index = 1

  if #parts > 5 then
    index = index + 1
  end

  fname = table.concat({ unpack(parts, index) }, sep)

  if #fname > 50 then
    fname = table.concat({ unpack(parts, index + 2) }, sep)
  end

  return icon .. " " .. fname .. builtins.modified
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
    return ""
  end

  return buf_ft
end

local function render()
  local segments = {
    builtins.space,
    provider.get_mode(),
    builtins.space,

    provider.git_branch(),
    builtins.space,
    provider.git_changes(),

    builtins.split,
    (provider.file_name() ~= " %m" and utils.wrap(provider.file_name()) or ""),

    builtins.split,
    builtins.space,
    (provider.lsp_enabled and provider.lsp() or provider.filetype()),
    builtins.space,
  }

  return styler.normal(table.concat(segments, ""))
end

local colors_keys = {
  Statusline = { fg = "#ffffff", bg = "gray", style = "none" },

  MSBold = { fg = "#ffffff", bg = "none", style = "bold" },
  MSNormal = { fg = "#ffffff", bg = "none", style = "none" },
}

function M.setup()
  -- vim.cmd([[set fillchars+=stl:━]])

  local regenerate_autocmds = { "WinEnter", "WinLeave", "ModeChanged", "LspAttach", "BufEnter", "BufWritePost" }

  vim.api.nvim_create_autocmd(regenerate_autocmds, {
    callback = function()
      utils.set_highlights(colors_keys)
      vim.opt.stl = render()
    end,
  })
end

-- M.setup()

return M
