-- Headless helpers to set up or check a machine (scripts/bootstrap.sh, scripts/verify.sh):
--   nvim --headless -c "lua require('config.bootstrap').install()"   install, wait, report
--   nvim --headless -c "lua require('config.bootstrap').check()"     report only
-- Both exit with a non-zero code when something is missing.
-- What has to be there is read from the config itself: Mason packages from plugins/mason.lua,
-- Treesitter parsers from plugins/treesitter.lua plus the LazyVim defaults and extras.
local M = {}

-- Programs that LazyVim, Mason and the Treesitter parser builds call (any name of a group will do).
local BINARIES = {
  { "git" },
  { "curl" },
  { "tar" },
  { "unzip" },
  { "gzip" },
  { "gcc", "cc" },
  { "make" },
  { "tree-sitter" },
  { "rg" },
  { "fd", "fdfind" },
  { "fzf" },
  { "lazygit" },
  { "node" },
  { "npm" },
  { "python3" },
  { "java" },
}

local function say(msg)
  io.stdout:write(msg .. "\n")
end

local function opts_of(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin and require("lazy.core.plugin").values(plugin, "opts", false) or {}
end

local function sorted_unique(list)
  local copy = vim.deepcopy(list or {})
  table.sort(copy)
  return vim.fn.uniq(copy)
end

local function load_plugins()
  require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter" } })
end

---@return table state of the Mason packages and Treesitter parsers the config asks for
local function state()
  local mason = sorted_unique(opts_of("mason.nvim").ensure_installed)
  local parsers = sorted_unique(opts_of("nvim-treesitter").ensure_installed)
  local s = {
    mason_total = #mason,
    ts_total = #parsers,
    mason_missing = {},
    mason_busy = 0,
    ts_missing = {},
  }

  local registry = require("mason-registry")
  for _, name in ipairs(mason) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and pkg:is_installing() then
      s.mason_busy = s.mason_busy + 1
    end
    if not ok or not pkg:is_installed() then
      table.insert(s.mason_missing, name)
    end
  end

  local have = {}
  for _, lang in ipairs(require("nvim-treesitter").get_installed()) do
    have[lang] = true
  end
  for _, lang in ipairs(parsers) do
    if not have[lang] then
      table.insert(s.ts_missing, lang)
    end
  end
  return s
end

---@return boolean all good
local function report(s)
  local good = true
  local function line(ok, text)
    say(string.format("  %s %s", ok and "ok     " or "MISSING", text))
    good = good and ok
  end

  say("Programs")
  for _, group in ipairs(BINARIES) do
    local found
    for _, name in ipairs(group) do
      found = found or (vim.fn.executable(name) == 1 and name)
    end
    line(found ~= nil and found ~= false, table.concat(group, " / "))
  end

  local jdk = require("config.jdk")
  say(string.format("Java for jdtls (needs %d or newer)", jdk.JDTLS_MIN))
  local default = jdk.default()
  local default_major = default ~= "" and jdk.major(default) or 0
  local java = default_major >= jdk.JDTLS_MIN and default or jdk.find_for_jdtls()
  line(
    java ~= nil,
    java and string.format("%s (%d)", java, jdk.major(java))
      or string.format("no JDK %d+ found", jdk.JDTLS_MIN)
  )

  say(string.format("Mason packages (%d)", s.mason_total))
  line(
    #s.mason_missing == 0,
    #s.mason_missing == 0 and "all installed" or table.concat(s.mason_missing, ", ")
  )

  say(string.format("Treesitter parsers (%d)", s.ts_total))
  line(
    #s.ts_missing == 0,
    #s.ts_missing == 0 and "all installed" or table.concat(s.ts_missing, ", ")
  )

  say("Groovy classpath jars (" .. require("config.groovy_libs").dir() .. ")")
  local missing_jars = {}
  for _, jar in ipairs(require("config.groovy_libs").classpath()) do
    if vim.fn.filereadable(jar) == 0 then
      table.insert(missing_jars, vim.fn.fnamemodify(jar, ":t"))
    end
  end
  line(#missing_jars == 0, #missing_jars == 0 and "all present" or table.concat(missing_jars, ", "))
  return good
end

local function finish(ok)
  vim.cmd(ok and "qa!" or "cquit 1")
end

function M.check()
  load_plugins()
  finish(report(state()))
end

---@param opts? { timeout?: integer } seconds to wait, default 1800
function M.install(opts)
  local timeout = (opts and opts.timeout) or 1800
  load_plugins()
  -- loading the plugins starts the installs; this loop waits for them and retries what failed
  local registry = require("mason-registry")
  local start = vim.uv.now()
  local last_progress, last_done = vim.uv.now(), -1
  local mason_tries, ts_tries = {}, 0

  local timer = vim.uv.new_timer()
  timer:start(
    5000,
    5000,
    vim.schedule_wrap(function()
      local s = state()
      local elapsed = (vim.uv.now() - start) / 1000
      local done = (s.mason_total - #s.mason_missing) + (s.ts_total - #s.ts_missing)
      if done ~= last_done then
        last_done, last_progress = done, vim.uv.now()
      end
      local stalled = (vim.uv.now() - last_progress) / 1000
      say(
        string.format(
          "[bootstrap] %4ds  mason %d/%d (%d installing)  treesitter %d/%d",
          elapsed,
          s.mason_total - #s.mason_missing,
          s.mason_total,
          s.mason_busy,
          s.ts_total - #s.ts_missing,
          s.ts_total
        )
      )

      if #s.mason_missing == 0 and #s.ts_missing == 0 then
        timer:stop()
        return finish(report(s))
      end

      -- nothing moved for a while: retry what is missing (twice), then give up
      local gave_up = false
      if s.mason_busy == 0 and stalled > 30 then
        local retried = false
        for _, name in ipairs(s.mason_missing) do
          local ok, pkg = pcall(registry.get_package, name)
          mason_tries[name] = (mason_tries[name] or 0) + 1
          if ok and mason_tries[name] <= 2 then
            pkg:install()
            retried = true
          end
        end
        if #s.ts_missing > 0 and ts_tries < 2 then
          ts_tries = ts_tries + 1
          require("nvim-treesitter").install(s.ts_missing)
          retried = true
        end
        if retried then
          last_progress = vim.uv.now()
        else
          gave_up = true
        end
      end

      if gave_up or elapsed > timeout then
        timer:stop()
        say(gave_up and "[bootstrap] giving up, see :Mason and :TSLog" or "[bootstrap] timeout")
        finish(report(s))
      end
    end)
  )
end

return M
