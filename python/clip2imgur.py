from typing import Optional
from json import load, dump
from time import time

import os
import AppKit
import requests
import base64
import webbrowser

CLIENT_ID = "dd530a37627eee4"
CONFIG_DIR = os.path.expanduser("~/.config/clip2imgur")
AUTH_FILE = os.path.join(CONFIG_DIR, "auth.json")


class Clip2imgur:
    """
    Clip2imgur CLI class to help users upload clipboard image to Imgur.
    """

    def __init__(self):
        # Try to load the config file
        self.auth_values = None
        if os.path.exists(AUTH_FILE):
            self.auth_values = load(open(AUTH_FILE, "r", encoding="utf8"))

            # Need to re-authenticate if the token is expired
            now = int(time())
            if now > self.auth_values["time"] + self.auth_values["expires_in"]:
                print("Authorization is expired. Please authorize again.")
                self.auth_user()

    def get_clipboard_image(self) -> Optional[bytes]:
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

    def post_image(self, image_data: bytes) -> str:
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

        if self.auth_values and self.auth_values["access_token"]:
            auth_value = f'Bearer {self.auth_values["access_token"]}'

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

    def parse_user_url(self, user_url: str) -> dict:
        """
        Parses a user URL and returns a dictionary of key-value pairs.

        Args:
            user_url (str): The user URL to parse.

        Returns:
            dict: A dictionary containing the key-value pairs extracted from the user URL.
        """

        pound_index = user_url.index("#")
        fragments = user_url[pound_index + 1 :].split("&")
        values = {}

        for fragment in fragments:
            parts = fragment.split("=")
            values[parts[0]] = parts[1]

        # Add a current time to the config
        values["time"] = int(time())

        return values

    def auth_user(self) -> dict:
        """
        Authorizes the user to use the Clip2imgur app by obtaining an access token from Imgur.

        Returns:
            A dictionary containing the user's authorization information.
        """

        auth_url = f"https://api.imgur.com/oauth2/authorize?client_id={CLIENT_ID}&response_type=token&state=copy-url"

        print(
            "\nTo use this app, we need your authorization. Please follow the instruction"
            + " to authorize Clip2imgur:\n"
        )
        print(
            "\t(1) You will be directed to Imgur authorization page in your default browser.\n"
            + "\t(2) Log in and authorize this app.\n"
            + "\t(3) After authorization, you will be redirected to the Imgur main page, please copy the new URL from your browser.\n"
        )
        print("Press [return ⏎ ] key to start step (1) \r\n")
        input()

        webbrowser.open(auth_url)
        os.system("clear")

        # Wait until the user enters the URL
        values = {}

        while True:
            print(
                "The new URL looks like https://imgur.com/?state=copy-url#access_token=...\n"
            )
            response = input("(4) Paste the full URL below:\n> ")

            if response.startswith("https://imgur.com"):
                values = self.parse_user_url(response)
                if values:
                    break
            print("\nMake sure you copy the full URL\n")

        # Save the user auth into a local config file
        if not os.path.exists(CONFIG_DIR):
            os.makedirs(CONFIG_DIR)

        self.auth_values = values

        dump(values, open(AUTH_FILE, "w", encoding="utf8"))
