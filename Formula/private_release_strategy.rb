# frozen_string_literal: true

require "utils/github"

# Homebrew DownloadStrategy for private GitHub repos.
#
# This tap is public, but the release assets live in a private repo.
# Users must set HOMEBREW_GITHUB_API_TOKEN to a token that can read the private repo.
class GitHubPrivateRepositoryDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super

    match = url.match(%r{https?://github\.com/([^/]+)/([^/]+)/(.+)})
    raise "Invalid url pattern for GitHub download strategy: #{url}" unless match

    @owner = match[1]
    @repo = match[2]
    @filepath = match[3]
    @filename = File.basename(@filepath)

    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"].to_s
    if @github_token.empty? && defined?(GitHub::API) && GitHub::API.respond_to?(:credentials)
      @github_token = GitHub::API.credentials.to_s
    end

    raise "Set HOMEBREW_GITHUB_API_TOKEN to download private GitHub release assets." if @github_token.empty?
  end

  def download_url
    "https://#{@github_token}@github.com/#{@owner}/#{@repo}/#{@filepath}"
  end

  # Homebrew may issue HEAD requests to resolve basename/size. For private assets, that fails without auth.
  # Force resolution against the authenticated URL.
  def resolve_url_basename_time_file_size(url, timeout: nil)
    url = download_url
    super(url, timeout: timeout)
  end

  # Fixes cases where Homebrew uses the resolved basename for file operations.
  def resolved_basename
    @filename
  end

  def _fetch(url:, resolved_url:, timeout: nil, **_options)
    curl_download download_url, to: temporary_path
  end
end

class GitHubPrivateRepositoryReleaseDownloadStrategy < GitHubPrivateRepositoryDownloadStrategy
  def initialize(url, name, version, **meta)
    super

    match = url.match(%r{https?://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)})
    raise "Invalid url pattern for GitHub release download strategy: #{url}" unless match

    @owner = match[1]
    @repo = match[2]
    @tag = match[3]
    @filename = match[4]
  end

  def download_url
    asset_id = resolve_release_asset_id!
    "https://#{@github_token}@api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id}"
  end

  def resolve_release_asset_id!
    release_metadata = GitHub.get_release(@owner, @repo, @tag)
    assets = release_metadata.fetch("assets", [])
    asset = assets.find { |a| a["name"] == @filename }
    raise "Asset #{@filename} not found in release #{@tag} (#{@owner}/#{@repo})." unless asset

    asset.fetch("id")
  rescue GitHub::API::HTTPNotFoundError
    raise "Release #{@tag} not found (or token lacks access) for #{@owner}/#{@repo}."
  end

  def _fetch(url:, resolved_url:, timeout: nil, **_options)
    curl_download download_url,
                  "--header",
                  "Accept: application/octet-stream",
                  to: temporary_path
  end
end
