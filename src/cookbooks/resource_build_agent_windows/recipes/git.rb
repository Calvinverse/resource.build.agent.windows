# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: git
#
# Copyright 2018, P. van der Velde
#

include_recipe 'git::windows'

#
# ADD GIT TO THE PATH
#

windows_path 'c:/Progam Files/Git/cmd' do
  action :add
end
