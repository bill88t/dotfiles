alias vncstart="termux-wake-lock && vncserver -xstartup ../usr/bin/startxfce4 -listen tcp :1"
alias vncstop="vncserver -kill :1 && termux-wake-unlock"
