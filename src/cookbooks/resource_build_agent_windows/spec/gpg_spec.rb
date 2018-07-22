# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::gpg' do
  context 'create the base locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'imports the gnugpg::default recipe' do
      expect(chef_run).to include_recipe('gnugpg::default')
    end
  end
end
