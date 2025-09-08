# nvim.nix

This is my personal Neovim configuration.

The basic idea behind it is this: most modern Neovim configs try to turn your
editor into an all-purpose IDE by adding dozens of plugins and abstractions.
There is no grand plan behind it other than needing to appeal to as many people
as possible. As a consequence you end up with a tool that works ok for most people,
but not great.

In this config I do the opposite. Everything needs to justify its existence
against the philosophy I have outlined below. By doing this I'm aiming to create
a PDE (personal development environment) that builds on top of (Neo)vim's existing
capabilities rather than replace them with plugin abstractions.

If you like this approach, you should fork this repository and adapt it to your
own needs. Remove the Lisp stuff if you don't write Lisp. Add Rust support if
that's what you do. The point isn't that my exact setup is perfect for you, but
that the systematic approach to making these decisions might be helpful.

## Principled vs. Minimalist

There is another point I need to clarify. Although this might look like a
minimal config given how few plugins are present this is a misunderstanding.
The vimrc is more than 200+ lines of code, and add on to that
comprehensive Nix infrastructure, language servers/formatters/linters, and what
you get is far from minimal.

This is a full-featured development environment. I just happen to think most
plugins are solving problems that don't actually exist.

Every plugin I use needs to provide capabilities that align closely with the
Vim philosophy and also provide capabilities that Vim doesn't already have.
This is why, for example, I have chosen not to include things like fuzzy finder
plugins or auto formatters. Vim already has perfectly good solutions for how to
handle this, namely using `:find` (and with Neovim we can even set our own
findfunc) or `:!black %`. These things force me to understand my environment.
Automated tooling would undoubtedly make me more productive in the short term,
but it would hamper my learning in the long term.

## Features

- **Principled**: Every decision is documented and reasoned through
- **Reproducible**: Exact same setup on any machine with Nix
- **Mastery-focused**: Emphasizes learning transferable Vim skills

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

If you want to try this before committing (no pun intended) to anything:

```bash
nix run github:mikabohinen/nvim-nix
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
pure minimalist route and wrote my master's thesis using only vanilla Vim.
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
   there is strong evidence to conclude that Vim has touched upon something
   more fundamental than just the technology itself. Modern plugins and
   enhancements should therefore build upon this and not replace it with tools
   that hide away these fundamentals. This is why we prefer builtin tools like
   `:grep` or `:find` compared to their modern counterparts. On the other hand,
   LSP and Treesitter hook into these fundamentals to extend the capabilities
   of Vim itself.

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

**Modern Necessities**

- **nvim-lspconfig**: Language server integration
- **nvim-treesitter + textobjects**: Enhanced syntax and structural navigation

**Editing**:

- **vim-surround**: Text object manipulation
- **vim-repeat**: Quality of life addition

**Development Integration**:

- **vim-fugitive**: Git integration

**Lisp Exception**:

- **vim-sexp**: Paredit-style editing for s-expressions

### Plugin Management

Pure Nix declarative plugin management replaces traditional plugin managers. Because
we have a minimal set of plugins, all of whom are very stable, managing plugins
in a Nix file with cryptographic hashes and specific commits isn't too bad. The
benefit is that we know exactly what we use and I think it to be worth the trouble
of having to manually update them every once in a while.

#### Local Plugins Managed via `config/plugins.nix`
```nix
vim-surround = {
  owner = "tpope";
  repo = "vim-surround";
  rev = "3d188ed2113431cf8dac77be61b842acb64433d9";
  sha256 = "sha256-abc123...";
};
```

#### Nixpkgs Plugins Managed via `package/default.nix`
Complex plugins that benefit from Nix's build system: nvim-lspconfig, nvim-treesitter, nvim-treesitter-textobjects.

### Plugin selection criteria

The goal isn't to use as few plugins as possible, it's to only use plugins that
provide genuine capabilities rather than convenience wrappers around existing
Vim functionality.

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

- **Fuzzy finders**: `:find` together with a custom findfunc accomplishes 90% of what we need, and using `:grep` together with the quickfix list is better
- **Auto-formatters**: `:!black %` forces you to understand the underlying tooling
- **Visual git tools**: command-line git + fugitive forces you to grok git
- **Session managers**: `:mksession` covers 80% of use cases
- **File managers**: netrw with proper configuration provides everything needed

## Architecture

### Three-Layer Approach

nvim.nix employs a three-layer architecture that leverages the strengths of
Nix, Vimscript, and Lua respectively. Each language does what it is good at and
no more:

#### Nix Layer (Infrastructure)

What should exist:

- **Declarative Environment**: Packages, plugins, language servers, formatters
- **Reproducible Systems**: Identical setups across machines and time
- **Dependency Management**: All external tools with exact versions

```nix
# Nix handles: "Make these tools available"
languageServers = [ pkgs.pyright pkgs.rust-analyzer ];
plugins = [ vim-surround vim-fugitive ];
```

#### Vimscript Layer (Behavior)

How should Vim behave:

- **Core Workflow**: Traditional Vim commands, mappings, patterns
- **User Interface**: Status line, quickfix integration, helper functions
- **Command Definitions**: All :commands and essential mappings
- **Editor Behavior**: Settings, autocommands, traditional Vim features

```vim
" Vimscript handles: "How should the editor behave"
set findfunc=FuzzyFindFiles
command! StripWhitespace call StripTrailingWhitespace()
```

#### Lua Layer (Modern Features)

How should modern features work:

- **LSP Configuration**: Language server setup, capabilities, handlers
- **Dynamic Behavior**: Buffer-local commands that activate in response to LSP events
- **Modern APIs**: Diagnostic configuration, treesitter, floating windows
- **Event-Driven**: Autocommands that respond to LSP attachment

```lua
-- Lua handles: "How should modern features integrate"
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    vim.api.nvim_buf_create_user_command(event.buf, 'LspAction',
      function() vim.lsp.buf.code_action() end, {})
  end,
})
```

## Installation

This assumes you're using Nix flakes.

Add to your `flake.nix`:

```nix
{
  description = "Your NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-nix = {
      url = "github:mikabohinen/nvim.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nvim-nix, ... }:
  {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or your system
      modules = [
        {
          nixpkgs.overlays = [
            nvim-nix.overlays.default
          ];

          environment.systemPackages = with pkgs; [
            nvim-nix
          ];
        }
      ];
    };
  };
}
```

Or if you already have a `configuration.nix`, add this to your existing configuration:

```nix
# In your configuration.nix or NixOS module
{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.nvim-nix.overlays.default
  ];

  environment.systemPackages = with pkgs; [
    nvim-nix
  ];
}
```

## Key Bindings

This configuration prioritizes learning transferable Vim skills through
compositional workflows. Operations use standard Vim commands that compose
together through Vim's built-in state management.

### Core Patterns

Leader mappings provide entry points to workflow domains that exchange data
through Vim's built-in systems (search register, quickfix lists, buffer system)

All operations use standard Vim commands and can be replicated anywhere with
simple single-line mappings

### Essential Mappings

```vim
" Fix Vim's & command behavior
&                    " Repeat last :s command with flags

