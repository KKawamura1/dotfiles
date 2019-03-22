# =================
# ----- zshrc -----
# =================

# If not running interactively, don't do anything
## For ssh non-interactive shell
## See: http://d.hatena.ne.jp/flying-foozy/20140130/1391096196
[ -z "${PS1:-}" ] && return

# Raise error when you use an undefined variable
set -u
# Halt shell scripts when an error occurs
set -e


# ----- Local functions -----

# Logger
## Main logger
logger_logging () {
    # Arg1
    # Log_level: str = 'NOTSET'
    # Level of the log. E.g. INFO or WARNING.
    log_level=${1:-'NOTSET'}
    # Arg2
    # Message: str = ''
    # Main message of the log.
    message=$2
    # Arg3
    # Continues: bool = false
    # Whether to open a new line or not at the end of the message.
    # If true, continue the same line and not to open a new line.
    continues=${3:-false}

    message_line="zshrc: [${log_level}] "${message}
    if ${continues}; then
    	printf ${message_line}'.'
    else
	    echo ${message_line}
    fi
}
## Continue
logger_continue () {
    printf '.'
}
## End continue
logger_finished () {
    echo '. done.'
}

# Update check
update_check () {
    local mode=$1
    local -i time_threshold=$2
    local check_command=$3
    local time_save_path=$4

    # Mode check
    if [[ ${mode} == 'NOTHING' ]]; then
        return
    elif [[ ${mode} == 'MANUAL' ]]; then
        :
    elif [[ ${mode} == 'APT' ]]; then
        check_command='/usr/lib/update-notifier/apt-check --human-readable'
    elif [[ ${mode} == 'APT_SAFE' ]]; then
        check_command='echo $(apt-get -s upgrade | grep ^Inst | wc -l) packages can be upgraded.'
    elif [[ ${mode} == 'BREW' ]]; then
        check_command='brew update && brew outdated'
    else
        logger_logging 'ERROR' "Invalid update_check_mode ${mode}!"
        return
    fi

    # Time check
    local now_unix_time=$(date +%s)
    if [[ -f ${time_save_path} ]]; then
        local last_unix_time=$(cat ${time_save_path})
        local one_hour=$((60 * 60))
        local difference_in_hour=$(( (now_unix_time - last_unix_time) / one_hour ))
        if ((difference_in_hour <= time_threshold)); then
            return
        fi
    fi
    ## Do update check
    eval ${check_command}
    date +%s > ${time_save_path}
}
    

# ----- First-of-all setups -----

# Compile when modified
zshrc_source=${HOME}/.zshrc
zshrc_compiled=${zshrc_source}.zwc
if [[ ( ! -f ${zshrc_compiled} ) || ${zshrc_source} -nt ${zshrc_compiled} ]]; then
    logger_logging 'INFO' 'compiling zshrc' true
    zcompile ${zshrc_source}
    logger_finished
fi


# ----- Read environment settings -----

# Local configuration
## Load local-config variables
## This file should contain some environment variables shown below
config_path=${HOME}/.zshrc.config
if [[ ! -f ${config_path} ]]; then
    logger_logging 'ERROR' 'Make your config file and place it in '${config_path}'!'
    # Safe exit
    return 2>&- || exit
fi
source ${config_path}
# Local home path
## We use this path instead of ${HOME} for who wants to use different path from ${HOME}
## Type: path
## Default: ${HOME}
local_home=${local_home:-${HOME}}
if [[ ${local_home} != ${HOME} && ! -d ${local_home} ]]; then
    mkdir -p ${local_home}
fi
## Re-read local config file in local home
config_path=${local_home:+${local_home}/.zshrc.config}
if [[ -f ${config_path} ]]; then
    source ${config_path}
fi
# Bin, lib, share, or others
## We use this path instead of /usr/local
## Type: path
## Default: "/usr/local"
usr_local=${usr_local:-'/usr/local'}
# Zsh-completions
## Path to the installed zsh-completions (https://github.com/zsh-users/zsh-completions), which enhances the auto completion systems on zsh
## Type: path
## Default: None
zsh_completion_path=${zsh_completion_path:-}
# Zsh zplug
## Path to the zplug (if not installed there, we automatically install it)
## Type: path
## Default: None
## Example: "${local_home}/.zplug"
zplug_home=${zplug_home:-}
# Zsh zplug packages
## Path to the zplug configuration file (repetition of 'zplug "hoge/huga"\n')
## Type: path
## Default: None
## Example: "${local_home}/zshrc.zplug"
zplug_packages=${zplug_packages:-}
# Cuda root
## Path to the cuda (if not installed, then the behaviour is not supported)
## Type: path
## Default: None
## Example: "${usr_local}/cuda"
cuda_root=${cuda_root:-}
# Memory limitation
## If set, we restrict the memoty usage
## Type: int (kbytes)
## Default: None
## Example: 104857600
mem_size=${mem_size:-}
# Apt update check
## If set, we check the update every specified time with the given command
## Type: CheckMode (enum; one of shown below), int (hours), command (to check them in MANUAL check-mode)
## CheckMode: 'APT', 'APT_SAFE', 'BREW', 'MANUAL', 'NOTHING'
## Default: NOTHING, 72, 'brew update && brew outdated'
update_check_mode=${update_check_mode:-'NOTHING'}
update_check_time=${update_check_time:-72}
update_check_command=${update_check_command:-'brew update && brew outdated'}
# Local configuration file
## If set, we source it after finishing the default settings
## Type: path
## Default: None
## Example: "${local_home}/.zshrc.local"
local_config_file=${local_config_file:-}


