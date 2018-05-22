# =================
# ----- zshrc -----
# =================

# If not running interactively, don't do anything
## for ssh non-interactive shell
## see: http://d.hatena.ne.jp/flying-foozy/20140130/1391096196
[ -z "${PS1:-}" ] && return

# ----- settings -----

# raise error when you use an undefined variable
set -u
# halt shell scripts when an error occurs
set -e

# logger
## main logger
function logger_logging () {
    # arg1
    # log_level: str = 'NOTSET'
    # level of the log. e.g. INFO or WARNING.
    log_level=${1:-'NOTSET'}
    # arg2
    # message: str = ''
    # main message of the log.
    message=$2
    # arg3
    # continues: bool = false
    # whether to open a new line or not at the end of the message.
    # if true, continue the same line and not to open a new line.
    continues=${3:-false}

    message_line="zshrc: [${log_level}] "${message}
    if ${continues}; then
	printf ${message_line}'.'
    else
	echo ${message_line}
    fi
}
## continue
function logger_continue () {
    printf '.'
}
## end continue
function logger_finished () {
    echo '. done.'
}


# compile when modified
zshrc_source=${HOME}/.zshrc
zshrc_compiled=${zshrc_source}.zwc
if [[ ( ! -f ${zshrc_compiled} ) || ${zshrc_source} -nt ${zshrc_compiled} ]]; then
    logger_logging 'INFO' 'compiling zshrc' true
    zcompile ${zshrc_source}
    logger_finished
fi

# local configuration
## load local-config file
config_path=${HOME}/.zshrc.config
if [[ ! -f ${config_path} ]]; then
    logger_logging 'ERROR' 'Make your config file and place it in '${config_path}'!'
    # safe exit
    return 2>&- || exit
fi
source ${config_path}
## local home path
## type: path
local_home=${local_home:-}
if [[ ! -d ${local_home} && -n ${local_home} ]]; then
    mkdir -p ${local_home}
fi
## local-config file in local-home
config_path=${local_home:+${local_home}/.zshrc.config}
if [[ -f ${config_path} ]]; then
    source ${config_path}
fi
## bin, lib, share, or others
## type: path
usr_local=${usr_local:-'/usr/local/'}
## zsh-completions
## type: path
zsh_completion_path=${zsh_completion_path:-}
## zsh zplug
## type: path
zplug_home=${zplug_home:-}
## cuda root
## type: path
cuda_root=${cuda_root:-}
## pyenv root
## type: path
pyenv_root=${pyenv_root:-}
## memory limitation
## type: int (kbytes)
mem_size=${mem_size:-}


# use standart lang
## see: https://eng-entrance.com/linux-localization-lang
export LANG=en_US.UTF-8
# export LANG=ja_JP.UTF-8

# add paths
export PATH=${usr_local}/bin:${PATH:-}
export LD_LIBRARY_PATH=${usr_local}/lib64:${usr_local}/lib:${LD_LIBRARY_PATH:-}
export CPATH=${usr_local}/include:${CPATH:-}

# use colors
autoload -Uz colors
colors

# emacs key bind
bindkey -e

# set history files and max lines
HISTFILE=${local_home:-${HOME}}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# enable add-zsh-hook
## usage: add-zsh-hook trigger-func execute-func
## see: https://qiita.com/mollifier/items/558712f1a93ee07e22e2
autoload -Uz add-zsh-hook

# fix directory stack size
export DIRSTACKSIZE=100

# share histories with other terminals
setopt share_history

# ignore duplicated histories
setopt histignorealldups

# change directory without cd command
setopt auto_cd
## paths that can be accessed from everywhere
## see: https://qiita.com/yaotti/items/157ff0a46736ec793a91
cdpath=(${local_home:-} ${HOME})

# automatically execute pushd
setopt auto_pushd

# ignore duplicated pushd histories
setopt pushd_ignore_dups

# correct command typo
setopt correct


# global aliases
alias -g L='| less'
alias -g HD='| head'
alias -g TL='| tail'
alias -g G='| grep'
alias -g GI='| grep -ri'
alias -g T='2>&1 | tee -i'