" File browser
-                    " Edit current file's directory (:e %:h)

" List navigation (Vim standard patterns)
]q / [q              " Next/previous quickfix
]l / [l              " Next/previous location list
]b / [b              " Next/previous buffer
]B / [B              " First/last buffer

" Clear search highlighting
<Esc><Esc>           " Clear search highlights
```

### Leader Mappings

These mappings enable workflow domains that exchange data through Vim's
built-in systems. Each domain provides entry points that compose with standard
Vim operations.

#### Search Domain
```vim
<leader>g            " :grep (project search)
<leader>G            " :grep <word-under-cursor>
<leader>*            " :grep <last-search> (reuse search register)
<leader>/            " :grep <word-under-cursor> (with prompt for refinement)
```

#### File Domain  
```vim
<leader><leader>     " :find (primary file opener)
<leader>sf           " :vert sf (split file opener)
```

#### List Domain
```vim
<leader>q            " :copen (open quickfix)
<leader>l            " :lopen (open location list)
<leader>Q            " :cclose (close quickfix)
<leader>L            " :lclose (close location list)
```

#### Buffer Domain
```vim
<leader>bl           " :ls | :b (buffer list and switch)
<leader>bd           " :bd (delete buffer)
```

### Workflow Examples

**Investigation Flow**:
```
/pattern → <leader>* → <leader>q → ]q → gd → <leader>G → <leader>q
```
Search buffer → expand to project → review results → navigate → follow definition → search symbol → review all references

**File Exploration Flow**:
```  
<leader><leader>file → <leader>tf → <leader>sf related → <leader>g pattern → <leader>l
```
Find file → find test → open related in split → search current context → window-local results

### LSP Mappings (Buffer-local, only when LSP attached)

```vim
" Core navigation
gd                   " Go to definition
gr                   " Go to references  
gi                   " Go to implementation
gD                   " Go to declaration
gy                   " Go to type definition
K                    " Hover documentation

