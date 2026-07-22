# ==========================================================
#  MANAGED BY CHEZMOI
#  Purpose: Initialize Java after machine-specific overrides
#  Provides: startup JAVA_HOME initialization
#  Edit:  chezmoi edit ~/.config/zsh/modules/600-initialize-java-home.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

# Initialize JAVA_HOME after ~/.zshrc.local has had a chance to override
# JAVA_HOME_DEFAULT_VERSION.
jh >/dev/null
