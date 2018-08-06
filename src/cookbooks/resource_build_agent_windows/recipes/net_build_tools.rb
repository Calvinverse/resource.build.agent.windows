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
  ' --add "Microsoft.VisualStudio.Workload.AzureBuildTools;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools;includeRecommended"' \
  ' --add "Microsoft.VisualStudio.Workload.MSBuildTools"' \
  ' --add "Microsoft.VisualStudio.Workload.NetCoreBuildTools"' \
  ' --add "Microsoft.VisualStudio.Workload.VCTools"' \
  ' --add "Microsoft.VisualStudio.Workload.WebBuildTools;includeRecommended"' \
  ' --add "Microsoft.Net.Component.4.7.1.SDK"' \
  ' --add "Microsoft.Net.Component.4.7.1.TargetingPack"' \
  ' --add "Microsoft.Net.ComponentGroup.4.7.1.DeveloperTools"'

# Because MS sucks at making VS installers we have to do this the hard way. Apparently --wait doesn't
# actually wait because that would be too sensible, so lets powershell this sucker
powershell_script 'install_vs_buildtools' do
  code <<-EOH
    $installerPath = Join-Path #{default['paths']['temp']} 'vs_buildtools.exe'

    # Download the installer
    Invoke-WebRequest -Uri #{node['net_build_tools']['url']} -OutFile $installerPath

    # Invoke the installer
    & $installerPath #{msbuild_install_options}

    # Eventhough we specify the --wait option, it won't because ... reasons. So do this the hard way
    # go find the process and wait for it to exit. Because we don't know exactly which one to wait for
    # we wait for all of these to exit
    Wait-Process -Name 'vs_buildtools', 'vs_installer', 'vs_setup_bootstrapper'
  EOH
end

#
# ADD MSBUILD TO THE PATH
#

windows_path 'C:/Program Files (x86)/Microsoft Visual Studio/2017/BuildTools/MSBuild/15.0/Bin/amd64' do
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
    file.write_file
  end
end
