alias stio="tio /dev/ttyS2"

alias kde="XDG_SESSION_TYPE=wayland QT_QPA_PLATFORM=wayland GDK_BACKEND=wayland dbus-run-session startplasma-wayland > /dev/null 2>&1"
alias niri="export DISPLAY=:0 && export XDG_SESSION_TYPE=wayland && export QT_QPA_PLATFORM=wayland && export GDK_BACKEND=wayland && dbus-run-session niri > /dev/null 2>&1"

bake() {
    cd /home/bill88t/git/BredOS

    local dir="/home/bill88t/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /home/bill88t/Images -c ./images/"$1"/ -x

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

