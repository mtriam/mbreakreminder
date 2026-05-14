#!/usr/bin/env zsh
IDLE_RESET_TIME=300
WORK_TIME=900
FLASHES=15

echo $$ > /tmp/break_reminder.pid

active_since=$(date +%s)

reset_timer() {
  active_since=$(date +%s)
}

trap reset_timer USR1

is_fullscreen() {
  mmsg -g -m | grep -q "fullscreen 1"
}


swayidle -w timeout $IDLE_RESET_TIME "kill -USR1 $(cat /tmp/break_reminder.pid 2>/dev/null)" &

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
      mmsg -d togglemaximizescreen; sleep 0.5
    done

    sleep 2s

    for (( i=1; i<=FLASHES; i++ )); do
      mmsg -d minimized
      sleep 0.5
      mmsg -d restore_minimized
      sleep 0.5
    done

    active_since=$(date +%s)
  fi

  sleep 15
done
