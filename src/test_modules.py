import unittest
import semver

def major(version):
    return semver.parse(version)['major']

class TestModules(unittest.TestCase):
    def test_major(self):
        self.assertEqual(major("4.3.2"), 4)
