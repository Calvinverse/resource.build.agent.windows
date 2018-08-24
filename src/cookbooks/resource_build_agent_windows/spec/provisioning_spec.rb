# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::provisioning' do
  provisioning_bin_path = 'c:/ops/provisioning'

  provisioning_custom_script = 'Initialize-CustomResource.ps1'
  context 'create the provisioning custom scripts' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates Initialize-CustomResource.ps1 in the provisioning ops directory' do
      expect(chef_run).to create_cookbook_file("#{provisioning_bin_path}/#{provisioning_custom_script}").with_source(provisioning_custom_script)
    end
  end
end
