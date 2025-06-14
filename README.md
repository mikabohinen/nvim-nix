# nvim-nix

An opinionated, principled, and distraction free Neovim environment that just works.

This is my personal Neovim configuration. I'm sharing it not because I think
everyone should use it exactly as-is, but because I've spent a lot of time
thinking through the principles behind editor configuration, and I think the
approach might be useful to others.

The basic idea is this: most modern Neovim configs try to turn your editor into
an IDE by adding dozens of plugins and abstractions. I went the opposite
direction. I use only 8 plugins, all of which enhance Vim's existing
capabilities rather than replacing them. Everything is built with Nix for
perfect reproducibility.

If you like the philosophy here, you should fork this repository and
adapt it to your own needs. Remove the Lisp stuff if you don't write Lisp. Add
Rust support if that's what you do. The point isn't that my exact setup is
perfect for you, but that the systematic approach to making these decisions
might be helpful.

## Features

- **Minimal**: Only 8 plugins for maximum performance and focus
- **Reproducible**: Exact same setup on any machine with Nix
- **Fast**: ~36ms startup time vs 200ms+ for typical modern configs
- **Principled**: Every decision documented and reasoned through

## Prerequisites

You'll need a few things before getting started:

**Nix with flakes enabled**:
```bash
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

**Basic Vim knowledge**: This config assumes you know Vim fundamentals. If
you're new to Vim, spend some time with vanilla Vim first to learn the core
concepts.

**Git**: For version control integration and cloning the repository.

## Quick Start

If you want to try this before committing to anything:

```bash
# Full development environment
nix run github:mikabohinen/nvim-nix#dev

# Just the editor
nix run github:mikabohinen/nvim-nix#neovim

# Development shell with all tools
nix develop github:mikabohinen/nvim-nix
```

## Philosophy

I have spent countless hours configuring (Neo)vim (often when I should have
been doing other more important things like studying or working). I started out
by writing a bloated vimrc with all plugins imaginable. Then I went over to
Neovim and Lua where I spent some time distro hopping between LazyVim, NvChad,
LunarVim, etc. Then I decided to write my own Lua config from scratch which
slowly turned into a hot mess of 100+ plugins which was supposed to accomplish
everything, but in reality made me spend most of my time reading documentation
for various plugins rather than getting any actual work done. I then went the
pure minimalist route and wrote my master's thesis using only vanilla vim.
The clarity of thought I gained from not having to fight my plugins all the
time meant I could focus 100% on writing my thesis instead of trying to understand
why my autocompletion mappings were not working the way I wanted them too. It
also made me realize that Vim is exceptionally capable on its own. However,
I also realized that there are a few things modern plugins provide that
vanilla Vim fundamentally cannot. This experience has led me to develop
my own philosophy about how to use (Neo)vim:

It is my opinion that mastery is more important in the long run than short term
productivity and convenience. This config therefore follows a principled
approach with only the most essential plugins that build upon the philosophy of
Vim itself. This builds upon a set of core principles:

1. **Vim-first**: Given that Vim has remained highly relevant for over 30 years
   one must conclude that Vim has touched upon something more fundamental than
   just the technology itself. Modern plugins and enhancements should therefore
   build upon this and not replace it with tools that hide away these
   fundamentals. This is why we prefer builtin tools like `:grep` or `:find`
   compared to their modern counterparts. On the other hand, LSP and Treesitter
   hook into these fundamentals to extend the capabilities of Vim itself.

2. **Reproducibility**: Modern tooling and environments grow increasingly
   complex day by day. This complexity isn't inherently bad as long as we can
   understand it. However, in a world where "works on my machine" is a common
   phrase it is valuable to have an environment in which you can be productive
   no matter where you are. You should be able to work with the same efficiency
   whether you are on your laptop, a server, a VM, or anywhere else. To achieve
   this we need a declarative configuration and not a set of imperative
   commands that you type into your terminal like a set of enchantments while
   you pray to the powers that be that everything works. Nix solves this by
   giving us absolute control over the dependency chain and environment state.

3. **Compositionality**: The power of Unix tools like `cd`, `ls`, `grep`,
   `awk`, etc., is their ability to be composed with each other through piping.
   We believe that this principle should be applied to the extensions we make
   to Vim itself. Every addition should be able to be composed with each other
   in a predictable way. In this way we can build increasingly complex
   workflows while still having a good understanding of what is happening at
   the more granular level.

These principles inform the choice of plugins.

## Plugin List

See [selection criteria](#Plugin-selection-criteria) for the exact details of
why these specific plugins are acceptable.

**Modern Necessities** (what vimscript can't handle well):

- **nvim-lspconfig**: Language server integration
- **nvim-treesitter + textobjects**: Enhanced syntax and structural navigation

**Editing** (amplify core Vim strengths):

- **vim-surround**: Text object manipulation
- **vim-repeat**: Quality of life addition
- **vim-vinegar**: Enhanced netrw

**Development Integration** (essential workflow tools):

- **vim-fugitive**: Git integration

**Lisp Exception** (structural editing for uniform syntax):

- **vim-sexp**: Paredit-style editing for s-expressions

**Total: 8 plugins** - 5 local (absolute control) + 3 nixpkgs (complex builds)

### Plugin Management

Pure Nix declarative plugin management replaces traditional plugin managers.

#### Local Plugins (5) - Managed via `plugins.nix`
```nix
# Declarative plugin definitions with exact version control
vim-surround = {
  owner = "tpope";
  repo = "vim-surround";
  rev = "3d188ed2113431cf8dac77be61b842acb64433d9";  # Exact commit
  sha256 = "sha256-abc123...";                       # Cryptographic integrity
};
```

#### Nixpkgs Plugins (3) - Managed via `default.nix`
Complex plugins that benefit from Nix's build system: nvim-lspconfig, nvim-treesitter, nvim-treesitter-textobjects.

#### Plugin Commands
```bash
# List all plugins with breakdown
nix run .#plugins list

