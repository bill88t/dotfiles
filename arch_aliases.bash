alias yayau='while pacman -Qdtq >/dev/null 2>&1; do sudo pacman -Rns $(pacman -Qdtq); done' # Autoremove
alias yayauf='while pacman -Qdtq >/dev/null 2>&1; do sudo pacman -Rns --noconfirm $(pacman -Qdtq); done'
alias yaycc='(while pacman -Qdtq >/dev/null 2>&1; do sudo pacman -Rns $(pacman -Qdtq); done) && ([ -d ~/Built ] && rm ~/Built/* || true) && (yes | yay -Scc)' # Cleanup fully
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

upkg() {
    local pkg="$1"

    local built_dir="$HOME/Built"
    local cache_dir="$HOME/.cache/yay/$pkg"
    local newpkg=""

    # Check ~/built first
    if [[ -d "$built_dir" ]]; then
        newpkg=$(ls "$built_dir"/${pkg}-*-*.pkg.tar.zst 2>/dev/null | sort -V | tail -n1)
    fi

    # Fallback to yay cache
    if [[ -z "$newpkg" && -d "$cache_dir" ]]; then
        newpkg=$(ls "$cache_dir"/${pkg}-*-*.pkg.tar.zst 2>/dev/null | sort -V | tail -n1)
    fi

    if [[ -z "$newpkg" ]]; then
        echo "No new package for $pkg found in $built_dir or $cache_dir"
        return 1
    fi

    # Extract architecture from filename
    local arch="${newpkg##*-}"
    arch="${arch%.pkg.tar.zst}"

    # Repo path based on arch
    local repo_dir
    if [[ "$arch" == "any" ]]; then
        repo_dir="$HOME/Repo/repo/BredOS-any/any"
    else
        repo_dir="$HOME/Repo/repo/BredOS/$arch"
    fi

    cd "$repo_dir" || return 1

    # Find and remove old package if it exists
    local oldpkg
    oldpkg=$(ls ${pkg}-*-*.pkg.tar.zst 2>/dev/null | sort -V | tail -n1)
    if [[ -n "$oldpkg" ]]; then
        ./db.sh remove "$pkg"
        rm -f "$oldpkg" "$oldpkg.sig"
    fi

    # Copy new package in place
    cp "$newpkg" ./
    gpsign "$(basename "$newpkg")"

    # Add to db
    ./db.sh add "$(basename "$newpkg")"

    cd - >/dev/null || true
}
