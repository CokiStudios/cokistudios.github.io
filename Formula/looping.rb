class Looping < Formula
  desc "Dual hybrid high-performance engine and programming language for Loop OS"
  homepage "https://cokistudios.github.io"
  version "2.5.0"
  license "MIT"

  url "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.5.0/looping-v2.5.0-darwin-universal.tar.gz"
  sha256 "4c681a67f7d6813526b699cb5f15f5362768a35828b6033eac65fa84745d6350"

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
