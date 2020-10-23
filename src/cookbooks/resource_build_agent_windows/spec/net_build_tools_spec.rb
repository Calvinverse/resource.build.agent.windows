# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::net_build_tools' do
  context 'installs visual studio' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

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

    it 'installs Visual Studio' do
      expect(chef_run).to install_windows_package('MsBuild').with(
        installer_type: :custom,
        options: msbuild_install_options,
        source: 'https://aka.ms/vs/16/release/vs_enterprise.exe'
      )
    end

    it 'installs the .NET 4.8 SDK' do
      expect(chef_run).to install_windows_package('.NET 4.8 SDK').with(
        installer_type: :custom,
        source: 'https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe'
      )
    end

    it 'adds msbuild to the path' do
      expect(chef_run).to add_windows_path('C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/Bin/amd64')
    end
  end

  context 'adds a label to the jenkins label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'adds the msbuild label' do
      expect(chef_run).to run_ruby_block('add_msbuild_label')
    end

    it 'adds the visual studio label' do
      expect(chef_run).to run_ruby_block('add_visualstudio_label')
    end

    it 'deletes the labels.txt.old backup file' do
      expect(chef_run).to delete_file('d:/ci/labels.txt.old')
    end
  end
end
