ffmpsp () {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffmpsp <input> [ffmpeg options...]"
        return 1
    fi

    ffmpeg -i "$1" \
        -vf "scale='min(480,iw)':'min(272,ih)':force_original_aspect_ratio=decrease,pad=480:272:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx264 -profile:v baseline -level 3.0 -pix_fmt yuv420p \
        -preset slow -crf 21 \
        -r 29.97 \
        -c:a aac -b:a 128k -ar 48000 \
        -movflags +faststart \
        "$2"
}

ffh264() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
        -hwaccel vaapi \
        -hwaccel_device intel \
        -hwaccel_output_format vaapi \
        -i "$input" \
        -c:v h264_vaapi \
        "$@"
}

ffch264() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
           -hwaccel vaapi \
           -hwaccel_device intel \
           -hwaccel_output_format vaapi \
           -i "$input" \
           -c:v h264_vaapi \
           -b:v 8M \
           -maxrate 10M \
           -bufsize 16M \
           -profile:v main \
           "$@"
}

ffh264_1080() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264_1080 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
        -hwaccel vaapi \
        -hwaccel_device intel \
        -hwaccel_output_format vaapi \
        -i "$input" \
        -c:v h264_vaapi \
        -vf "scale_vaapi=w=-2:h=1080" \
        "$@"
}

ffch264_1080() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264_1080 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
           -hwaccel vaapi \
           -hwaccel_device intel \
           -hwaccel_output_format vaapi \
           -i "$input" \
           -c:v h264_vaapi \
           -b:v 8M \
           -maxrate 10M \
           -bufsize 16M \
           -profile:v main \
           -vf "scale_vaapi=w=-2:h=1080" \
           "$@"
}

ffh264_720() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264_720 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
        -hwaccel vaapi \
        -hwaccel_device intel \
        -hwaccel_output_format vaapi \
        -i "$input" \
        -c:v h264_vaapi \
        -vf "scale_vaapi=w=-2:h=720" \
        "$@"
}

ffch264_720() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264_720 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
           -hwaccel vaapi \
           -hwaccel_device intel \
           -hwaccel_output_format vaapi \
           -i "$input" \
           -c:v h264_vaapi \
           -b:v 5M \
           -maxrate 5M \
           -bufsize 8M \
           -profile:v main \
           -vf "scale_vaapi=w=-2:h=720" \
           "$@"
}


ffh264_480() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264_480 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
        -hwaccel vaapi \
        -hwaccel_device intel \
        -hwaccel_output_format vaapi \
        -i "$input" \
        -c:v h264_vaapi \
        -vf "scale_vaapi=w=-2:h=480" \
        "$@"
}


ffch264_480() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ffh264_480 <input> [ffmpeg options...]"
        return 1
    fi

    local input="$1"
    shift

    ffmpeg -init_hw_device "vaapi=intel:/dev/dri/renderD128" \
           -hwaccel vaapi \
           -hwaccel_device intel \
           -hwaccel_output_format vaapi \
           -i "$input" \
           -c:v h264_vaapi \
           -b:v 2M \
           -maxrate 2.5M \
           -bufsize 4M \
           -profile:v main \
           -vf "scale_vaapi=w=-2:h=480" \
           "$@"
}

alias matlab="/home/bill88t/Matlab/R2024b/bin/matlab -webui -nosoftwareopengl"

bake() {
    (
        cd /home/bill88t/git/Beryllium

        local dir="/home/bill88t/BUILD"
        echo "Cleaning $dir"
        [ -d "$dir" ] && sudo rm -rf "$dir"

        mkdir "$dir"
        sudo mkimage/mkimage.py -w $dir -o /home/bill88t/Images -c ./images/"$1"/ -x

        local status=$?
        [ $status -ne 0 ] && sudo rm -rf "$dir"

        return $status
    )
}


alias hotspot-up="nmcli connection modify Hotspot 802-11-wireless-security.pairwise ccmp && nmcli connection modify Hotspot 802-11-wireless-security.group ccmp && nmcli connection up Hotspot"

alias hotspot-down="nmcli connection down Hotspot"

build_llama() {
    cd /home/bill88t/git/llama.cpp
    sudo ulimit -l unlimited
    source /opt/intel/oneapi/setvars.sh
    cmake -B build -DGGML_SYCL=ON -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx -DGGML_SYCL_F16=ON -DCMAKE_BUILD_TYPE=Release -DGGML_CCACHE=OFF -DGGML_NATIVE=ON && cmake --build build --config Release -j8
}

export PATH="$HOME/git/llama.cpp/build/bin:$PATH"

llama() {
    (
        cd ~/git/llama.cpp/build/bin
        clear

        sudo bash -c "ulimit -l unlimited && source /opt/intel/oneapi/setvars.sh && ./llama-server \
            -m /home/bill88t/Local/flint-abliterated-Q3_K_M.gguf \
            --alias \"Flint Uncensored\" \
            --port 5501 --ui-mcp-proxy -c 16384 --threads 6 -ngl 0 \
            --prio 3 --prio-batch 3 -fit on -np 1 -lm mmap -lv 4 --agent \
            -b 128 --top-k 40 --temp 0.5 --top-p 0.95 --min-p 0 --repeat-penalty 1.0 --presence-penalty 0 \
            --jinja -cms 128 -fa on --no-warmup -ctk q4_0 -ctv q4_0 -cram 2048 \
            --webui-config-file /home/bill88t/Local/llmconfig.json"

        return 0
    )
}

dex() {
    echo "Stopping firewalld"
    sudo systemctl stop firewalld

    echo "Launching scrcpy"
    scrcpy --fullscreen --new-display=1920x1200/180 -S --max-fps=60 --mouse=uhid

    echo "Killing adb.."
    adb kill-server

    echo "Starting firewalld"
    sudo systemctl start firewalld
}

dex_cadmium() {
    echo "Stopping firewalld.."
    sudo systemctl stop firewalld

    echo "Connecting.."
    adb connect 192.168.1.231:5555

    echo "Launching scrcpy.."
    scrcpy \
        --fullscreen \
        --new-display=1920x1200/180 \
        --video-codec=h265 -b16M \
        --max-fps=60 \
        --mouse=uhid

    echo "Killing adb.."
    adb disconnect
    adb kill-server

    echo "Starting firewalld.."
    sudo systemctl start firewalld
}

