require 'bundler'
Bundler.setup(:build)

$LOAD_PATH << __dir__

Dir[File.expand_path('RakeHelpers/*.rb', __dir__)].each do |file|
  require file
end

def on_build_server?
  ENV.key? 'BUILD_SERVER'
end
