bake() {
    cd /home/bill88t/git/BredOS

    local dir="/mnt/Beeg/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /mnt/Beeg/Images -c ./images/"$1"/ -x

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

alias cm5rcon="mcrcon -H 192.168.1.235 -p 1234"
alias prionrcon="mcrcon -H 192.168.1.236 -p QwEr2252"
