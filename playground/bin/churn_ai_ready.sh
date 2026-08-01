#!/usr/bin/env bash
# AI-style churn: parallel writes, streaming incomplete files, hotkeys via
# .revali_cmd, renames, mass rewrites — while revali dev stays alive.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROUTES="$ROOT/routes"
CMD="$ROOT/.revali_cmd"
BASE="${BASE_URL:-http://127.0.0.1:8090}"
FAILS=0

wait_code() {
  local path="$1" want="$2" seconds="${3:-90}"
  local i code
  for i in $(seq 1 "$seconds"); do
    code=$(curl -sS -o /tmp/ai_churn_body.txt -w '%{http_code}' --max-time 2 \
      "$BASE$path" 2>/dev/null || echo fail)
    if [ "$code" = "$want" ]; then
      echo "  WAIT $path -> $code (${i}s)"
      return 0
    fi
    sleep 1
  done
  echo "  WAIT $path TIMEOUT want=$want last=$code"
  FAILS=$((FAILS + 1))
  return 1
}

wait_ready() { wait_code /api/stress/ping 200 "${1:-90}" || true; }

dev_cmd() {
  # Headless hotkey channel (works without a TTY)
  printf '%s\n' "$1" >"$CMD"
}

write_controller() {
  local class_name="$1" path_seg="$2" file_stem="$3" ping_body="${4:-$path_seg-pong}"
  local extra_methods="${5:-}"
  cat >"$ROUTES/${file_stem}_controller.dart" <<EOF
import 'package:revali_router/revali_router.dart';

@Controller('$path_seg')
class ${class_name}Controller {
  ${class_name}Controller();

  @Get('ping')
  String ping() => '$ping_body';
$extra_methods
}
EOF
}

cleanup_ai() {
  rm -f "$ROUTES"/ai*_controller.dart \
    "$ROUTES"/stream*_controller.dart \
    "$ROUTES"/bulk*_controller.dart \
    "$ROUTES"/renamed*_controller.dart \
    "$ROUTES"/partial*_controller.dart \
    "$ROUTES"/large*_controller.dart \
    "$CMD" 2>/dev/null || true
}

echo "== AI: spam clear/reload commands while idle =="
wait_ready 30
for i in $(seq 1 8); do
  dev_cmd c
  sleep 0.05
  dev_cmd r
  sleep 0.08
done
wait_ready 60

echo "== AI: parallel burst create (25 controllers) =="
cleanup_ai
for i in $(seq 1 25); do
  (
    write_controller "Ai$i" "ai$i" "ai$i" "ai-$i"
  ) &
done
wait
dev_cmd r
wait_ready 120
wait_code /api/ai1/ping 200 90 || true
wait_code /api/ai25/ping 200 90 || true
wait_code /api/ai13/ping 200 90 || true

echo "== AI: streaming incomplete file then complete =="
# Mimic token streaming / partial apply
{
  printf '%s\n' "import 'package:revali_router/revali_router.dart';"
  sleep 0.15
  printf '%s\n' ""
  printf '%s\n' "@Controller('stream1')"
  sleep 0.1
  printf '%s\n' "class Stream1Controller {"
  sleep 0.05
  printf '%s\n' "  Stream1Controller();"
  sleep 0.05
  # incomplete method — syntax error window
  printf '%s\n' "  @Get('ping')"
  printf '%s\n' "  String ping( => 'broken';"
  sleep 0.4
} >"$ROUTES/stream1_controller.dart"
dev_cmd r
sleep 1
# Finish like an agent correcting itself
write_controller "Stream1" "stream1" "stream1" "stream-ok"
dev_cmd r
wait_ready 90
wait_code /api/stream1/ping 200 90 || true

echo "== AI: rapid multi-method rewrite (agent iterating) =="
methods=""
for n in $(seq 1 12); do
  methods="${methods}
  @Get('m$n')
  String m$n() => 'm$n-v1';
"
done
write_controller "Large" "large" "large" "large-v1" "$methods"
for v in $(seq 2 15); do
  methods=""
  for n in $(seq 1 12); do
    methods="${methods}
  @Get('m$n')
  String m$n() => 'm$n-v$v';
"
  done
  write_controller "Large" "large" "large" "large-v$v" "$methods"
  # Agent mashes reload while iterating
  if (( v % 3 == 0 )); then dev_cmd r; fi
  sleep 0.04
done
wait_ready 90
wait_code /api/large/ping 200 90 || true
wait_code /api/large/m12 200 90 || true

echo "== AI: rename storm (write new + delete old) =="
write_controller "RenamedA" "renamed-a" "renamed_a" "a1"
wait_code /api/renamed-a/ping 200 60 || true
write_controller "RenamedB" "renamed-b" "renamed_b" "b1"
rm -f "$ROUTES/renamed_a_controller.dart"
dev_cmd r
wait_ready 90
wait_code /api/renamed-b/ping 200 90 || true
wait_code /api/renamed-a/ping 404 60 || true

echo "== AI: mass delete while hammering reload =="
for i in $(seq 1 5); do dev_cmd r; sleep 0.05; done
rm -f "$ROUTES"/ai*_controller.dart
for i in $(seq 1 5); do dev_cmd r; sleep 0.05; done
wait_ready 90
wait_code /api/ai1/ping 404 60 || true

echo "== AI: recreate after delete (agent undoes) =="
for i in 1 2 3; do
  write_controller "Ai$i" "ai$i" "ai$i" "back-$i" &
done
wait
dev_cmd r
wait_ready 90
wait_code /api/ai2/ping 200 90 || true

echo "== AI: touch app + controllers together =="
# Touch app config safely (never truncate-in-place) + new controller
APP="$ROUTES/playground_app.dart"
cp "$APP" /tmp/playground_app.bak
# rewrite via temp file like an editor atomic save
cp /tmp/playground_app.bak /tmp/playground_app.next
mv /tmp/playground_app.next "$APP"
write_controller "BulkZ" "bulkz" "bulkz" "bulkz-ok"
dev_cmd c
dev_cmd r
wait_ready 90
wait_code /api/bulkz/ping 200 90 || true

echo "== cleanup =="
cleanup_ai
dev_cmd r
wait_ready 90
wait_code /api/stress/ping 200 30 || true

echo "DONE fails=$FAILS"
exit "$FAILS"
