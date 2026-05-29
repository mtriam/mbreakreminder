#!/usr/bin/env bash
IDLE_RESET_TIME=300
WORK_TIME=900
FLASHES=15

echo $$ > /tmp/break_reminder.pid

active_since=$(date +%s)
interrupted=0


reset_timer() {
  active_since=$(date +%s)
  interrupted=1
 }

trap reset_timer USR1

is_fullscreen() {
  mmsg get all-clients | jq -e '.clients | any(.is_fullscreen == true)' >/dev/null 2>&1
}


swayidle -w timeout $IDLE_RESET_TIME "kill -USR1 $(cat /tmp/break_reminder.pid 2>/dev/null)" resume "kill -USR1 $(cat /tmp/break_reminder.pid 2>/dev/null)" &

while true; do
  now=$(date +%s)

  if is_fullscreen; then
    active_since=$(date +%s)
    sleep 30
    continue
   fi

  elapsed=$(( now - active_since ))


  if (( elapsed >= WORK_TIME )); then

    if (( elapsed > WORK_TIME + 120 )); then
      active_since=$(date +%s)
      continue
    fi

    for i in {1..6}; do
      if (( interrupted )); then
        break
      fi
      mmsg dispatch togglemaximizescreen; sleep 0.5
    done

    sleep 2s

    for (( i=1; i<=FLASHES; i++ )); do
      if (( interrupted )); then
        interrupted=0
        break
      fi
      mmsg dispatch minimized
      sleep 0.5
      mmsg dispatch restore_minimized
      sleep 0.5
    done

    active_since=$(date +%s)
  fi

  sleep 15
done
