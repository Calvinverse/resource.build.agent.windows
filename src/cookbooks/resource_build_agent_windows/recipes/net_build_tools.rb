# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: net_build_tools
#
# Copyright 2018, P. van der Velde
#

#
# VISUAL STUDIO BUILD TOOLS
#

# Use the following standard options:
# - quiet: Don't show a UI or progress bar
# - norestart: Don't restart even if that is required
# - wait: wait for the installation to be done
# - nocache: Don't cache components, they will be downloaded again next time
# - noUpdateInstaller: Don't update the installer
msbuild_install_options =
  '--quiet' \
  ' --norestart' \
  ' --wait' \
  ' --nocache' \
  ' --noUpdateInstaller' \
  ' --add "Microsoft.VisualStudio.Workload.Azure;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.Data;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.ManagedDesktop;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.NetCoreTools;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.NetWeb;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended"'

windows_package 'MsBuild' do
  action :install
  installer_type :custom
  options msbuild_install_options
  source node['net_visual_studio']['url']
  timeout 2400
end

#
# ADD MSBUILD TO THE PATH
#

windows_path 'C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/Bin/amd64' do
  action :add
end

#
# ADD TO THE JENKINS LABELS FILE
#

jenkins_labels_file = node['jenkins']['file']['labels_file']
ruby_block 'add_msbuild_label' do
  block do
    file = Chef::Util::FileEdit.new(jenkins_labels_file)
    file.insert_line_if_no_match('msbuild', 'msbuild')
    file.insert_line_if_no_match('msbuild_16', 'msbuild_16')
    file.write_file
  end
end

ruby_block 'add_visualstudio_label' do
  block do
    file = Chef::Util::FileEdit.new(jenkins_labels_file)
    file.insert_line_if_no_match('visualstudio', 'visualstudio')
    file.insert_line_if_no_match('visualstudio_2019', 'visualstudio_2019')
    file.write_file
  end
end

# Chef::Util::FileEdit creates the .old file when it inserts the line.
# We don't want this file so nuke it.
file "#{jenkins_labels_file}.old" do
  action :delete
end
