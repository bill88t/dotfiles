bake() {
    cd /home/bill88t/git/Beryllium

    local dir="/tmp/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /home/bill88t/Images -c ./images/"$1"/

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

bake_iso() {
    cd /home/bill88t/git/Beryllium/iso

    local dir="/tmp/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo ./mkarchiso -v -w $dir -o /home/bill88t/Images ./"$1"

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

alias ledmod="(stty 115200 && echo -ne 'mod\n' >> /dev/ttyACM0)"
alias ledoff="(stty 115200 && echo -ne 'off\n' >> /dev/ttyACM0)"
alias ledrst="(stty 115200 && echo -ne 'rst\n' >> /dev/ttyACM0)"
alias ledprog="(stty 115200 && echo -ne 'pro\n' >> /dev/ttyACM0)"

build_llama() {
    cd /home/bill88t/git/llama.cpp

    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_CCACHE=OFF -DGGML_NATIVE=ON -DGGML_CPU_KLEIDIAI=ON
    cmake --build build --config Release -j15
}
