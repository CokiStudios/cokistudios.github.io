class Smiledev < Formula
  desc "Official package manager for Looping v1.1.3 (Arch 3.1A) and Loop OS ecosystem"
  homepage "https://engine.cokistudios.com"
  version "1.1.3"
  version_scheme 1
  license "MIT"

  url "https://engine.cokistudios.com/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://repo.cokistudios.com/engine/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/engine/releases/download/v1.1/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v1.1/looping-v1.1-darwin-universal.tar.gz"
  sha256 "8a0b3d64c27fa2fde12044217fef3bab9ad6c1e3ec56fa6e298c376b68fe29f8"

  def install
    bin.install "smiledev"
  end

  test do
    system "#{bin}/smiledev", "version"
  end
end
