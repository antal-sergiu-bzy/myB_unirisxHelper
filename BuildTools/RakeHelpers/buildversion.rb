require_relative './pullrequests'

# BuildVersion
module BuildVersion
  # Used to get the build version for PR and Master builds.
  # Returns x.y.z-PRxyz for PR branches, x.y.z for any other branch
  def self.get_build_version(version, pr_number = nil)
    (pr_number ||= PullRequests.get_pr_number).to_i.zero? ? version : version + "-PR#{pr_number}"
  end
end
