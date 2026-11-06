import base64
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("configure_updates", ROOT / "scripts/configure-updates.py")
tools = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tools)


class UpdateConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.plist = Path(self.directory.name) / "Info.plist"
        self.plist.write_bytes(plistlib.dumps({"CFBundleVersion": "2"}))
        self.key = base64.b64encode(bytes(range(32))).decode()

    def test_embeds_only_public_configuration(self):
        tools.configure(self.plist, "https://example.com/appcast.xml", self.key, required=True)
        info = plistlib.loads(self.plist.read_bytes())
        self.assertEqual(info["SUFeedURL"], "https://example.com/appcast.xml")
        self.assertEqual(info["SUPublicEDKey"], self.key)
        self.assertEqual(info["CFBundleVersion"], "2")
        self.assertEqual(set(info), {"SUFeedURL", "SUPublicEDKey", "CFBundleVersion"})

    def test_unconfigured_local_build_stays_without_updates(self):
        tools.configure(self.plist, "", "")
        self.assertNotIn("SUFeedURL", plistlib.loads(self.plist.read_bytes()))

    def test_partial_or_missing_release_configuration_fails(self):
        for feed, key in [("", ""), ("https://example.com/appcast.xml", ""), ("", self.key)]:
            with self.subTest(feed=feed, has_key=bool(key)), self.assertRaises(ValueError):
                tools.configure(self.plist, feed, key, required=True)

    def test_invalid_urls_are_rejected_before_changing_the_plist(self):
        original = self.plist.read_bytes()
        for feed in ["http://example.com/appcast.xml", "file:///tmp/appcast.xml", "https:///appcast.xml", "https://token@example.com/appcast.xml", "https://example.com/appcast.xml#fragment"]:
            with self.subTest(feed=feed), self.assertRaises(ValueError):
                tools.configure(self.plist, feed, self.key)
            self.assertEqual(self.plist.read_bytes(), original)

    def test_malformed_or_incorrect_length_public_keys_fail(self):
        for key in ["not base64", base64.b64encode(bytes(31)).decode(), base64.b64encode(bytes(64)).decode()]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                tools.configure(self.plist, "https://example.com/appcast.xml", key)

    def test_reconfiguring_removes_stale_configuration(self):
        tools.configure(self.plist, "https://example.com/appcast.xml", self.key)
        tools.configure(self.plist, "", "")
        self.assertEqual(plistlib.loads(self.plist.read_bytes()), {"CFBundleVersion": "2"})


if __name__ == "__main__":
    unittest.main()
