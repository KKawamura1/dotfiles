# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z ${PS1:-} ] && return

# raise error when you use an undefined variable
set -u
PROMPT_COMMAND=

# use zsh (cannot use chsh because it needs sudoers)
# HOST_NAME=`hostname`
# use_default_zsh_hosts=('crane0' 'crane2')
# use_own_zsh_hosts=('kiwi' 'trana0')
# which_zsh_is_use=0
# for host in ${use_default_zsh_hosts[@]}; do
#     if [ $HOST_NAME = $host ]; then
# 	which_zsh_is_use=1
#     fi
# done
# for host in ${use_own_zsh_hosts[@]}; do
#     if [ $HOST_NAME = $host ]; then
# 	which_zsh_is_use=2
#     fi
# done
# if [ $which_zsh_is_use -eq 1 ]; then
#     echo "zsh doesn't work in my .zshrc settings... fix me"
#     #    exec /usr/bin/zsh
# elif [ $which_zsh_is_use -eq 2 ]; then
#     exec /home/kkawamura/tools/bin/zsh
# else
#     echo '$HOST_NAME is unknown hostname, please write your .bashrc to specify its zsh place!'
# fi

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
HISTCONTROL=${HISTCONTROL:-}${HISTCONTROL:+:}ignoredups
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z ${debian_chroot:-} ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# dinamically update prompt message
# https://github.com/pyenv/pyenv-virtualenv/issues/135
# ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$
function updatePrompt {
    # Color styles
    c_user='\[\e[0m\]'
    c_host='\[\e[1;32m\]'
    c_wdir='\[\e[1;37m\]'
    c_git='\[\e[0;32m\]'
    c_env='\[\e[0;36m\]'
    c_reset='\[\e[0m\]'

    # Base prompt
    # \u: user
    # \h: host name
    # \w: working dir
    prompt_base=${c_user}'\u'${c_reset}'@'${c_host}'\h'${c_reset}':'${c_wdir}'\w'${c_reset}
    prompt_base="[${prompt_base}]"

    # Current Git repo
    if type '__git_ps1' > /dev/null 2>&1; then
        prompt_git=${c_git}$(__git_ps1)${c_reset}
    else
	prompt_git=''
    fi

    # Current virtualenv
    pyenv_version=$(pyenv version 2>/dev/null)
    pyenv_version=${pyenv_version%%\ *}
    if [ "$pyenv_version" != '' ] && [ "$pyenv_version" != 'system' ]; then
        # Strip out the path and just leave the env name
	prompt_env="[${c_env}${pyenv_version}${c_reset}]"
    else
	prompt_env=''
    fi
    export PS1="${prompt_base} ${prompt_env}${prompt_git}\n$ "
}
export -f updatePrompt
export PROMPT_COMMAND=${PROMPT_COMMAND:+${PROMPT_COMMAND};}'updatePrompt'

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi


# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    set +u
    . /etc/bash_completion
    set -u
fi

# --------- my settings ----------


# crane0, crane2, kiwi, ...
# this method is bad:
#   HOST_NAME=`hostname`
# this is better:
HOST_NAME=$(uname -n)
# except kiwi
if [ ! $HOST_NAME == 'kiwi' ]; then
    # local home
    LOCAL_HOME='/data/local/kkawamura'
    if [ ! -d ${LOCAL_HOME} ]; then
	mkdir ${LOCAL_HOME}
    fi
    # use cupy
    cupy_hosts=('crane0' 'crane2' 'owl0' 'owl1')
    cupy_mode=-1
    for host in ${cupy_hosts[@]}; do
	if [ $HOST_NAME = $host ]; then
            cupy_mode=0
	fi
    done
    if [ $cupy_mode -eq 0 ]; then
	# cuda のpathをとおす
	# 参考: https://qiita.com/daichan1111/items/6ca75c688fff4cf14023
	export CUDA_ROOT=/usr/local/cuda
	if [ $HOST_NAME = 'owl1' ]; then
	    export CUDA_ROOT=/usr/local/cuda-8.0
	fi
	export CUDA_PATH=${CUDA_ROOT}
	export PATH=${CUDA_ROOT}/bin:${PATH}
	export LD_LIBRARY_PATH=${CUDA_ROOT}/lib64:${CUDA_ROOT}/lib:${LD_LIBRARY_PATH:-}
	export CPATH=${CUDA_ROOT}/include:${CPATH:-}
    fi

    # パスを通す
    # export MY_TOOLS_HOME=$HOME/tools
    export PATH=${LOCAL_HOME}/tools/bin:${PATH}
    export LD_LIBRARY_PATH=${LOCAL_HOME}/tools/lib64:${LOCAL_HOME}/tools/lib:${LD_LIBRARY_PATH:-}
    export CPATH=${LOCAL_HOME}/tools/include:${CPATH:-}

    # memory limit setting
    mem_limit='notset'
    giga=$((1024*1024)) # ulimit uses kbytes
    mem_size='notset'
    division_num='notset'
    margin=$((${giga}))
    if [ $HOST_NAME == 'crane0' ]; then
	mem_size=$((100*${giga}))
	division_num=$((4))
	margin=$((${giga}/2))
    fi
    if [ $HOST_NAME == 'crane2' ]; then
	mem_size=$((100*${giga}))
	division_num=$((4))
	margin=$((${giga}/2))
    fi
    if [ $HOST_NAME == 'pigeon0' ]; then
	mem_size=$((300*${giga}))
	division_num=$((4))
    fi
    if [ $HOST_NAME == 'pigeon1' ]; then
	mem_size=$((382*${giga}))
	division_num=$((4))
    fi
    if [ $HOST_NAME == 'owl0' ]; then
	mem_size=$((250*${giga}))
	division_num=$((4))
    fi
    if [ $HOST_NAME == 'owl1' ]; then
	mem_size=$((250*${giga}))
	division_num=$((4))
    fi
    if [ $mem_limit == 'notset' ]; then
	if [ $mem_size == 'notset' ]; then
	    echo '.bashrc Warning: memory limitation is not set'
	    mem_limit='unlimited'
	else
	    mem_limit=$((${mem_size}/${division_num}-${margin}))
	fi
    fi
    if expr ${mem_limit} : '[0-9]*' > /dev/null ; then
	echo '.bashrc info: virtual memory is limited up to ['$((${mem_limit}/${giga}))' GB]'
    fi
    ulimit -S -v $mem_limit

    # pyenv settings
    if [ -d "${LOCAL_HOME}" ]; then
    	export PYENV_ROOT="${LOCAL_HOME}/.pyenv"
    	if [ ! -d "${PYENV_ROOT}" ]; then
    	    echo "Installing pyenv and pyenv-virtualenv..."
    	    git clone git://github.com/yyuu/pyenv.git ${PYENV_ROOT}
    	    git clone https://github.com/pyenv/pyenv-virtualenv.git ${PYENV_ROOT}/plugins/pyenv-virtualenv
    	fi
    	export PATH=${PYENV_ROOT}/bin:$PATH
    	eval "$(pyenv init -)"
    	eval "$(pyenv virtualenv-init -)"
    fi
