-- JDK discovery. jdtls (Mason package) needs a recent JDK while other tools on the machine may need
-- an older default `java` (for example Java 17 for AEM).
local M = {}

-- jdtls v1.63: the launcher script only checks for Java 21, but its Eclipse bundles require Java 25
-- (with 21 it dies with "Application org.eclipse.jdt.ls.core.id1 could not be found in the registry").
-- Raise this number when a newer jdtls asks for more.
M.JDTLS_MIN = 25

---@param java string path of a java executable
---@return integer major version, 0 when it cannot be determined
function M.major(java)
  local ok, res = pcall(function()
    return vim.system({ java, "-version" }, { text = true }):wait(5000)
  end)
  if not ok or not res then
    return 0
  end
  return tonumber((res.stderr .. res.stdout):match('version "(%d+)')) or 0
end

---@return string path of the `java` a plain `java` call would run, "" when there is none
function M.default()
  local home = vim.env.JAVA_HOME
  if home and vim.fn.executable(home .. "/bin/java") == 1 then
    return home .. "/bin/java"
  end
  return vim.fn.exepath("java")
end

---@return string? java executable of a JDK that jdtls can run on: $JDTLS_JAVA_HOME, then the usual install locations
function M.find_for_jdtls()
  local candidates = {}
  if vim.env.JDTLS_JAVA_HOME and vim.env.JDTLS_JAVA_HOME ~= "" then
    table.insert(candidates, vim.env.JDTLS_JAVA_HOME .. "/bin/java")
  end
  for _, pattern in ipairs({
    "/usr/lib/jvm/*", -- Debian, Ubuntu, Fedora
    "/usr/lib64/jvm/*", -- openSUSE
    "~/.sdkman/candidates/java/*",
    "~/.jdks/*",
    "/opt/java/*",
    "/opt/jdk*",
  }) do
    for _, dir in ipairs(vim.fn.glob(pattern, false, true)) do
      table.insert(candidates, dir .. "/bin/java")
    end
  end

  local best, best_major = nil, M.JDTLS_MIN - 1
  for _, java in ipairs(candidates) do
    if vim.fn.executable(java) == 1 then
      local major = M.major(java)
      if major > best_major then
        best, best_major = java, major
      end
    end
  end
  return best
end

return M
