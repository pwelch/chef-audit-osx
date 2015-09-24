#
# Cookbook Name:: audit-osx
#
module AuditOSX
  # @return [Array] of Return a list of OS X users based on /Users directory
  def self.users
    user_dirs = Dir.glob('/Users/**')
    user_names = user_dirs.map { |u| u.split('/Users/').last }

    # return a list of real users
    user_names.reject { |u| u == 'Guest' || u == 'Shared' }
  end
end
