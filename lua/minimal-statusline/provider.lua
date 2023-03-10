local provider = {}

provider.lsp = function ()
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

  local mode = vim.api.nvim_get_mode().mode

  return alias[mode] or alias[string.sub(mode, 1, 1)] or "UNK"
end

provider.shortend_file = function()
  -- local fname = vim.api.nvim_buf_get_name(0)
  -- local sep = path_sep()
  -- local parts = vim.split(fname, sep, { trimempty = true })
  -- local index = #parts - 1 <= 0 and 1 or #parts - 1
  --
  -- fname = table.concat({ unpack(parts, index) }, sep)
  return ""
end

provider.filetype = function()
  local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
  return buf_ft
end


return provider
