from PIL import Image
from matplotlib import pyplot as plt
from typing import Union, Optional

import io
import AppKit
import requests
import base64


def get_clipboard_image() -> Optional[bytes]:
    """
    Get the image from the clipboard.

    Returns:
        Optional[Image.Image]: The image from the clipboard,
            or None if no image data is found.
    """

    # Get the general pasteboard
    pasteboard = AppKit.NSPasteboard.generalPasteboard()

    # Check for image data in the pasteboard
    raw_data = pasteboard.dataForType_(AppKit.NSPasteboardTypePNG)
    if not raw_data:
        return None

    # Create an image from the data
    data = raw_data.bytes().tobytes()
    return data
