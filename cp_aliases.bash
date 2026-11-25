# Auto-alias every eim install in ~/.espressif (espload-<ver>, espload-cp<ver>).
# Default env: newest cp-v* fork install, else newest stock version.
_espload_versions=()
_espload_cp_versions=()
for _espload_dir in "$HOME"/.espressif/v*/ "$HOME"/.espressif/cp-v*/; do
    [[ -d "$_espload_dir" ]] || continue
    _espload_ver="$(basename "$_espload_dir")"
    if [[ -s "$HOME/.espressif/tools/activate_idf_${_espload_ver}.sh" ]]; then
        if [[ "$_espload_ver" == cp-v* ]]; then
            _espload_cp_versions+=("$_espload_ver")
            alias "espload-cp${_espload_ver#cp-v}"=". \"\$HOME/.espressif/tools/activate_idf_${_espload_ver}.sh\""
        else
            _espload_versions+=("$_espload_ver")
            alias "espload-${_espload_ver#v}"=". \"\$HOME/.espressif/tools/activate_idf_${_espload_ver}.sh\""
        fi
    fi
done
_espload_latest=""
if (( ${#_espload_cp_versions[@]} )); then
    mapfile -t _espload_cp_versions < <(printf '%s\n' "${_espload_cp_versions[@]}" | sort -V)
    _espload_latest="${_espload_cp_versions[-1]}"
elif (( ${#_espload_versions[@]} )); then
    mapfile -t _espload_versions < <(printf '%s\n' "${_espload_versions[@]}" | sort -V)
    _espload_latest="${_espload_versions[-1]}"
fi
_cp_idf_default="$_espload_latest"
unset _espload_versions _espload_cp_versions _espload_dir _espload_ver _espload_latest

# Env pick: $CP_IDF override, else newest cp-v* (else newest stock); only when no IDF is loaded.
_espload_pick_env() {
    local d="${CP_IDF:-$_cp_idf_default}"
    if [[ -n "$d" ]]; then
        if [[ -s "$HOME/.espressif/tools/activate_idf_${d}.sh" ]]; then
            . "$HOME/.espressif/tools/activate_idf_${d}.sh"
        else
            echo "cp_idf_env: no IDF install '$d' (activate_idf_${d}.sh missing)" >&2
            return 1
        fi
    fi
}
espload() {
    _espload_pick_env
}
cp_idf_env() {
    [[ -n "$IDF_PATH" ]] && return 0
    _espload_pick_env
}

alias utio-chipid="(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyUSB0 chip-id)"
alias utio-bchipid="(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyUSB0 --before no-reset --after no-reset chip-id)"
alias atio-chipid="(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyACM0 chip-id)"
alias atio-bchipid="(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyACM0 --before no-reset --after no-reset chip-id)"
for _n in 1 2 3 4 5 6 7 8 9; do
    alias "utio${_n}-chipid=(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyUSB${_n} chip-id)"
    alias "utio${_n}-bchipid=(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyUSB${_n} --before no-reset --after no-reset chip-id)"
    alias "atio${_n}-chipid=(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyACM${_n} chip-id)"
    alias "atio${_n}-bchipid=(cp_idf_env && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool --port /dev/ttyACM${_n} --before no-reset --after no-reset chip-id)"
done
unset _n

make-aliases() {
    # name board [label=<usb msd label>] [chip=<idf target>] [baud=115200] [port=/dev/ttyACM0] [freq=keep] [fm=keep]
    # -m/-c/-cm/-dm/-dcm/-gdb always; -l when label=; flash family and -dump when chip=.
    local name="$1" board="$2" opt
    shift 2
    local label="" chip="" baud=115200 port=/dev/ttyACM0 freq=keep fm=keep
    for opt in "$@"; do
        case "${opt%%=*}" in
            label) label="${opt#*=}" ;;
            chip) chip="${opt#*=}" ;;
            baud) baud="${opt#*=}" ;;
            port) port="${opt#*=}" ;;
            freq) freq="${opt#*=}" ;;
            fm) fm="${opt#*=}" ;;
            *) echo "make-aliases: unknown option '$opt'" >&2; return 1 ;;
        esac
    done
    local ncpu
    ncpu=$(nproc)
    eval "
