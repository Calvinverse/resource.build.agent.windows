# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::nuget' do
  context 'installs nuget' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the nuget install directory' do
      expect(chef_run).to create_directory('c:/tools/nuget')
    end

    it 'creates nuget.exe in the nuget tools directory' do
      expect(chef_run).to create_remote_file('c:/tools/nuget/nuget.exe')
    end

    it 'adds nuget to the path' do
      expect(chef_run).to add_windows_path('c:/tools/nuget')
    end
  end

  context 'sets the nuget cache directory' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the nuget cache directory' do
      expect(chef_run).to create_directory('e:/nuget')
    end

    it 'sets the NUGET_PACKAGES environment variable' do
      expect(chef_run).to create_env('NUGET_PACKAGES').with_value('e:/nuget')
    end
  end

  context 'adds a label to the jenkins label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'adds the nuget label' do
      expect(chef_run).to run_ruby_block('add_nuget_label')
    end

    it 'deletes the labels.txt.old backup file' do
      expect(chef_run).to delete_file('d:/ci/labels.txt.old')
    end
  end
end