# Show plugin statistics
nix run .#plugins stats

# Check for updates
nix run .#plugins check-updates

# Plugin management environment
nix develop .#plugins
```

### Plugin selection criteria

A plugin is excluded if it does one or more of these things:

1. Hides complexity you should understand
2. Replaces learning with convenience
3. Creates dependencies on specific abstractions
4. Violates Vim patterns
5. Provides convenience over capability

If a plugin doesn't violate any of the above then we will consider
it if and only if it also satisfies the following criteria:

1. Makes you a better developer
2. Provides capabilities Vim doesn't natively have
3. Builds upon Vim's philosophy
4. Reinforces good practices

#### Examples of excluded plugins

- **Fuzzy finders**: :find \*\*/\* is sufficient, and using :grep together with the quickfix list is better
- **Auto-formatters**: :!black % teaches you more
- **Visual git tools**: command-line git + fugitive forces you to grok git
- **Comment automation**: manual commenting teaches language syntax
- **Session managers**: :mksession covers 80% of use cases

## Architecture

### Three-Layer Approach

nvim-nix employs a three-layer architecture that leverages the strengths of
Nix, Vimscript, and Lua respectively. Each language does what it is good at and
no more:

#### Nix Layer (Infrastructure)

*"What should exist"*

- **Declarative Environment**: Packages, plugins, language servers, formatters
- **Reproducible Systems**: Identical setups across machines and time
- **Integration Logic**: Desktop entries, terminal detection, system configuration
- **Dependency Management**: All external tools with exact versions

```nix
# Nix handles: "Make these tools available"
languageServers = [ pkgs.pyright pkgs.rust-analyzer ];
plugins = [ vim-surround vim-fugitive ];
```

#### Vimscript Layer (Behavior)

*"How should Vim behave"*

- **Core Workflow**: Traditional Vim commands, mappings, patterns
- **User Interface**: Status line, quickfix integration, helper functions
- **Command Definitions**: All :commands and <leader> mappings
- **Editor Behavior**: Settings, autocommands, traditional vim features

```vim
" Vimscript handles: "How should the editor behave"
nnoremap <leader>fw :grep "" .<Left><Left><Left>
command! StripWhitespace call StripTrailingWhitespace()
```

#### Lua Layer (Modern Features)

*"How should modern features work"*

- **LSP Configuration**: Language server setup, capabilities, handlers
- **Dynamic Behavior**: Buffer-local keymaps that activate in response to LSP events
- **Modern APIs**: Diagnostic configuration, treesitter, floating windows
- **Event-Driven**: Autocommands that respond to LSP attachment

```lua
-- Lua handles: "How should modern features integrate"
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {buffer = event.buf})
  end,
})
```

#### Clean Boundaries

Each layer has clear responsibilities and interfaces:

- **Nix → Lua**: Provides tools and generates configuration
- **Lua → Vimscript**: Calls vim commands and integrates with existing patterns
- **No layer bypassing**: Each respects the others' domains

This architecture ensures that adding a language server happens in Nix,
defining key-mappings happens in Vimscript (with the exception of LSP
bindings), configuring LSP behavior happens in Lua. Each language does what it
is meant to do.

### File Structure

- `flake.nix` - Flake inputs/outputs with clean organization
- `plugins.nix` - Declarative plugin definitions with exact versions
- `lib/languages.nix` - Language support definitions
- `lib/plugin-management.nix` - Nix plugin utilities
- `lib/desktop.nix` - Desktop integration utilities
- `modules/` - Home Manager and NixOS integration modules
- `vimrc.vim` - Core vim configuration following traditional patterns

### Plugin Architecture

```
Plugins (8 total)
├── Local Plugins (5) - plugins.nix
│   ├── vim-surround
│   ├── vim-vinegar
│   ├── vim-repeat
│   ├── vim-fugitive
│   └── vim-sexp
└── Nixpkgs Plugins (3) - default.nix
    ├── nvim-lspconfig
    ├── nvim-treesitter
    └── nvim-treesitter-textobjects
