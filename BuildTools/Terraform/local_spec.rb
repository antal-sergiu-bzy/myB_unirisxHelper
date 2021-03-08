require 'json'
require_relative './beazley_terraform.rb'

# This is the standard set up testing at the root of the repo
RSpec.configure do |config|
  config.before(:all) do
    tf = BeazleyTerraform.new('./Terraform.exe')
    @output = JSON.parse(
      tf.exec_terraform(
        'output',
        flags: ['json'],
        silent: true
      )
    )
  end
end
