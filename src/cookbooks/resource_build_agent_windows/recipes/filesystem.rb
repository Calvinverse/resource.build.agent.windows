# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: filesystem
#
# Copyright 2018, P. van der Veld
#

#
# ENABLE LONG PATHS
#

# See: https://docs.microsoft.com/en-us/windows/desktop/fileio/naming-a-file#maximum-path-length-limitation
registry_key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem' do
  action :create
  recursive true
  values [{
    name: 'LongPathsEnabled',
    type: :dword,
    data: 1
  }]
end

#
# CREATE THE LANGUAGES DIRECTORY
#

languages_directory = node['paths']['languages']
tools_directory = node['paths']['tools']
temp_directory = node['paths']['temp']
%W[#{languages_directory} #{tools_directory} #{temp_directory}].each do |path|
  directory path do
    action :create
    rights :read, 'Everyone', applies_to_children: true
    rights :modify, 'Administrators', applies_to_children: true
  end
end

#
# CREATE THE SECRETS DIRECTORY
#

secrets_directory = node['paths']['secrets']
directory secrets_directory do
  action :create
  inherits false
  rights :modify, 'Administrators', applies_to_children: true
end
