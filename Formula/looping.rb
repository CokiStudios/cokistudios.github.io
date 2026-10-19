class Looping < Formula
  desc "Dual hybrid high-performance engine and programming language for Loop OS"
  homepage "https://cokistudios.github.io"
  version "2.6.0"
  license "MIT"

  url "https://repo.cokistudios.com/engine/looping-v2.6.0-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.6.0/looping-v2.6.0-darwin-universal.tar.gz"
  sha256 "c028b5e0e78545d038b5cb18877514f835deba49ae00dae7d3ee30c5b9eca4bd"

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
