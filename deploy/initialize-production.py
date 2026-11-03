"""Run once on Ubuntu as root. Creates private local material; never prints secrets."""
import argparse
import os
from pathlib import Path
import secrets
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--directory", default="/opt/yorungez/private")
args = parser.parse_args()
if os.name != "posix" or os.geteuid() != 0:
    raise SystemExit("Run on the Ubuntu host as root; no remote deployment is performed.")
directory = Path(args.directory).resolve()
if directory.exists():
    raise SystemExit("Target already exists; refusing to overwrite secrets or key rings.")
os.umask(0o077)
directory.mkdir(parents=True, mode=0o700)
keys = directory / "keys"
keys.mkdir(mode=0o700)
os.chown(keys, 1654, 1654)
# The API user must traverse this directory to reach both read-only cert and writable key ring.
os.chown(directory, 0, 1654)
directory.chmod(0o710)
password = secrets.token_hex(32)
env = dict(os.environ, YORUNGEZ_CERT_PASSWORD=password)
try:
    subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:3072", "-nodes", "-days", "3650",
                    "-subj", "/CN=yorungez-data-protection", "-keyout", str(directory / "key.pem"),
                    "-out", str(directory / "cert.pem")], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["openssl", "pkcs12", "-export", "-inkey", str(directory / "key.pem"),
                    "-in", str(directory / "cert.pem"), "-out", str(directory / "keyring.pfx"),
                    "-passout", "env:YORUNGEZ_CERT_PASSWORD"], check=True)
finally:
    for name in ["key.pem", "cert.pem"]:
        (directory / name).unlink(missing_ok=True)
certificate = directory / "keyring.pfx"
os.chown(certificate, 1654, 1654)
certificate.chmod(0o400)
template = (Path(__file__).parent / ".env.example").read_text()
for key, value in {
    "POSTGRES_PASSWORD": secrets.token_hex(32), "REDIS_PASSWORD": secrets.token_hex(32),
    "JWT_SIGNING_KEY": secrets.token_hex(64), "KEYRING_CERT_PASSWORD": password,
    "KEYRING_PATH": str(keys), "KEYRING_CERT_PATH": str(certificate),
}.items():
    template = "\n".join(f"{key}={value}" if line.startswith(key + "=") else line for line in template.splitlines()) + "\n"
destination = directory / ".env"
destination.write_text(template)
destination.chmod(0o600)
print(f"Private material created in {directory}. Fill image tags, Traefik settings and SMTP in .env locally. No secrets printed.")
