# Break Reminder for MangoWM

A simple Bash break reminder for MangoWM using `mmsg` and `jq`.

The script tracks active work time and reminds you to take a break by repeatedly minimizing/restoring the current window after a configurable amount of uninterrupted activity.

Fullscreen windows are ignored automatically, making it suitable for gaming, videos, or presentations.

---

## Features

- Tracks active work time
- Resets timer automatically after user idle
- Ignores fullscreen windows
- Visual break reminder using window minimize/restore flashing
- Warning phase before flashing by toggling maximize state
- Lightweight and minimal

---

## Requirements

- Bash
- `jq`
- `swayidle`
- MangoWM

---

## Versions

This repository includes two script versions:

- `break_reminder.sh` – current `mmsg` syntax using `mmsg get all-clients` and `mmsg dispatch ...`
- `break_reminder_old_mmsg.sh` – legacy `mmsg` syntax using `mmsg -g -m` and `mmsg -d ...`

Use the one that matches your MangoWM / `mmsg` installation.

---

## Configuration

The script accepts optional command-line arguments using long flags, with short aliases available as well:

```bash
./break_reminder.sh \
  --work-time 900 \
  --idle-reset-time 300 \
  --break 15 \
  --pre-flashes 6 \
  --tick 30 \
  --mode MONITOR
```

Short aliases:

```bash
./break_reminder.sh -w 900 -i 300 -b 15 -p 6 -t 30 -m MONITOR
```

- `-w`, `--work-time` — seconds of continuous work before the reminder (default: `900`)
- `-i`, `--idle-reset-time` — seconds of idle before the timer resets automatically (default: `300`)
- `-b`, `--break` — break duration: number of flash cycles in `TAG` mode, or seconds of monitor sleep in `MONITOR` mode (default: `15`)
- `-p`, `--pre-flashes` — number of maximize toggle flashes before the main reminder (default: `6`)
- `-t`, `--tick` — sleep interval between checks (default: `30`)
- `-m`, `--mode` — `TAG` or `MONITOR` (default: `MONITOR`)
- `-h`, `--help` — show usage

Default behavior:

- 15 minutes active work → trigger reminder
- 5 minutes idle resets the timer
- 15 seconds monitor sleep in `MONITOR` mode, or 15 tag flash cycles in `TAG` mode
- 6 warning maximize toggles
- 30-second check interval

---

## How It Works

1. The script stores the last active timestamp in:

```text
~/.cache/break_reminder
```

2. It detects interruptions by checking for long sleep or inactivity gaps in its main loop, and uses `swayidle` to reset the timer after idle.

3. If any fullscreen window is active, the timer is reset and the reminder is delayed.

4. If the active work timer exceeds `WORK_TIME`:
   - the active window is maximized and restored several times as a warning phase
   - then the reminder runs in the selected mode:
     - `TAG`: minimize/restore the active tag repeatedly
     - `MONITOR`: sleep and wake the monitors for the configured break duration

---

## Installation

Choose the script that matches your `mmsg` version:

- `break_reminder.sh` – new `mmsg` syntax
- `break_reminder_old_mmsg.sh` – old `mmsg` syntax

Save the chosen script somewhere convenient, for example:

```bash
~/.local/bin/break_reminder.sh
```

Make it executable:

```bash
chmod +x ~/.local/bin/break_reminder.sh
```

If you want to keep both versions available, rename the old one:

```bash
cp break_reminder_old_mmsg.sh ~/.local/bin/break_reminder_old_mmsg.sh
chmod +x ~/.local/bin/break_reminder_old_mmsg.sh
```

### Quick Install

```bash
mkdir -p ~/.local/bin && \
wget -O ~/.local/bin/break_reminder.sh https://raw.githubusercontent.com/mtriam/mbreakreminder/main/break_reminder.sh && \
chmod +x ~/.local/bin/break_reminder.sh
```

If you need the legacy version instead, replace the filename in the command above with `break_reminder_old_mmsg.sh`.

---

## Autostart (MangoWM)

Add this to your MangoWM config:

```ini
exec-once = ~/.local/bin/break_reminder.sh
```

---

## Notes

- System sleep or long interruptions reset the timer.
- Fullscreen windows temporarily pause tracking and reset the active timer.
- No notifications, overlays, or external GUI dependencies.

---

## License
GPL 3.0
