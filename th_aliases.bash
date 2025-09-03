export PYTHONPATH="/home/bill88t/git/pytherm/"

alias thcut="python3 -c \"from pytherm import thermal;a=thermal();a.cut()\""
alias thline="python3 -c \"from pytherm import thermal;a=thermal();a.line()\""
alias thdoujin="python3 /home/bill88t/git/dotfiles/thdoujin.py"
thimg () {
    python3 -c "from pytherm import thermal;a=thermal();a.image(\"$1\");a.cut()"
}
thcat () {
    python3 -c "from pytherm import thermal;a=thermal();a.cat(\"$1\");a.cut()"
}
uthcat () {
    python3 -c "from pytherm import thermal;a=thermal();a.cat(\"$1\")"
}
thqr() {
    python3 -c "from pytherm import thermal;a=thermal();a.qr(\"$1\")"
}
