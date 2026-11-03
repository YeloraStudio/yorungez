#!/usr/bin/env bash
# Disposable Linux CI host only; all resources belong to this unique fixture.
set -euo pipefail
cd "$(dirname "$0")/.."
fixture="yorungez-smoke-${GITHUB_RUN_ID:-$$}"
private_dir="$(mktemp -d)"
export API_IMAGE="yorungez-api:$fixture" WEB_IMAGE="yorungez-web:$fixture"
export TRAEFIK_NETWORK="$fixture-edge" TRAEFIK_IP=192.0.2.1
export TRAEFIK_CERTRESOLVER=unused-smoke
export POSTGRES_PASSWORD="$(openssl rand -hex 32)" REDIS_PASSWORD="$(openssl rand -hex 32)"
export JWT_SIGNING_KEY="$(openssl rand -hex 64)" KEYRING_CERT_PASSWORD="$(openssl rand -hex 32)"
export KEYRING_PATH="$private_dir/keys" KEYRING_CERT_PATH="$private_dir/keyring.pfx"
export SMTP_SENDER=smoke@example.invalid SMTP_USERNAME=smoke SMTP_PASSWORD=smoke-only-not-used
compose=(docker compose -p "$fixture" -f deploy/compose.production.yaml -f deploy/compose.smoke.yaml)
cleanup() {
  "${compose[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
  docker network rm "$TRAEFIK_NETWORK" >/dev/null 2>&1 || true
  # mktemp-created directory only; preserve no user/server material.
  sudo rm -rf -- "$private_dir"
}
trap cleanup EXIT
mkdir "$KEYRING_PATH"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=smoke-keyring \
  -keyout "$private_dir/key.pem" -out "$private_dir/cert.pem" >/dev/null 2>&1
openssl pkcs12 -export -inkey "$private_dir/key.pem" -in "$private_dir/cert.pem" \
  -out "$KEYRING_CERT_PATH" -passout env:KEYRING_CERT_PASSWORD
sudo chown -R 1654:1654 "$private_dir"
sudo chmod 755 "$private_dir"
sudo chmod 700 "$KEYRING_PATH"
sudo chmod 400 "$KEYRING_CERT_PATH"
docker network create "$TRAEFIK_NETWORK" >/dev/null
docker build -f deploy/Dockerfile.api -t "$API_IMAGE" .
docker build -f deploy/Dockerfile.web -t "$WEB_IMAGE" .
"${compose[@]}" config --quiet
"${compose[@]}" up -d --wait --wait-timeout 180
curl --fail --silent http://127.0.0.1:18080/health/ready >/dev/null
curl --fail --silent http://127.0.0.1:13000/en >/dev/null
curl --fail --silent http://127.0.0.1:13000/tr/terms >/dev/null
curl --fail --silent http://127.0.0.1:13000/pwa-pack.json >/dev/null
# The trusted Web hop must not cause an API HTTPS redirect. Missing credentials yield 401, not 503.
status="$(curl --silent -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:13000/api/account/login \
  -H 'Origin: https://yorungez.com' -H 'X-Yorungez-Request: 1' -H 'Content-Type: application/json' \
  --data '{"email":"absent@example.invalid","password":"a-long-synthetic-password"}')"
test "$status" = 401
# An arbitrary client cannot make direct HTTP look trusted using a spoofed header.
status="$(curl --silent -o /dev/null -w '%{http_code}' http://127.0.0.1:18080/api/v1/status \
  -H 'Host: api.yorungez.com' -H 'X-Forwarded-Proto: https')"
test "$status" = 307
echo 'Production containers: migrations, readiness, EN/TR/PWA, BFF HTTPS and untrusted-proxy rejection passed.'
