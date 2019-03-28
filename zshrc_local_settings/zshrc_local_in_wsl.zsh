# X server settings
## See: https://www.atmarkit.co.jp/ait/articles/1812/06/news040.html
## See also: https://qiita.com/kilo/items/c8b51f2b52bf5c6f3aa3
export DISPLAY=:0.0
export GDK_SCALE=2
## Han-Zen settings
## See: https://qiita.com/dozo/items/97ac6c80f4cd13b84558
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export DefaultIMModule=fcitx
if [[ ${SHLVL:-} = 1 ]]; then
  xset -r 49  > /dev/null 2>&1
  (fcitx-autostart > /dev/null 2>&1 &)
fi
