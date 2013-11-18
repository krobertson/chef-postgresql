#
# Cookbook Name:: postgresql
# Recipe:: server
#

include_recipe "postgresql"

# don't auto-start the service to allow custom configuration
file "/usr/sbin/policy-rc.d" do
  mode "0755"
  content("#!/bin/sh\nexit 101\n")
  not_if "pgrep postgres"
end

# install the package
package "postgresql-#{node["postgresql"]["version"]}" do
  notifies :stop, "service[postgresql]", :immediately
  notifies :run,  "execute[remove-initial-postgres-data-dir]", :immediately
  action :install
end

# triggers removal of the initial data directory
execute "remove-initial-postgres-data-dir" do
  command "rm -rf #{node["postgresql"]["data_directory"]}"
  action :nothing
end

# setup the data directory
include_recipe "postgresql::data_directory"

# add the configuration
include_recipe "postgresql::configuration"

# declare the system service
include_recipe "postgresql::service"

# setup users
include_recipe "postgresql::setup_users"

# setup databases
include_recipe "postgresql::setup_databases"

# setup extensions
include_recipe "postgresql::setup_extensions"

# setup languages
include_recipe "postgresql::setup_languages"
