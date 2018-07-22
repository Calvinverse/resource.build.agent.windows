# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: gpg
#
# Copyright 2018, P. van der Velde
#

#
# INSTALL GPG
#

include_recipe 'gnugpg::default'

#
# ADD TO THE JENKINS LABELS FILE
#

jenkins_labels_file = node['jenkins']['file']['labels_file']
ruby_block 'add_gpg_label' do
  block do
    file = Chef::Util::FileEdit.new(jenkins_labels_file)
    file.insert_line_if_no_match('gpg', 'gpg')
    file.write_file
  end
end
