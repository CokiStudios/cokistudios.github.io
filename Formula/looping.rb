class Looping < Formula
  desc "Official runtime, compiler & module ecosystem for Shine Loop & Holo Looping OoS"
  homepage "https://cokistudios.com"
  url "https://github.com/CokiStudios/cokistudios.github.io/archive/refs/heads/main.tar.gz"
  version "2.0.4"
  license "Proprietary"

  depends_on "node"
  depends_on "python@3.11"

  def install
    bin.install "bin/looping"
    prefix.install "LoopingEngine"
    prefix.install "holo-looping-oos"
  end

  test do
    system "#{bin}/looping", "--version"
  end
end
