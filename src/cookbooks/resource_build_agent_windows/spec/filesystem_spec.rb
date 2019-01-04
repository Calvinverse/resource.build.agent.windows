# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::filesystem' do
  context 'create the base locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the tools directory' do
      expect(chef_run).to create_directory('c:/languages')
    end

    it 'creates the tools directory' do
      expect(chef_run).to create_directory('c:/tools')
    end

    it 'creates the secrets directory' do
      expect(chef_run).to create_directory('c:/secrets')
    end
  end
end
