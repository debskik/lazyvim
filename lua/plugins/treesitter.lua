return {
  -- Parsers on top of the LazyVim defaults (opts.ensure_installed is extended, not replaced).
  -- css: ui/src/index.css · groovy: AEM scripts · ini: .sqlfluff · editorconfig: .editorconfig
  -- git*: commit messages, .gitignore, .gitattributes and rebase todo files
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "css",
        "groovy",
        "ini",
        "editorconfig",
        "gitcommit",
        "gitignore",
        "gitattributes",
        "git_rebase",
      },
    },
  },
}
