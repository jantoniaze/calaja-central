#!/usr/bin/env bash

BASE_DIR="/opt/calajaminer"
SYSTEM_CONF="$BASE_DIR/config/system.conf"
MINER_CONF="$BASE_DIR/config/miner.conf"
POOL_CONF="$BASE_DIR/config/pool.conf"
LOG_DIR="$BASE_DIR/logs"

if [ -f "$SYSTEM_CONF" ]; then
  source "$SYSTEM_CONF"
else
  echo "Falta $SYSTEM_CONF"
  exit 1
fi

if [ -f "$MINER_CONF" ]; then
  source "$MINER_CONF"
fi

if [ -f "$POOL_CONF" ]; then
  source "$POOL_CONF"
fi

RIG_ID="${RIG_ID:-unknown-rig}"
WORKER="${WORKER:-unknown-worker}"
LOCATION="${LOCATION:-unknown-location}"
WSNODE_URL="${WSNODE_URL:-}"
THREADS_CFG="${THREADS:-n/a}"
POOL_ADDR="${POOL_HOST:-n/a}:${POOL_PORT:-n/a}"

if [ -z "$WSNODE_URL" ]; then
  echo "WSNODE_URL não definido em $SYSTEM_CONF"
  exit 1
fi

get_latest_log() {
  ls -1t "$LOG_DIR"/miner_*.log 2>/dev/null | head -1
}

clean_log_stream() {
  local logfile="$1"
  [ -z "$logfile" ] && return
  sed -r 's/\x1B\[[0-9;]*[[:alpha:]]//g; s/\r//g' "$logfile" 2>/dev/null
}

get_hashrate() {
  local logfile line
  logfile="$(get_latest_log)"

  if [ -z "$logfile" ]; then
    echo "n/a"
    return
  fi

  line="$(clean_log_stream "$logfile" | grep 'speed 10s/60s/15m' | tail -1)"

  if [ -z "$line" ]; then
    echo "n/a"
    return
  fi

  echo "$line" | awk '{for(i=1;i<=NF;i++){if($i=="10s/60s/15m"){print $(i+1); exit}}}'
}

get_accept_reject() {
  local logfile line
  logfile="$(get_latest_log)"

  if [ -z "$logfile" ]; then
    ACCEPTED="0"
    REJECTED="0"
    return
  fi

  line="$(clean_log_stream "$logfile" | grep 'accepted (' | tail -1)"

  ACCEPTED="$(echo "$line" | sed -n 's/.*accepted (\([0-9]\+\)\/\([0-9]\+\)).*/\1/p')"
  REJECTED="$(echo "$line" | sed -n 's/.*accepted (\([0-9]\+\)\/\([0-9]\+\)).*/\2/p')"

  [ -z "$ACCEPTED" ] && ACCEPTED="0"
  [ -z "$REJECTED" ] && REJECTED="0"
}

get_cpu() {
  top -bn1 | awk '/Cpu\(s\)/ {print $2 + $4}'
}

get_ram() {
  free | awk '/Mem:/ {printf("%.2f"), $3/$2 * 100}'
}

get_disk() {
  df -h / | awk 'NR==2 {print $5}'
}

get_temp() {
  sensors 2>/dev/null | awk '/Tctl:|Package id 0:|temp1:/ {print $2; exit}'
}

get_uptime() {
  uptime -p 2>/dev/null
}

get_load() {
  uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//'
}

get_ip() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

get_ping() {
  ping -c 1 8.8.8.8 2>/dev/null | awk -F'time=' '/time=/{print $2}' | cut -d' ' -f1
}

while true; do
  HASHRATE="$(get_hashrate)"
  [ -z "$HASHRATE" ] && HASHRATE="n/a"

  get_accept_reject

  CPU="$(get_cpu)"
  [ -z "$CPU" ] && CPU="n/a"

  RAM="$(get_ram)"
  [ -z "$RAM" ] && RAM="n/a"

  DISK="$(get_disk)"
  [ -z "$DISK" ] && DISK="n/a"

  TEMP="$(get_temp)"
  [ -z "$TEMP" ] && TEMP="n/a"

  UPTIME="$(get_uptime)"
  [ -z "$UPTIME" ] && UPTIME="n/a"

  LOAD="$(get_load)"
  [ -z "$LOAD" ] && LOAD="n/a"

  IP="$(get_ip)"
  [ -z "$IP" ] && IP="n/a"

  PING="$(get_ping)"
  [ -z "$PING" ] && PING="n/a"

  curl -s -X POST "$WSNODE_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"rig_id\": \"$RIG_ID\",
      \"worker\": \"$WORKER\",
      \"location\": \"$LOCATION\",
      \"hashrate\": \"$HASHRATE\",
      \"cpu\": \"$CPU\",
      \"ram\": \"$RAM\",
      \"disk\": \"$DISK\",
      \"temp\": \"$TEMP\",
      \"uptime\": \"$UPTIME\",
      \"load\": \"$LOAD\",
      \"ip\": \"$IP\",
      \"ping\": \"$PING\",
      \"threads\": \"$THREADS_CFG\",
      \"accepted\": \"$ACCEPTED\",
      \"rejected\": \"$REJECTED\",
      \"pool\": \"$POOL_ADDR\",
      \"control_url\": \"http://$IP:5010\"
    }" >/dev/null

  sleep 30
done
