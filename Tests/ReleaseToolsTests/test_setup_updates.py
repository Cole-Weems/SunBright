import base64
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/setup-updates.sh"


class SetupUpdatesTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "scripts").mkdir()
        shutil.copyfile(SCRIPT, self.root / "scripts/setup-updates.sh")
        self.log = self.root / "calls.jsonl"
        self.export_log = self.root / "exported-path"
        self.public_key = base64.b64encode(bytes(range(32))).decode()
        self.make_executable("uname", "#!/bin/sh\necho Darwin\n")
        self.make_executable("swift", "#!/bin/sh\nexit 0\n")
        self.make_executable(".build/artifacts/sparkle/Sparkle/bin/generate_keys", '''#!/usr/bin/env python3
import os, pathlib, sys
if '-p' in sys.argv:
    print(os.environ['MOCK_LOCAL_KEY'])
if '-x' in sys.argv:
    path = pathlib.Path(sys.argv[sys.argv.index('-x') + 1])
    path.write_text('TEST_PRIVATE_KEY')
    pathlib.Path(os.environ['MOCK_EXPORT_LOG']).write_text(str(path))
''')
        self.make_executable("gh", '''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['MOCK_GH_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
if args[:2] == ['repo', 'view']:
    print(os.environ.get('MOCK_VISIBILITY', 'PUBLIC'))
elif args[:2] == ['variable', 'list']:
    print(os.environ['MOCK_REMOTE_KEY'])
elif args[:2] == ['secret', 'list']:
    print(os.environ['MOCK_HAS_SECRET'])
elif args[:2] == ['secret', 'set']:
    assert sys.stdin.read() == 'TEST_PRIVATE_KEY'
    if os.environ.get('MOCK_FAIL_SECRET'):
        sys.exit(1)
elif args[0] == 'api' and '/git/ref/heads/main' in args[1]:
    print('a' * 40)
elif args[0] == 'api' and '/contents/' in args[1]:
    print(os.environ['MOCK_PLIST'])
elif args[0] == 'api' and '/git/ref/tags/' in args[1]:
    value = os.environ.get('MOCK_TAG_SHA', '')
    if not value:
        sys.exit(1)
    print(value)
''')

    def make_executable(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        path.chmod(0o755)

    def run_setup(self, publish=False, **overrides):
        self.log.write_text("")
        env = {
            **os.environ, "PATH": f'{self.root}:{os.environ["PATH"]}',
            "MOCK_GH_LOG": str(self.log), "MOCK_EXPORT_LOG": str(self.export_log),
            "MOCK_REMOTE_KEY": "", "MOCK_HAS_SECRET": "false", "MOCK_LOCAL_KEY": self.public_key,
            "MOCK_PLIST": base64.b64encode(plistlib.dumps({"CFBundleShortVersionString": "0.2.1", "SURequireSignedFeed": True})).decode(),
            **overrides,
        }
        result = subprocess.run(["bash", str(self.root / "scripts/setup-updates.sh"), *(["--publish"] if publish else [])], env=env, text=True, capture_output=True)
        self.assertNotIn("TEST_PRIVATE_KEY", result.stdout + result.stderr + self.log.read_text())
        if self.export_log.exists():
            self.assertFalse(Path(self.export_log.read_text()).parent.exists(), "Exported signing key was not cleaned up")
        return result, [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_new_keys_are_transferred_without_exposing_the_private_key(self):
        result, calls = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(call[:2] == ["secret", "set"] for call in calls))
        self.assertTrue(any(call[:3] == ["variable", "set", "SUNBRIGHT_SPARKLE_PUBLIC_KEY"] for call in calls))

    def test_existing_signing_secret_is_preserved(self):
        result, calls = self.run_setup(MOCK_HAS_SECRET="true", MOCK_REMOTE_KEY=self.public_key)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(call[:2] == ["secret", "set"] for call in calls))
        self.assertFalse(self.export_log.exists())

    def test_mismatched_or_incomplete_keys_are_not_overwritten(self):
        for state in [{"MOCK_REMOTE_KEY": "different-public-key"}, {"MOCK_HAS_SECRET": "true"}]:
            with self.subTest(state=state):
                result, calls = self.run_setup(**state)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(any(call[:2] == ["secret", "set"] for call in calls))

    def test_failed_secret_upload_cleans_the_export_and_does_not_publish(self):
        result, calls = self.run_setup(publish=True, MOCK_FAIL_SECRET="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(call[:2] == ["workflow", "run"] or "POST" in call for call in calls))

    def test_publish_creates_a_tag_on_remote_main(self):
        result, calls = self.run_setup(publish=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        create = next(call for call in calls if "POST" in call)
        self.assertIn("ref=refs/tags/v0.2.1", create)
        self.assertIn("sha=" + "a" * 40, create)

    def test_existing_matching_tag_reruns_the_release(self):
        result, calls = self.run_setup(publish=True, MOCK_TAG_SHA="a" * 40)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(call[:3] == ["workflow", "run", "release.yml"] for call in calls))
        self.assertFalse(any("POST" in call for call in calls))

    def test_existing_tag_is_never_moved(self):
        result, calls = self.run_setup(publish=True, MOCK_TAG_SHA="b" * 40)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(call[:2] == ["workflow", "run"] or "POST" in call for call in calls))


if __name__ == "__main__":
    unittest.main()
