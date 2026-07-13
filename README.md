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
- `mmsg`
- `jq`
- MangoWM

---

## Versions

This repository includes two script versions:

- `break_reminder.sh` – current `mmsg` syntax using `mmsg get all-clients` and `mmsg dispatch ...`
- `break_reminder_old_mmsg.sh` – legacy `mmsg` syntax using `mmsg -g -m` and `mmsg -d ...`

Use the one that matches your MangoWM / `mmsg` installation.

---

## Configuration

The script accepts optional command-line arguments:

```bash
./break_reminder.sh [WORK_TIME] [FLASHES] [PRE_FLASHES]
```

- `WORK_TIME` — seconds of continuous work before the reminder (default: `900`)
- `FLASHES` — number of minimize/restore flashes after the warning phase (default: `15`)
- `PRE_FLASHES` — number of maximize toggle flashes before the main reminder (default: `6`)

Default behavior:

- 15 minutes active work → trigger reminder
- 15 minimize/restore flashes
- 6 warning maximize toggles

---

## How It Works

1. The script stores the last active timestamp in:

```text
~/.cache/break_reminder
```

2. It detects interruptions by checking for long sleep or inactivity gaps in its main loop.

3. If any fullscreen window is active, the timer is reset and the reminder is delayed.

4. If the active work timer exceeds `WORK_TIME`:
   - the active window is maximized and restored several times as a warning phase
   - then minimized/restored repeatedly as a visual reminder

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
