#!/usr/bin/env bash
# Rapidly churn playground routes while revali dev is running.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROUTES="$ROOT/routes"
BASE="${BASE_URL:-http://127.0.0.1:8090}"

ping_ok() {
  local path="$1"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$BASE$path" 2>/dev/null || echo fail)
  echo "  GET $path -> $code"
}

wait_code() {
  local path="$1"
  local want="$2"
  local seconds="${3:-60}"
  local i code
  for i in $(seq 1 "$seconds"); do
    code=$(curl -sS -o /tmp/churn_body.txt -w '%{http_code}' --max-time 2 \
      "$BASE$path" 2>/dev/null || echo fail)
    if [ "$code" = "$want" ]; then
      echo "  WAIT $path -> $code (${i}s) $(tr -d '\n' </tmp/churn_body.txt | head -c 80)"
      return 0
    fi
    sleep 1
  done
  echo "  WAIT $path TIMEOUT want=$want last=$code"
  return 1
}

wait_ready() {
  wait_code /api/stress/ping 200 "${1:-60}" || true
}

write_controller() {
  local class_name="$1"
  local path_seg="$2"
  local file_stem="$3"
  local ping_body="${4:-$path_seg-pong}"
  cat >"$ROUTES/${file_stem}_controller.dart" <<EOF
import 'package:revali_router/revali_router.dart';

@Controller('$path_seg')
class ${class_name}Controller {
  ${class_name}Controller();

  @Get('ping')
  String ping() => '$ping_body';
}
EOF
}

echo "== churn: add controllers =="
for i in 1 2 3 4 5; do
  write_controller "Alpha$i" "alpha$i" "alpha$i"
  sleep 0.15
done
wait_ready 90
wait_code /api/alpha1/ping 200 60 || true
wait_code /api/alpha5/ping 200 60 || true

echo "== churn: rapid rewrite same controller =="
for i in $(seq 1 20); do
  write_controller "Beta" "beta" "beta" "beta-$i"
  sleep 0.05
done
wait_ready 90
wait_code /api/beta/ping 200 60 || true

echo "== churn: remove controllers =="
rm -f "$ROUTES"/alpha*_controller.dart
wait_ready 90
wait_code /api/alpha1/ping 404 60 || true

echo "== churn: add+remove race =="
for i in $(seq 1 15); do
  write_controller "Gamma" "gamma" "gamma"
  sleep 0.05
  rm -f "$ROUTES/gamma_controller.dart"
  sleep 0.05
done
write_controller "Gamma" "gamma" "gamma"
wait_ready 90
wait_code /api/gamma/ping 200 90 || true

echo "== churn: second app file =="
cat >"$ROUTES/other_app.dart" <<'EOF'
import 'package:revali_router/revali_router.dart';

@App(flavor: 'other')
final class OtherApp extends AppConfig {
  OtherApp()
    : super(
        host: 'localhost',
        port: 8091,
        workers: 1,
      );
}
EOF
wait_ready 90

echo "== churn: remove second app =="
rm -f "$ROUTES/other_app.dart"
wait_ready 90

echo "== churn: broken controller then fix =="
cat >"$ROUTES/broken_controller.dart" <<'EOF'
import 'package:revali_router/revali_router.dart';

@Controller('broken')
class BrokenController {
  BrokenController();

  @Get('ping')
  String ping( => 'oops'; // syntax error
}
EOF
sleep 2
wait_ready 90
cat >"$ROUTES/broken_controller.dart" <<'EOF'
import 'package:revali_router/revali_router.dart';

@Controller('broken')
class BrokenController {
  BrokenController();

  @Get('ping')
  String ping() => 'broken-fixed';
}
EOF
wait_ready 90
wait_code /api/broken/ping 200 90 || true

echo "== cleanup temp controllers =="
rm -f "$ROUTES"/alpha*_controller.dart \
  "$ROUTES/beta_controller.dart" \
  "$ROUTES/gamma_controller.dart" \
  "$ROUTES/broken_controller.dart" \
  "$ROUTES/other_app.dart"
wait_ready 90
wait_code /api/stress/ping 200 30 || true

echo "DONE"
