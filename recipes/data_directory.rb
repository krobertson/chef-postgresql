#
# Cookbook Name:: postgresql
# Recipe:: data_directory
#

# ensure data directory exists
directory node["postgresql"]["data_directory"] do
  owner  "postgres"
  group  "postgres"
  mode   "0700"
  recursive true
  not_if { ::File.exist?("#{node["postgresql"]["data_directory"]}/PG_VERSION") }
end

# initialize the data directory if necessary and if we are not a slave
unless node[:postgresql][:slave]
  bash "postgresql initdb" do
    user "postgres"
    code <<-EOC
    /usr/lib/postgresql/#{node["postgresql"]["version"]}/bin/initdb \
      #{node["postgresql"]["initdb_options"]} \
      -U postgres \
      -D #{node["postgresql"]["data_directory"]}
    EOC
    not_if { ::File.exist?("#{node["postgresql"]["data_directory"]}/PG_VERSION") }
  end
else
  bash "postgresql initial data directory from master" do
    user "postgres"
    code <<-EOC
    /usr/lib/postgresql/#{node["postgresql"]["version"]}/bin/pg_basebackup \
      -h #{node[:postgresql][:primary_conninfo].scan(/host=(\S+)/).flatten.first} \
      -D #{node["postgresql"]["data_directory"]} \
      --xlog --checkpoint=fast --progress
    EOC
    not_if { ::File.exist?("#{node["postgresql"]["data_directory"]}/PG_VERSION") }
  end
end
