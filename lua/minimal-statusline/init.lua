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
  -- TabLineSel = { fg = "none", bg = "none", style = "none" },
  -- TabLineFill = { fg = "none", bg = "none", style = "none" },
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
  left = _sep .. " ",
  middle = _sep,
  right = " " .. _sep,
}

local extensions = {}

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


local builtin = {}
---   t S   File name (tail) of file in the buffer.
builtin.tail = "%t"

---   m F   Modified flag, text is "[+]"; "[-]" if 'modifiable' is off.
builtin.modified = "%m"
builtin.modified_flag = "%m"

---   M F   Modified flag, text is ",+" or ",-".
builtin.modified_list = "%M"

---   r F   Readonly flag, text is "[RO]".
builtin.readonly = "%r"

---   r F   Readonly flag, text is "[RO]".
builtin.readonly_flag = "%r"

---   R F   Readonly flag, text is ",RO".
builtin.readonly_list = "%R"

---   h F   Help buffer flag, text is "[help]".
builtin.help = "%h"

---   h F   Help buffer flag, text is "[help]".
builtin.help_flag = "%h"

---   H F   Help buffer flag, text is ",HLP".
builtin.help_list = "%H"

---   w F   Preview window flag, text is "[Preview]".
builtin.preview = "%w"

---   w F   Preview window flag, text is "[Preview]".
builtin.preview_flag = "%w"

---   W F   Preview window flag, text is ",PRV".
builtin.preview_list = "%W"

---   y F   Type of file in the buffer, e.g., "[vim]".  See 'filetype'.
builtin.filetype = "%y"

---   y F   Type of file in the buffer, e.g., "[vim]".  See 'filetype'.
builtin.filetype_flag = "%y"

---   Y F   Type of file in the buffer, e.g., ",VIM".  See 'filetype'.
builtin.filetype_list = "%Y"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.quickfix = "%q"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.quickfix_flag = "%q"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.locationlist = "%q"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.locationlist_flag = "%q"

---   k S   Value of "b:keymap_name" or 'keymap' when |:lmap| mappings are being used: "<keymap>"
builtin.keymap = "%k"

---   n N   Buffer number.
builtin.bufnr = "%n"

---   n N   Buffer number.
builtin.buffer_number = "%n"

---   b N   Value of character under cursor.
builtin.character = "%b"

---   b N   Value of character under cursor.
builtin.character_decimal = "%b"

---   B N   As above, in hexadecimal.
builtin.character_hex = "%B"

--- <pre>
---   o N   Byte number in file of byte under cursor, first byte is 1.
---         Mnemonic: Offset from start of file (with one added)
--- </pre>
builtin.byte_number = "%o"
builtin.byte_number_decimal = "%o"

---   O N   As above, in hexadecimal.
builtin.byte_number_hex = "%O"

---   N N   Printer page number.  (Only works in the 'printheader' option.)
builtin.printer_page = "%N"

---   l N   Line number.
builtin.line = "%l"

---   l N   Line number.
builtin.line_number = builtin.line

--- TODO: Document
builtin.line_with_width = function(width)
  return "%-0" .. width .. "l"
end

---   L N   Number of lines in buffer.
builtin.number_of_lines = "%L"

---   c N   Column number.
builtin.column = "%c"

---   c N   Column number.
builtin.column_number = builtin.column

--- TODO: Document
builtin.column_with_width = function(width)
  return "%-0" .. width .. "c"
end

---   v N   Virtual column number.
builtin.virtual_column = "%v"

---   v N   Virtual column number.
builtin.virtual_column_number = "%v"

---   V N   Virtual column number as -{num}.  Not displayed if equal to 'c'.
--- TODO: This isn't a good name.
builtin.virtual_column_number_long = "V"

---   p N   Percentage through file in lines as in |CTRL-G|.
builtin.percentage_through_file = "%3p"

--- <pre>
---   P S   Percentage through file of displayed window.  This is like the
---         percentage described for 'ruler'.  Always 3 in length, unless
---         translated.
--- </pre>
builtin.percentage_through_window = "%P"

--- <pre>
---   a S   Argument list status as in default title.  ({current} of {max})
---         Empty if the argument file count is zero or one.
--- </pre>
builtin.argument_list_status = "%a"

local function render()
  local segments = {
    " ",
    s.left,
    extensions.get_mode(),
    s.right,

    "%=",

    s.left,
    extensions.shortend_file(),
    s.right,

    "%=",

    s.left,
    builtin.line,
    "/",
    builtin.number_of_lines,
    s.right,
    s.left,
    string.sub(builtin.filetype, 1),
    " ",
  }

  return table.concat(segments, "")
end

-- function M.run(winid)
--   return M.render()
-- end

function M.regenerate(winid) end

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
