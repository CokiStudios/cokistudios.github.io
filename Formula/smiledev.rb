class Smiledev < Formula
  desc "Official package manager for Looping and Loop OS ecosystem"
  homepage "https://cokistudios.github.io"
  version "2.5.0"
  license "MIT"

  url "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.5.0/looping-v2.5.0-darwin-universal.tar.gz"
  sha256 "8ad7ee7f7eb30114b92ea4252ecd3484c44d0ac197b9674480c769755d6c2a53"

  def install
    bin.install "smiledev"
  end

  test do
    system "#{bin}/smiledev", "version"
  end
end