" Diagnostic navigation
]d / [d              " Next/previous diagnostic
]D / [D              " Next/previous error diagnostic
```

### Treesitter Features

**Text objects**:

```vim
af / if          " Around/inside function
ac / ic          " Around/inside class
al / il          " Around/inside loop
aa / ia          " Around/inside parameter
```

**Movement**:

```vim
]f / [f          " Next/previous function start
]c / [c          " Next/previous class start
]F / [F          " Next/previous function end
]C / [C          " Next/previous class end
```

**Incremental selection**:

```vim
gnn              " Start incremental selection
grn              " Increment to next node
grc              " Increment to scope
grm              " Decrement selection

## Commands

### Workflow Commands

These commands provide entry points for common workflows:

```vim
:Grep pattern        " Run grep and open results in quickfix
:LGrep pattern       " Run lgrep and open results in location list  
:Todo                " Find TODO/FIXME/XXX comments project-wide
:GitGrep pattern     " Use git grep for repository-aware search
```

### Essential Commands to Learn

**File Operations**:
```vim
:find filename       " Find and open file (with fuzzy completion)
:vert sf filename    " Find and open in vertical split
:grep pattern        " Search project-wide
:grep <C-R><C-W>     " Search word under cursor
:grep <C-R>/         " Search for last search pattern
```

**Navigation**:
```vim
:cnext / :cprev      " Quickfix navigation
:lnext / :lprev      " Location list navigation
:bnext / :bprev      " Buffer navigation
:bfirst / :blast     " First/last buffer
```

**Lists**:
```vim
:copen / :cclose     " Quickfix window
:lopen / :lclose     " Location list window
:Cfilter pattern     " Filter quickfix (from cfilter plugin)
```

### LSP Commands

```vim
:LspHover            " Show documentation
:LspSig              " Show signature help
:LspAction           " Show code actions
:LspRename           " Rename symbol
:WorkspaceAdd        " Add workspace folder
:WorkspaceRemove     " Remove workspace folder
:WorkspaceList       " List workspace folders
```

### Diagnostic Commands

```vim
:DiagFloat           " Show diagnostic at cursor
:DiagQF              " Send all diagnostics to quickfix
:DiagLoc             " Send buffer diagnostics to location list
:DiagToggle          " Toggle virtual text diagnostics
:LspRestart          " Restart LSP client
:LspInfo             " Show LSP information
```

### Utility Commands

```vim
:StripWhitespace     " Remove trailing whitespace from entire buffer
```

## Development Workflow

### Adding a Language

Edit `config/languages.nix` and add

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
if you for example want rust support.

### Adding a Plugin

Edit `config/plugins.nix` and add

```nix
vim-commentary = {
  owner = "tpope";
  repo = "vim-commentary";
  rev = "b90f96...";  # Whatever the hash is
  sha256 = lib.fakeHash;  # It will fail the first time you build but then you get the expected hash to put in
};
```
if you wanted to auto-comment.

## FAQ

**Q: Only 7 plugins when my current config has 50+?**
A: I prioritize learning Vim's native capabilities over convenience features.
Each plugin must provide capabilities Vim lacks. More plugins often means more
complexity and less understanding of what's actually happening.

**Q: No telescope? How do I find files quickly?**
A: Use `:find` with fuzzy completion via our custom `findfunc`. This teaches you transferable skills that work on any Vim installation. Once you learn the patterns, they're often faster than fuzzy finders anyway.

**Q: Can I add my favorite plugin X?**
A: If you fork this (which you should), absolutely. Check the [plugin selection criteria](#plugin-selection-criteria) to think through the trade-offs. If it violates none of the exclusion rules and meets all inclusion criteria, it might be worth considering.

**Q: Is this suitable for beginners?**
A: This config assumes intermediate Vim knowledge. For beginners, I'd recommend starting with vanilla Vim/Neovim to learn fundamentals first. This config is about mastery, not getting started.

**Q: Why share a personal config instead of making it configurable?**
A: Configuration options lead to complexity and compromise. A personal config can be opinionated and coherent. Fork it and make it yours rather than trying to make one config work for everyone.

**Q: I need IDE features like auto-completion and file trees**
A: That's perfectly valid! Fork this and add what you need, or consider
LazyVim/AstroNvim if you want those features out of the box. This config is
deliberately minimal. For auto-completion specifically, I recommend learning
Vim's built-in autocompletion system like `<C-x><C-o>` and `<C-n>/<C-p>`.

**Q: How do I access diagnostics without shortcuts?**
A: Use explicit commands: `:DiagFloat` for current cursor, `:DiagQF` for all diagnostics, `:DiagLoc` for buffer diagnostics. This teaches you the underlying diagnostic system.

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

**Expect workflow changes**:
- Use `:find filename` instead of fuzzy finder shortcuts
- Use `:grep pattern` instead of live grep shortcuts
- Use native quickfix lists instead of fancy UIs
- Use explicit commands instead of memorized shortcuts

The goal is to learn Vim deeply rather than memorize config-specific shortcuts.

## Troubleshooting

### Common Issues

**"nix: command not found"**
Install Nix: `curl -L https://nixos.org/nix/install | sh`

**"experimental features not enabled"**
Enable flakes in nix.conf - see [Prerequisites](#prerequisites)

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
- Leader key mappings or convenience shortcuts

## License

[MIT](./LICENSE)
