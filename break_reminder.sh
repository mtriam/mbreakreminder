#!/usr/bin/env bash
WORK_TIME=${1:-900}
FLASHES=${2:-15}
PRE_FLASHES=${3:-6}
LAST_ACTIVE_FILE="${HOME:-/home/$USER}/.cache/break_reminder"
SLEEP_THRESHOLD=300

mkdir -p "$(dirname "$LAST_ACTIVE_FILE")"

interrupted=0

if [ -r "$LAST_ACTIVE_FILE" ]; then
  active_since=$(<"$LAST_ACTIVE_FILE")
else
  active_since=$(date +%s)
  printf '%s\n' "$active_since" > "$LAST_ACTIVE_FILE" 2>/dev/null
fi


check_sleep_interruption() {
  local now=$(date +%s)
  if (( now - last_check > SLEEP_THRESHOLD )); then
    interrupted=1
    active_since=$now
  fi
  last_check=$now
}

flash() {
    check_sleep_interruption
    for ((i=1; i<=PRE_FLASHES; i++)); do
      check_sleep_interruption
      if (( interrupted )); then
        break
      fi
      mmsg dispatch togglemaximizescreen; sleep 0.5
    done

    sleep 2s

    for (( i=1; i<=FLASHES; i++ )); do
      check_sleep_interruption
      if (( interrupted )); then
          break
      fi
      mmsg dispatch minimized
      sleep 0.5
      mmsg dispatch restore_minimized
      sleep 0.5
    done
}


last_check=$(date +%s)

while true; do
  now=$(date +%s)
  check_sleep_interruption

  if mmsg get all-clients | jq -e '.clients | any(.is_fullscreen == true)' >/dev/null 2>&1; then
    active_since=$(date +%s)
    sleep 30
    continue
   fi

  if (( now - active_since >= WORK_TIME )); then
    interrupted=0

    printf '%s\n' "$active_since" > "$LAST_ACTIVE_FILE" 2>/dev/null
    flash

    active_since=$(date +%s)
  fi

  sleep 15
done