# normal aliases
## ls
alias myls='ls -lh --color=auto'
alias lst='myls -tr'
alias l='lst'
alias ll='myls'
alias la='myls -a'
## editors
alias emacs='emacs -nw'
alias e='emacs'
alias v='vim'
alias vi='vim'
## cd
alias c='cdr'
alias ..='c ../'
alias ...='c ../../'
alias ....='c ../../../'
alias back='pushd'
## tmux
alias t='tmux'
alias ta='t a'
## history
alias hist='fc -lt '%F %T' 1'
## copy/remove with info
alias cp='cp -i'
alias rm='rm -I'
## make directory with parents
alias mkdir='mkdir -p'
## ssh X forwarding
alias ssh='ssh -X'
## human readable diff
alias diff='diff -U1'
## su without environment variables
alias su='su -l'
## cmake
if [ -d ${usr_local} ]; then
    cmake_install_options=' -DCMAKE_INSTALL_PREFIX='${usr_local}
fi
alias cmake='cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1'${cmake_install_options:-}
alias cmake_release='cmake -DCMAKE_BUILD_TYPE=Release'

# do ls after cd
## abbreviate if there are lots of files
## see: https://qiita.com/yuyuchu3333/items/b10542db482c3ac8b059
chpwd() {
    ls_abbrev
}
ls_abbrev() {
    # -a : Do not ignore entries starting with '.'.
    # -l : Long line format.
    # -h : Human-readable file size.
    local cmd_ls='ls'
    local -a opt_ls
    opt_ls=('-alh' '--color=always')
    local -i print_line_num=5
    case "${OSTYPE}" in
        freebsd*|darwin*)
            if type gls > /dev/null 2>&1; then
                cmd_ls='gls'
            else
                # -G : Enable colorized output.
                opt_ls=('-aCFG')
            fi
            ;;
    esac

    local ls_result
    ls_result=$(CLICOLOR_FORCE=1 COLUMNS=$COLUMNS command $cmd_ls ${opt_ls[@]} | sed $'/^\e\[[0-9;]*m$/d')

    local ls_lines=$(echo "$ls_result" | wc -l | tr -d ' ')

    if [ $ls_lines -gt $((print_line_num*2 + 1)) ]; then
        echo "$ls_result" | head -n $((print_line_num + 1))
        echo '...'
        echo "$ls_result" | tail -n ${print_line_num}
        echo "$(command ls -1 -A | wc -l | tr -d ' ') files exist"
    else
        echo "$ls_result"
    fi
}

# set chunk charactors
## see: https://gist.github.com/mollifier/4331a4db00a5555582e4
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars ' /=;@:{}[]()<>,|.'
# zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified

# unset Ctrl+s lock and Ctrl+q unlock
## see: http://blog.mkt-sys.jp/2014/06/fix-zsh-env.html
setopt no_flow_control

# set prompt
## deprecated; use liquidprompt instead
# PROMPT="%(?.%{${fg[green]}%}.%{${fg[red]}%})%n${reset_color}@${fg[blue]}%m${reset_color}(%*%) %~
#%# "
# git
#RPROMPT="%{${fg[blue]}%}[%~]%{${reset_color}%}"
#autoload -Uz vcs_info
#setopt prompt_subst
#zstyle ':vcs_info:git:*' check-for-changes true
#zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
#zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
#zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
#zstyle ':vcs_info:*' actionformats '[%b|%a]'
#precmd () { vcs_info }
#RPROMPT=$RPROMPT'${vcs_info_msg_0_}'
# see: http://www.yoheim.net/blog.php?q=20140309
# export PS1="\u: \w $" # user-name: directory-name $

# move with <- and -> keys after TAB completion
zstyle ':completion:*:default' menu select=2

# capital-unaware fuzzy match
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# incremental forward/backward search with Ctrl+s/Ctrl+r
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

# history search with middle inputs
## ex.
## % ls ~/<Ctrl+p>
## -> % ls ~/.ssh/
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^b" history-beginning-search-forward-end

# enable cdr, chpwd_recent_dirs
## cdr: cd with history stack
## chpwd_recent_dirs: memorize cd history
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
# use cdr like normal-cd
zstyle ":chpwd:*" recent-dirs-default true

# bundled move
## ex.
## zmv *.txt *.txt.bk
autoload -Uz zmv
alias zmv='noglob zmv -W'

# do mkdir and cd
function mkcd() {
    if [[ -d ${1} ]]; then
	logger_logging 'ERROR' 'directory'${1}' already exists.'
	cd $1
    else
	mkdir -p $1 && cd $1
    fi
}

