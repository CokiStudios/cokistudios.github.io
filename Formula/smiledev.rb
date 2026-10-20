class Smiledev < Formula
  desc "Official package manager for Looping and Loop OS ecosystem"
  homepage "https://cokistudios.github.io"
  version "2.7.0"
  license "MIT"

  url "https://repo.cokistudios.com/engine/looping-v2.7.0-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.7.0/looping-v2.7.0-darwin-universal.tar.gz"
  sha256 "2cdfb20f27d453e3a85640e2d6fbf48d853d4df7b64112fdb070be43a9b9d53a"

  def install
    bin.install "smiledev"
  end

  test do
    system "#{bin}/smiledev", "version"
  end
end
