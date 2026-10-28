-- Every tool that Mason has to provide, in one place. A new machine gets all of them on the first
-- start (or headless with scripts/bootstrap.sh). LazyVim extends ensure_installed (opts_extend), so
-- names that an enabled extra also lists are harmless duplicates. Add a tool = add it here.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- language servers
        "bash-language-server", -- sh, bash
        "docker-compose-language-service", -- docker-compose.yml / compose.yaml
        "dockerfile-language-server", -- Dockerfile
        "groovy-language-server", -- Groovy / AEM scripts (classpath: config/groovy_libs.lua)
        "jdtls", -- Java (needs JDK 25+, see config/jdk.lua)
        "json-lsp", -- JSON
        "lua-language-server", -- this config
        "marksman", -- Markdown
        "pyright", -- Python types
        "ruff", -- Python lint + format (LSP)
        "vtsls", -- TypeScript / JavaScript / TSX
        "yaml-language-server", -- YAML

        -- linters and formatters
        "hadolint", -- Dockerfile lint
        "markdown-toc", -- Markdown table of contents
        "markdownlint-cli2", -- Markdown lint
        "npm-groovy-lint", -- Groovy lint + format
        "shellcheck", -- sh / bash lint
        "shfmt", -- sh / bash format
        "sqlfluff", -- SQL lint + format
        "stylua", -- Lua format
      },
    },
  },
}
