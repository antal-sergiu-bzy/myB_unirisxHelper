require 'net/http'
require 'json'

# PullRequests
module PullRequests
  GIT_URL = ENV['git_api_http_url']
  GIT_ORGANIZATION = ENV['git_organization']
  GIT_REPOSITORY = ENV['git_repository']

  # branch_name: normally available from TeamCity as an environment variable
  #   could possibly alternatively access from local git
  def self.get_pr_number(branch_name = ENV['branch_name'])
    puts "Resolving PR identifier for: #{branch_name ||= 'nil'}"

    pull_request_match = %r{^([0-9]+)/}.match(branch_name)
    pull_request_match.nil? ? 0 : pull_request_match[1].to_i
  end

  def self.get_pull_request(pull_request_number)
    pull_request_url = "#{GIT_URL}/repos/#{GIT_ORGANIZATION}/#{GIT_REPOSITORY}/pulls/" \
        "#{pull_request_number}"

    JSON.parse(Net::HTTP.get(URI(pull_request_url)))
  end
end
