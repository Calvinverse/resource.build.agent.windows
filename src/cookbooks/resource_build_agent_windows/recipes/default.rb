# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: default
#
# Copyright 2018, P. van der Velde
#

#
# Include the local recipes
#

include_recipe 'resource_build_agent_windows::filesystem'
include_recipe 'resource_build_agent_windows::firewall'

include_recipe 'resource_build_agent_windows::meta'

include_recipe 'resource_build_agent_windows::provisioning'
