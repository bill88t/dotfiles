#!/usr/bin/env python3
import os, sys, time, signal, socket, subprocess, fcntl, pyinotify

UID = os.getuid()
LOCKFILE = f"/tmp/waybar.{UID}.lock"
PIDFILE = f"/tmp/waybar.{UID}.pid"

BASE_DIR = os.path.expanduser("~/git/dotfiles/waybar")
MINIMAL_FLAG = os.path.join(BASE_DIR, "minimal_mode")
HOSTNAME = socket.gethostname()

child = None
fail_times = []
start_time = time.time()
current_mode = None
last_niri_check = 0


def find_niri_pid() -> int:
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/comm", "r") as f:
                if f.read().strip() == "niri":
                    return int(pid)
        except FileNotFoundError:
            pass
    raise RuntimeError("niri not running")

try:
    NIRIRI = find_niri_pid()
except RuntimeError:
    sys.exit(1)

def niri_alive() -> bool:
    try:
        os.kill(NIRIRI, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True

def is_alive(proc):
    return proc and proc.poll() is None


def cleanup(*_):
    global child
    if is_alive(child):
        child.terminate()
        try:
            child.wait(timeout=2)
        except subprocess.TimeoutExpired:
            child.kill()
    for f in (LOCKFILE, PIDFILE):
        try:
            os.unlink(f)
        except FileNotFoundError:
            pass
    sys.exit(0)


signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)


# --- locking ---
lock_fd = os.open(LOCKFILE, os.O_RDWR | os.O_CREAT, 0o600)
try:
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    sys.exit(1)


def detect_mode() -> str:
    return "minimal" if os.path.exists(MINIMAL_FLAG) else "normal"


def pick_config(mode: str) -> tuple:
    minimal = False
    if mode == "minimal":
        minimal = True

    config = os.path.join(BASE_DIR, "config-minimal.jsonc") if minimal else os.path.join(BASE_DIR, "config.jsonc")
    style = os.path.join(BASE_DIR, "style-minimal.css") if minimal else os.path.join(BASE_DIR, "style.css")

    host_config = os.path.join(BASE_DIR, f"config-minimal-{HOSTNAME}.jsonc") if minimal else os.path.join(BASE_DIR, f"config-{HOSTNAME}.jsonc")
    host_style = os.path.join(BASE_DIR, f"style-minimal-{HOSTNAME}.css") if minimal else os.path.join(BASE_DIR, f"style-{HOSTNAME}.css")

    if os.path.exists(host_config):
        config = host_config
    if os.path.exists(host_style):
        style = host_style

    return config, style


def spawn_waybar() -> None:
    global child, current_mode

    mode = detect_mode()
    current_mode = mode
    config, style = pick_config(mode)

    child = subprocess.Popen(
        ["waybar", "-c", config, "-s", style],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    with open(PIDFILE, "w") as f:
        f.write(str(child.pid))


def record_failure() -> None:
    global fail_times
    now = time.time()
    fail_times.append(now)
    fail_times = [t for t in fail_times if now - t <= 4]

    if len(fail_times) >= 3 and now - start_time > 10:
        cleanup()


class ModeWatcher(pyinotify.ProcessEvent):
    def process_default(self, event):
        global child
        new_mode = detect_mode()
        if new_mode != current_mode and is_alive(child):
            child.terminate()


wm = pyinotify.WatchManager()
mask = (
    pyinotify.IN_CREATE
    | pyinotify.IN_DELETE
    | pyinotify.IN_MOVED_TO
    | pyinotify.IN_MOVED_FROM
)

wm.add_watch(BASE_DIR, mask, rec=True)
notifier = pyinotify.Notifier(wm, ModeWatcher())

# --- main loop ---
while True:
    spawn_waybar()

    while is_alive(child):
        now = time.time()
        if now - last_niri_check >= 2:
            last_niri_check = now
            if not niri_alive():
                cleanup()

        notifier.process_events()
        if notifier.check_events(timeout=500):
            notifier.read_events()

    child.wait()
    record_failure()
