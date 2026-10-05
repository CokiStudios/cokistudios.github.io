class Smiledev < Formula
  desc "Official package manager for Looping and Loop OS ecosystem"
  homepage "https://cokistudios.github.io"
  version "2.5.0"
  license "MIT"

  url "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.5.0/looping-v2.5.0-darwin-universal.tar.gz"
  sha256 "0799d384fef01410c72d0359ca2b548ab982f14d9b09fe92da93ed5da55f08e6"

  def install
    bin.install "smiledev"
  end

  test do
    system "#{bin}/smiledev", "version"
  end
end
