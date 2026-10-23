return {
  -- 1. Ensure Mason installs binaries
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "shellcheck",
        "shfmt",
        "npm-groovy-lint",
        "groovy-language-server",
      })
    end,
  },

  -- 2. Configure Mason-LSPconfig
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "groovyls" },
    },
  },

  -- 3. Configure nvim-lspconfig (with vim.fn.expand for the JARs)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        groovyls = {
          filetypes = { "groovy" },
          settings = {
            groovy = {
              classpath = {
                -- AEM 6.5 Primary API
                vim.fn.expand("~/libs/adobe-aem-uber-jar-6.5.22.jar"),

                -- Groovy 4.0.22 Modules
                vim.fn.expand("~/libs/groovy-4.0.22.jar"),
                vim.fn.expand("~/libs/groovy-dateutil-4.0.22.jar"),
                vim.fn.expand("~/libs/groovy-json-4.0.22.jar"),
                vim.fn.expand("~/libs/groovy-nio-4.0.22.jar"),
                vim.fn.expand("~/libs/groovy-templates-4.0.22.jar"),
                vim.fn.expand("~/libs/groovy-xml-4.0.22.jar"),
                vim.fn.expand("~/libs/groovy-yaml-4.0.22.jar"),

                -- AEM Groovy Console API & Bundle
                vim.fn.expand("~/libs/aem-groovy-console-api-19.0.8.jar"),
                vim.fn.expand("~/libs/aem-groovy-console-bundle-19.0.8.jar"),
              },
            },
          },
        },
      },
    },
  },

  -- 4. Hook nvim-lint (file-based npm-groovy-lint with --no-parse)
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.sh = { "shellcheck" }
      opts.linters_by_ft.bash = { "shellcheck" }
      opts.linters_by_ft.groovy = { "npm-groovy-lint" }

      -- Lint the file on disk instead of stdin: npm-groovy-lint reads the nvim-lint
      -- stdin pipe non-blocking, crashes with EAGAIN (exit 2) and, as the exit code is
      -- ignored, yields silently empty diagnostics. Args set (not appended) so a
      -- re-run of this opts function can't duplicate --no-parse.
      local lint = require("lint")
      local npm_groovy_lint = lint.linters["npm-groovy-lint"]
      if npm_groovy_lint then
        npm_groovy_lint.stdin = false
        npm_groovy_lint.args = { "--no-parse", "-o", "json" }
      end
    end,
  },

  -- 5. Hook conform.nvim (Formatting)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
        groovy = { "npm-groovy-lint" },
      },
    },
  },
}
