source ~/.devenv/scripts/git-prompt.sh
[ -f ~/nvm.sh ] && source ~/nvm.sh
[ -d /usr/local/go/bin ] && export PATH=$PATH:/usr/local/go/bin

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1

PS1='\u@\h:\w$(__git_ps1 " (%s)")\$ '