```

## Supported Languages

Each language includes appropriate tooling based on ecosystem maturity:

| Language        | LSP     | Treesitter   | Formatter          | Notes |
| --------------- | ------- | ------------ | ------------------ | ------- |
| **Bash**        | bashls  | ✓            | shfmt              | Full shell scripting support |
| **Haskell**     | hls     | ✓            | fourmolu           | Complete functional programming |
| **Java**        | jdtls   | ✓            | google-java-format | Enterprise development |
| **Common Lisp** | —       | ✓            | —                  | Structural editing with vim-sexp |
| **Markdown**    | —       | ✓            | prettier           | Documentation writing |
| **Nix**         | nixd    | ✓            | nixpkgs-fmt        | First-class Nix support |
| **LaTeX**       | texlab  | ✓            | —                  | Academic writing |
| **Lua**         | —       | ✓            | stylua             | Neovim configuration |
| **Python**      | pyright | ✓            | black              | Modern Python development |

## Installation

This assumes you're using Nix flakes.

### Home Manager

Add to your `flake.nix`:

```nix
{
  description = "Your home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-nix = {
      url = "github:mikabohinen/nvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nvim-nix, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux; # or your system
      modules = [
        nvim-nix.homeManagerModules.default
        {
          programs.nvimNix = {
            enable = true;
            enableDevTools = true; # Install formatters, linters, etc.
          };
        }
      ];
    };
  };
}
```

Or if you already have a `home.nix`, add this to your existing configuration:

```nix
# In your home.nix or home-manager module
{
  imports = [ inputs.nvim-nix.homeManagerModules.default ];

  programs.nvimNix = {
    enable = true;
    enableDevTools = true;
  };
}
```

### NixOS System-wide

Add to your `flake.nix`:

```nix
{
  description = "Your NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-nix = {
      url = "github:mikabohinen/nvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nvim-nix, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or your system
      modules = [
        nvim-nix.nixosModules.default
        {
          programs.nvimNix = {
            enable = true;
            defaultEditor = true;
            enableDevTools = true;
          };
        }
      ];
    };
  };
}
```

Or if you already have a `configuration.nix`, add this to your existing configuration:

```nix
# In your configuration.nix or NixOS module
{
  imports = [ inputs.nvim-nix.nixosModules.default ];

  programs.nvimNix = {
    enable = true;
    defaultEditor = true;
    enableDevTools = true;
  };
}
```

### Package Variants

- **`#neovim`**: Minimal editor with LSP support only
- **`#default`**: Full editor with all development tools
- **`#dev`**: App launcher with proper PATH for all tools
- **`#dev-tools`**: Just the development tools (formatters, linters, etc.)

