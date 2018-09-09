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

windows_path 'c:/Program Files/Git/cmd' do
  action :add
end

#
# ADD TO THE JENKINS LABELS FILE
#

jenkins_labels_file = node['jenkins']['file']['labels_file']
ruby_block 'add_git_label' do
  block do
    file = Chef::Util::FileEdit.new(jenkins_labels_file)
    file.insert_line_if_no_match('git', 'git')
    file.write_file
  end
end

# Chef::Util::FileEdit creates the .old file when it inserts the line.
# We don't want this file so nuke it.
file "#{jenkins_labels_file}.old" do
  action :delete
end
