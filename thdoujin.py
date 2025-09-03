import argparse
import os
import subprocess
import sys
from time import sleep
from pytherm import thermal

_lc = "\033[K"


def resize_and_print(directory: str, cmd: str, rsz: str, thr: str):
    cmd = cmd.split(" ")

    def _drc(nm):
        return (
            subprocess.check_output(
                f'{" ".join(cmd)} {nm}'
                + ' -format "%[fx:mean*100]" info: '
                + f'| awk \'{{print ($1 > {thr}) ? "l" : "d"}}\'',
                shell=True,
                universal_newlines=True,
            )[:-1]
            == "d"
        )

    def is_image_file(name: str) -> bool:
        return name.endswith((".jpg", ".png", ".webp"))

    a = thermal()

    # Cleanup pre-existing temporary files
    for file in os.listdir(directory):
        if "thtrim" in file:
            print(_lc + f"Cleaning up {file}...", end="\r", flush=True)
            os.remove(os.path.join(directory, file))

    try:
        files = sorted(os.listdir(directory))
        files.reverse()
        for file in files:
            if is_image_file(file):
                print(_lc + f"Processing file: {file}", end="\r", flush=True)
                temp_file = os.path.join(directory, file[:-4] + "_thtrim.jpg")
                subprocess.call(
                    cmd
                    + [
                        os.path.join(directory, file),
                        "-resize",
                        f"{rsz}>",
                        "-colorspace",
                        "Gray",
                        "-strip",
                        "-interlace",
                        "Plane",
                        "-quality",
                        "80%",
                        temp_file,
                    ]
                )
                while _drc(temp_file):
                    print(_lc + "Increasing brightness...", end="\r", flush=True)
                    subprocess.call(
                        cmd
                        + [
                            temp_file,
                            "-fill",
                            "black",
                            "-brightness-contrast",
                            "+5x0",
                            temp_file,
                        ]
                    )
                print(_lc + f"Printing {file}...", end="\r", flush=True)
                sleep(2.5)
                a.image(temp_file)
                print(
                    _lc + f"Deleting temporary file: {temp_file}...",
                    end="\r",
                    flush=True,
                )
                os.remove(temp_file)
                a.cut()
        print(" " * 50, end="\r", flush=True)  # Clear progress line
        print("All files processed successfully!")
    except Exception as err:
        print("\n" + "-" * 25)
        print(f"Printing FAILED!\n{err}")
        print("-" * 25)
        for file in os.listdir(directory):
            if "thtrim" in file:
                print(_lc + f"Cleaning up {file}...", end="\r", flush=True)
                os.remove(os.path.join(directory, file))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Resize and print images with a thermal printer."
    )
    parser.add_argument("directory", type=str, help="Directory containing the images.")
    parser.add_argument(
        "-c",
        type=str,
        default="/usr/bin/magick",
        help="Command for image processing (default: '/usr/bin/magick').",
    )
    parser.add_argument(
        "-r",
        type=str,
        default="550x800",
        help="Resize dimensions for the images (default: '550x800').",
    )
    parser.add_argument(
        "-t", type=str, default="65", help="Brightness threshold (default: '65')."
    )

    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Error: Directory '{args.directory}' does not exist.")
        sys.exit(1)

    resize_and_print(args.directory, args.c, args.r, args.t)
