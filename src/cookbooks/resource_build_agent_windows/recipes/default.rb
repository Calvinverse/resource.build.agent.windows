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

include_recipe 'resource_build_agent_windows::java'

include_recipe 'resource_build_agent_windows::git'
include_recipe 'resource_build_agent_windows::gpg'
include_recipe 'resource_build_agent_windows::nuget'

include_recipe 'resource_build_agent_windows::net_build_tools'
include_recipe 'resource_build_agent_windows::net_core_build_tools'

include_recipe 'resource_build_agent_windows::nodejs'

include_recipe 'resource_build_agent_windows::jenkins'

include_recipe 'resource_build_agent_windows::provisioning'
