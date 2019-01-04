# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: nuget
#
# Copyright 2018, P. van der Velde
#

#
# INSTALL NUGET
#

nuget_bin_path = node['nuget']['path']['exe']
directory nuget_bin_path do
  action :create
  rights :read_execute, 'Everyone', applies_to_children: true, applies_to_self: true
end

nuget_cache_path = node['nuget']['path']['cache']
directory nuget_cache_path do
  action :create
  rights :modify, 'Everyone', applies_to_children: true, applies_to_self: false
end

nuget_exe_path = node['nuget']['path']['exe_file']
remote_file nuget_exe_path do
  action :create
  source node['nuget']['url']
end

#
# ADD NUGET TO THE PATH
#

windows_path nuget_bin_path do
  action :add
end

#
# SET NUGET CACHE LOCATION
#

env 'NUGET_PACKAGES' do
  value nuget_cache_path
end

# Default NuGet config file

# NuGet credential provider that links to Vault

#
# ADD TO THE JENKINS LABELS FILE
#

jenkins_labels_file = node['jenkins']['file']['labels_file']
ruby_block 'add_nuget_label' do
  block do
    file = Chef::Util::FileEdit.new(jenkins_labels_file)
    file.insert_line_if_no_match('nuget', 'nuget')
    file.write_file
  end
end

# Chef::Util::FileEdit creates the .old file when it inserts the line.
# We don't want this file so nuke it.
file "#{jenkins_labels_file}.old" do
  action :delete
end
