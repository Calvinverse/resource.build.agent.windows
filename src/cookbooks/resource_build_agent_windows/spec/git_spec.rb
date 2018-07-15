# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::git' do
  context 'create the base locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'imports the git::windows recipe' do
      expect(chef_run).to include_recipe('git::windows')
    end
  end
end