## Key Bindings

My key bindings follow consistent patterns to make them easier to remember and
use. Rather than scattering related functions across random key combinations, I
group them logically.

### Core Patterns

**Leader key**: `<Space>` for global operations
**Local leader**: `,` for filetype-specific operations

All bindings follow functional grouping:
- `<leader>f*`: All "finding" operations (files, buffers, search)
- `<leader>g*`: Git operations
- `<leader>c*`: Code operations (LSP, diagnostics, formatting)
- `<leader>cd*`: Code diagnostic operations specifically
- `<leader>n*`: Nix development workflow
- `<leader>w*`: Workspace management (LSP)

This way, once you remember that `f` means "find", you can guess that
`<leader>fw` probably searches the workspace, `<leader>ff` finds files, etc.

### Finding and Navigation

The core of any editor workflow is finding things quickly. Vim's built-in tools
are powerful once you learn them:

```vim
" File finding (vim native - teaches you about path and wildcards)
<leader><leader>  " :find * (quick access)
<leader>ff        " :find * (explicit)
<leader>fF        " :find **/* (recursive search)

" Buffer operations (work with vim's buffer model)
<leader>fb       " :buffer * (find and open)
<leader>fB       " :sbuffer * (find and split)
[b / ]b          " Previous/next buffer (follows vim's ][ pattern)
<leader>bd       " Delete buffer

" Search operations (builds on grep/vimgrep)
<leader>fw       " :grep "" . (project-wide search)
<leader>fW       " :vimgrep // **/* (vim's internal search)
<leader>fs       " :lgrep "" . (location list search)
<leader>fS       " :lvimgrep // **/* (location list vim search)
```

The point here is that you're learning transferable skills. `:find` works on
any Vim installation. Understanding the difference between quickfix and
location lists helps you on any system.

### Lists and Navigation

Vim's list management is incredibly powerful once you understand it:

```vim
" Quickfix & Location Lists (core vim navigation)
<leader>q / <leader>Q   " Open/close quickfix
<leader>l / <leader>L   " Open/close location list
]q / [q                 " Next/previous quickfix (vim's standard pattern)
]l / [l                 " Next/previous location list

" Window movement (simplified from default C-w commands)
<C-J>                   " Move to next window
<C-K>                   " Move to previous window
```

### Enhanced Search

```vim
" Enhanced search patterns (very magic mode makes regex more predictable)
<leader>/        " Search with \v (very magic)
<leader>?        " Reverse search with \v (very magic)

" Search control
<Esc><Esc>       " Clear search highlighting
n / N            " Next/previous search (auto-centered)
* / #            " Search word under cursor (auto-centered)
```

### LSP and Modern Features

These mappings only activate when LSP is attached to a buffer, so they don't interfere with regular Vim usage:

```vim
" Core LSP navigation (buffer-local, only when LSP is attached)
gd               " Go to definition
gr               " Go to references
gi               " Go to implementation
gD               " Go to declaration
gy               " Go to type definition
K                " Hover documentation
<leader>cr       " Rename symbol
<leader>ca       " Code actions (normal and visual mode)
<leader>ck       " Signature help
```

