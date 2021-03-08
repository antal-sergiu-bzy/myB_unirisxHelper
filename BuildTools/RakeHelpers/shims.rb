# This file contains shims for features that are in newer versions of Ruby

class Array
  # TODO: Remove once fully upgraded to Ruby 2.6
  alias_method :filter, :find_all unless method_defined?(:filter)
end
