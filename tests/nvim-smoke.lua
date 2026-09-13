-- Run: nvim --headless -l tests/nvim-smoke.lua
-- -l skips the user init, so load it explicitly and catch startup errors.
vim.go.loadplugins = true -- -l disables plugins; lazy.nvim requires this option.
vim.g.anbar_smoke = true
local errors = {}
vim.notify = function(message, level)
  if level == vim.log.levels.ERROR then table.insert(errors, tostring(message)) end
end
local ok, err = pcall(dofile, vim.fn.stdpath("config") .. "/init.lua")
if not ok then table.insert(errors, tostring(err)) end
if ok then
  local names = {}
  for name in pairs(require("lazy.core.config").plugins) do names[#names + 1] = name end
  require("lazy").load({ plugins = names })
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  for _, ft in ipairs({ "lua", "php", "blade", "javascript", "typescript", "vue", "go", "rust", "markdown", "sql" }) do
    vim.cmd.enew()
    local success, failure = pcall(function() vim.bo.filetype = ft end)
    if not success then table.insert(errors, ft .. ": " .. tostring(failure)) end
  end
  assert(vim.g.mapleader == " ", "Leader should be Space")
  assert(vim.fn.maparg(" ?", "n") ~= "", "Space + ? is missing")
  assert(vim.lsp.config.laravel_lsp.filetypes[2] == "blade", "Laravel/Blade LSP missing")
  assert(vim.fn.exists(":DevdocsOpen") == 2, "Devdocs command missing")
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  -- Exercise both keymap menus, not just their registration.
  require("telescope.builtin").keymaps()
  require("telescope.actions").close(vim.api.nvim_get_current_buf())
  vim.wait(500) -- which-key initializes its mode tables on the next event loop.
  require("which-key").show({ global = true })
  vim.wait(1500)
end
if #errors > 0 then
  io.stderr:write(table.concat(errors, "\n") .. "\n")
  vim.cmd("cquit 1")
else
  io.stdout:write("Neovim startup, plugin loading, filetypes and keymaps passed\n")
  vim.cmd("qa!")
end