**Diagnostic navigation** follows vim's `]q`/`[q` pattern for consistency:

```vim
]d / [d          " Next/previous diagnostic
]D / [D          " Next/previous error (skips warnings)
```

**Diagnostic operations** are grouped under `<leader>cd` for "code diagnostic":

```vim
<leader>cdf      " Show diagnostic float (quick peek, auto-closes)
<leader>cdF      " Show diagnostic float (scrollable, focusable)
<leader>cdl      " Send buffer diagnostics to location list
<leader>cdq      " Send all diagnostics to quickfix list
<leader>cds      " Show diagnostic summary (error/warning/hint counts)
<leader>cdt      " Toggle virtual text diagnostics on/off
```

**LSP management** (always available):

```vim
<leader>cR       " Restart LSP client
<leader>cI       " Show LSP info
```

**Workspace management** (buffer-local, LSP-specific):

```vim
<leader>wa       " Add workspace folder
<leader>wr       " Remove workspace folder
<leader>wl       " List workspace folders
```

### Treesitter Features

**Text objects** work with operators like `d`, `y`, `c`:

```vim
af / if          " Around/inside function
ac / ic          " Around/inside class
al / il          " Around/inside loop
aa / ia          " Around/inside parameter
```

**Movement** follows vim's `][` convention:

```vim
]f / [f          " Next/previous function start
]c / [c          " Next/previous class start
]F / [F          " Next/previous function end
]C / [C          " Next/previous class end
```

**Incremental selection** (for precise text selection):

```vim
gnn              " Start incremental selection
grn              " Increment to next node
grc              " Increment to scope
grm              " Decrement selection
```

### Nix Development Workflow

Since this config is built with Nix, I've integrated Nix commands directly:

```vim
" Global Nix operations (available everywhere)
<leader>nr       " :NixRun (with prompt)
<leader>nb       " :NixBuild (with prompt)
<leader>ns       " Enter nix develop shell
<leader>nu       " Update flake.lock
<leader>nc       " Check flake
<leader>ni       " Show flake info
<leader>nS       " Search packages (with prompt)
<leader>ne       " Evaluate expression (with prompt)
<leader>nC       " Clean nix store

" Quick file access
<leader>ef       " Edit flake.nix
<leader>ed       " Edit default.nix
```

**Nix file-specific mappings** (in .nix files only):

```vim
<localleader>r   " Run current flake
<localleader>b   " Build current flake
<localleader>c   " Check current flake
<localleader>u   " Update flake.lock
<localleader>s   " Enter nix shell
<localleader>i   " Show flake info
```

### Lisp Development

For Lisp, I use a terminal-based REPL workflow rather than trying to integrate everything into the editor:

```vim
:terminal sbcl    " Start SBCL in terminal split
:terminal         " General terminal (customize as needed)

" Vim-sexp provides paredit-style editing
" Standard text objects work semantically:
di(              " Delete inside s-expression
ya(              " Yank around s-expression
ci(              " Change inside s-expression
```

## Commands

### Utility Commands

```vim
:H [topic]           " Open help in vertical split (e.g., :H buffers)
:O [file...]         " Open file(s) with system default application
:StripWhitespace     " Remove trailing whitespace from entire buffer
```

### Command Shortcuts

```vim
:W                   " Same as :w (save)
:Q                   " Same as :q (quit)
:WQ / :Wq            " Same as :wq (save and quit)
:Qa                  " Same as :qa (quit all)
```

### Configuration Management

```vim
:EditVimrc           " Edit the main vimrc configuration
:ReloadVimrc         " Reload the vimrc configuration
```

### Nix Development Commands

**File Management**:
```vim
:EditFlake           " Edit flake.nix
:EditDefault         " Edit default.nix
```

