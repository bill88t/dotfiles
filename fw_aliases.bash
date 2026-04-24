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


alias hotspot-up="nmcli connection modify Hotspot 802-11-wireless-security.pairwise ccmp && nmcli connection modify Hotspot 802-11-wireless-security.group ccmp && nmcli connection up Hotspot"

alias hotspot-down="nmcli connection down Hotspot"

kobold() {
    (
        cd ~
        clear

        python3 git/koboldcpp/koboldcpp.py \
            -m Local/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf \
            -b 512 \
            -c 4096 \
            --threads 6 \
            --usevulkan \
            --gpulayers 25 \
            --smartcache 4 \
            --usemmap

        return 0
    )
}

kobold_alt() {
    (
        cd ~
        clear

        python3 git/koboldcpp/koboldcpp.py \
            -m Local/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf \
            --port 5502 \
            -b 512 \
            -c 4096 \
            --threads 6 \
            --usevulkan \
            --gpulayers 25 \
            --smartcache 4 \
            --usemmap \
            --websearch \
            --mmproj Local/mmproj-Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-f16.gguf

        return 0
    )
}

kobold_img() {
    (
        cd ~
        clear

        python3 git/koboldcpp/koboldcpp.py \
            --sdmodel /home/bill88t/Local/Bunny-XL2-V3-NS.safetensors.q8_0.gguf \
            --threads 6 \
            --sdconvdirect full \
            --usevulkan

        return 0
    )
}