fi

# tmux color settings
# 参考: https://github.com/sellout/emacs-color-theme-solarized/issues/62
export TERM="xterm-256color"

# alias
alias myls='ls -lh --color=auto'
alias lst='myls -tr'
alias l='lst'
alias ll='myls'
alias la='myls -a'
alias so='source'
alias v='vim'
alias vi='vim'
alias vz='vim ~/.zshrc'
alias c='cd'
alias h='fc -lt "%F %T" 1'
alias cp='cp -i'
alias rm='rm -I'
alias mkdir='mkdir -p'
alias ..='c ../'
alias back='pushd'
alias diff='diff -U1'
alias su='su -l' # don't use my env variables

# emacs
alias emacs='emacs -nw'
alias e='emacs'
# ssh
alias ssh='ssh -X'
# cmake
if [ -d ${LOCAL_HOME:-} ]; then
    cmake_install_options=" -DCMAKE_INSTALL_PREFIX="${LOCAL_HOME}"/tools/"
fi
alias cmake='cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1'${cmake_install_options:-}
alias cmake_release='cmake -DCMAKE_BUILD_TYPE=Release'

# auto ls
autols(){
  [[ ${AUTOLS_DIR:-${PWD}} != $PWD ]] && l
  AUTOLS_DIR=${PWD}
}
export PROMPT_COMMAND="${PROMPT_COMMAND:-};autols"

# if [ -n "$CPATH" ]; then export CPATH=:$CPATH; fi
# export CPATH=$MY_TOOLS_HOME/include$CPATH
# if [ -n "$CPPPATH" ]; then export CPPPATH=:$CPPPATH; fi
# export CPPPATH=$MY_TOOLS_HOME/include$CPPPATH
# if [ -n "$LIBRARY_PATH" ]; then export LIBRARY_PATH=:$LIBRARY_PATH; fi
# export LIBRARY_PATH=$MY_TOOLS_HOME/lib$LIBRARY_PATH
# if [ -n "$LD_LIBRARY_PATH" ]; then export LD_LIBRARY_PATH=:$LD_LIBRARY_PATH; fi
# export LD_LIBRARY_PATH=$MY_TOOLS_HOME/lib$LD_LIBRARY_PATH
# if [ -n "$PATH" ]; then export PATH=:$PATH; fi
# export PATH=$MY_TOOLS_HOME/bin$PATH

# if [ -n "$ZPLUG_HOME" ]; then export ZPLUG_HOME=:$ZPLUG_HOME; fi
# export ZPLUG_HOME=$HOME/.zshrc.zplug:$ZPLUG_HOME


#export GLIBC_HOME=$MY_TOOLS_HOME/glibc
# export LD_LIBRARY_PATH=$GLIBC_HOME/lib:$LD_LIBRARY_PATH

# --- from /home/kameko/.bashrc ---
# export JAVA_HOME="/home/kameko/tools/java8/jdk1.8.0_60"
# export ANT_HOME="/home/kameko/tools/java8/apache-ant-1.9.6"
# export CUDA_HOME="/usr/local/cuda"
# export CUDNN_HOME="/data/local/kameko/tools/cudnn"
# export PYENV_HOME="/home/kameko/.pyenv"
# export PYENV_ROOT="/data/local/kameko/tools/pyenv"
# export LOCAL_HOME="/data/local/kameko/tools"

# export RLGLUE_HOME="/home/kameko/proj/DQN/rlglue-3.04/lib"
# export RLGLUE_HOME="/data/local/kameko/tools/rlglue-3.04/lib"

# export CPATH=$CUDA_HOME/include:$CUDNN_HOME/include:$CPATH
# export LIBRARY_PATH=$RLGLUE_HOME:$CUDA_HOME/lib64:$CUDNN_HOME/lib64:$LIBRARY_PATH
# export LD_LIBRARY_PATH=$RLGLUE_HOME:$CUDA_HOME/lib64:$CUDNN_HOME/lib64:$LOCAL_HOME/lib64:$LD_LIBRARY_PATH
# export PATH=$CUDA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin:$PYENV_ROOT/bin:$PATH

# added by Anaconda3 installer
# export PATH="/data/local/kkawamura/tools/anaconda3/bin:$PATH"

set +u
