#!/usr/bin/env bash
set -e

BASE_DIR="/opt/calajaminer"
source "$BASE_DIR/config/wallet.conf"
source "$BASE_DIR/config/pool.conf"
source "$BASE_DIR/config/miner.conf"

if [ -z "$WALLET" ] || [ "$WALLET" = "COLOQUE_SUA_WALLET_ZEPHYR_AQUI" ]; then
  echo "Wallet não configurada em $BASE_DIR/config/wallet.conf"
  exit 1
fi

if [ -z "$POOL_HOST" ] || [ "$POOL_HOST" = "SEU_POOL_AQUI" ]; then
  echo "Pool não configurado em $BASE_DIR/config/pool.conf"
  exit 1
fi

if [ -z "$POOL_PORT" ] || [ "$POOL_PORT" = "SEU_PORT_AQUI" ]; then
  echo "Porta da pool não configurada em $BASE_DIR/config/pool.conf"
  exit 1
fi

USER_LOGIN="${POOL_USER:-$WALLET}"
LOGFILE="$BASE_DIR/logs/miner_$(date +%Y%m%d_%H%M%S).log"

cd "$BASE_DIR/miners/xmrig"

THREAD_ARGS=""
if [ -n "$THREADS" ] && [ "$THREADS" != "0" ]; then
  THREAD_ARGS="-t $THREADS"
fi

exec ./xmrig \
  -a "$ALGO" \
  -o "$POOL_HOST:$POOL_PORT" \
  -u "$USER_LOGIN" \
  -p "$POOL_PASS" \
  $THREAD_ARGS \
  --donate-level="$DONATE_LEVEL" \
  --cpu-priority="$CPU_PRIORITY" \
  | tee -a "$LOGFILE"
