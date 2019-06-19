# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::filesystem' do
  context 'allows long paths' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    # Note that the value - data is the MD5 hash of 0. See: https://github.com/chefspec/chefspec/issues/629
    it 'sets the registry key' do
      expect(chef_run).to create_registry_key('HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\FileSystem').with(
        values: [{
          name: 'LongPathsEnabled',
          type: :dword,
          data: '6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b'
        }]
      )
    end
  end

  context 'create the base locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the languages directory' do
      expect(chef_run).to create_directory('c:/languages')
    end

    it 'creates the secrets directory' do
      expect(chef_run).to create_directory('c:/secrets')
    end
  end
end
