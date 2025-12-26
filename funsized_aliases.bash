bake() {
    cd /home/bill88t/git/BredOS

    local dir="/mnt/data/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /home/bill88t/Images -c ./images/"$1"/ -x

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

alias ledmod="stty -F /dev/ttyACM0 115200 && echo -ne 'mod\n' > /dev/ttyACM0"
alias ledoff="stty -F /dev/ttyACM0 115200 && echo -ne 'off\n' > /dev/ttyACM0"
alias ledrst="stty -F /dev/ttyACM0 115200 && echo -ne 'rst\n' > /dev/ttyACM0"
alias ledprog="stty -F /dev/ttyACM0 115200 && echo -ne 'pro\n' > /dev/ttyACM0"
