################
# Init
################

# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

# OS vars
OS=$(uname -s)


# OS specyfic actionscolors
case $OS in 
  "Linux" ) 
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
  ;;

  "Darwin" )
    # bash completion
    [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
    # colors
    export CLICOLOR=1
    export LSCOLORS=GxFxCxDxBxegedabagaced
  ;;
esac


################
# Functions
################

# agents
function agent_start(){
    # SSH agent
    if [ ! -f /tmp/agent.$USER ]; then
        ssh-agent >> /tmp/agent.$USER
        chmod 700 /tmp/agent.$USER
        eval `cat /tmp/agent.$USER` > /dev/null
    else
        eval `cat /tmp/agent.$USER` > /dev/null
    fi

    # GPG agent
    # It will start automatically per config:
    # ~/.gnupg/gpg.conf
    # ~/.gnupg/gpg-agent.conf
}

function agent_stop(){
    ps -u $USER | egrep "[g]pg-agent|[s]sh-agent" | awk '{print $2}' | while read a ; do kill -9 $a; done
    rm -f /tmp/agent.$USER
}

function agent_check(){
    for i in ssh-agent gpg-agent pinentry-curses ; do	
        which $i &> /dev/null && echo -e "$i\tOK" || echo -e "$i\tNOK"
    done
}

function agent_load_ssh_key(){
    if [ -z "$SSHKEYS" ]; then
        >&2 echo -e "\$SSHKEYS variable not specified\nex: SSHKEYS=\"~/.ssh/id_rsa ~/.ssh/id_dsa\""
        return 1
    fi
    tildefix=`echo $SSHKEYS | sed "s|~|${HOME}|g"`
    for k in $tildefix; do
        fingerprint=`ssh-keygen -l -f "$k" 2>/dev/null | cut -f2 -d ' '`
        if [ $fingerprint ]; then
            ssh-add -l | grep $fingerprint &>/dev/null || ssh-add $k
        else
            >&2 echo "Key $k not found"
        fi
    done
}

function agent_load_gpg_key(){
    if [ -z $EMAIL ]; then
        >&2 echo "\$EMAIL variable not specified"
        return 1
    fi
    date | gpg -r $EMAIL -e > /tmp/$$ && gpg -d /tmp/$$ &>/dev/null && rm -f /tmp/$$ || return 1
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


################
# Common for all OSes
################

# PATH
for i in $HOME/bin $HOME/.local/bin; do
  if [ -d $i ] ; then
    echo $PATH | grep $i &> /dev/null || PATH="$i:$PATH"
  fi
done

# History
HISTCONTROL=ignoreboth #Ignore doubled cmd
shopt -s histappend #Append hist
HISTSIZE=1000000
HISTFILESIZE=1000000
HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "

# Window control - check the window size after each command
shopt -s checkwinsize

# Set PS1 to green - default
if [ $(whoami) == 'root' ];then
  PS1_set '1;31'
else
  PS1_set '1;32'
fi

# Bar title
export PROMPT_COMMAND='printf "\033]0;%s\033\\" "${HOSTNAME}"'


################
# Aliases
################

# Import bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
#alias l='ls -CF'
alias su='su -'
alias ssh='ssh -o ServerAliveInterval=120'
alias ipx='grep -Eo "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"'
alias active_grep_only='grep -Ev "^#|^$"'
alias whatismyipaddr="curl http://myip.dnsomatic.com && echo"
alias weather="wget -q -O - wttr.in/KRK"
alias internetspeed="wget -O /dev/null data.interia.pl/100mb"
alias script="script -a -q"
alias 8="ping -c 5 8.8.8.8"


################
# Host specific addons
################
if [ -f ~/.bash_$HOSTNAME ]; then
    . ~/.bash_$HOSTNAME
fi


