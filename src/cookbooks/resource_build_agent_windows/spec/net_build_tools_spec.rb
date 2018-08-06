# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::net_build_tools' do
  context 'installs .NET build tools' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'installs the VS build tools' do
      expect(chef_run).to run_powershell_script('install_vs_buildtools')
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
