#
# Cookbook Name:: postgresql
# Recipe:: configuration
#

pg_version = node["postgresql"]["version"]
restart_action = node["postgresql"]["cfg_update_action"].to_sym

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
  notifies restart_action, "service[postgresql]"
end

# pg_ctl
template "/etc/postgresql/#{pg_version}/main/pg_ctl.conf" do
  source "pg_ctl.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0644"
  notifies restart_action, "service[postgresql]"
end

# pg_hba
template node["postgresql"]["hba_file"] do
  source "pg_hba.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0640"
  notifies :reload, "service[postgresql]"
  sensitive true
end

# pg_ident
template node["postgresql"]["ident_file"] do
  source "pg_ident.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0640"
  notifies :reload, "service[postgresql]"
  sensitive true
end

# postgresql
if node["postgresql"]["conf_custom"]
  file "/etc/postgresql/#{pg_version}/main/postgresql.conf" do
    content node["postgresql"]["conf"].map { |k, v| "#{k} = '#{v}'" }.join("\n")
    owner  "postgres"
    group  "postgres"
    mode   "0644"
    notifies restart_action, "service[postgresql]"
  end
else
  template "/etc/postgresql/#{pg_version}/main/postgresql.conf" do
    source "postgresql.conf.erb"
    owner  "postgres"
    group  "postgres"
    mode   "0644"
    notifies restart_action, "service[postgresql]"
  end
end

# start
template "/etc/postgresql/#{pg_version}/main/start.conf" do # ~FC037 variable ok
  source "start.conf.erb"
  owner  "postgres"
  group  "postgres"
  mode   "0644"
  notifies restart_action, "service[postgresql]", :immediately
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
