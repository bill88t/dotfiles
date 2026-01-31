mkdir ~/.config/micro || true
mkdir ~/.config/microfast || true
./rw.sh
rm ~/.config/micro/bindings.json || true
rm ~/.config/micro/settings.json || true
[ -L ~/.config/micro/bindings.json ] || ln -s ~/git/micro-config/bindings.json ~/.config/micro/bindings.json
[ -L ~/.config/micro/settings.json ] || ln -s ~/git/micro-config/settings.json ~/.config/micro/settings.json
[ -L ~/.config/micro/colorschemes ] || ln -s ~/git/micro-config/bindings.json ~/.config/microfast/bindings.json
[ -L ~/.config/microfast/bindings.json ] || ln -s ~/git/micro-config/settings-fast.json ~/.config/microfast/settings.json
[ -L ~/.config/micro/colorschemes ] || ln -s ~/git/micro-config/colorschemes ~/.config/micro/colorschemes
[ -L ~/.config/microfast/colorschemes ] || ln -s ~/git/micro-config/colorschemes ~/.config/microfast/colorschemes
[ -L ~/.config/microfast/backups ] || ln -s ~/.config/micro/backups ~/.config/microfast/backups
[ -L ~/.config/microfast/buffers ] || ln -s ~/.config/micro/buffers ~/.config/microfast/buffers
[ -L ~/.config/microfast/plug ] || ln -s ~/.config/micro/plug ~/.config/microfast/plug
chmod +x ro.sh rw.sh
./ro.sh
micro -plugin install wc filemanager jump aspell
micro -plugin update

echo -e '\n --- Install "aspell aspell-en aspell-el fzf ctags" ---'
