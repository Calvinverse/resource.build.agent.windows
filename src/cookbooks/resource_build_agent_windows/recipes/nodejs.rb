# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: nodejs
#
# Copyright 2018, P. van der Velde
#

#
# SET NPM CACHE REDIRECT ENVIRONMENT VARIABLE
#

npm_cache_path = node['npm']['path']['cache']
directory path do
  action :create
  rights :modify, 'Everyone', applies_to_children: true, applies_to_self: false
end

env 'npm_config_cache' do
  value npm_cache_path
end


#
# INSTALL NVM
#

node_base_directory = node['node']['path']['base']
directory node_base_directory do
  action :create
end

nvm_zip_path = "#{node['paths']['temp']}/nvm.zip"
remote_file nvm_zip_path do
  action :create
  source node['nvm']['url']
end

nvm_bin_path = node['nvm']['path']['bin']
seven_zip_archive nvm_bin_path do
  overwrite true
  source nvm_zip_path
  timeout 30
end

env 'NVM_HOME' do
  value nvm_bin_path
end

env 'NVM_SYMLINK' do
  value node['nvm']['path']['symlink']
end

windows_path '%NVM_HOME%' do
  action :add
end

windows_path '%NVM_SYMLINK%' do
  action :add
end

file "#{nvm_bin_path}/settings.txt" do
  action :create
  content <<~TXT
    root: #{nvm_bin_path}
    path: #{node['nvm']['path']['symlink']}
    arch: 64
    proxy: none
  TXT
end

#
# INSTALL NODE
#

powershell_script 'install_node' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    nvm install #{node['node']['version']}
    nvm use #{node['node']['version']}
  POWERSHELL
end

#
# INSTALL NPM
#

powershell_script 'install_npm' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    npm install -g npm@#{node['npm']['version']}
  POWERSHELL
end
