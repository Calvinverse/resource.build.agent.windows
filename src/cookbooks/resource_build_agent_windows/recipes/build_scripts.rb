# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: build_scripts
#
# Copyright 2018, P. van der Velde
#

#
# SET THE NBUILDKIT ENVIRONMENT VARIABLE
#

env 'NBUILDKIT_BUILDSERVER_ENVIRONMENT_DIR' do
  value ''
end

#
# CONSUL-TEMPLATE
#
