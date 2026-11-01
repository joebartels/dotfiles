# Shared Neovim configuration

This is **lazy.nvim**, the plugin manager, not the **LazyVim** distribution.
The current plugin spec is empty: only lazy.nvim itself is bootstrapped.
`init.lua` loads `lua/config/lazy.lua`, which imports `lua/plugins/`.

## What is shared

Chezmoi manages this directory (Lua configuration, this README, and
`lazy-lock.json`) from `private_dot_config/nvim/` in the dotfiles source.
lazy.nvim generates the lockfile to record plugin commits; do not fabricate it
or edit commit hashes by hand. Commit it alongside plugin declarations.

Downloaded plugins live in `~/.local/share/nvim/lazy` by default and are not
managed. Do not add runtime data, caches, or state to chezmoi. The lockfile does
not pin Neovim or external tools such as language servers and formatters.
Declare shared tools in `Brewfile.base`, or platform-specific tools in
`Brewfile.darwin` / `Brewfile.linux`. Prefer plugins that work on both macOS and
Linux; explicitly guard any platform-specific configuration.

## First machine / receiving changes

On a new machine, initialize the dotfiles with `chezmoi init <repository-url>`,
set the machine profile as described in the repository README, and review/apply
the configuration. Then launch `nvim` and run `:Lazy restore` to install/restore
the locked revisions. Bootstrap and plugin downloads require network access;
the enabled update checker also uses the network. Chezmoi apply does **not**
launch Neovim or install plugins.

On an existing machine:

1. Preserve any local target edits first (see below), then run `chezmoi update`.
2. Launch `nvim` and run `:Lazy restore`.

Use **restore**, not `:Lazy sync`, when receiving another machine's lockfile:
sync includes updates and can unintentionally advance the shared versions.

## Editing and adding plugins

Ordinary edits in `~/.config/nvim` are fine. Add declarations in
`lua/plugins/*.lua`, each returning lazy.nvim specs, for example:

```lua
return {
  { "owner/plugin" },
}
```

This is a placeholder example, not an installed plugin. Configure plugin
options/dependencies in those specs; keep bootstrap configuration in
`lua/config/lazy.lua`.

When intentionally adding or updating plugins, run `:Lazy sync` (install,
clean, and update) or `:Lazy update` as appropriate. These commands intentionally
advance `lazy-lock.json`. Review and test the resulting configuration, then
capture target changes in the source:

```sh
chezmoi diff --recursive ~/.config/nvim
chezmoi add ~/.config/nvim
git -C "$(chezmoi source-path)" status --short
git -C "$(chezmoi source-path)" diff
```

Commit and push the source configuration and generated lockfile together when
ready to share. Editing target files alone does not update the repository.
Alternatively, use `chezmoi edit ~/.config/nvim/lua/plugins/init.lua` (or another
managed file), review `chezmoi diff --recursive ~/.config/nvim`, then apply only
the intended paths with
`chezmoi apply <target-path>`. After lazy.nvim changes the target lockfile,
capture that file with `chezmoi add ~/.config/nvim/lazy-lock.json` too.

### Removing managed files

`chezmoi add` is **not deletion synchronization**. Deleting a target Lua file
and adding the directory can leave its source copy behind, causing it to return
on the next apply. Inspect `chezmoi remove --help` and use
`chezmoi remove <target-file>` for a managed file you intend to delete. By
default this removes **both source and target**. Review and commit the removal
along with any resulting lockfile changes.

## Agent / safety guardrails

- Inspect source and target differences before editing or applying anything.
- Before `apply` or `update`, preserve unrelated/local target edits (capture
  intended changes with `chezmoi add`, or back them up). These commands can
  overwrite target files; `update` also pulls and applies repository changes.
- Prefer targeted applies; do not run a broad apply merely to test Neovim.
  Repository-wide apply can run package/bootstrap scripts unrelated to Neovim.
- Do not install/update plugins or change shared versions incidentally. Use
  `:Lazy restore` for reproducibility, with explicit approval for network work.
- Do not commit or push unless the user requests it. Never include unrelated
  changes or manage runtime directories.
