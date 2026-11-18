class Looping < Formula
  desc "Dual hybrid high-performance 2D/3D engine and programming language (Production Release / Arch 3.1A)"
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
    bin.install "looping"
    bin.install_symlink "looping" => "ruuping"
    bin.install "smiledev"
  end

  test do
    system "#{bin}/looping", "test"
    system "#{bin}/smiledev", "version"
  end
end
