import json
import tempfile
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from build_store import validate


class StoreBuildTests(unittest.TestCase):
    def test_missing_inputs_block_release(self):
        errors, public_key = validate({}, {})
        self.assertGreaterEqual(len(errors), 10)
        self.assertEqual(public_key, '')

    def test_demo_ids_debug_keys_and_placeholder_urls_block_release(self):
        errors, _ = validate({
            'verification_url': 'https://verifier.example/v1/play/verify',
            'privacy_url': 'http://localhost/privacy',
            'admob_app_id': 'ca-app-pub-3940256099942544~3347511713',
            'rewarded_unit_id': 'ca-app-pub-3940256099942544/5224354917',
            'version_code': 10, 'version_name': 'dev', 'purchase_option': 'buy',
        }, {'GODOT_ANDROID_KEYSTORE_RELEASE_PATH': '/tmp/debug.keystore',
            'GODOT_ANDROID_KEYSTORE_RELEASE_USER': 'androiddebugkey'})
        for field in ('verification_url', 'privacy_url', 'admob_app_id', 'rewarded_unit_id', 'version_code', 'version_name', 'debug certificate'):
            self.assertTrue(any(field in error for error in errors), field)

    def test_complete_public_configuration_is_accepted(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            public_key = directory / 'receipt-public.pem'
            public_key.write_text(json.loads((ROOT / 'build/receipt-fixture.json').read_text())['public_key'])
            upload = directory / 'upload.jks'
            upload.touch()  # The CLI separately validates the actual certificate with keytool.
            config = {
                'verification_url': 'https://mem-mem-verifier.run.app/v1/play/verify',
                'privacy_url': 'https://mem-mem.app/privacy',
                'admob_app_id': 'ca-app-pub-1111111111111111~1111111111',
                'rewarded_unit_id': 'ca-app-pub-1111111111111111/1111111111',
                'purchase_option': 'buy', 'version_code': 11, 'version_name': '0.7.0',
                'child_directed': True, 'under_age_of_consent': True,
                'receipt_public_key_file': str(public_key),
            }
            errors, pem = validate(config, {
                'GODOT_ANDROID_KEYSTORE_RELEASE_PATH': str(upload),
                'GODOT_ANDROID_KEYSTORE_RELEASE_USER': 'upload',
                'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD': 'test-only',
            })
            self.assertEqual(errors, [])
            self.assertTrue(pem.startswith('-----BEGIN PUBLIC KEY-----'))

    def test_non_string_urls_do_not_crash(self):
        errors, _ = validate({'verification_url': 1, 'privacy_url': []}, {})
        self.assertTrue(any('verification_url' in error for error in errors))
        self.assertTrue(any('privacy_url' in error for error in errors))

    def test_verifier_route_cannot_silently_disable_access_codes(self):
        errors, _ = validate({'verification_url': 'https://mem-mem-verifier.run.app/wrong-route'}, {})
        self.assertTrue(any('/v1/play/verify endpoint' in error for error in errors))


if __name__ == '__main__':
    unittest.main()
