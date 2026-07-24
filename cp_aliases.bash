alias espload='source ~/git/esp-idf-v5.5.3/export.sh'
alias esp6load='source ~/git/esp-idf-v6.0.2/export.sh'

function lcontains {
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then result=0; else result=1; fi
  return $result
}

alias utio-chipid="(${BASH_ALIASES[espload]} && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py --port /dev/ttyUSB0 chip_id)"
alias utio-bchipid="(${BASH_ALIASES[espload]} && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py --port /dev/ttyUSB0 --before no_reset --after no_reset chip_id)"
alias atio-chipid="(${BASH_ALIASES[espload]} && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py --port /dev/ttyACM0 chip_id)"
alias atio-bchipid="(${BASH_ALIASES[espload]} && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py --port /dev/ttyACM0 --before no_reset --after no_reset chip_id)"

NUM_CPUS=`nproc`
make-aliases () {
    alias ${1}-m="(${BASH_ALIASES[$3]}; time make -j$NUM_CPUS V='steps rules' BOARD=${2})"
    alias ${1}-c="(${BASH_ALIASES[$3]}; make V=0 BOARD=${2} clean)"
    alias ${1}-cm="(${BASH_ALIASES[$3]}; make -j$NUM_CPUS V='steps rules' BOARD=${2} clean; time make -j$NUM_CPUS V='steps rules' BOARD=${2})"
    alias ${1}-dm="(${BASH_ALIASES[$3]}; time make -j$NUM_CPUS V='steps rules' BOARD=${2} DEBUG=1)"
    alias ${1}-dcm="(${BASH_ALIASES[$3]}; make -j$NUM_CPUS V='steps rules' BOARD=${2} clean; time make -j$NUM_CPUS V='steps rules' BOARD=${2} DEBUG=1)"
    lcontains "both uf2" ${5} && alias ${1}-l="echo 'Loading..' && sh -c 'cp build-${2}/firmware.uf2 \$(lsblk | grep -o '/.*'"${4}"'.*$')/firmware.uf2' && sync"
    lcontains "both flash" ${5} && alias ${1}-f="echo "Flashing.." && (${BASH_ALIASES[$3]}; while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py -c ${6} -p ${8} -b ${7} write_flash -fm ${10} -ff ${9} 0x0 build-${2}/firmware.bin)"
    lcontains "both flash" ${5} && alias ${1}-bf="echo "Flashing.." && (${BASH_ALIASES[$3]}; while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py -c ${6} --before no_reset --after no_reset -p ${8} -b ${7} write_flash -fm ${10} -ff ${9} 0x0 build-${2}/firmware.bin)"
    lcontains "both flash" ${5} && alias ${1}-df="echo "Flashing.." && ${BASH_ALIASES[$3]} && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py -c ${6} -p ${8} -b ${7} write_flash -fm ${10} -ff ${9} 0x0"
    lcontains "both flash" ${5} && alias ${1}-bdf="echo "Flashing.." && ${BASH_ALIASES[$3]} && while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py -c ${6} --before no_reset --after no_reset -p ${8} -b ${7} write_flash -fm ${10} -ff ${9} 0x0"
    lcontains "both flash" ${5} && alias ${1}-w="echo "Wiping.." && (${BASH_ALIASES[$3]}; while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py --after no_reset -c ${6} -p ${8} -b ${7} erase_flash)"
    lcontains "both flash" ${5} && alias ${1}-bw="echo "Wiping.." && (${BASH_ALIASES[$3]}; while [ ! -e ${8} ]; do echo 'Waiting for board..'; sleep 1; done; esptool.py --after no_reset -c ${6} --before no_reset --after no_reset -p ${8} -b {7} erase_flash)"
    alias ${1}-gdb="gdb -ex 'target extended-remote localhost:3333' build-${2}/firmware.elf"
    alias ${1}-dump="(${BASH_ALIASES[$3]}; esptool.py -c ${6} -b ${7} -p ${8} read_flash 0x0 \$(esptool.py --after no_reset -b ${7} -p ${8} flash_id | grep 'flash size:' | awk '{printf \"0x%x\", \$NF*1024*1024}') backup.bin)"
}

