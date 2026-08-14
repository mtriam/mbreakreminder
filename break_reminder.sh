#!/usr/bin/env bash
WORK_TIME=900
IDLE_RESET_TIME=300
BREAK=15
PRE_FLASHES=6
TICK=30
MODE="MONITOR"
LAST_ACTIVE_FILE="${HOME:-/home/$USER}/.cache/break_reminder"
PID_FILE="/tmp/break_reminder.pid"
SWAYIDLE_PID_FILE="/tmp/break_reminder_swayidle.pid"
SLEEP_THRESHOLD=300

usage() {
  cat <<'EOF'
Usage: ./break_reminder.sh [options]

Options:
  -w, --work-time SECONDS
  -i, --idle-reset-time SECONDS
  -b, --break SECONDS
  -p, --pre-flashes N
  -t, --tick SECONDS
  -m, --mode TAG|MONITOR
  -h, --help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--work-time)
        [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
        WORK_TIME="$2"
        shift 2
        ;;
      -i|--idle-reset-time)
        [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
        IDLE_RESET_TIME="$2"
        shift 2
        ;;
      -b|--break)
        [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
        BREAK="$2"
        shift 2
        ;;
      -p|--pre-flashes)
        [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
        PRE_FLASHES="$2"
        shift 2
        ;;
      -t|--tick)
        [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
        TICK="$2"
        shift 2
        ;;
      -m|--mode)
        [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
        MODE="${2^^}"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$MODE" in
    TAG|MONITOR)
      ;;
    *)
      echo "Unsupported mode: $MODE" >&2
      usage >&2
      exit 1
      ;;
  esac
}

parse_args "$@"

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
      mmsg dispatch togglemaximizescreen >/dev/null; sleep 0.5
    done

    sleep 2s

    if [[ "${MODE^^}" == "MONITOR" ]]; then
      local monitors=()
      mapfile -t monitors < <(mmsg get all-monitors | jq -r '.monitors[].name' 2>/dev/null)
      if (( ${#monitors[@]} == 0 )); then
        MODE="TAG"
      else
        for m in "${monitors[@]}"; do
          mmsg dispatch sleep_monitor,"$m" >/dev/null
        done

        sleep "${BREAK}s"

        for m in "${monitors[@]}"; do
          mmsg dispatch wakeup_monitor,"$m" >/dev/null
        done
        return
      fi
    fi

    local CURRENT_TAG
    local OTHER_TAG

    CURRENT_TAG=$(mmsg get all-tags | jq -r '.all_tags[].tags[] | select(.is_active) | .index' | head -n1)
    if [[ ! "$CURRENT_TAG" =~ ^[1-9]$ ]]; then
      CURRENT_TAG=1
    fi

    local TAG_TOTAL
    TAG_TOTAL=$(mmsg get monitor "$(mmsg get cursorpos | jq -r '.monitor')" | jq '.tag_num')
    if ! [[ "$TAG_TOTAL" =~ ^[1-9][0-9]*$ ]]; then
      TAG_TOTAL=2
    fi

    while true; do
      OTHER_TAG=$((RANDOM % TAG_TOTAL + 1))
      if (( OTHER_TAG != CURRENT_TAG )); then
        break
      fi
    done

    for (( i=1; i<=BREAK; i++ )); do
      check_sleep_interruption
      if (( interrupted )); then
            mmsg dispatch, view, "$CURRENT_TAG" >/dev/null
          return
      fi
      mmsg dispatch, view, "$OTHER_TAG" >/dev/null
      sleep 0.5
      mmsg dispatch, view, "$CURRENT_TAG" >/dev/null
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