# overwrite commands with coreutils
## see: http://qiita.com/catatsuy/items/50b339ead2571fd3f628
if [[ $(uname) == 'Darwin' ]]; then
    export PATH=/usr/local/opt/coreutils/libexec/gnubin:${PATH:-}
    export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:${MANPATH:-}
fi

# disable wildcard expansion (for like scp)
setopt nonomatch

# completions
## add zsh-completions
if [[ -d ${zsh_completion_path} ]]; then
    fpath=(${zsh_completion_path} ${fpath:-})
fi
## load compinit
autoload -Uz compinit
compinit

# cuda settings
if [[ -d ${cuda_root} ]]; then
    # set cuda path
    # see: https://qiita.com/daichan1111/items/6ca75c688fff4cf14023
    export CUDA_ROOT=${cuda_root}
    export CUDA_PATH=${CUDA_ROOT}
    export PATH=${CUDA_ROOT}/bin:${PATH}
    export LD_LIBRARY_PATH=${CUDA_ROOT}/lib64:${CUDA_ROOT}/lib:${LD_LIBRARY_PATH}
    export CPATH=${CUDA_ROOT}/include:${CPATH}
fi

# memory settings
## see: http://www.yukun.info/blog/2011/08/bash-if-num-str.html
if expr ${mem_size:-'not'} : "[0-9]*" > /dev/null ; then
    logger_logging 'INFO' 'Virtual memory is limited up to'${mem_size}'KB.'
    ulimit -S -v ${mem_size}
fi

# pyenv settings
if [[ -n ${pyenv_root} ]]; then
    export PYENV_ROOT=${pyenv_root}
    if [ ! -d ${PYENV_ROOT} ]; then
	logger_logging 'INFO' 'Installing pyenv and pyenv-virtualenv' true
    	git clone 'git://github.com/yyuu/pyenv.git' ${PYENV_ROOT}
	logger_continue
    	git clone 'https://github.com/pyenv/pyenv-virtualenv.git' ${PYENV_ROOT}'/plugins/pyenv-virtualenv'
	logger_finished
    fi
    export PATH=${PYENV_ROOT}/bin:$PATH
    logger_logging 'INFO' 'Execute pyenv-init' true
    set +ue
    logger_continue
    eval "$(pyenv init -)"
    logger_continue
    eval "$(pyenv virtualenv-init -)"
    logger_continue
    set -ue
    logger_finished
fi

# tmux color settings
# see: https://github.com/sellout/emacs-color-theme-solarized/issues/62
export TERM="xterm-256color"

# set other paths
export MYPYPATH=${HOME}/.config/mypy/stubs/:${MYPYPATH:-}


# zplug config
## if not exist, install zplug
if [[ -n ${zplug_home} ]]; then
    if [[ ! -d ${zplug_home} ]]; then
	logger_logging 'INFO' 'Installing zplug' true
	git clone 'https://github.com/zplug/zplug' ${zplug_home}
	logger_finished
    fi
fi
## settings
set +ue
if [[ -d ${zplug_home} ]]; then
    export ZPLUG_HOME=${zplug_home}
    # load zplug
    source ${ZPLUG_HOME}/init.zsh
    # load defalut plugins
    zplug 'zplug/zplug'
    zplug 'zsh-users/zsh-autosuggestions'
    zplug 'nojhan/liquidprompt'
    zplug 'zsh-users/zsh-syntax-highlighting'
    if [[ -d ${zsh_completion_path} ]]; then
	zplug 'zsh-users/zsh-completions'
    fi
    # load your zplug config
    ## ex.
    ## zplug "hoge/huga"
    zplug_source=${local_home:-${HOME}}/.zshrc.zplug
    if [[ -f ${zplug_source} ]]; then
	source ${zplug_source}
    fi
    # auto install
    if ! zplug check --verbose; then
	printf 'Install? [y/N]: '
	if read -q; then
	    echo; zplug install
	fi
    fi
    # load plugins
    zplug load --verbose
else
    logger_logging 'WARNING' 'Cannot find zplug_home in local config file.'
fi
set -ue


# end -u, -e
set +ue

# ----- end settings -----


# ----- begin loading outside files -----

# load outside files
## local rc
local_source=${local_home:-${HOME}}/.zshrc.local
if [[ -f ${local_source} ]]; then
    source ${local_source}
fi