# rp2
make-aliases pico raspberry_pi_pico esp6load "RPI-RP2" uf2
make-aliases pico2 raspberry_pi_pico2 esp6load "RP2350" uf2
make-aliases picow raspberry_pi_pico_w esp6load "RPI-RP2" uf2
make-aliases ppl16 pimoroni_picolipo_16mb esp6load "RPI-RP2" uf2
make-aliases ppl4 pimoroni_picolipo_4mb esp6load "RPI-RP2" uf2
make-aliases rp2z waveshare_rp2040_zero esp6load "RPI-RP2" uf2
make-aliases rp2t waveshare_rp2040_tiny esp6load "RPI-RP2" uf2
make-aliases f2350 adafruit_feather_rp2350 esp6load "RP2350" uf2

# nrf
make-aliases sx52 Seeed_XIAO_nRF52840_Sense esp6load "XIAO-SENSE" uf2

# esp
make-aliases wspico waveshare_esp32s2_pico esp6load ESP32S2PICO both esp32s2 115200 "/dev/ttyACM0" 80m keep
make-aliases beetlec3 beetle-esp32-c3 esp6load "None" flash esp32c3 115200 "/dev/ttyACM0" 40m keep
make-aliases yd16 yd_esp32_s3_n16r8 esp6load YDESP32S3 both esp32s3 2000000 "/dev/ttyACM0" 80m keep
make-aliases ttgoten lilygo_ttgo_tenergy esp6load "None" flash esp32 115200 "/dev/ttyUSB0" 40m keep
make-aliases s3tft adafruit_feather_esp32s3_tft esp6load FTHRS3BOOT both esp32s3 115200 "/dev/ttyACM0" 40m keep
make-aliases m5x m5stack_timer_camera_x esp6load "None" flash esp32 115200 "/dev/ttyUSB0" 80m qio
make-aliases wc6 weact_esp32c6_n4 esp6load "None" flash esp32c6 921600 "/dev/ttyACM0" 40m keep
make-aliases fbs3 firebeetle2_esp32s3 esp6load FIRE2BOOT both esp32s3 2000000 "/dev/ttyACM0" 80m keep
make-aliases ls2 lolin_s2_mini esp6load S2MINIBOOT both esp32s2 115200 "/dev/ttyACM0" 80m keep
make-aliases espcam ai_thinker_esp32_cam esp6load "None" flash esp32 921600 "/dev/ttyUSB0" 80m qio
make-aliases monster monster esp6load "None" flash esp32 921600 "/dev/ttyUSB0" 80m qio
make-aliases c3sm makergo_esp32c3_supermini esp6load "None" flash esp32c3 2000000 "/dev/ttyACM0" 80m keep
make-aliases c6sm makergo_esp32c6_supermini esp6load "None" flash esp32c6 2000000 "/dev/ttyACM0" 80m keep
make-aliases esp32lite wemos_lolin32_lite esp6load "None" flash esp32 2000000 "/dev/ttyUSB0" 80m keep
make-aliases cardputer m5stack_cardputer esp6load M5S3BOOT both esp32s3 2000000 "/dev/ttyACM0" keep keep
make-aliases nodec2 nodemcu_esp32c2 esp6load "None" flash esp32c2 921600 "/dev/ttyUSB0" 60m keep
make-aliases tws3 lilygo_twatch_s3 espload TWS3BOOT both esp32s3 921600 "/dev/ttyACM0" 80m keep
make-aliases ws3z waveshare_esp32_s3_zero esp6load WS3ZEROBOOT both esp32s3 2000000 "/dev/ttyACM0" 80m keep
make-aliases tdeck lilygo_tdeck esp6load TDECKBOOT both esp32s3 2000000 "/dev/ttyACM0" 80m keep
make-aliases c3lcd 01space_lcd042_esp32c3 esp6load "None" flash esp32c3 2000000 "/dev/ttyACM0" 80m keep
make-aliases wsh2 waveshare_esp32h2 esp6load "None" flash esp32h2 2000000 "/dev/ttyACM0" 48m keep
make-aliases ws3lcd waveshare_esp32_s3_touch_lcd_1_54 esp6load "WSS3BOOT" flash esp32s3 2000000 "/dev/ttyACM0" 80m keep

# samd
make-aliases wio seeeduino_wio_terminal esp6load Arduino uf2

# modmcu
make-aliases m2s3 beryllium_m2s3 esp6load M2S3 both esp32s3 2000000 "/dev/ttyACM0" 80m keep

unset make-aliases
unset NUM_CPUS

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