**Build and Run**:
```vim
:NixRun [target]     " Run nix package (defaults to current flake)
:NixBuild [target]   " Build nix package (defaults to current flake)
:NixShell [target]   " Enter nix develop shell
```

**Package Management**:
```vim
:NixUpdate [input]   " Update flake.lock (optionally specific input)
:NixCheck [args]     " Run nix flake check
:NixClean            " Clean nix store (with confirmation)
:NixInfo [target]    " Show flake information
```

**Search and Analysis**:
```vim
:NixSearch <term>     " Search nixpkgs for packages
:NixEval <expr>       " Evaluate nix expression
:NixWhyDepends <args> " Show dependency chain
```

### LSP Diagnostic Commands

```vim
:DiagnosticsQF                 " Send all diagnostics to quickfix
:DiagnosticsLoc                " Send buffer diagnostics to location list
:DiagnosticsAll                " Show all project diagnostics
:DiagnosticsErrors             " Show only errors
:DiagnosticsWarnings           " Show only warnings
:DiagnosticsToggleVirtualText  " Toggle inline diagnostic text
:LspRestart                    " Restart LSP client
:LspInfo                       " Show LSP client information
```

## Performance

On my machine (Intel i7-1355U, 16GB RAM, NixOS with btrfs), this starts up in
about 36ms. Part of that is having fewer plugins, but part of it is also
that everything is compiled ahead of time with Nix rather than being installed
and configured at runtime.

You can benchmark this yourself with:

```bash
# Install hyperfine for benchmarking
nix shell nixpkgs#hyperfine

# Test startup times
hyperfine --warmup 3 --runs 10 'nvim --headless +q'

# Compare with other configs if you have them
hyperfine 'nvim --headless +q' 'lazyvim --headless +q'
```

## Module Configuration

### Home Manager Options

```nix
programs.nvimNix = {
  enable = true;
  package = pkgs.my-neovim;            # Custom package override
  enableDevTools = true;               # Install formatters/linters
  extraConfig = "vim.opt.tabstop = 2"; # Custom Lua config
  shellAliases = {                     # Shell aliases
    vi = "nvim";
    vim = "nvim";
  };

  # Desktop integration
  terminalEmulator = "kitty";          # or "auto"
  installTerminalEmulator = true;      # Install the terminal
  enableDesktopEntry = true;           # Create desktop entries
  createGuiWrapper = true;             # Create nvim-gui command
};
```

### NixOS Options

```nix
programs.nvimNix = {
  enable = true;
  package = pkgs.my-neovim;     # Custom package override
  defaultEditor = true;         # Set as system EDITOR
  enableDevTools = true;        # Install tools system-wide

  # Desktop integration
  terminalEmulator = "auto";    # Auto-detect based on DE
  enableDesktopEntry = true;    # System-wide desktop entries
  enableGitIntegration = true;  # Configure git to use nvim
};
```

## Development Workflow

### Quick Commands
```bash
# List installed plugins with breakdown
nix run .#plugins list

# Show plugin statistics
nix run .#plugins stats

# Check for plugin updates
nix run .#plugins check-updates

# Plugin management environment
nix develop .#plugins
```

### Adding a Language

Edit `lib/languages.nix` and add to `supportedLanguages`:

```nix
rust = {
  lsp = {
    package = pkgs.rust-analyzer;
    serverName = "rust_analyzer";
  };
  treesitter = "rust";
  formatter = {
    name = "rustfmt";
    package = pkgs.rustfmt;
  };
};
```

### Adding a Plugin

Edit `plugins.nix` and add to `pluginSources`:

```nix
vim-commentary = {
  owner = "tpope";
  repo = "vim-commentary";
  rev = "b90f965880e761a026ae0c1e1d7174e65e4d7b45";  # Get with nix-prefetch-github
  sha256 = lib.fakeHash;  # Will be computed automatically
};
```

### Updating Plugins

```bash
# Get latest commit info
nix-prefetch-github tpope vim-surround

# Update plugins.nix with new rev and sha256
# Test the build
nix build .#neovim
```

