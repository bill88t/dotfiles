alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'
alias nv="sudo nvtop"

nollm() {
    systemctl --user stop llama.gemma
    systemctl --user stop llama.gemma.low
    systemctl --user stop llama.biggemma

    sudo killall -s9 llama-server 2>/dev/null || true
}

killllm() {
    systemctl --user kill llama.gemma
    systemctl --user kill llama.gemma.low
    systemctl --user kill llama.biggemma

    sudo killall -s9 llama-server 2>/dev/null || true
}

gemma() {
    nollm
    systemctl --user start llama.gemma
}

lowgemma() {
    nollm
    systemctl --user start llama.gemma.low
}

biggemma() {
    nollm
    systemctl --user start llama.biggemma
}

bake() {
    cd /home/bill88t/git/Beryllium

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

bake_iso() {
    cd /home/bill88t/git/Beryllium/iso

    local dir="/mnt/Array/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo ./mkarchiso -v -w $dir -o /mnt/Array/Images ./"$1"

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

export PATH="$HOME/git/llama.cpp/build/bin:$PATH"

build_llama() {
    cd /home/bill88t/git/llama.cpp

    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_CCACHE=OFF -DGGML_NATIVE=ON -DGGML_VULKAN=ON -DGGML_CPU_KLEIDIAI=ON
    cmake --build build --config Release -j15
}
