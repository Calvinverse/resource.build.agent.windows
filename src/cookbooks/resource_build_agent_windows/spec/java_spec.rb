# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::java' do
  context 'installs java' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the java language directory' do
      expect(chef_run).to create_directory('c:/languages/java')
    end

    it 'extracts the java zip file to in the bin directory' do
      expect(chef_run).to extract_seven_zip_archive('c:/languages/java')
    end
  end
end
