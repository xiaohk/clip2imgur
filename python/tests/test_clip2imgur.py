#!/usr/bin/env python

"""Tests for `clip2imgur` package."""


import unittest

from clip2imgur import clip2imgur


class TestClip2imgur(unittest.TestCase):
    """Tests for `timbertrek` package."""

    def setUp(self):
        """Set up test fixtures, if any."""

    def tearDown(self):
        """Tear down test fixtures, if any."""

    def test_clip2imgur(self):
        """Test something."""
        cli = clip2imgur.Clip2imgurApp()
        cli.run()


if __name__ == "__main__":
    unittest.main()
