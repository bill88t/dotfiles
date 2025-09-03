alias lstty='/bin/ls /dev/ttyACM* /dev/ttyUSB* /dev/ttyS* 2>/dev/null'

alias atio='tio /dev/ttyACM0'  # ACM0
alias atio1='tio /dev/ttyACM1' # ACM1
alias atio2='tio /dev/ttyACM2' # ACM2

alias stio='tio /dev/ttyS0'    # Serial0
alias stio1='tio /dev/ttyS1'   # Serial1
alias stio2='tio /dev/ttyS2'   # Serial2

alias utio='tio /dev/ttyUSB0'  # USB0
alias utio1='tio /dev/ttyUSB1' # USB1
alias utio2='tio /dev/ttyUSB2' # USB2

alias picoprog='flashprog -p serprog:dev=/dev/ttyACM0:115200,spispeed=12M'