# ----- Export variables -----

# Use standart lang
## See: https://eng-entrance.com/linux-localization-lang
export LANG=en_US.UTF-8
# export LANG=ja_JP.UTF-8

# Add paths
export PATH=${usr_local}/bin:${PATH:-}
export LD_LIBRARY_PATH=${usr_local}/lib:${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${usr_local}/lib:${LIBRARY_PATH:-}
export CPATH=${usr_local}/include:${CPATH:-}

# Cuda settings
if [[ -d ${cuda_root} ]]; then
    # Set cuda path
    # See: https://qiita.com/daichan1111/items/6ca75c688fff4cf14023
    export CUDA_ROOT=${cuda_root}
    export CUDA_PATH=${CUDA_ROOT}
    export PATH=${CUDA_ROOT}/bin:${PATH}
    export LD_LIBRARY_PATH=${CUDA_ROOT}/lib64:${CUDA_ROOT}/lib:${LD_LIBRARY_PATH}
    export CPATH=${CUDA_ROOT}/include:${CPATH}
fi

# Overwrite commands with coreutils
## See: http://qiita.com/catatsuy/items/50b339ead2571fd3f628
if [[ $(uname) == 'Darwin' ]]; then
    export PATH=${usr_local}/opt/coreutils/libexec/gnubin:${PATH:-}
    export MANPATH=${usr_local}/opt/coreutils/libexec/gnuman:${MANPATH:-}
fi

# Tmux color settings
# See: https://github.com/sellout/emacs-color-theme-solarized/issues/62
export TERM="xterm-256color"

# Fix directory stack size
export DIRSTACKSIZE=100

# Set other paths
export MYPYPATH=${HOME}/.config/mypy/stubs/:${MYPYPATH:-}


# ----- Aliases -----

# Global aliases
alias -g L='| less'
alias -g HD='| head'
alias -g TL='| tail'
alias -g G='| grep'
alias -g GI='| grep -ri'
alias -g T='2>&1 | tee -i'

# Normal aliases
## ls
alias myls='ls -lh --color=auto'
alias lst='myls -tr'
alias l='lst'
alias ll='myls'
alias la='myls -a'
## Editors
alias emacs='emacs -nw'
alias e='emacs'
alias v='vim'
alias vi='vim'
## cd
alias cd='HOME=${local_home} cd'
alias c='cdr'
alias back='pushd'
## tmux
alias t='tmux'
alias ta='t a'
## History
alias hist='fc -lt '%F %T' 1'
## Copy/remove with info
alias cp='cp -i'
alias rm='rm -I'
## Make directory with parents
alias mkdir='mkdir -p'
## ssh X forwarding
alias ssh='ssh -X'
## Human readable diff
alias diff='diff -U1'
## su without environment variables
alias su='su -l'
## cmake
if [ -d ${usr_local} ]; then
    cmake_install_options=' -DCMAKE_INSTALL_PREFIX='${usr_local}
fi
alias cmake_export='cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1'${cmake_install_options:-}
alias cmake_release='cmake_export -DCMAKE_BUILD_TYPE=Release'
alias cmake_debug='cmake -DCMAKE_BUILD_TYPE=Debug'


# ----- Useful function commands -----

# Do ls after cd
## Abbreviate if there are lots of files
## See: https://qiita.com/yuyuchu3333/items/b10542db482c3ac8b059
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
    local -i print_line_num=8
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

# Do mkdir and cd
function mkcd() {
    if [[ -d ${1} ]]; then
	logger_logging 'ERROR' 'directory'${1}' already exists.'
	cd $1
    else
	mkdir -p $1 && cd $1
    fi
}


# ----- Zsh-specific settings -----

# Use colors
autoload -Uz colors
colors

# Emacs key bind
bindkey -e

# Set history files and max lines
HISTFILE=${local_home}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Enable add-zsh-hook
## Usage: add-zsh-hook trigger-func execute-func
## See: https://qiita.com/mollifier/items/558712f1a93ee07e22e2
autoload -Uz add-zsh-hook

# Share histories with other terminals
setopt share_history

# Ignore duplicated histories
setopt histignorealldups

# Change directory without cd command
setopt auto_cd
## Paths that can be accessed from everywhere
## See: https://qiita.com/yaotti/items/157ff0a46736ec793a91
cdpath=(${local_home} ${HOME})

# Automatically execute pushd
setopt auto_pushd

# Ignore duplicated pushd histories
setopt pushd_ignore_dups

# Correct command typo
setopt correct

# Auto complete --prefix=/hoge/fug| <= tab
setopt magic_equal_subst

# Set chunk charactors
## See: https://gist.github.com/mollifier/4331a4db00a5555582e4
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars ' /=;@:{}[]()<>,|.'
# Zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified

# Unset Ctrl+s lock and Ctrl+q unlock
## See: http://blog.mkt-sys.jp/2014/06/fix-zsh-env.html
setopt no_flow_control

# Move with <- and -> keys after TAB completion
zstyle ':completion:*:default' menu select=2

# Capital-unaware fuzzy match
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Incremental forward/backward search with Ctrl+s/Ctrl+r
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

# History search with middle inputs
## Ex.) % ls ~/<Ctrl+p>
##   -> % ls ~/.ssh/
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^b" history-beginning-search-forward-end

# Enable cdr, chpwd_recent_dirs
## cdr: cd with history stack
## chpwd_recent_dirs: memorize cd history
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
# Use cdr like normal-cd
zstyle ":chpwd:*" recent-dirs-default true

# Bundled move
## Ex.) zmv *.txt *.txt.bk
autoload -Uz zmv
alias zmv='noglob zmv -W'

# Disable wildcard expansion (for like scp)
setopt nonomatch

# Completions
## Add zsh-completions
if [[ -d ${zsh_completion_path} ]]; then
    fpath=(${zsh_completion_path} ${fpath:-})
fi
## Load compinit
## Not-required: zplug do it automatically
# autoload -Uz compinit
# compinit

# Remove redundant PATHs
# See: https://qiita.com/camisoul/items/78e43923615434ba519b
typeset -U PATH path


# ----- Memory limitation -----

# Memory settings
## See: http://www.yukun.info/blog/2011/08/bash-if-num-str.html
if expr ${mem_size:-'not'} : "[0-9]*" > /dev/null ; then
    logger_logging 'INFO' 'Virtual memory is limited up to'${mem_size}'KB.'
    ulimit -S -v ${mem_size}
fi

# Core dump settings
ulimit -c 'unlimited'


# ----- Zplug -----

# Zplug config
## If not exist, install zplug
if [[ -n ${zplug_home} ]]; then
    if [[ ! -d ${zplug_home} ]]; then
	logger_logging 'INFO' 'Installing zplug' true
	git clone 'https://github.com/zplug/zplug' ${zplug_home}
	logger_finished
    fi
fi
## Settings
set +ue
if [[ -d ${zplug_home} ]]; then
    export ZPLUG_HOME=${zplug_home}
    # Load zplug
    ## Caution: redundant PATHs are automatically removed by zplug
    source ${ZPLUG_HOME}/init.zsh
    # Load defalut plugins
    zplug 'zplug/zplug'
    zplug 'zsh-users/zsh-autosuggestions'
    zplug 'nojhan/liquidprompt'
    zplug 'zsh-users/zsh-syntax-highlighting'
    if [[ -d ${zsh_completion_path} ]]; then
	    zplug 'zsh-users/zsh-completions'
    fi
    # Load your zplug config
    if [[ -n ${zplug_packages} ]]; then
    	source ${zplug_packages}
    fi
    # Auto install
    if ! zplug check --verbose; then
        printf 'Install? [y/N]: '
        if read -q; then
            echo; zplug install
        fi
    fi
    # Load plugins
    zplug load --verbose
else
    logger_logging 'WARNING' 'Cannot find zplug_home in local config file.'
fi
set -ue


# ----- Update check -----
update_check_path="${local_home}/.update_check_time"
update_check ${update_check_mode} ${update_check_time} ${update_check_command} ${update_check_path}


# ----- Finalize -----

# End -u, -e
set +ue

# Remove local functions
unset -f logger_logging logger_continue logger_finished update_check


# ----- Local & outside configurations -----

# Load outside files
## Local rc
if [[ -n ${local_config_file} ]]; then
    source ${local_config_file}
fi
