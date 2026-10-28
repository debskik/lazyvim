-- Jars on the groovy-language-server classpath (AEM / Groovy scripts).
-- scripts/groovy-libs.tsv is the single source (name, Maven Central URL, SHA-256);
-- scripts/install-libs.sh downloads and verifies them into this directory.
local M = {}

---@return string
function M.dir()
  return vim.fn.expand(vim.env.GROOVY_LIBS_DIR or "~/libs")
end

---@return string[] file names listed in the manifest
function M.names()
  local manifest = vim.fn.stdpath("config") .. "/scripts/groovy-libs.tsv"
  local names = {}
  if vim.fn.filereadable(manifest) == 1 then
    for _, line in ipairs(vim.fn.readfile(manifest)) do
      local name = line:match("^([^#%s][^\t]*)\t")
      if name then
        table.insert(names, name)
      end
    end
  end
  return names
end

---@return string[] absolute jar paths
function M.classpath()
  local dir = M.dir()
  return vim.tbl_map(function(name)
    return dir .. "/" .. name
  end, M.names())
end

return M