$name-m() (cp_idf_env; time make -j$ncpu V='steps rules' BOARD=$board)
$name-c() (cp_idf_env; make V=0 BOARD=$board clean)
$name-cm() (cp_idf_env; make -j$ncpu V='steps rules' BOARD=$board clean; time make -j$ncpu V='steps rules' BOARD=$board)
$name-dm() (cp_idf_env; time make -j$ncpu V='steps rules' BOARD=$board DEBUG=1)
$name-dcm() (cp_idf_env; make -j$ncpu V='steps rules' BOARD=$board clean; time make -j$ncpu V='steps rules' BOARD=$board DEBUG=1)
$name-gdb() (gdb -ex 'target extended-remote localhost:3333' build-$board/firmware.elf)
"
    if [[ -n "$label" ]]; then
        eval "
$name-l() (
    echo 'Loading..'
    dest=\$(lsblk | grep -o \"/.*$label.*\$\") || exit 1
    cp \"build-$board/firmware.uf2\" \"\$dest/firmware.uf2\" && sync
)"
    fi
    if [[ -n "$chip" ]]; then
        eval "
$name-f() (echo 'Flashing..'; cp_idf_env; while [ ! -e '$port' ]; do echo 'Waiting for board..'; sleep 1; done; esptool -c '$chip' -p '$port' -b '$baud' write-flash -fm '$fm' -ff '$freq' 0x0 'build-$board/firmware.bin')
$name-bf() (echo 'Flashing..'; cp_idf_env; while [ ! -e '$port' ]; do echo 'Waiting for board..'; sleep 1; done; esptool -c '$chip' --before no-reset --after no-reset -p '$port' -b '$baud' write-flash -fm '$fm' -ff '$freq' 0x0 'build-$board/firmware.bin')
$name-df() (echo 'Flashing..'; cp_idf_env; while [ ! -e '$port' ]; do echo 'Waiting for board..'; sleep 1; done; esptool -c '$chip' -p '$port' -b '$baud' write-flash -fm '$fm' -ff '$freq' 0x0 'build-$board/firmware.bin')
$name-bdf() (echo 'Flashing..'; cp_idf_env; while [ ! -e '$port' ]; do echo 'Waiting for board..'; sleep 1; done; esptool -c '$chip' --before no-reset --after no-reset -p '$port' -b '$baud' write-flash -fm '$fm' -ff '$freq' 0x0 'build-$board/firmware.bin')
$name-w() (echo 'Wiping..'; cp_idf_env; while [ ! -e '$port' ]; do echo 'Waiting for board..'; sleep 1; done; esptool --after no-reset -c '$chip' -p '$port' -b '$baud' erase-flash)
$name-bw() (echo 'Wiping..'; cp_idf_env; while [ ! -e '$port' ]; do echo 'Waiting for board..'; sleep 1; done; esptool --after no-reset -c '$chip' --before no-reset --after no-reset -p '$port' -b '$baud' erase-flash)
$name-dump() (cp_idf_env; esptool -c '$chip' -b '$baud' -p '$port' read-flash 0x0 \"\$(esptool --after no-reset -b '$baud' -p '$port' flash-id | grep 'flash size:' | awk '{printf \"0x%x\", \$NF*1024*1024}')\" backup.bin)
"
    fi
}

# rp2
make-aliases pico raspberry_pi_pico label=RPI-RP2
make-aliases pico2 raspberry_pi_pico2 label=RP2350
make-aliases picow raspberry_pi_pico_w label=RPI-RP2
make-aliases ppl16 pimoroni_picolipo_16mb label=RPI-RP2
make-aliases ppl4 pimoroni_picolipo_4mb label=RPI-RP2
make-aliases rp2z waveshare_rp2040_zero label=RPI-RP2
make-aliases rp2t waveshare_rp2040_tiny label=RPI-RP2
make-aliases f2350 adafruit_feather_rp2350 label=RP2350

# nrf
make-aliases sx52 Seeed_XIAO_nRF52840_Sense label=XIAO-SENSE

# esp
make-aliases wspico waveshare_esp32s2_pico label=ESP32S2PICO chip=esp32s2
make-aliases beetlec3 beetle-esp32-c3 chip=esp32c3 freq=40m
make-aliases yd16 yd_esp32_s3_n16r8 label=YDESP32S3 chip=esp32s3 baud=2000000
make-aliases ttgoten lilygo_ttgo_tenergy chip=esp32 port=/dev/ttyUSB0 freq=40m
make-aliases s3tft adafruit_feather_esp32s3_tft label=FTHRS3BOOT chip=esp32s3 freq=40m
make-aliases m5x m5stack_timer_camera_x chip=esp32 port=/dev/ttyUSB0 fm=qio
make-aliases wc6 weact_esp32c6_n4 chip=esp32c6 baud=921600 freq=40m
make-aliases fbs3 firebeetle2_esp32s3 label=FIRE2BOOT chip=esp32s3 baud=2000000
make-aliases ls2 lolin_s2_mini label=S2MINIBOOT chip=esp32s2
make-aliases espcam ai_thinker_esp32_cam chip=esp32 baud=921600 port=/dev/ttyUSB0 fm=qio
make-aliases monster monster chip=esp32 baud=921600 port=/dev/ttyUSB0 fm=qio
make-aliases c3sm makergo_esp32c3_supermini chip=esp32c3 baud=2000000
make-aliases c6sm makergo_esp32c6_supermini chip=esp32c6 baud=2000000
make-aliases esp32lite wemos_lolin32_lite chip=esp32 baud=2000000 port=/dev/ttyUSB0
make-aliases cardputer m5stack_cardputer label=M5S3BOOT chip=esp32s3 baud=2000000
make-aliases nodec2 nodemcu_esp32c2 chip=esp32c2 baud=921600 port=/dev/ttyUSB0 freq=60m
make-aliases tws3 lilygo_twatch_s3 label=TWS3BOOT chip=esp32s3 baud=921600
make-aliases ws3z waveshare_esp32_s3_zero label=WS3ZEROBOOT chip=esp32s3 baud=2000000
make-aliases tdeck lilygo_tdeck label=TDECKBOOT chip=esp32s3 baud=2000000
make-aliases c3lcd 01space_lcd042_esp32c3 chip=esp32c3 baud=2000000
make-aliases wsh2 waveshare_esp32h2 chip=esp32h2 baud=2000000 freq=48m
make-aliases ws3lcd waveshare_esp32_s3_touch_lcd_1_54 chip=esp32s3 baud=2000000
make-aliases ws3dk waveshare_esp32_s3_devkit_n32r16v chip=esp32s3 baud=2000000 fm=dout freq=80m

# samd
make-aliases wio seeeduino_wio_terminal label=Arduino

# modmcu
make-aliases m2s3 beryllium_m2s3 label=M2S3 chip=esp32s3 baud=2000000

unset make-aliases

# Print current on-board flash parameters: what the bootloader header at 0x0
# holds (what -fm/-ff/-fs program), plus the detected flash size from flash-id.
flash-info() {
    local port="${1:-/dev/ttyACM0}"
    while [ ! -e "$port" ]; do echo 'Waiting for board..'; sleep 1; done
    cp_idf_env
    esptool -p "$port" flash-id
    local tmp bytes
    tmp=$(mktemp)
    if ! esptool -p "$port" read-flash 0x0 0x4 "$tmp" >/dev/null 2>&1; then
        rm -f "$tmp"
        echo "flash-info: could not read image header" >&2
        return 1
    fi
    bytes=$(od -An -tx1 -N4 "$tmp" | tr -d ' \n')
    rm -f "$tmp"
    local fs=${bytes:4:1} fm=${bytes:5:1} ff=${bytes:6:1}
    local fss fms ffs
    case "$fs" in 0) fss=1MB;; 1) fss=2MB;; 2) fss=4MB;; 3) fss=8MB;; 4) fss=16MB;; 5) fss=32MB;; *) fss="reserved(0x$fs)";; esac
    case "$fm" in 0) fms=qio;; 1) fms=qout;; 2) fms=dio;; 3) fms=dout;; *) fms="reserved(0x$fm)";; esac
    case "$ff" in 0) ffs=40m;; 1) ffs=80m;; 2) ffs=160m;; f|F) ffs=120m;; *) ffs="reserved(0x$ff)";; esac
    echo "Bootloader header: mode=$fms freq=$ffs size=$fss"
    return 0
}

# wav conversion
ffmpeg_wav() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: ffmpeg_wav <input.mp3> <output.wav> [additional ffmpeg options]"
        return 1
    fi

    input_file="$1"
    output_file="$2"
    shift 2

    ffmpeg -i "$input_file" -bitexact -acodec pcm_s16le -ac 1 -ar 16000 -map_metadata -1 -bitexact "$@" "$output_file"
}
