"""Validate the actual exported IPA before upload; no credentials are read."""
import argparse
import hashlib
import plistlib
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    for field in ['ipa', 'bundle-id', 'team-id', 'certificate-sha1', 'version', 'build-number']:
        parser.add_argument('--' + field, required=True)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='yorungez-ipa-') as temporary:
        root = Path(temporary)
        subprocess.run(['ditto', '-x', '-k', args.ipa, str(root)], check=True)
        apps = list((root / 'Payload').glob('*.app'))
        if len(apps) != 1:
            raise ValueError('Expected exactly one application in the IPA')
        app = apps[0]
        info = plistlib.loads((app / 'Info.plist').read_bytes())
        for key, expected in [('CFBundleIdentifier', args.bundle_id),
                              ('CFBundleShortVersionString', args.version),
                              ('CFBundleVersion', args.build_number)]:
            if info.get(key) != expected:
                raise ValueError('Exported application mismatch: ' + key)
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
        prefix = str(root / 'signer-')
        subprocess.run(['codesign', '-d', '--extract-certificates=' + prefix, str(app)],
                       check=True, capture_output=True)
        fingerprint = hashlib.sha1(Path(prefix + '0').read_bytes()).hexdigest().upper()
        if fingerprint != args.certificate_sha1:
            raise ValueError('IPA was not signed by the selected renewed certificate')
        result = subprocess.run(['security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')],
                                check=True, capture_output=True)
        profile = plistlib.loads(result.stdout)
        entitlements = profile['Entitlements']
        if (entitlements.get('application-identifier') != args.team_id + '.' + args.bundle_id
                or profile.get('TeamIdentifier') != [args.team_id]
                or entitlements.get('get-task-allow', False)
                or profile.get('ProvisionedDevices') or profile.get('ProvisionsAllDevices')):
            raise ValueError('IPA does not contain the expected App Store distribution profile')
        certificates = {hashlib.sha1(value).hexdigest().upper()
                        for value in profile['DeveloperCertificates']}
        if args.certificate_sha1 not in certificates:
            raise ValueError('Profile does not contain the selected certificate')
        print('IPA signature, selected certificate, App Store profile, bundle and version verified.')


if __name__ == '__main__':
    main()
