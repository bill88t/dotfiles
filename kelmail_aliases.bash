alias raids="echo 'ROOT:' && sudo btrfs filesystem usage / && echo && sudo btrfs device stats / && echo && echo 'DATA:' && sudo btrfs filesystem usage /mnt/data && echo && sudo btrfs device stats /mnt/data && echo && sudo megasasctl"
export PATH="$PATH:/usr/sbin"
