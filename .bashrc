# If not running interactively, don't do anything
## For ssh non-interactive shell
## See: http://d.hatena.ne.jp/flying-foozy/20140130/1391096196
## Also see: http://tyru.hatenablog.com/entry/20100104/do_not_exec_zsh_from_bashrc
[ -z "${PS1:-}" ] && return

# Attempt to use zsh (sometimes we cannot use chsh because in LDAP environment you have to get sudo authentication)
if type 'zsh' > /dev/null 2>&1; then
    echo 'bashrc: [INFO] This is bash, and `exec zsh` was run; consider `chsh` if you can.'
    exec zsh
    # safe exit
    return 2>&- || exit
else
    echo 'bashrc: [FATAL] zsh not found.'
fi
