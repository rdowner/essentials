# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' verbose true
zstyle :compinstall filename '/home/richard/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install

# Load functions
if [ -d ${HOME}/.zsh/functions ]; then
    fpath=($fpath ${HOME}/.zsh/functions)
    typeset -U fpath
fi

# Prompt setup
autoload -U colors && colors
PS1="%{%(!.$fg[red].$fg[cyan])%}%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}%% "
RPROMPT="%{$fg[magenta]%}%~%{$reset_color%}"

setopt promptsubst
if autoload -U promptinit; then
    promptinit
    [ -f ~/.zsh/functions/prompt_richard_setup ] && prompt richard
fi

# Change window title
case $TERM in
	xterm*)
		print -Pn "\e]2;%m\a"
		;;
esac

# 'ls' aliases
[ "$(uname)" = "Darwin" ] && LS_OPTS="-Fh" || LS_OPTS="-Fh --color=auto"
alias ls="ls $LS_OPTS"
alias ll="ls $LS_OPTS -l"
alias la="ls $LS_OPTS -a"
alias lla="ls $LS_OPTS -la"
alias lltr="ls $LS_OPTS -ltr"
unset LS_OPTS

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias listening='lsof -iTCP -sTCP:LISTEN -n -P'
alias dryrsync='rsync --dry-run'

# Git
alias gs='git status'
alias gco='git checkout'
alias gpull='git pull'
alias gpush='git push'
alias gff="git merge --ff-only $*"
gmmpush() {
    # Merge this branch to master using fast-forward only and push
    # Your local master branch must be up-to-date, and your current branch
    # rebased (or merged?) with local master.

    # Only proceed if the local master branch is the same as the remote
    remote_master_head=$(git ls-remote origin -h refs/heads/master | cut -f1)
    local_master_head=$(git rev-list --max-count=1 master)
    if [ "$remote_master_head" != "$local_master_head" ]; then
	echo >&2 Seems that master is out-of-date. Aborting. Local=${local_master_head} Remote=${remote_master_head}
	return 1
    fi
    # Figure out my branch name
    branch_name=$(git symbolic-ref -q HEAD) || return 100
    branch_name=${branch_name##refs/heads/} || return 100
    branch_name=${branch_name:-HEAD} || return 100
    # Do it
    git checkout master || return 100
    git merge --ff-only ${branch_name} || return 100
    echo Ready to git push || return 100
}
gpullrb() {
    # Pull from remote, and rebase current branch against master

    # Figure out my branch name
    branch_name=$(git symbolic-ref -q HEAD) || return 100
    branch_name=${branch_name##refs/heads/} || return 100
    branch_name=${branch_name:-HEAD} || return 100
    # Do it
    git checkout master || return 100
    git pull || return 100
    git checkout ${branch_name} || return 100
    git rebase master || return 100
}
grevert() {
    git reset -- "$*"
    git checkout -- "$*"
}
gsu() { git status --porcelain | awk '$1=="??"{print $2}' }
gfetchall() {
    for remote in $( git remote ); do echo \*\* Fetching $remote; git fetch $remote; done
    echo \*\* Garbage collection
    git gc --auto
}
githubadd() {
    if [ "$1" = "-rw" ]; then mode=rw; shift; else mode=ro; fi
    if [ -z "$1" ]; then echo >&2 bad args; return; else user=$1; fi
    if [ -z "$2" ]; then repo=$( basename $( pwd ) ); else repo=$2; fi
    case "$mode" in
	rw)
	    git remote add $user git@github.com:$user/$repo.git
	    ;;
	ro)
	    git remote add $user https://github.com/$user/$repo.git
	    ;;
    esac
    gfetchall
}
ghclone() {
    if [ "$1" = "-rw" ]; then mode=rw; shift; fi
    if [ "$1" = "-ro" ]; then mode=ro; shift; fi
    if [ -z "$mode" ]; then
        if [ "$1" = "rdowner" -o "$1" = "richardcloudsoft" ]; then mode=rw; else mode=ro; fi
    fi
    if [ -z "$1" ]; then echo >&2 bad args; return; else user=$1; fi
    if [ -z "$2" ]; then echo >&2 bad args; return; else repo=$2; fi
    echo Cloning from github $user/$repo, mode=$mode
    mkdir $repo
    cd $repo
    git init
    case "$mode" in
	rw)
	    githubadd -rw $user $repo
	    ;;
	ro)
	    githubadd $user $repo
	    ;;
    esac
    git reset --hard $user/master
    git branch --set-upstream-to remotes/$user/master
}
gwhatpush() {
	branch=$( git branch | grep '^* ' | cut -f2 -d' ' )
	remote=$( git config --local --get branch.${branch}.remote )
	if [ \! -z "$remote" ]; then
		remotebranch=$( git config --local --get branch.${branch}.merge | sed 's:refs/heads/::' )
	else
		remote=$( git config --local --get branch.master.remote )
		remotebranch=${branch}
	fi
	echo What would be pushed, if I pushed ${branch} to ${remote}/${remotebranch} \?
	topush=$( git push --dry-run --porcelain ${remote} ${remotebranch} | grep -E '[0-9a-f]+\.\.[0-9a-f]+' | cut -f3 )
	if [ $? -ne 0 -o -z "$topush" ]; then
		echo "Couldn't determine range. There was an error."
		return 1
	fi
	echo Range $topush
	git ls ${topush}
}
gdopush() {
	branch=$( git branch | grep '^* ' | cut -f2 -d' ' )
	remote=$( git config --local --get branch.${branch}.remote )
	remotebranch=$( git config --local --get branch.${branch}.merge | sed 's:refs/heads/::' )
	echo Push ${branch} to ${remote}/${remotebranch}
	git push ${remote} ${remotebranch}
}
idea-open() {
  open -a "IntelliJ IDEA 13" "$1"
}


# Java
alias jtrace='kill -SIGQUIT'

# Find+grep
findgrep() {
    findcmd=(find)
    while [ "$1" != "--" ]; do
	findcmd+=("$1")
	shift
    done
    shift
    findcmd+=(-print0)
    grepcmd=(xargs -0 grep -H)
    while [ "$#" -gt 0 ]; do
	grepcmd+=("$1")
	shift
    done

    echo "$findcmd[@]" >&2
    echo "$grepcmd[@]" >&2

    "$findcmd[@]" | "$grepcmd[@]"
}

# Processes
ispidalive() {
    [ -z "$1" ] && ( echo usage: $0 pid; return 2 )
    [ $( ps -p $1 | wc -l ) -gt 1 ] && return 1 || return 0
}
repkill() {
    [ -z "$1" ] && ( echo usage: $0 pid; return 2 )
    for sig in HUP TERM KILL; do
	ispidalive $1 || return 0
	echo kill -$sig $1
	kill -$sig $1
	sleep 3s
    done
    ispidalive $1 && echo 'Process could not be killed'
}

[ -f ${HOME}/.zshrc.local ] && . ${HOME}/.zshrc.local
