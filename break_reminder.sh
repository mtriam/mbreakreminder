#!/usr/bin/env bash
WORK_TIME=${1:-900}
IDLE_RESET_TIME=${2:-300}
FLASHES=${3:-15}
PRE_FLASHES=${4:-6}
TICK=${5:-30}
LAST_ACTIVE_FILE="${HOME:-/home/$USER}/.cache/break_reminder"
PID_FILE="/tmp/break_reminder.pid"
SWAYIDLE_PID_FILE="/tmp/break_reminder_swayidle.pid"
SLEEP_THRESHOLD=300

mkdir -p "$(dirname "$LAST_ACTIVE_FILE")"
echo $$ > "$PID_FILE"

cleanup() {
  local swayidle_pid
  if [ -r "$SWAYIDLE_PID_FILE" ]; then
    swayidle_pid=$(<"$SWAYIDLE_PID_FILE")
    kill "$swayidle_pid" 2>/dev/null || true
  fi
  rm -f "$PID_FILE" "$SWAYIDLE_PID_FILE"
  exit 0
}

trap cleanup EXIT INT TERM

swayidle -w \
  timeout "$IDLE_RESET_TIME" "rm -f \"$LAST_ACTIVE_FILE\"" \
  resume "bash -c 'printf \"%s\n\" \"\$(date +%s)\" > \"$LAST_ACTIVE_FILE\"'" &
echo $! > "$SWAYIDLE_PID_FILE"

update_last_active_file() {
  printf '%s\n' "$(date +%s)" > "$LAST_ACTIVE_FILE" 2>/dev/null
}

check_sleep_interruption() {
  local now=$(date +%s)
  if (( now - last_check > SLEEP_THRESHOLD )); then
    interrupted=1
    active_since=$now
    update_last_active_file
  fi
  last_check=$now
}

flash() {
    check_sleep_interruption
    for ((i=1; i<=PRE_FLASHES; i++)); do
      check_sleep_interruption
      if (( interrupted )); then
        return
      fi
      mmsg dispatch togglemaximizescreen; sleep 0.5
    done

    sleep 2s

    for (( i=1; i<=FLASHES; i++ )); do
      check_sleep_interruption
      if (( interrupted )); then
          return
      fi
      mmsg dispatch minimized
      sleep 0.5
      mmsg dispatch restore_minimized
      sleep 0.5
    done
}


last_check=$(date +%s)
if ! [ -r "$LAST_ACTIVE_FILE" ]; then
  update_last_active_file
fi
interrupted=0


while true; do
  if ! [ -r "$LAST_ACTIVE_FILE" ]; then
    sleep "$TICK"
    continue
  else
    active_since=$(<"$LAST_ACTIVE_FILE")
  fi


  if mmsg get all-clients | jq -e '.clients | any(.is_fullscreen == true)' >/dev/null 2>&1; then
    update_last_active_file
    sleep "$TICK"
    continue
   fi

  check_sleep_interruption

  now=$(date +%s)

  if (( now - active_since >= WORK_TIME )); then
    interrupted=0
    flash
    update_last_active_file
  fi

  sleep "$TICK"
done
