# ==========================================================
#  MANAGED BY CHEZMOI
#  Purpose: Initialize macOS Java after machine-specific overrides
#  Provides: startup JAVA_HOME initialization
#  Edit:  chezmoi edit ~/.config/zsh/modules/600-initialize-java-home.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

# Initialize JAVA_HOME after ~/.zshrc.local has had a chance to override
# JAVA_HOME_DEFAULT_VERSION. Linux keeps its existing JAVA_HOME; jh uses
# Apple's java_home helper, which is not available there.
if [[ "$OSTYPE" == darwin* && -x /usr/libexec/java_home ]]; then
  jh >/dev/null
fi
