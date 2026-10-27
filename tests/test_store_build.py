import tempfile
from pathlib import Path
import sys
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from build_store import validate

class StoreBuildTests(unittest.TestCase):
    def test_missing_signing_and_version_block_release(self):
        errors = validate({}, {})
        self.assertTrue(any('version_code' in e for e in errors))
        self.assertTrue(any('KEYSTORE' in e for e in errors))

    def test_no_ads_or_billing_configuration_is_required(self):
        with tempfile.TemporaryDirectory() as temp:
            upload = Path(temp) / 'upload.jks'
            upload.touch()  # CLI independently checks the certificate with keytool.
            errors = validate({'version_code': 11, 'version_name': '0.7.0'}, {
                'GODOT_ANDROID_KEYSTORE_RELEASE_PATH': str(upload),
                'GODOT_ANDROID_KEYSTORE_RELEASE_USER': 'upload',
                'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD': 'test-only',
            })
            self.assertEqual(errors, [])

    def test_debug_signing_is_still_rejected(self):
        errors = validate({'version_code': 10, 'version_name': 'dev'}, {
            'GODOT_ANDROID_KEYSTORE_RELEASE_PATH': '/tmp/debug.keystore',
            'GODOT_ANDROID_KEYSTORE_RELEASE_USER': 'androiddebugkey',
        })
        for field in ('version_code', 'version_name', 'debug certificate'):
            self.assertTrue(any(field in e for e in errors))

    def test_android_export_has_no_network_permissions_or_plugins(self):
        preset = (ROOT / 'game/export_presets.cfg').read_text()
        self.assertIn('permissions/internet=false', preset)
        self.assertIn('permissions/access_network_state=false', preset)
        self.assertNotIn('GodotGooglePlayBilling', (ROOT / 'game/project.godot').read_text())
        self.assertFalse((ROOT / 'server').exists())

if __name__ == '__main__':
    unittest.main()
