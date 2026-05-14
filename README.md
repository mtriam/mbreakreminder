# Break Reminder for MangoWM

A simple Bash break reminder for MangoWM using `mmsg` and `swayidle`.

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
- `swayidle`
- `mmsg`
- MangoWM

---

## Configuration

You can modify these variables at the top of the script:

```bash
IDLE_RESET_TIME=300   # Seconds of idle time before timer resets
WORK_TIME=900         # Seconds of continuous work before reminder
FLASHES=15            # Number of minimize/restore flashes
```

Default behavior:

- 5 minutes idle → reset timer
- 15 minutes active work → trigger reminder

---

## How It Works

1. The script stores its PID in:

```text
/tmp/break_reminder.pid
```

2. `swayidle` watches for inactivity.

3. After enough idle time, the script receives `USR1` and resets the work timer.

4. If the active work timer exceeds `WORK_TIME`:
   - fullscreen windows are skipped
   - the current window is toggled several times
   - then minimized/restored repeatedly as a visual reminder

---

## Installation

Save the script somewhere, for example:

```bash
~/.local/bin/break_reminder.sh
```

Make it executable:

```bash
chmod +x ~/.local/bin/break_reminder.sh
```

or

## Quick Install

```bash
mkdir -p ~/.local/bin && \
wget -O ~/.local/bin/break_reminder.sh https://raw.githubusercontent.com/mtriam/mbreakreminder/main/break_reminder.sh && \
chmod +x ~/.local/bin/break_reminder.sh
```

---

## Autostart (MangoWM)

Add this to your MangoWM config:

```ini
exec-once = ~/.local/bin/break_reminder.sh
```

---

## Notes

- The reminder automatically cancels if the timer exceeds `WORK_TIME + 120`.
- Fullscreen windows temporarily pause tracking.
- No notifications, overlays, or external GUI dependencies.

---

## License
GPL 3.0
