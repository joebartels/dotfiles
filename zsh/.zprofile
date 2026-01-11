# Universal ZSH Profile Configuration
# Safe to source from any environment
# Loaded once at login

#########
# FUNCTIONS
#########

# Display PATH with one entry per line
pathn() {
    echo $PATH | sed -e $'s/:/\\\n/g'
}
