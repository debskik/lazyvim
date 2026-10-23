-- Shell scripts (sh/bash): 4-space indentation.
-- conform.nvim passes shiftwidth to shfmt (-i 4) when no .editorconfig is found.
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true
