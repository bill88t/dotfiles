#!/usr/bin/env python3
import os
import shutil
import argparse
from pathlib import Path
import re
import subprocess

HOME = Path.home()
SCRIPT_DIR = Path(__file__).resolve().parent
BASHRC_SOURCE = SCRIPT_DIR / "bashrc"
BASHRC_TARGET = HOME / ".bashrc"
ALACRITTY_SOURCE = SCRIPT_DIR / "alacritty.toml"
ALACRITTY_TARGET = HOME / ".alacritty.toml"
BASE_PACKAGES = SCRIPT_DIR / "packages1.txt"
GPG_CONF_SRC = SCRIPT_DIR / "gpg-agent.conf"
GPG_CONF_DST = HOME / ".gnupg" / "gpg-agent.conf"
NIRI_SRC = SCRIPT_DIR / "niri"
NIRI_DST = HOME / ".config/niri"


def confirm_overwrite(path, force) -> bool:
    if path.exists() or path.is_symlink():
        if force:
            print(f"Overwriting {path}")
            path.unlink(missing_ok=True)
        else:
            resp = input(f"{path} exists. Overwrite? [y/N] ").strip().lower()
            if resp != "y":
                print(f"Skipping {path}")
                return False
            path.unlink(missing_ok=True)
    return True


def symlink_file(src, dst, force=False) -> None:
    dst = Path(dst).expanduser()
    if not confirm_overwrite(dst, force):
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.symlink_to(src)
    print(f"Linked {dst} → {src}")


def install_alacritty(force=False):
    symlink_file(ALACRITTY_SOURCE, ALACRITTY_TARGET, force=force)


def install_bashrc(force=False) -> None:
    with BASHRC_SOURCE.open() as f:
        text = f.read()

    lines, entries = parse_sourcings(text)
    print("Available bashrc alias sets:\n")
    print_selection(entries)

    raw = input(
        "\nSelect which to enable (e.g. '1 3-6 8'). Leave empty to keep defaults: "
    ).strip()
    if raw:
        selected = parse_ranges(raw)
        for i, e in enumerate(entries):
            lines[e["line_num"]] = (
                f". ~/git/dotfiles/{e['name']}"
                if i in selected
                else f"#. ~/git/dotfiles/{e['name']}"
            )

    if not confirm_overwrite(BASHRC_TARGET, force):
        return

    BASHRC_TARGET.write_text("\n".join(lines) + "\n")
    print(f"Installed to {BASHRC_TARGET}")


def parse_sourcings(text: str) -> tuple:
    lines = text.splitlines()
    pattern = re.compile(r"^(\#?)\s*\. ~/git/dotfiles/([a-zA-Z0-9_]+)")
    entries = []
    for i, line in enumerate(lines):
        m = pattern.match(line)
        if m:
            commented, name = m.groups()
            entries.append(
                {
                    "line_num": i,
                    "enabled": not commented,
                    "name": name,
                }
            )
    return lines, entries


def print_selection(entries: list) -> None:
    for i, e in enumerate(entries):
        status = "[enabled]" if e["enabled"] else "[ ]"
        print(f"{i:3}. {e['name']:<25} {status}")


def parse_ranges(input_str) -> set:
    selected = set()
    for part in input_str.strip().split():
        if "-" in part:
            start, end = map(int, part.split("-"))
            selected.update(range(start, end + 1))
        else:
            selected.add(int(part))
    return selected


def install_packages(source="", force=False):
    try:
        with open(PACKAGE_LIST) as f:
            pkgs = [
                line.strip() for line in f if line.strip() and not line.startswith("#")
            ]
    except Exception as e:
        print(f"Failed to read packages.txt: {e}")
        return

    subprocess.run(["yay", "-S", "--needed"] + pkgs)


def list_groups():
    print("Available install targets:")
    for k in INSTALLERS:
        print(f" - {k}")


def install_gpgconf(force=False):
    gnupg_home = GPG_CONF_DST.parent
    gnupg_home.mkdir(mode=0o700, exist_ok=True)

    symlink_file(GPG_CONF_SRC, GPG_CONF_DST, force=force)

    try:
        subprocess.run(
            ["gpgconf", "--reload", "gpg-agent"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print("Reloaded gpg-agent successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to reload gpg-agent: {e.stderr.decode().strip()}")


def interactive_mode(force=False):
    list_groups()
    selection = input(
        "\nWhich to install? (comma-separated or blank for all): "
    ).strip()
    if not selection:
        selected = list(INSTALLERS.keys())
    else:
        selected = [s.strip() for s in selection.split(",") if s.strip() in INSTALLERS]

    for group in selected:
        INSTALLERS[group](force=force)


def main():
    parser = argparse.ArgumentParser(description="Dotfiles installer")
    parser.add_argument("group", nargs="?", help="Group to install")
    parser.add_argument(
        "-r", "--replace", action="store_true", help="Overwrite existing files"
    )
    args = parser.parse_args()

    if args.group:
        if args.group not in INSTALLERS:
            print(f"Unknown group: {args.group}")
            list_groups()
            return
        INSTALLERS[args.group](force=args.replace)
    else:
        interactive_mode(force=args.replace)


def install_niri(force=False):
    symlink_file(NIRI_SRC, NIRI_DST, force=force)


INSTALLERS = {
    "bashrc": install_bashrc,
    "alacritty": install_alacritty,
    "packages": install_packages,
    "gpgconf": install_gpgconf,
    "niri": install_niri,
}


if __name__ == "__main__":
    main()
