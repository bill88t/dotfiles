alias stio="tio /dev/ttyS2"

bake() {
    cd /home/bill88t/git/Beryllium

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

bake_iso() {
    cd /home/bill88t/git/Beryllium/iso

    local dir="/home/bill88t/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo ./mkarchiso -v -w $dir -o /home/bill88t/Images ./"$1"

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

export PATH="$HOME/git/llama.cpp/build/bin:$PATH"

build_llama() {
    cd /home/bill88t/git/llama.cpp

    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_CCACHE=OFF -DGGML_NATIVE=ON -DGGML_VULKAN=ON -DGGML_CPU_KLEIDIAI=ON
    cmake --build build --config Release -j9
}
