#########
# ALIASES
#########
alias ls='ls -laphG'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

export PATH="$HOME/development/bin:$PATH"
export PATH="$HOME/development/lib/flutter/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.please:$PATH"

pathn() {
	echo $PATH | sed -e $'s/:/\\\n/g'
}

# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/development/lib/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/development/lib/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/development/lib/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/development/lib/google-cloud-sdk/completion.zsh.inc'; fi

# Setting PATH for Python 3.6
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
export PATH


# Added by Toolbox App
export PATH="$PATH:/usr/local/bin"


# Setting PATH for Python 3.14
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.14/bin:${PATH}"
export PATH
