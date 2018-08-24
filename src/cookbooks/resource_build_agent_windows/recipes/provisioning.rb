# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: provisioning.rb
#
# Copyright 2018, P. van der Velde
#

provisioning_bin_path = node['provisioning']['path']['bin']

custom_provisioning_script = 'Initialize-CustomResource.ps1'
cookbook_file "#{provisioning_bin_path}/#{custom_provisioning_script}" do
  action :create
  source custom_provisioning_script
end
