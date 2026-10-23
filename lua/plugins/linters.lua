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

  -- 2. Configure Mason-LSPconfig to auto-setup language servers
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "groovyls" },
    },
  },

  -- 3. Configure nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        groovyls = {
          filetypes = { "groovy" },
        },
      },
    },
  },

  -- 4. Hook nvim-lint (Diagnostics)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        groovy = { "npm-groovy-lint" },
      },
    },
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
