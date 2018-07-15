# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::meta' do
  context 'updates the environment variables' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'sets the RESOURCE_NAME environment variable' do
      expect(chef_run).to create_env('RESOURCE_NAME')
    end

    it 'sets the RESOURCE_SHORT_NAME environment variable' do
        expect(chef_run).to create_env('RESOURCE_SHORT_NAME')
      end

    it 'sets the RESOURCE_VERSION_MAJOR environment variable' do
      expect(chef_run).to create_env('RESOURCE_VERSION_MAJOR')
    end

    it 'sets the RESOURCE_VERSION_MINOR environment variable' do
      expect(chef_run).to create_env('RESOURCE_VERSION_MINOR')
    end

    it 'sets the RESOURCE_VERSION_PATCH environment variable' do
      expect(chef_run).to create_env('RESOURCE_VERSION_PATCH')
    end

    it 'sets the RESOURCE_VERSION_SEMANTIC environment variable' do
      expect(chef_run).to create_env('RESOURCE_VERSION_SEMANTIC')
    end

    it 'sets the STATSD_ENABLED_SERVICES environment variable' do
      expect(chef_run).to create_env('STATSD_ENABLED_SERVICES')
    end
  end
end
