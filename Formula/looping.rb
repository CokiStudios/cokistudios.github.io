class Looping < Formula
  desc "Dual hybrid high-performance 2D/3D engine and programming language (Production Release / Arch 3.0A)"
  homepage "https://cokistudios.github.io"
  version "1.1"
  version_scheme 1
  license "MIT"

  url "https://repo.cokistudios.com/engine/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/engine/releases/download/v1.1/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v1.1/looping-v1.1-darwin-universal.tar.gz"
  sha256 "6494f61686a699aab2715b3ed9cca3778a7dd5cd35ab4859d5fbf7f4d2193b7d"

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
