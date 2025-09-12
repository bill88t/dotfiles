alias yayau='while pacman -Qdtq >/dev/null 2>&1; do sudo pacman -Rns $(pacman -Qdtq); done' # Autoremove
alias yayauf='while pacman -Qdtq >/dev/null 2>&1; do sudo pacman -Rns --noconfirm $(pacman -Qdtq); done'
alias yaycc='(yes | yay -Scc) && (while pacman -Qdtq >/dev/null 2>&1; do sudo pacman -Rns $(pacman -Qdtq); done)' # Cleanup fully
alias yayc='yes | yay -Scc' # Cleanup locally stored packages
alias yayd='yay -Su --devel' # Devel packages upgrade
alias yayexpl="yay -Qeq"

alias mksrc="(updpkgsums || true) -S > .SRCINFO"
alias mkncs="makepkg -rA --skipchecksums --skippgpcheck -s"
alias mkncsi="makepkg -rA --skipchecksums --skippgpcheck -si"
alias mkncsif="makepkg -rA --skipchecksums --skippgpcheck -si --noconfirm"
alias mks="(updpkgsums || true) && makepkg -sr"
alias mksi="(updpkgsums || true) && makepkg -si"
alias mksif="(updpkgsums || true) && makepkg -si --noconfirm"
alias mkndcs="makepkg -dA --skipchecksums --skippgpcheck -s"
alias mkndcsi="makepkg -dA --skipchecksums --skippgpcheck -si"
alias mkndcsif="makepkg -dA --skipchecksums --skippgpcheck -si --noconfirm"
alias mkr="(updpkgsums || true) && rm -rf src *.zst && makepkg -sr"
alias mkri="(updpkgsums || true) && rm -rf src *.zst && makepkg -si"
alias mkrif="(updpkgsums || true) && rm -rf src *.zst && makepkg -si --noconfirm"
alias mkndcr="rm -rf src *.zst && makepkg -dA --skipchecksums --skippgpcheck -s"
alias mkndcri="rm -rf src *.zst && makepkg -dA --skipchecksums --skippgpcheck -si"
alias mkndcrif="rm -rf src *.zst && makepkg -dA --skipchecksums --skippgpcheck -si --noconfirm"
alias mksd="(updpkgsums || true) && makepkg -sd"
alias mksdi="(updpkgsums || true) && makepkg -sid"
alias mksdif="(updpkgsums || true) && makepkg -sid --noconfirm"
alias mkdl="(updpkgsums || true) && makepkg --nobuild"
alias mkc="rm -rf pkg src"
alias mkcc="rm -rf pkg src *.zst"
alias mkrpk="makepkg -Rdf"
alias mkms="makepkg --noprepare --noextract -df"

yaydown() {
    for pkg in "$@"; do
        file=$(basename "$(pacman -Sp "$pkg" --cachedir="$(pwd)" --noconfirm 2>/dev/null)")
        sudo pacman -Sw --cachedir="$(pwd)" --noconfirm "$pkg"
        sudo chown "$(id -u):$(id -g)" "$file"
        sudo rm "$file".sig
    done
}
