# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::git' do
  context 'create the base locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'imports the git::windows recipe' do
      expect(chef_run).to include_recipe('git::windows')
    end

    it 'adds git to the path' do
      expect(chef_run).to add_windows_path('c:/Program Files/Git/cmd')
    end
  end

  context 'adds a label to the jenkins label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'adds the git label' do
      expect(chef_run).to run_ruby_block('add_git_label')
    end

    it 'deletes the labels.txt.old backup file' do
      expect(chef_run).to delete_file('c:/ops/jenkins/labels.txt.old')
    end
  end
end
