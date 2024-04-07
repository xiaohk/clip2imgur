from typing import Optional
from json import load, dump
from time import time
from rich.console import Console

import os
import AppKit
import requests
import base64
import webbrowser
import argparse
import pyperclip

CLIENT_ID = "dd530a37627eee4"
CONFIG_DIR = os.path.expanduser("~/.config/clip2imgur")
AUTH_FILE = os.path.join(CONFIG_DIR, "auth.json")
console = Console()


class Clip2imgurApp:
    """CLI wrapper for Clip2imgur."""

    def __init__(self):
        self.clip2imgur = Clip2imgur()

        # Initialize the argument parser and register flags
        description = (
            "clip2imgur is a simple CLI that uploads your image in"
            + "clipboard to Imgur."
        )
        self.parser = argparse.ArgumentParser(description=description)
        self.parser.add_argument(
            "-m",
            "--markdown",
            action="store_true",
            help="Copy the image URL in Markdown format",
        )
        self.parser.add_argument(
            "-t",
            "--html",
            action="store_true",
            help="Copy the image URL in HTML format",
        )
        self.parser.add_argument(
            "-n",
            "--nocopy",
            action="store_true",
            help="Do not copy the image URL after posting",
        )
        self.parser.add_argument(
            "-a",
            "--anon",
            action="store_true",
            help="Post the image anonymously",
        )

    def run(self):
        """The app's main logic"""

        # Parse the arguments
        args = self.parser.parse_args()
        is_anon = False

        if args.anon:
            is_anon = True

        # Post the user's image
        url = self.post_image(is_anon)

        # Transform the url
        if url is not None:
            if args.nocopy:
                return

            elif args.html:
                self.copy_url_to_clipboard(url, "html")

            elif args.markdown:
                self.copy_url_to_clipboard(url, "markdown")

            else:
                self.copy_url_to_clipboard(url)

            console.print(
                "The image url is copied to your clipboard.", style="blue bold"
            )

    def post_image(self, is_anon):
        """
        Post the image from the clipboard to Imgur. Ask the user to authorize
        if they have not done so.
        """
        ok_responses = set(["yes", "'yes'", "y", ""])
        no_responses = set(["no", "'no'", "n"])

        if self.clip2imgur.auth_values is None:
            console.print(
                "In order to upload image to your collection, you need to "
                + "authorize this app. Otherwise, you will be posting your "
                + "image anonymously. Do you want to authorize this app now?\n"
            )
            response = ""
            while True:
                console.print(
                    "[Enter 'yes' to start authorization, enter 'no' to post anonymously]"
                )
                response = input("> (yes)")

                if response in ok_responses:
                    self.clip2imgur.auth_user()
                    return self.clip2imgur.post_clipboard_image(is_anon=is_anon)
                elif response in no_responses:
                    return self.clip2imgur.post_clipboard_image(is_anon=is_anon)
        else:
            return self.clip2imgur.post_clipboard_image(is_anon=is_anon)

    def copy_url_to_clipboard(self, url: str, using_format="plain"):
        """
        Copy the url to the clipboard.
        """
        formatted_url = url

        if using_format == "html":
            formatted_url = f'<img src="{url}">'
        elif using_format == "markdown":
            formatted_url = f"![]({url})"

        pyperclip.copy(formatted_url)


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
            if now > int(self.auth_values["time"]) + int(
                self.auth_values["expires_in"]
            ):
                console.print(
                    "Authorization is expired. Please authorize again.",
                    style="bold red",
                )
                self.auth_user()

    def post_clipboard_image(self, is_anon=False):
        """
        Uploads an image from the clipboard to Imgur.

        Parameters:
            is_anon (bool): If True, the image will be uploaded anonymously.
                If False, the image will be associated with your Imgur account.

        Returns:
            str: The link to the uploaded image on Imgur.

        """
        image_data = self.get_clipboard_image()
        if image_data is None:
            console.print(
                "No image file detected in your clipboard \n\n"
                + "You can use [⌘ ⌃ ⇧ 4] or [⌘ ⌃ ⇧ 3] to capture a screenshot and "
                + "copy it to your clipboard.",
                style="bold red",
            )
            return

        console.print("Uploading...")
        link = self.post_image(image_data, is_anon=is_anon)
        console.print(
            f"\n🎉 Successfully uploaded your screenshot to Imgur at [link]{link}[/link]\n"
        )
        return link

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

    def post_image(self, image_data: bytes, is_anon=False) -> str:
        """
        Posts an image to Imgur using the provided image data.

        Args:
            image_data (bytes): The image data to be uploaded.
            is_anon (bool): If True, the image will be uploaded anonymously.
                If False, the image will be associated with your Imgur account.

        Returns:
            str: The URL of the uploaded image.

        Raises:
            ValueError: If the response from Imgur is not successful.
        """

        image_base64 = base64.b64encode(image_data)

        # Build the requests
        auth_value = f"Client-ID {CLIENT_ID}"

        if not is_anon and self.auth_values and self.auth_values["access_token"]:
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
        values["time"] = str(int(time()))

        return values

    def auth_user(self) -> dict:
        """
        Authorizes the user to use the Clip2imgur app by obtaining an access token from Imgur.

        Returns:
            A dictionary containing the user's authorization information.
        """

        auth_url = f"https://api.imgur.com/oauth2/authorize?client_id={CLIENT_ID}&response_type=token&state=copy-url"

        console.print(
            "\nTo use this app, we need your authorization. Please follow the instruction"
            + " to authorize Clip2imgur:\n"
        )
        console.print(
            "\t(1) You will be directed to Imgur authorization page in your default browser.\n"
            + "\t(2) Log in and authorize this app.\n"
            + "\t(3) After authorization, you will be redirected to the Imgur main page, please copy the new URL from your browser.\n"
        )
        console.print("Press [return ⏎ ] key to start step (1) \r\n")
        input()

        webbrowser.open(auth_url)
        os.system("clear")

        # Wait until the user enters the URL
        values = {}

        while True:
            console.print(
                "The new URL looks like https://imgur.com/?state=copy-url#access_token=...\n"
            )
            response = input("(4) Paste the full URL below:\n> ")

            if response.startswith("https://imgur.com"):
                values = self.parse_user_url(response)
                if values:
                    break
            console.print("\nMake sure you copy the full URL\n", style="bold red")

        # Save the user auth into a local config file
        if not os.path.exists(CONFIG_DIR):
            os.makedirs(CONFIG_DIR)

        self.auth_values = values

        dump(values, open(AUTH_FILE, "w", encoding="utf8"))

    def auth_is_expired(self):
        """
        Check if the authorization is expired.
        """
        if self.auth_values is None:
            return

        return int(time()) < int(self.auth_values.time) + int(
            self.auth_values.expires_in
        )


if __name__ == "__main__":
    cli = Clip2imgurApp()
    cli.run()
