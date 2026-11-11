class Looping < Formula
  desc "Dual hybrid high-performance 2D/3D engine and programming language (Production Release / Arch 3.0A)"
  homepage "https://cokistudios.github.io"
  version "1.1"
  version_scheme 1
  license "MIT"

  url "https://repo.cokistudios.com/engine/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/engine/releases/download/v1.1/looping-v1.1-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v1.1/looping-v1.1-darwin-universal.tar.gz"
  sha256 "b64ef06c95a2e58d659aa177db8fe735210efe2bea07a55c68535fb9461a350e"

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
