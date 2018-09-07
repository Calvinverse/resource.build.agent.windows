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
directory npm_cache_path do
  action :create
  rights :modify, 'Everyone', applies_to_children: true, applies_to_self: false
end

env 'npm_config_cache' do
  value npm_cache_path
end

env 'npm_config_progress' do
  value 'false'
end

env 'npm_config_spin' do
  value 'false'
end

#
# INSTALL NVM
#

node_base_directory = node['nodejs']['path']['base']
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

    nvm install #{node['nodejs']['version']}
    nvm use #{node['nodejs']['version']}
  POWERSHELL
end

#
# INSTALL NPM
#

powershell_script 'install_npm' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    # Because NPM sucks they broke their own update on Windows, so lets go Powershell our way out of
    # trouble by using a modification of the script found here: https://gist.github.com/noahleigh/ba34e18b3e0bc4a6a4e93ed7a480536e

    $ErrorActionPreference = 'stop'

    # Create a folder in the Temp directory and return it
    # Source: https://stackoverflow.com/a/34559554/9165387
    function New-TemporaryDirectory {
        $parent = [System.IO.Path]::GetTempPath()
        $name = [System.IO.Path]::GetRandomFileName()
        New-Item -ItemType Directory -Path (Join-Path $parent $name)
    }

    # Get the path to the active node install from nvm
    $currentVer = (
        nvm list | ForEach-Object {[regex]::Match($_, "\\* (\\d+\\.\\d+.\\d+)")} |
        Where-Object Success | ForEach-Object {"v" + $_.Captures.Groups[1].Value} |
        Select-Object -First 1
    )
    $nvmRoot = (
        nvm root | ForEach-Object {[regex]::Match($_, "Current Root: (.+)")} |
        Where-Object Success | ForEach-Object {$_.Captures.Groups[1].Value} |
        Select-Object -First 1
    )
    $nodeInstallPath = Join-Path $nvmRoot $currentVer

    if (-not (Test-Path $nodeInstallPath)) {
        throw [System.IO.FileNotFoundException] "Test-Path : `"$nodeInstallPath`" does not exist."
    }

    # Create a temp directory and move the node_modules\\npm dir into it
    $tempDir = New-TemporaryDirectory
    Write-Output "Moving '$(Join-Path (Join-Path $nodeInstallPath "node_modules") "npm")' to '$tempDir'..."
    Move-Item $(Join-Path (Join-Path $nodeInstallPath "node_modules") "npm") $tempDir

    # Delete the npm and npm.cmd files from the node folder
    Write-Output "Removing 'npm' and 'npm.cmd' from '$nodeInstallPath'..."
    Remove-Item $(Join-Path $nodeInstallPath "npm*")

    $tempNpmBinDir = Join-Path (Join-Path $tempDir "npm") "bin"
    if (-not (Test-Path $tempNpmBinDir)) {
        throw [System.IO.FileNotFoundException] "Test-Path : `"$tempNpmBinDir`" does not exist."
    }

    # Run the install script from the temp folder
    Write-Output "Running `"node npm-cli.js i npm@latest -g`" from `"$tempNpmBinDir`"..."
    node $(Join-Path $tempNpmBinDir "npm-cli.js") i 'npm@latest' -g

    # Delete the temp folder once complete
    Write-Output "Cleanup..."
    Remove-Item $tempDir -Recurse
  POWERSHELL
end

#
# ADD TO THE JENKINS LABELS FILE
#

jenkins_labels_file = node['jenkins']['file']['labels_file']
ruby_block 'add_nodejs_label' do
  block do
    file = Chef::Util::FileEdit.new(jenkins_labels_file)
    file.insert_line_if_no_match('nodejs', 'nodejs')
    file.write_file
  end
end

# Chef::Util::FileEdit creates the .old file when it inserts the line.
# We don't want this file so nuke it.
file "#{jenkins_labels_file}.old" do
  action :delete
end
