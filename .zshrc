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
    local log_level=${1:-'NOTSET'}
    # Arg2
    # Message: str = ''
    # Main message of the log.
    local message=$2
    # Arg3
    # Continues: bool = false
    # Whether to open a new line or not at the end of the message.
    # If true, continue the same line and not to open a new line.
    local continues=${3:-false}

    local message_line="zshrc: [${log_level}] "${message}
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

# Windows WSL check
## See: https://moyapro.com/2018/03/21/detect-wsl/
is_WSL () {
    if [[ -f '/proc/sys/fs/binfmt_misc/WSLInterop' ]]; then
        return 0
    fi
    return 1
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

# Safe exit
finalize () {
    # End -u, -e
    set +ue

    # Remove local functions
    unset -f logger_logging logger_continue logger_finished is_WSL update_check
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


# ----- WSL check -----

# If we're in WSL and there is no /etc/wsl.conf, it might be problematic because the default umask is 000
## See: https://www.atmarkit.co.jp/ait/articles/1807/12/news036.html
if is_WSL; then
    if ! [[ -f '/etc/wsl.conf' ]]; then
        logger_logging 'ERROR' 'It seems that we are in WSL and there is no setting in `/etc/wsl.conf`.\nYou should do:\nsudo echo '\''[automount]\nenabled = true\noptions = '\"'metadata,umask=22,fmask=111'\"\'' > /etc/wsl.conf'
        finalize
        return 2>&- || exit 1
    fi
    umask 022
fi


# ----- Read environment settings -----

# Local configuration
## Load local-config variables
## This file should contain some environment variables shown below
config_path=${HOME}/.zshrc.config
if [[ ! -f ${config_path} ]]; then
    logger_logging 'ERROR' 'Make your config file and place it in '${config_path}'!'
    finalize
    return 2>&- || exit 1
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
# Pyenv setting
## If set, we execute `pyenv init -`.
## Type: bool
## Default: false
do_pyenv_init=${do_pyenv_init:-false}
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

# Python user path (used when pip install --user)
## https://qiita.com/ronin_gw/items/cdf8112b61649ca455f5
export PYTHONUSERBASE=${local_home}/local

# Add paths
export PATH=${PYTHONUSERBASE}/bin:${usr_local}/bin:${PATH:-}
export LD_LIBRARY_PATH=${PYTHONUSERBASE}/lib:${usr_local}/lib:${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${PYTHONUSERBASE}/lib:${usr_local}/lib:${LIBRARY_PATH:-}
export CPATH=${PYTHONUSERBASE}/include:${usr_local}/include:${CPATH:-}

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
    coreutils_path=${usr_local}/opt/coreutils
    if [[ -d ${coreutils_path} ]]; then
        export PATH=${coreutils_path}/libexec/gnubin:${PATH:-}
        export MANPATH=${coreutils_path}/libexec/gnuman:${MANPATH:-}
    else
        logger_logging 'WARNING' 'You may in MacOS and coreutils not found; consider using `brew install coreutils`.'
    fi
fi

# Use brew paths
## See: https://qiita.com/noblejasper/items/cc9332cfdd9cf450d744
## And for llvm from brew
if type brew 2>&1 >/dev/null; then
    brew_prefix='/usr/local/opt'
    applications=( llvm openssl sqlite3 )
    for application in ${applications[@]}; do
        export PATH=${brew_prefix}/${application}/bin:${PATH:-}
        export CFLAGS="-I${brew_prefix}/${application}/include ${CFLAGS:-}"
        export CPPFLAGS="-I${brew_prefix}/${application}/include ${CPPFLAGS:-}"
        if [[ application == 'llvm' ]]; then
            # See: https://embeddedartistry.com/blog/2017/2/20/installing-clangllvm-on-osx
            export LDFLAGS="-L${brew_prefix}/${application}/lib -Wl,-rpath,${brew_prefix}/${application}/llvm/lib ${LDFLAGS:-}"
        else
            export LDFLAGS="-L${brew_prefix}/${application}/lib ${LDFLAGS:-}"
        fi
    done
fi


# Tmux color settings
## See: https://github.com/sellout/emacs-color-theme-solarized/issues/62
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
## Note that even in macOS we use --color=auto (which is not suited for macos `ls`) because we want to use coreutils
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
alias cd='HOME=${local_home} cdr'
alias c='cd'
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
## Create symlink
alias symlink='ln -s'
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
    local -a opt_ls=('-alh' '--color=always')
    local -i print_line_num=8

    local ls_result=$(CLICOLOR_FORCE=1 COLUMNS=$COLUMNS $cmd_ls ${opt_ls[@]} | sed $'/^\e\[[0-9;]*m$/d')

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
mkcd() {
    if [[ -d ${1} ]]; then
	logger_logging 'ERROR' 'directory'${1}' already exists.'
	cd $1
    else
	mkdir -p $1 && cd $1
    fi
}

# Listen password from stdin and echo it
## Example: require-pass-command --password $(get_password)
get_password() {
    echo -n "Type password: " 1>&2
    local password
    read -s password
    echo -n ${password}
}

# Remove all branch that is merged
## See: https://stackoverflow.com/questions/6127328/how-can-i-delete-all-git-branches-which-have-been-merged
git-clean-branch() {
    git branch --merged master | egrep -v "(^\*|master|dev)" | xargs git branch -d
    git remote prune origin
}

# Fetch pull request to a new branch and checkout to it.
## Example: git-fetch-pull-request --upstream origin 42
## For parsing arguments, see: http://dojineko.hateblo.jp/entry/2016/06/30/225113
git-fetch-pull-request() {
  local function_name='git-fetch-pull-request'

  local help="Usage: ${function_name} [-h,--help] [--upstream UPSTREAM] NUMBER

Fetch pull request to a new branch and checkout to it.

Positional arguments:
  NUMBER (int): id for the target pull request.

Optional arguments:
  -h, --help: show this message and exit.
  --upstream UPSTREAM (str): remote upstream name. default: 'upstream'.
  "

  _git-fetch-pull-request() {
    local number=$1
    local upstream=$2

    local branch_name="pull-request/${number}"
    if [[ -z `git rev-parse --is-inside-work-tree 2> /dev/null` ]]; then
      # Not a git repo
      echo "Not a git repository (or any of the parent directories). Stop."
      return 1
    fi
    if [[ -n `git branch --list ${branch_name}` ]]; then
      # Branch exists
      echo "Branch ${branch_name} already exists. Stop."
      return 1
    fi
    if ! git remote show ${upstream} 2>&1 > /dev/null; then
      # Upstream not exists
      echo "Remote ${upstream} not exists. Stop."
      return 1
    fi

    # Fetch
    local fetching="git fetch upstream pull/${number}/head:${branch_name}"
    echo "Execute ${fetching}..."
    if ! eval ${fetching}; then
      echo "Something went wrong. Stop."
      return 1
    fi

    # Checkout
    local checkout="git checkout ${branch_name}"
    echo "Checkout to ${branch_name}..."
    if ! eval ${checkout}; then
      echo "Something went wrong. Stop."
      return 1
    fi
    
    return 0
  }

  show_help () {
    echo $help
  }

  invalid_arguments () {
    local argument=${1:-}
    echo "${function_name}: illegal option ${argument}"
    show_help
  }

  parameter_required () {
    local argument=${1:-}
    echo "${function_name}: argument required for ${argument}"
    show_help
  }

  # Parse optional arguments
  local upstream='upstream'
  local PARAM=()
  for OPT in "$@"; do
    case $OPT in
      '-h' | '--help' )
        show_help
        return 0
        ;;
      '--upstream' )
        if [[ -z $2 ]] || [[ $2 =~ ^-+ ]]; then
          parameter_required '--upstream'
          return 1
        fi
        upstream=$2
        shift 2
        ;;
      '--' | '-' )
        # Treat following all arguments as positional arguments
        shift
        PARAM+=( "$@" )
        break
        ;;
      -* )
        invalid_arguments $1
        return 1
        ;;
      * )
        if [[ -n $1 ]] && [[ ! $1 =~ ^-+ ]]; then
          PARAM+=( "$1" )
          shift
        fi
        ;;
    esac
  done
  # Get positional arguments
  number=$PARAM; PARAM=( "${PARAM[@]:1}" )
  if [[ -z $number ]]; then
    parameter_required 'NUMBER'
    return 1
  fi
  # Check remains
  if [[ -n "${PARAM[@]}" ]]; then
    invalid_arguments $PARAM
    return 1
  fi

  # Main
  _git-fetch-pull-request ${number} ${upstream}
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

# No overwrite with >
## To disable this behavior, see: https://qiita.com/yuku_t/items/c83120ea22e892083651
setopt noclobber

# NICE not working in WSL
## https://github.com/Microsoft/WSL/issues/1887
if is_WSL; then
    unsetopt BG_NICE
fi

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


# Ls colors
## See: https://qiita.com/s-age/items/2046185547c73a86f09f
if type dircolors 2>&1 > /dev/null ; then
    color_rc='~/.colorrc'
    if [[ -f ${color_rc} ]]; then
        eval "dircolors ${color_rc}"
    fi
else
    logger_logging 'WARNING' 'Command dircolors not found; are we in macos? If so, consider brew install coreutils.'
fi


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

# ----- Pyenv settings -----
if ${do_pyenv_init}; then
    logger_logging 'INFO' 'Running pyenv init...'
    eval "$(pyenv init -)"
fi

# ----- Local & outside configurations -----

# Load outside files
## Local rc
if [[ -n ${local_config_file} ]]; then
    source ${local_config_file}
fi


finalize
return 2>&- || exit 0