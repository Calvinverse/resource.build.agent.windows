# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: filesystem
#
# Copyright 2018, P. van der Velde
#

tools_directory = node['paths']['tools']
%W[#{tools_directory}].each do |path|
  directory path do
    action :create
    rights :read, 'Everyone', applies_to_children: true
    rights :modify, 'Administrators', applies_to_children: true
  end
end

secrets_directory = node['paths']['secrets']
directory secrets_directory do
  action :create
  inherits false
  rights :modify, 'Administrators', applies_to_children: true
end
