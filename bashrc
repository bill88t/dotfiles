# bill88t's configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

color_prompt=yes

# Base environment
. ~/git/dotfiles/base_env.bash           # Basic env parameters
. ~/git/dotfiles/base_aliases.bash       # Basic aliases
. ~/git/dotfiles/extra_aliases.bash      # Extra general aliases
#. ~/git/dotfiles/cp_aliases.bash        # Circuitpython building
#. ~/git/dotfiles/w800_aliases.bash      # W800 firmware building
. ~/git/dotfiles/ssh_aliases.bash       # SSH into common devices
. ~/git/dotfiles/serial_aliases.bash    # For using tio
. ~/git/dotfiles/git_aliases.bash       # General git aliases
. ~/git/dotfiles/docker_aliases.bash    # A bunch of docker aliases
#. ~/git/dotfiles/th_aliases.bash        # For using my thermal printer
. ~/git/dotfiles/gpg_aliases.bash       # GPG command aliases
. ~/git/dotfiles/rkdev_aliases.bash     # rkdeveloptool aliases
. ~/git/dotfiles/veracrypt_aliases.bash # veracrypt aliases
. ~/git/dotfiles/arch_aliases.bash      # For use on arch distros.
. ~/git/dotfiles/bred_aliases.bash      # For use on BredOS.
#. ~/git/dotfiles/bixel_aliases.bash     # Google Pixel 2XL
#. ~/git/dotfiles/thinkpood_aliases.bash # Thinkpad T480
#. ~/git/dotfiles/motog32_aliases.bash   # Moto G32
#. ~/git/dotfiles/bp_aliases.bash        # Radxa Rock 5B Plus "r5bp"
#. ~/git/dotfiles/fydetab_aliases.bash   # FydeTab Duo Aliases
#. ~/git/dotfiles/prion_aliases.bash     # Radxa Orion O6 "Prion"
#. ~/git/dotfiles/op5u_aliases.bash      # OPi 5 Ultra
#. ~/git/dotfiles/r5t_aliases.bash       # Rock 5T
#. ~/git/dotfiles/fw_aliases.bash        # FraemeWoke 12
#. ~/git/dotfiles/funsized_aliases.bash  # Fun Sized Prion
. ~/git/dotfiles/zoxide_loader.bash      # z directory changer
. ~/git/dotfiles/secrets.bash            # Load secrets

bredos-news || true
