class Smiledev < Formula
  desc "Official package manager for Looping and Loop OS ecosystem"
  homepage "https://cokistudios.github.io"
  version "2.5.0"
  license "MIT"

  url "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.5.0/looping-v2.5.0-darwin-universal.tar.gz"
  sha256 "1ff3d001be3b39081153d8e95c27ecedd2bcf6244189b32f2ee398c4bb5a7dee"

  def install
    bin.install "smiledev"
  end

  test do
    system "#{bin}/smiledev", "version"
  end
end
