# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::gpg' do
  context 'create the base locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'imports the gnugpg::default recipe' do
      expect(chef_run).to include_recipe('gnugpg::default')
    end
  end

  context 'adds a label to the jenkins label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'adds the gpg label' do
      expect(chef_run).to run_ruby_block('add_gpg_label')
    end
  end
end
