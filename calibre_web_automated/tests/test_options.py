"""Run the production Python options adapter with only filesystem paths redirected."""
import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

RUN = Path(__file__).parents[1] / 'rootfs/etc/s6-overlay/s6-rc.d/ha-cwa-options/run'
SOURCE = RUN.read_text().split("python3 - <<'PY'\n", 1)[1].split('\nPY\n', 1)[0]


class OptionsTests(unittest.TestCase):
    def run_options(self, payload=None, environment=None, raw=None, env_dirs=True):
        with tempfile.TemporaryDirectory() as root:
            root = Path(root)
            options = root / 'data/options.json'
            options.parent.mkdir()
            if raw is not None:
                options.write_text(raw)
            elif payload is not None:
                options.write_text(json.dumps(payload))
            directories = ['/run/s6/container_environment', '/var/run/s6/container_environment']
            if env_dirs:
                for directory in directories:
                    (root / directory.lstrip('/')).mkdir(parents=True)
            real_path = Path
            def mapped_path(value):
                return real_path(root / str(value).lstrip('/'))
            output = io.StringIO()
            with patch('pathlib.Path', mapped_path), patch.dict(os.environ, environment or {}, clear=True), contextlib.redirect_stdout(output):
                exec(compile(SOURCE, str(RUN), 'exec'), {})
            values = []
            for directory in directories:
                target = root / directory.lstrip('/')
                values.append({p.name: p.read_text() for p in target.iterdir()} if target.exists() else {})
            return values, output.getvalue()

    def test_missing_options_defaults_and_both_s6_directories(self):
        values, _ = self.run_options()
        self.assertEqual(values[0], values[1])
        self.assertEqual(values[0], {'TZ': 'Europe/Zurich', 'NETWORK_SHARE_MODE': 'false', 'TRUSTED_PROXY_COUNT': '1', 'DISABLE_LIBRARY_AUTOMOUNT': 'false'})

    def test_all_options_and_secret_not_logged(self):
        values, output = self.run_options({'timezone': 'UTC', 'network_share_mode': True, 'force_polling': True, 'trusted_proxy_count': 3, 'hardcover_token': ' secret-token ', 'disable_library_automount': True})
        self.assertEqual(values[0], {'TZ': 'UTC', 'NETWORK_SHARE_MODE': 'true', 'CWA_WATCH_MODE': 'poll', 'TRUSTED_PROXY_COUNT': '3', 'HARDCOVER_TOKEN': 'secret-token', 'DISABLE_LIBRARY_AUTOMOUNT': 'true'})
        self.assertNotIn('secret-token', output)

    def test_zero_trusted_proxies_is_preserved(self):
        values, _ = self.run_options({'trusted_proxy_count': 0}, {'TRUSTED_PROXY_COUNT': '4'})
        self.assertEqual(values[0]['TRUSTED_PROXY_COUNT'], '0')

    def test_existing_image_environment_fallback(self):
        values, _ = self.run_options({}, {'TZ': 'UTC', 'TRUSTED_PROXY_COUNT': '2', 'CWA_WATCH_MODE': 'native'})
        self.assertEqual(values[0]['TZ'], 'UTC')
        self.assertEqual(values[0]['TRUSTED_PROXY_COUNT'], '2')
        self.assertEqual(values[0]['CWA_WATCH_MODE'], 'native')

    def test_polling_overrides_image_environment(self):
        values, _ = self.run_options({'force_polling': True}, {'CWA_WATCH_MODE': 'native'})
        self.assertEqual(values[0]['CWA_WATCH_MODE'], 'poll')

    def test_empty_token_and_disabled_polling_are_not_exported(self):
        values, _ = self.run_options({'hardcover_token': '  ', 'force_polling': False})
        self.assertNotIn('HARDCOVER_TOKEN', values[0])
        self.assertNotIn('CWA_WATCH_MODE', values[0])

    def test_malformed_or_nonobject_json_falls_back_without_crashing(self):
        for raw in ['{', '[]', 'null', '"text"', '1']:
            with self.subTest(raw=raw):
                values, output = self.run_options(raw=raw)
                self.assertIn('Could not read', output)
                self.assertEqual(values[0]['TZ'], 'Europe/Zurich')

    def test_absent_s6_environment_directory_does_not_crash(self):
        values, _ = self.run_options(env_dirs=False)
        self.assertEqual(values, [{}, {}])

    def test_service_dependency_orders_adapter_before_upstream_startup(self):
        services = RUN.parents[1]
        self.assertEqual((services / 'ha-cwa-options/type').read_text().strip(), 'oneshot')
        self.assertTrue((services / 'cwa-init/dependencies.d/ha-cwa-options').exists())
        self.assertTrue((services / 'ha-cwa-options/dependencies.d/init-config').exists())
        self.assertTrue((services / 'user/contents.d/ha-cwa-options').exists())
        self.assertIn('/etc/s6-overlay/s6-rc.d/ha-cwa-options/run', (services / 'ha-cwa-options/up').read_text())


if __name__ == '__main__':
    unittest.main()
