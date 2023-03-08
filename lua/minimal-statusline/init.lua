local co, api, fn = coroutine, vim.api, vim.fn
local M = {}

local function path_sep()
  return vim.loop.os_uname().sysname == "Windows_NT" and "\\" or "/"
end

local highlight = function(group, properties)
  local fg = properties.fg == nil and "" or "guifg=" .. properties.fg
  local bg = properties.bg == nil and "" or "guibg=" .. properties.bg
  local style = properties.style == nil and "" or "gui=" .. properties.style
  local cmd = table.concat({ "highlight", group, bg, fg, style }, " ")
  vim.cmd(cmd)
end

local colors_keys = {
  Statusline = { fg = "none", bg = "none", style = "none" },
  -- MTReset = { fg = "none", bg = "none", style = "none" },
  -- MTActive = { fg = "#ffffff", style = "underline,bold" },
}

function M.set_highlights()
  for hl, col in pairs(colors_keys) do
    highlight(hl, col)
  end
end

local _sep = "━"
local s = {
  sep = _sep,
  left = _sep .. " ",
  right = " " .. _sep,
}

local extensions = {}

extensions.lsp = function ()
  local buffer = api.nvim_get_current_buf()
  local buffer_clients = vim.lsp.buf_get_clients(buffer)
  local attached_lsps = {}

  for _, v in pairs(buffer_clients) do
    table.insert(attached_lsps, v.name)
  end

  if #attached_lsps == 0 then
    return ""
  end

  local lsps = table.concat(attached_lsps, ",")

  return " lsp (" .. lsps .. ") "
end

extensions.get_mode = function()
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

  local mode = api.nvim_get_mode().mode

  return alias[mode] or alias[string.sub(mode, 1, 1)] or "UNK"
end

extensions.shortend_file = function()
  local fname = api.nvim_buf_get_name(0)
  local sep = path_sep()
  local parts = vim.split(fname, sep, { trimempty = true })
  local index = #parts - 1 <= 0 and 1 or #parts - 1

  fname = table.concat({ unpack(parts, index) }, sep)
  return fname
end

extensions.filetype = function()
  local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
  return buf_ft
end


local builtin = {}

builtin.modified = "%m"
builtin.line = "%l"
builtin.line_number = builtin.line
builtin.number_of_lines = "%L"

local function render()
  local segments = {
    s.left,
    extensions.get_mode(),
    s.right,

    s.left,
    "git",
    s.right,

    s.left,
    extensions.shortend_file(),
    builtin.modified,
    s.right,

    "%=",
    extensions.lsp(),

    s.left,
    extensions.filetype(),
    s.right,

    s.left,
    builtin.line,
    "/",
    builtin.number_of_lines,
    s.right,
  }

  return table.concat(segments, "")
end

-- function M.run(winid)
--   return M.render()
-- end

function M.setup(opts)
  vim.cmd([[set fillchars+=stl:━]])
  local winid = vim.api.nvim_get_current_win()

  M.set_highlights()

  api.nvim_create_autocmd(opts.regenerate_autocmds, {
    callback = function()
      vim.opt.stl = render()
    end,
  })

  -- vim.cmd [=[
  --   augroup MinimalStatusLineAutoGroup
  --     au!
  --     autocmd BufWinEnter,WinEnter * :lua vim.wo.statusline = string.format([[%%!luaeval('require("minimal-statusline").run(%s)')]], vim.api.nvim_get_current_win())
  -- ]=]
  --
  -- for _, event in ipairs(opts.regenerate_autocmds) do
  --   vim.cmd(string.format([=[  autocmd %s * :lua require('minimal-statusline').regenerate(vim.api.nvim_get_current_win())]=], event))
  -- end
  --
  -- vim.cmd [[augroup END]]
  -- vim.cmd [[doautocmd BufWinEnter]]
end

M.setup({
  enabled = true,
  regenerate_autocmds = { "WinEnter", "WinLeave", "DiagnosticChanged", "ModeChanged", "BufEnter", "BufWritePost" },
})

return M
