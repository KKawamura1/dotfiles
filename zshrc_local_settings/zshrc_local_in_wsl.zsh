# Execute vscode (in windows) and detatch it
code () {
    nohup /mnt/c/Users/kkawa/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe "$@" < /dev/null > /dev/null &
}
