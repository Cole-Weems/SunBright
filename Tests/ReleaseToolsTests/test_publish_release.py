import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/publish-release.sh"


class PublishReleaseTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.log = self.root / "gh.log"
        for asset in ["dist/SunBright-0.2.0-apple-silicon.zip", "dist/SunBright-0.2.0-apple-silicon.zip.sha256", "dist/updates/appcast.xml"]:
            path = self.root / asset
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("fixture")
        gh = self.root / "gh"
        gh.write_text('''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['MOCK_GH_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
command = args[1]
if command == 'view':
    if os.environ['MOCK_RELEASE'] == 'missing':
        sys.exit(1)
    print('true' if os.environ['MOCK_RELEASE'] == 'draft' else 'false')
if command == os.environ.get('MOCK_FAIL'):
    sys.exit(1)
''')
        gh.chmod(0o755)

    def run_release(self, repository="owner/source", state="missing", fail="", tag="v0.2.0"):
        self.log.write_text("")
        result = subprocess.run(
            ["bash", str(SCRIPT), repository, tag, "0.2.0"], cwd=self.root, text=True, capture_output=True,
            env={**os.environ, "PATH": f'{self.root}:{os.environ["PATH"]}', "MOCK_GH_LOG": str(self.log),
                 "GITHUB_REPOSITORY": "owner/source", "MOCK_RELEASE": state, "MOCK_FAIL": fail},
        )
        return result, [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_source_release_uploads_before_publishing(self):
        result, calls = self.run_release()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call[1] for call in calls], ["view", "create", "edit"])
        for expected in ["--draft", "--verify-tag", "--generate-notes", "dist/updates/appcast.xml", "dist/SunBright-0.2.0-apple-silicon.zip", "dist/SunBright-0.2.0-apple-silicon.zip.sha256"]:
            self.assertIn(expected, calls[1])
        self.assertIn("--draft=false", calls[2])

    def test_public_mirror_does_not_copy_private_change_notes_or_require_a_source_tag(self):
        result, calls = self.run_release(repository="owner/downloads")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("--generate-notes", calls[1])
        self.assertNotIn("--verify-tag", calls[1])
        self.assertNotIn("--verify-tag", calls[2])
        self.assertIn("--notes-file", calls[1])
        for call in calls:
            self.assertEqual(call[call.index("--repo") + 1], "owner/downloads")

    def test_retry_preserves_notes_and_finishes_a_draft(self):
        for state, commands in [("draft", ["view", "upload", "edit"]), ("published", ["view", "upload"])]:
            with self.subTest(state=state):
                result, calls = self.run_release(state=state)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual([call[1] for call in calls], commands)
                self.assertIn("--clobber", calls[1])
                self.assertNotIn("--notes-file", calls[1])

    def test_upload_failures_never_publish_a_draft(self):
        for state, failure in [("missing", "create"), ("draft", "upload"), ("published", "upload")]:
            with self.subTest(state=state):
                result, calls = self.run_release(state=state, fail=failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("edit", [call[1] for call in calls])

    def test_missing_feed_or_mismatched_tag_stops_before_api_calls(self):
        result, calls = self.run_release(tag="v0.3.0")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])
        (self.root / "dist/updates/appcast.xml").unlink()
        result, calls = self.run_release()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
