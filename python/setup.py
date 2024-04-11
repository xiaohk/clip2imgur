#!/usr/bin/env python

"""The setup script."""

from json import loads
from setuptools import setup, find_packages
from pathlib import Path

with open("README.md") as readme_file:
    readme = readme_file.read()

requirements = ["pyobjc-framework-Cocoa", "pyperclip", "rich", "requests"]

test_requirements = []

setup(
    author="Jay Wang",
    author_email="jayw@zijie.wang",
    python_requires=">=3.6",
    platforms="Linux, Mac OS X, Windows",
    keywords=[
        "Imgur",
        "CLI",
        "Image",
        "Clipboard",
    ],
    classifiers=[
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Framework :: Jupyter",
        "Framework :: Jupyter :: JupyterLab",
        "Framework :: Jupyter :: JupyterLab :: 3",
    ],
    description="A simple CLI that uploads your image in the clipboard to Imgur.",
    install_requires=requirements,
    license="MIT license",
    long_description=readme,
    long_description_content_type="text/markdown",
    include_package_data=True,
    name="clip2imgur",
    packages=find_packages(include=["clip2imgur", "clip2imgur.*"]),
    test_suite="tests",
    tests_require=test_requirements,
    url="https://github.com/xiaohk/clip2imgur",
    version="0.9.3",
    zip_safe=False,
    entry_points={
        "console_scripts": [
            "clip2imgur=clip2imgur.clip2imgur:main",
        ],
    },
)
