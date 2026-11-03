"""Run once on Ubuntu as root. Creates private local material; never prints secrets."""
import argparse
import getpass
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--directory", default="/opt/yorungez/private")
args = parser.parse_args()
if os.name != "posix" or os.geteuid() != 0:
    raise SystemExit("Run on the Ubuntu host as root; no remote deployment is performed.")
directory = Path(args.directory).resolve()
if directory.exists():
    raise SystemExit("Target already exists; refusing to overwrite secrets or key rings.")
password = getpass.getpass("Keyring PFX password (at least 32 characters; save in your private secret manager): ")
if len(password) < 32 or password != getpass.getpass("Confirm PFX password: "):
    raise SystemExit("Passwords must match and contain at least 32 characters.")
os.umask(0o077)
directory.mkdir(parents=True, mode=0o700)
keys = directory / "keys"
keys.mkdir(mode=0o700)
os.chown(keys, 1654, 1654)
# The API user must traverse this directory to reach both read-only cert and writable key ring.
os.chown(directory, 0, 1654)
directory.chmod(0o710)
env = dict(os.environ, YORUNGEZ_CERT_PASSWORD=password)
try:
    subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:3072", "-nodes", "-days", "3650",
                    "-subj", "/CN=yorungez-data-protection", "-keyout", str(directory / "key.pem"),
                    "-out", str(directory / "cert.pem")], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["openssl", "pkcs12", "-export", "-inkey", str(directory / "key.pem"),
                    "-in", str(directory / "cert.pem"), "-out", str(directory / "keyring.pfx"),
                    "-passout", "env:YORUNGEZ_CERT_PASSWORD"], env=env, check=True)
finally:
    for name in ["key.pem", "cert.pem"]:
        (directory / name).unlink(missing_ok=True)
certificate = directory / "keyring.pfx"
os.chown(certificate, 1654, 1654)
certificate.chmod(0o400)
template = (Path(__file__).parent / ".env.example").read_text()
for key, value in {
    "KEYRING_PATH": str(keys), "KEYRING_CERT_PATH": str(certificate),
}.items():
    template = "\n".join(f"{key}={value}" if line.startswith(key + "=") else line for line in template.splitlines()) + "\n"
destination = directory / ".env"
destination.write_text(template)
destination.chmod(0o600)
print(f"Encrypted PFX and template created in {directory}. Fill ALL secrets (including the same PFX password), image tags, Traefik and SMTP locally. No passwords saved to the template or printed.")
