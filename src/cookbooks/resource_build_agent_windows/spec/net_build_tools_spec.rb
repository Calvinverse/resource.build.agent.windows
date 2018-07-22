# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::net_build_tools' do
  context 'installs .NET build tools' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    msbuild_install_options =
      '--quiet' \
      ' --norestart' \
      ' --wait' \
      ' --nocache' \
      ' --noUpdateInstaller' \
      ' -add Microsoft.VisualStudio.Workload.AzureBuildTools;includeRecommended' \
      ' -add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools;includeRecommended' \
      ' -add Microsoft.VisualStudio.Workload.MSBuildTools' \
      ' -add Microsoft.VisualStudio.Workload.NetCoreBuildTools' \
      ' -add Microsoft.VisualStudio.Workload.VCTools' \
      ' -add Microsoft.VisualStudio.Workload.WebBuildTools;includeRecommended' \
      ' -add Microsoft.Net.Component.4.7.1.SDK' \
      ' -add Microsoft.Net.Component.4.7.1.TargetingPack' \
      ' -add Microsoft.Net.ComponentGroup.4.7.1.DeveloperTools'

    it 'installs the .NET build tools' do
      expect(chef_run).to install_windows_package('MsBuild').with(
        installer_type: custom,
        options: msbuild_install_options,
        source: 'https://aka.ms/vs/15/release/vs_buildtools.exe'
      )
    end

    it 'adds msbuild to the path' do
      expect(chef_run).to add_windows_path('C:/Program Files (x86)/Microsoft Visual Studio/2017/BuildTools/MSBuild/15.0/Bin/amd64')
    end
  end

  context 'adds a label to the jenkins label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'adds the msbuild label' do
      expect(chef_run).to run_ruby_block('add_msbuild_label')
    end
  end
end
