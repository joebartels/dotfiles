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

## Module map

| Module | Owns |
| --- | --- |
| `000-shell-bootstrap.zsh` | Homebrew, Oh My Zsh, and function autoloading |
| `100-docker.zsh` | Docker aliases and cleanup helpers |
| `100-java.zsh` | Java selection and `jh` |
| `100-shell-utilities.zsh` | General shell aliases and helpers |
| `100-tmux.zsh` | Tmux session shortcuts |
| `400-powerlevel10k.zsh` | Prompt configuration |
| `500-local-overrides.zsh` | Sources `.zshrc.local` |
| `600-initialize-java-home.zsh` | Initializes Java after local overrides |

## Where should it go?

- Tool-specific setting or helper: existing or new `100-<tool>.zsh`
- General shell behavior: `100-shell-utilities.zsh`
- Machine-specific value: `~/.zshrc.local`
- Must run before ordinary modules: `000-099`
- Depends on local overrides: `600-899`

List module responsibilities with:

```sh
rg '^#  (Purpose|Provides):' ~/.config/zsh/modules
```

Edit the ChezMoi source under `private_dot_config/zsh/modules/`, then apply it
with `chezmoi apply ~/.config/zsh`.
