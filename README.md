# Neovim configuration (LazyVim)

[LazyVim](https://www.lazyvim.org) with the extras and tooling used for Python, Shell, SQL,
Docker, TypeScript, YAML/JSON/Markdown, Groovy (AEM scripts) and Java. Everything that has to be
installed on a machine is declared in this repository, so a new workstation is one clone and one
script.

## New machine

```bash
git clone <repository-url> ~/.config/nvim
~/.config/nvim/scripts/bootstrap.sh --optional
```

`bootstrap.sh` runs, in this order:

1. `install-prereqs.sh` — system packages through `apt` or `zypper` (needs `sudo`; skip with `--no-system`)
2. `install-libs.sh` — the Groovy / AEM jars, verified by SHA-256
3. plugins at the commits of `lazy-lock.json`
4. all Mason packages and Treesitter parsers, headless, with retries
5. `verify.sh` — exit code 1 when anything is missing

Then set a Nerd Font in the terminal (see [Fonts](#fonts)) and start `nvim`.

`scripts/verify.sh` can be run at any time; it installs nothing.

## Prerequisites

Neovim **0.11.2 or newer** (LazyVim requirement), `git`, a C compiler and the programs below.
The package names were checked against Ubuntu 26.04 (installed and queried with `apt`) and against the
repository metadata of openSUSE Leap 16.0 and Tumbleweed (not installed on an openSUSE host).

### Ubuntu 26.04 LTS

```bash
sudo apt-get update
sudo apt-get install -y neovim git curl wget unzip tar gzip build-essential tree-sitter-cli \
    ripgrep fd-find fzf lazygit nodejs npm python3 python3-venv openjdk-25-jdk-headless

# optional: clipboard on a native Linux desktop, image preview in the terminal
sudo apt-get install -y xclip wl-clipboard imagemagick ghostscript
```

Versions in 26.04: neovim 0.11.6, tree-sitter-cli 0.25.9, nodejs 22, ripgrep 15.1, fzf 0.67,
lazygit 0.57.

### openSUSE Leap 16.0 and Tumbleweed

```bash
sudo zypper install --no-recommends neovim git curl wget unzip tar gzip \
    patterns-devel-base-devel_basis tree-sitter ripgrep fd fzf lazygit \
    nodejs-default npm-default python3 python3-pip java-25-openjdk-headless

# optional
sudo zypper install --no-recommends xclip wl-clipboard ImageMagick ghostscript
```

The `tree-sitter` package ships the `tree-sitter` command. Leap 16.0 has neovim 0.11.3,
tree-sitter 0.25.3 and lazygit 0.41; Tumbleweed has neovim 0.12.6, tree-sitter 0.27.0 and lazygit 0.66.
`python3` is provided by `python313` on both.

`scripts/install-prereqs.sh [--optional] [--dry-run]` runs the matching commands for the distribution
it finds in `/etc/os-release`.

### What needs what

| Program | Used by |
| --- | --- |
| `git`, `curl`, `tar`, `unzip`, `gzip` | lazy.nvim, Mason (downloads and unpacks every package) |
| `gcc`, `make` | building the Treesitter parsers |
| `tree-sitter` (CLI) | nvim-treesitter, main branch; its README names 0.26.1 as the minimum, 0.25.9 builds every parser listed here. If a parser fails to build, install a newer CLI from the project's releases |
| `ripgrep`, `fd` (or `fdfind`), `fzf` | file and text search (Snacks picker) |
| `lazygit` | the git UI (`<leader>gg`) |
| `node`, `npm` | Mason packages written in JavaScript (pyright, vtsls, bash/yaml/docker servers, markdownlint, npm-groovy-lint) |
| `python3` with `venv` | Mason packages from PyPI (ruff, sqlfluff) |
| JDK 25 | jdtls; Mason's Java-based packages (groovy-language-server, npm-groovy-lint) run on the default `java` |
| `xclip` or `wl-clipboard` | system clipboard on a Linux desktop (on WSL the Windows clipboard is used) |
| `imagemagick`, `ghostscript` | inline image and PDF preview (Snacks image, kitty-protocol terminals only) |

### Java

jdtls v1.63 needs **Java 25**. Its launcher script only checks for Java 21, but the Eclipse bundles
it ships require Java 25: with 21 the server dies at start-up and attaches nothing (the reason is in
`~/.cache/nvim/jdtls/<project>/config/*.log`). Both Ubuntu 26.04 and openSUSE package JDK 25.

The default `java` of a machine may stay older (for example Java 17 for AEM tooling):
`lua/config/jdk.lua` looks for a JDK 25+ in `$JDTLS_JAVA_HOME`, `/usr/lib/jvm`, `/usr/lib64/jvm`,
`~/.sdkman/candidates/java`, `~/.jdks`, `/opt/java` and `/opt/jdk*` and passes it to jdtls only. A
warning is shown when none is found. `JDTLS_MIN` in `jdk.lua` is the one number to raise when a newer
jdtls asks for more.

### Fonts

LazyVim draws icons from a [Nerd Font](https://www.nerdfonts.com); set one in the terminal emulator.
On WSL the font has to be installed on **Windows**, not in the distribution.

```bash
# Linux desktop, any font family from https://github.com/ryanoasis/nerd-fonts/releases
mkdir -p ~/.local/share/fonts && curl -fsSL \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz |
    tar -xJ -C ~/.local/share/fonts && fc-cache -f
```

openSUSE also packages the symbols alone, which work next to any font:
`symbols-only-nerd-fonts` (Leap 16.0) or `nerdfonts-symbolsonly-fonts` (Tumbleweed).

## Layout

| Path | Purpose |
| --- | --- |
| `init.lua`, `lua/config/lazy.lua` | bootstrap lazy.nvim and import LazyVim and `lua/plugins` |
| `lazyvim.json` | enabled LazyVim extras |
| `lazy-lock.json` | plugin commits; commit it after `:Lazy update` |
| `lua/plugins/mason.lua` | **every Mason package** (language servers, linters, formatters) |
| `lua/plugins/treesitter.lua` | Treesitter parsers on top of the LazyVim defaults |
| `lua/plugins/linters.lua` | shellcheck for sh and bash, Groovy server and linter, shfmt, sqlfluff formatter |
| `lua/plugins/java.lua` | points jdtls at a JDK 25+ |
| `lua/config/options.lua` | docker-compose file type |
| `lua/config/groovy_libs.lua` | classpath of the Groovy server, read from `scripts/groovy-libs.tsv` |
| `lua/config/jdk.lua` | JDK discovery |
| `lua/config/bootstrap.lua` | headless `install()` and `check()` behind the scripts |
| `after/ftplugin/sh.lua` | 4-space indent in shell scripts |
| `scripts/` | `bootstrap.sh`, `verify.sh`, `install-prereqs.sh`, `install-libs.sh`, `groovy-libs.tsv` |

## Mason packages

| Package | For |
| --- | --- |
| `bash-language-server`, `shellcheck`, `shfmt` | shell scripts |
| `pyright`, `ruff` | Python (types; lint and format) |
| `vtsls` | TypeScript, JavaScript, TSX |
| `yaml-language-server`, `json-lsp` | YAML, JSON (with SchemaStore) |
| `dockerfile-language-server`, `docker-compose-language-service`, `hadolint` | Dockerfile, compose files |
| `marksman`, `markdownlint-cli2`, `markdown-toc` | Markdown |
| `sqlfluff` | SQL lint and format (dialect from the project's `.sqlfluff`, ANSI without one) |
| `groovy-language-server`, `npm-groovy-lint` | Groovy and AEM scripts |
| `jdtls` | Java |
| `lua-language-server`, `stylua` | this configuration |

Adding a tool is one line in `lua/plugins/mason.lua`.

## Groovy and AEM jars

The Groovy server completes against the AEM 6.5.22 uber jar, Groovy 4.0.22 and the AEM Groovy Console
19.0.8 jars. They are not stored in git; `scripts/groovy-libs.tsv` lists their Maven Central URLs
and SHA-256 sums, `scripts/install-libs.sh` downloads them to `~/libs` (`GROOVY_LIBS_DIR` changes the
directory) and `scripts/install-libs.sh --check` verifies them.

## Differences from stock LazyVim

- **SQL formatting.** The LazyVim SQL extra forces `sqlfluff --dialect=ansi`, which overrides a
  project's `.sqlfluff` and fails on MySQL scripts. The formatter now runs from the directory of the
  nearest `.sqlfluff` without `--dialect`, and keeps ANSI only for projects without one.
- **Compose files.** Neovim 0.11 types `docker-compose.yml` as plain `yaml`, so the compose language
  server never attached. `options.lua` maps the compose file names to `yaml.docker-compose`.
- **Groovy lint.** `npm-groovy-lint` reads the file on disk (`--no-parse`): through stdin it crashed
  with `EAGAIN` and produced no diagnostics.
- **Headless installs.** LazyVim installs language servers only when a server is first needed, which
  never happens in a headless run. Listing every package in `mason.lua` makes
  `scripts/bootstrap.sh` independent of that.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `jdtls requires at least Java 21`, or jdtls never attaches and its log says `Application "org.eclipse.jdt.ls.core.id1" could not be found` | the JDK is too old: install JDK 25+ or set `$JDTLS_JAVA_HOME` |
| `:checkhealth lazy` warns about `luarocks` | harmless, no plugin here needs it |
| a parser fails to build | `:TSLog`; check `gcc` and the `tree-sitter` version |
| first start is slow | Mason and the parsers install in the background; run `scripts/bootstrap.sh` once |
| `lazy-lock.json` shows up as modified | `:Lazy update` changed it on purpose, or `git checkout lazy-lock.json` |
| icons are boxes | the terminal does not use a Nerd Font |
