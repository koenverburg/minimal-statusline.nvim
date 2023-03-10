local co, api, fn = coroutine, vim.api, vim.fn
local provider = require('minimal-statusline.provider')
local utils    = require('minimal-statusline.utils')
local builtins = require('minimal-statusline.builtins')
local M = {}


local wrap = utils.wrap

-- local function path_sep()
--   return vim.loop.os_uname().sysname == "Windows_NT" and "\\" or "/"
-- end


local colors_keys = {
  Statusline = { fg = "none", bg = "none", style = "none" },
  -- StatuslineNC = { fg = "none", bg = "none", style = "none" },
  -- MTReset = { fg = "none", bg = "none", style = "none" },
  -- MTActive = { fg = "#ffffff", style = "underline,bold" },
}

local function render()
  local segments = {
    wrap(provider.get_mode()),
    -- wrap(utils.get_icon("git")),

    builtins.split,

    wrap(
      provider.shortend_file() .. builtins.modified
    ),
    wrap(provider.filetype()),

    builtins.split,

    wrap(provider.lsp()),

    wrap(
      builtins.line .. "/" .. builtins.number_of_lines
    )
  }

  return table.concat(segments, "")
end

-- function M.run(winid)
--   return M.render()
-- end

function M.setup(opts)
  vim.cmd([[set fillchars+=stl:━]])
  -- local winid = vim.api.nvim_get_current_win()

  M.set_highlights()

  api.nvim_create_autocmd(opts.regenerate_autocmds, {
    callback = function()
      vim.opt.stl = render()
      -- M.set_highlights()
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
  regenerate_autocmds = { "WinEnter", "WinLeave", "DiagnosticChanged", "ModeChanged", "BufEnter", "BufWritePost" },
})

return M
