-- Mason packages are listed in plugins/mason.lua.
return {
  -- 1. Configure Mason-LSPconfig
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "groovyls" },
    },
  },

  -- 2. Configure nvim-lspconfig: Groovy classpath = the jars of scripts/groovy-libs.tsv in
  --    $GROOVY_LIBS_DIR (default ~/libs); scripts/install-libs.sh downloads them.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        groovyls = {
          filetypes = { "groovy" },
          settings = {
            groovy = {
              classpath = require("config.groovy_libs").classpath(),
            },
          },
        },
      },
    },
  },

  -- 3. Hook nvim-lint (file-based npm-groovy-lint with --no-parse)
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

  -- 4. Hook conform.nvim (Formatting)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.sh = { "shfmt" }
      opts.formatters_by_ft.bash = { "shfmt" }
      opts.formatters_by_ft.groovy = { "npm-groovy-lint" }

      -- The LazyVim sql extra forces `--dialect=ansi`, which overrides .sqlfluff and fails
      -- (exit 1, parse error) on MySQL scripts. Let a project's .sqlfluff pick the dialect
      -- and keep ansi only for projects without one.
      opts.formatters = opts.formatters or {}
      opts.formatters.sqlfluff = {
        cwd = function(_, ctx)
          local found =
            vim.fs.find(".sqlfluff", { upward = true, path = ctx.dirname, limit = 1 })[1]
          return found and vim.fs.dirname(found) or ctx.dirname
        end,
        args = function(_, ctx)
          if vim.fs.find(".sqlfluff", { upward = true, path = ctx.dirname, limit = 1 })[1] then
            return { "format", "-" }
          end
          return { "format", "--dialect=ansi", "-" }
        end,
      }
    end,
  },
}
