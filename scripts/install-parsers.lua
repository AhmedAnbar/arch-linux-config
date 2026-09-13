-- The pinned Tree-sitter master branch provides a noninteractive ensure API.
-- TSInstallSync asks to reinstall existing parsers, which loops in headless mode.
local languages = require("nvim-treesitter.configs").get_ensure_installed_parsers()
assert(type(languages) == "table" and #languages > 0, "No syntax parsers configured")
require("nvim-treesitter.install").ensure_installed_sync(languages)

-- Tree-sitter reports some build failures without a nonzero process exit code.
-- Verify each parser can actually load before letting the installer continue.
local failures = {}
for _, language in ipairs(languages) do
  local ok, result = pcall(vim.treesitter.language.add, language)
  if not ok or result == false then
    failures[#failures + 1] = language .. ": " .. tostring(result)
  end
end
if #failures > 0 then
  io.stderr:write("Syntax parser installation failed:\n" .. table.concat(failures, "\n") .. "\n")
  vim.cmd("cquit 1")
else
  io.stdout:write("All " .. #languages .. " configured parsers are available; existing parsers were kept.\n")
end
