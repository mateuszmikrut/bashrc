# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History
HISTCONTROL=ignoreboth #Ignore doubled cmd
shopt -s histappend #Append hist
HISTSIZE=1000000
HISTFILESIZE=1000000
HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "

# Window control - check the window size after each command
shopt -s checkwinsize

# Color in ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi


# agents
function agent_start(){
    if [ ! -f /tmp/agent.$USER ]; then
        # gpg agent will start automatically
        # ~/.gnupg/gpg.conf
        # ~/.gnupg/gpg-agent.conf

        ssh-agent >> /tmp/agent.$USER
        chmod 700 /tmp/agent.$USER
        eval `cat /tmp/agent.$USER` > /dev/null
    else
        eval `cat /tmp/agent.$USER` > /dev/null
    fi
}

function agent_stop(){
    ps -ef  | grep $USER | egrep "[g]pg-agent|[s]sh-agent" | awk '{print $2}' | while read a ; do kill -9 $a; done
    rm -f /tmp/agent.$USER
}

function agent_check(){
    for i in ssh-agent gpg-agent pinentry-curses ; do	
        which $i &> /dev/null && echo -e "$i\tOK" || echo -e "$i\tNOK"
    done
}

function agent_load_ssh_key(){
    if [ -z $SSHKEY ]; then
        >&2 echo "\$SSHKEY variable not specified"
        return 1
    fi
    ssh-add -l 2> /dev/null || ssh-add $SSHKEY
}

function agent_load_gpg_key(){
    if [ -z $EMAIL ]; then
        >&2 echo "\$EMAIL variable not specified"
        return 1
    fi
    date | gpg -r $EMAIL -e > /tmp/$$ && gpg -d /tmp/$$ && rm -f /tmp/$$
}

# PS1
function PS1_set(){
    # PPID=`ps -o ppid |sed -n 2p` 
    PS_color=$1	
    if `ps -e | grep $PPID | grep [s]cript$ > /dev/null`; then
        PS1='[\[\033[0;33m\]SCR \[\033[${PS_color}m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]$(if [ $? == 0 ]; then echo "\[\033[00;32m\]" ; else echo "\[\033[00;31m\]"; fi)\$ \[\033[00m\]'
    else
        PS1='[\[\033[${PS_color}m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]$(if [ $? == 0 ]; then echo "\[\033[00;32m\]" ; else echo "\[\033[00;31m\]"; fi)\$ \[\033[00m\]'
    fi
}

# Set PS1 to green - default
PS1_set '1;32'
export PROMPT_COMMAND='printf "\033]0;%s\033\\" "${HOSTNAME}"'

# Aliases
if [ -f ~/.bash_liases ]; then
    . ~/.bash_aliases
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
#alias l='ls -CF'
alias su='su -'
alias ssh='ssh -A -o ServerAliveInterval=120'
alias ipx='grep -Eo "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"'
alias active_grep_only='grep -Ev "^#|^$"'
alias whatismyipaddr="curl http://myip.dnsomatic.com && echo"
alias weather="wget -q -O - wttr.in/KRK"
alias internetspeed="wget -O /dev/null data.interia.pl/100mb"
alias script="script -a -q"
alias 8="ping -c 5 8.8.8.8"


# Host specific addons
if [ -f ~/.bash_$HOSTNAME ]; then
    . ~/.bash_$HOSTNAME
fi

# PATH
if [ -d "$HOME/bin" ] ; then
    echo $PATH | grep $HOME/bin &> /dev/null || PATH="$HOME/bin:$PATH"
fi


