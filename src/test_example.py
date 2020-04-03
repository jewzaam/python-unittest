import unittest

class TestMyStuff(unittest.TestCase):
    def test_success(self):
        self.assertTrue(True) # will pass

    def test_failure(self):
        self.assertFalse(True) # will fail
