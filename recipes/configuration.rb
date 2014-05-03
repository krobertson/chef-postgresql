#
# Cookbook Name:: postgresql
# Recipe:: configuration
#


pg_version = node["postgresql"]["version"]

directory "/etc/postgresql/#{pg_version}/main/" do
  owner  "postgres"
  group  "postgres"
  recursive true
end

# environment
template "/etc/postgresql/#{pg_version}/main/environment" do
  source "environment.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0644"
  notifies :restart, "service[postgresql]"
end

# pg_ctl
template "/etc/postgresql/#{pg_version}/main/pg_ctl.conf" do
  source "pg_ctl.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0644"
  notifies :restart, "service[postgresql]"
end

# pg_hba
template node["postgresql"]["hba_file"] do
  source "pg_hba.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0640"
  notifies :restart, "service[postgresql]"
end

# pg_ident
template node["postgresql"]["ident_file"] do
  source "pg_ident.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0640"
  notifies :restart, "service[postgresql]"
end

# postgresql
pg_template_source = node["postgresql"]["conf"].any? ? "custom" : "standard"
template "/etc/postgresql/#{pg_version}/main/postgresql.conf" do
  source "postgresql.conf.#{pg_template_source}.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0644"
  notifies :restart, "service[postgresql]"
end

# start
template "/etc/postgresql/#{pg_version}/main/start.conf" do
  source "start.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0644"
  notifies :restart, "service[postgresql]", :immediately
end

# Write recovery.conf if we are a slave
if node[:postgresql][:slave]
  # This goes in the data directory; where data is stored
  template File.join(node["postgresql"]["data_directory"], "recovery.conf") do
    source "recovery.conf.erb"
    owner  "postgres"
    group  "postgres"
    mode   "0600"
    notifies :restart, "service[postgresql]"
  end
end

# If this is the master, but there is a recovery.conf, then run promote
if node[:postgresql][:master]
  bash "promote-to-master" do
    user "postgres"
    code <<-EOC
    /usr/lib/postgresql/#{node["postgresql"]["version"]}/bin/pg_ctl promote \
      -D #{node["postgresql"]["data_directory"]}
    EOC
    only_if "test -f #{node["postgresql"]["data_directory"]}/recovery.conf"
  end
end
