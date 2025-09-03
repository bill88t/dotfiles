alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

bake() {
    cd /home/bill88t/git/BredOS

    local dir="/mnt/Array/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /mnt/Array/Images -c ./images/"$1"/ -x

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

cbake() {
    cd /home/bill88t/git/BredOS

    local dir="/mnt/Array/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /mnt/Array/Images -c ./images/"$1"/

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

alias cin="startx /usr/bin/cinnamon-session && clear"
