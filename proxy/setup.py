#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Setup script for TG MTProto Proxy
"""

from setuptools import setup, find_packages

setup(
    name="tg-mtproto-proxy",
    version="1.6.3",
    description="Telegram MTProto WebSocket Bridge Proxy with GUI",
    author="Proxy Developer",
    packages=find_packages(),
    install_requires=[
        "cryptography>=41.0.0",
        "customtkinter>=5.2.0",
        "pyinstaller>=6.0.0",
    ],
    python_requires=">=3.8",
    entry_points={
        "console_scripts": [
            "tg-proxy=run:main",
            "tg-proxy-gui=run:ProxyGUI.run",
        ],
    },
)