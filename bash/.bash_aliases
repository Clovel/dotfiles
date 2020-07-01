# ls aliases ------------------------------------
alias ll='ls -laF'
alias la='ls -A'
alias l='ls -CF'

# cdmkdir ---------------------------------------
function mkcdir {
    mkdir -p -- "$1" && cd -P -- "$1"
}

# Script aliases --------------------------------
alias srcbash='source ~/.bashrc'

# Directory aliases -----------------------------

# Custom program aliases ------------------------
alias vscode='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
alias qtcreator='/Applications/Qt\ Creator.app/Contents/MacOS/Qt\ Creator'

# Linux aliases ---------------------------------
alias sagu='sudo apt-get update'
alias sagu='sudo apt-get update'
alias sagg='sudo apt-get upgrade'
alias sagd='sudo apt-get dist-upgrade'
