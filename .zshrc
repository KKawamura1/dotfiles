# raise error when you use an undefined variable
set -u
# halt shell scripts when an error occurs
set -e

# compile when modified
zshrc_source=${HOME}/.zshrc
zshrc_compiled=${zshrc_source}.zwc
if [[ ! -f ${zshrc_compiled} || ${zshrc_source} -nt ${zshrc_compiled} ]]; then
    zcompile ${zshrc_source}
fi

# local configuration
## load local-config file
config_path=${HOME}/.zshrc.config
if [[ ! -f ${config_path} ]]; then
    echo 'zshrc: [ERROR] Make your config file and place it in '${config_path}'!'
    # safe exit
    return 2>&- || exit
fi
source ${config_path}
## local home path
local_home=${local_home:-${HOME}}
if [[ ! -d ${local_home} ]]; then
    mkdir ${local_home}
fi
## bin, lib, share, or others
usr_local=${usr_local:-'/usr/local/'}
## zsh-completions
zsh_completion_path=${zsh_completion_path:-'NOTSET'}

# use Japanese
## see: http://qiita.com/d-dai/items/d7f329b7d82e2165dab3
export LANG=ja_JP.UTF-8

# add paths
export PATH=${usr_local}/bin:${PATH:-}
export LD_LIBRARY_PATH=${usr_local}/lib64:${usr_local}/lib:${LD_LIBRARY_PATH:-}

# use colors
autoload -Uz colors
colors

# emacs key bind
bindkey -e

# set history files and max lines
HISTFILE=${local_home}/.zsh_history
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
cdpath=(~)

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


# do ls after cd
chpwd() { la }

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
    echo ${1}' already exists!'
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
if [[ ! ${zsh_completion_path} == 'NOTSET' ]]; then
    fpath=(${zsh_completion_path} ${fpath:-})
fi
## load compinit
autoload -Uz compinit
compinit

# end -u, -e
set +ue

# load outside files

# zplug関連
[ -f ~/.zshrc.zplug ] && source ~/.zshrc.zplug

# vxs_info関連
# [ -f ~/.zshrc.vcsinfo ] && source ~/.zshrc.vcsinfo

# ローカル設定
# 環境依存な設定はここで設定したファイルに書く
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
