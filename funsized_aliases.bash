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

export PATH="$HOME/git/llama.cpp/build/bin:$PATH"

# Android build env (aarch64 SDK + SnowNF r29 NDK + lzhiyong aarch64 tools)
export ANDROID_HOME="$HOME/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Android/sdk"
export JAVA_HOME="/usr/lib/jvm/default"

build_llama() {
    cd /home/bill88t/git/llama.cpp

    if [ -d build ]; then
        echo "Removing existing build dir"
        rm -rf build
    fi

    cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=ON -DGGML_CPU_KLEIDIAI=ON
    cmake --build build --config Release -j15
}

build_sd() {
    cd /home/bill88t/git/stable-diffusion.cpp

    if [ -d build ]; then
        echo "Removing existing build dir"
        rm -rf build
    fi

    cmake -B build -DCMAKE_BUILD_TYPE=Release -DSD_CURL=ON -DGGML_NATIVE=ON -DGGML_CPU_KLEIDIAI=ON
    cmake --build build -j14
}

update_llama() {
    cd /home/bill88t/git/llama.cpp
    git pull
    build_llama
}

update_sd() {
    cd /home/bill88t/git/stable-diffusion.cpp
    git pull
    git submodule update --init --recursive
    build_sd
}
