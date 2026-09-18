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
  -- Empty buffers miss injection/predicate API errors: parse actual content.
  local fixtures = {
    { "markdown", "# Test\n```ts\nconst value: number = 1;\n```\n<script type=\"module\">const x = 1;</script>" },
    { "html", '<script type="application/ecmascript">const x = 1;</script><style>body { color: red; }</style>' },
    { "lua", 'local function greet(name) return "Hello " .. name end\ngreet("world")' },
    { "php", '<?php function greet(string $name): string { return "Hello " . $name; }' },
    { "blade", '<div>@if($ready)<span>{{ $name }}</span>@endif</div>' },
  }
  local function parse_buffer()
    local parser = vim.treesitter.get_parser(0)
    assert(parser:parse(true), "Tree-sitter parse failed")
    parser:for_each_tree(function(tree, language_tree)
      local query = vim.treesitter.query.get(language_tree:lang(), "highlights")
      if query then
        for _ in query:iter_captures(tree:root(), 0) do end
      end
    end)
  end
  for _, fixture in ipairs(fixtures) do
    vim.cmd.enew()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(fixture[2], "\n", { plain = true }))
    vim.bo.filetype = fixture[1]
    local success, failure = pcall(parse_buffer)
    if not success then table.insert(errors, fixture[1] .. ": " .. tostring(failure)) end
    vim.bo.modified = false
  end
  local repo = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
  vim.cmd.edit(vim.fn.fnameescape(repo .. "/README.md"))
  local parsed, failure = pcall(parse_buffer)
  if not parsed then table.insert(errors, "README: " .. tostring(failure)) end
  assert(vim.g.colors_name == "catppuccin-mocha", "Catppuccin Mocha is not active")
  assert(not require("catppuccin").options.transparent_background, "Editor background should be opaque")
  assert(vim.api.nvim_get_hl(0, { name = "Normal" }).bg, "Editor background color is missing")
  require("lualine.utils.notices").show_notices()
  local notices = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  if notices:match("%S") then table.insert(errors, "Lualine: " .. notices) end
  vim.cmd.close()
  assert(vim.g.mapleader == " ", "Leader should be Space")
  assert(vim.fn.maparg(" ?", "n") ~= "", "Space + ? is missing")
  assert(vim.lsp.config.laravel_lsp.filetypes[2] == "blade", "Laravel/Blade LSP missing")
  -- phpactor's phar refuses to start without iconv; it is enabled for phpactor's own
  -- processes through PHP_INI_SCAN_DIR instead of the global php.ini.
  local phpactor_env = (vim.lsp.config.phpactor or {}).cmd_env or {}
  assert((phpactor_env.PHP_INI_SCAN_DIR or ""):find("phpactor/php.d", 1, true),
    "phpactor must load its iconv ini through PHP_INI_SCAN_DIR")
  end
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
  io.stdout:write("Neovim startup, plugins, filetypes, real-content parsing and keymaps passed\n")
  vim.cmd("qa!")
end
