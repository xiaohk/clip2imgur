class clip2imgur < Formula
  desc "A simple macOS command line tool for uploading your copied image to Imgur"
  homepage "https://github.com/xiaohk/clip2imgur"
  url "https://github.com/xiaohk/clip2imgur/releases/download/v0.8/clip2imgur-0.8.0.zip"
  sha256 "a8c5f73e57ccf324a57952b737065516b4866481a387724330fd8cf5528aa567"

  bottle :unneeded

  def install
    bin.install "clip2imgur"
  end

  test do
    system "#{bin}/clip2imgur", "--help"
  end
end
