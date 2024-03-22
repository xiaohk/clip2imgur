from PIL import Image
from matplotlib import pyplot as plt
from typing import Union, Optional

import AppKit
import requests
import base64

CLIENT_ID = "db7dd95cd20fa48"


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


def post_image(image_data: bytes) -> str:
    """
    Posts an image to Imgur using the provided image data.

    Args:
        image_data (bytes): The image data to be uploaded.

    Returns:
        str: The URL of the uploaded image.

    Raises:
        ValueError: If the response from Imgur is not successful.
    """

    image_base64 = base64.b64encode(image_data)

    # Build the requests
    auth_value = f"Client-ID {CLIENT_ID}"
    headers = {"Authorization": auth_value, "Cache-Control": "no-cache"}
    parameters = {
        "image": (None, image_base64),
        "type": (None, "base64"),
    }
    url = "https://api.imgur.com/3/image"

    # Get the results
    response = requests.post(url, headers=headers, files=parameters, timeout=120)
    data = response.json()

    if response.status_code == 200:
        return data["data"]["link"]
    else:
        raise ValueError(data)
