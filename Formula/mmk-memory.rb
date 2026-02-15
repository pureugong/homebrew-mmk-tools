require_relative "private_release_strategy"

class MmkMemory < Formula
  desc "Offline-first, Markdown-based memory index + search for coding agents."
  homepage "https://github.com/pureugong/mmk-openmemory"
  version "0.1.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pureugong/mmk-openmemory/releases/download/v0.1.0/mmk-memory_0.1.0_darwin_arm64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "eeb4e47565632703759dd12b8d085cbb4c7da6b4aec173574443f82962d07ef8"
    end
    if Hardware::CPU.intel?
      url "https://github.com/pureugong/mmk-openmemory/releases/download/v0.1.0/mmk-memory_0.1.0_darwin_amd64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "f7f5138f09a7af3665730740b09bf00f8f08483e99873ba7587d1ef0863fe872"
    end
  end

  def install
    bin.install "mmk-memory"
  end

  test do
    system "#{bin}/mmk-memory", "version"
  end
end
