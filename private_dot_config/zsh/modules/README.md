# Zsh modules

Small, focused pieces of the managed `.zshrc`. The module loader sources only
`*.zsh` files, in filename order; this README is ignored.

## Naming and order

- `000-099` — shell bootstrap
- `100-499` — ordinary, independent modules
- `500-599` — machine-local overrides
- `600-899` — initialization that depends on those overrides
- `900-999` — finalization

Modules with the same prefix should be independent and load alphabetically.
Add new files as `<phase>-<purpose>.zsh`, such as `100-kubernetes.zsh`.
Keep machine-specific settings in `~/.zshrc.local`.

Edit the ChezMoi source under `private_dot_config/zsh/modules/`, then apply it
with `chezmoi apply ~/.config/zsh`.