## FAQ

**Q: Why only 8 plugins when my current config has 50+?**
A: I prioritize learning Vim's native capabilities over convenience features.
Each plugin must provide capabilities Vim lacks entirely. More plugins often
means more complexity and less understanding of what's actually happening.

**Q: No fuzzy finder? How do I find files quickly?**
A: Use `:find **/*` with tab completion, or `:grep` with quickfix lists. These
teach you transferable skills that work on any Vim installation. Once you learn
the patterns, they're often faster than fuzzy finders anyway. And if you really
need a fuzzy finder then just use it in the terminal.

**Q: Can I add my favorite plugin X?**
A: If you fork this (which you should), absolutely. Check the [plugin selection criteria](#plugin-selection-criteria) to think through the trade-offs. If it violates none of the exclusion rules and meets all inclusion criteria, it might be worth considering.

**Q: Is this suitable for beginners?**
A: This config assumes intermediate Vim knowledge. For beginners, I'd recommend starting with vanilla Vim/Neovim to learn fundamentals first. This config is about mastery, not getting started.

**Q: Why share a personal config instead of making it configurable?**
A: Configuration options lead to complexity and compromise. A personal config can be opinionated and coherent. Fork it and make it yours rather than trying to make one config work for everyone.

**Q: I need IDE features like auto-completion and file trees**
A: That's perfectly valid! Fork this and add what you need, or consider LazyVim/AstroNvim if you want those features out of the box. This config is deliberately minimal. For auto-completion specifically, you could add nvim-cmp or just use Vim's built-in `<C-x><C-o>` and `<C-n>/<C-p>`.

## Migrating From Other Configs

If you're coming from a more feature-rich config, expect some adjustment:

**From LazyVim/AstroNvim/LunarVim**: You'll have fewer convenience features,
but you'll learn more transferable skills. The trade-off is short-term
productivity for long-term mastery.

**Backup your current config first**:
```bash
mv ~/.config/nvim ~/.config/nvim.backup
# Try nvim-nix for a week
# Then decide what you actually need
```

**Expect workflow changes**: Manual formatting instead of auto-formatters,
native file finding instead of fuzzy finders, quickfix lists instead of fancy
UIs.

## Troubleshooting

### Common Issues

**"nix: command not found"**
Install Nix: `curl -L https://nixos.org/nix/install | sh`

**"experimental features not enabled"**
Enable flakes in nix.conf - see [Prerequisites](#prerequisites)

**LSP not working**
Ensure you're using the full variant: `nix run .#dev` or enable `enableDevTools = true`

**Formatters not available**
You're probably using the minimal variant. Use `nix run .#dev` or install via modules with `enableDevTools = true`

**Terminal emulator not detected**
Specify explicitly: `terminalEmulator = "kitty"` in your config

**Performance issues**
This config is optimized for speed. If you experience slowness:
- Check for large files (>10MB) - Vim handles these differently
- Network filesystems may affect file operations
- Ensure you're not loading additional plugins

### Desktop Integration Issues

**Desktop entries not appearing**
Check that `enableDesktopEntry = true` and you have a desktop environment running

**Wrong terminal used**
Force a specific terminal: `terminalEmulator = "kitty"` instead of "auto"

**Check available terminals**:
```bash
nix eval .#lib.versionInfo.available-terminals
```

## Contributing

If you find bugs or think the documentation could be clearer, I'm happy to
accept contributions. If you want to add features that don't fit with the
existing philosophy, you should probably just fork the repository instead. The
whole point is to keep this focused and opinionated rather than trying to make
it work for everyone.

**Welcome contributions:**
- Bug fixes and typos
- Documentation improvements
- Architecture improvements that maintain philosophy
- Performance optimizations

**Please fork instead for:**
- Additional plugins that violate selection criteria
- UI/theme changes
- Configuration options and customization features
- Support for languages I don't use

## License

[MIT](./LICENSE)
