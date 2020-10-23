# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: java
#
# Copyright 2018, P. van der Velde
#

#
# INSTALL JAVA JDK
#

# Do this the hard way because the java cookbook can only install oracle packages for windows

java_base_directory = node['java']['path']['base']
directory java_base_directory do
  action :create
end

# Download the java installer from the openjdk archive page
java_zip_path = "#{node['paths']['temp']}/java.zip"
remote_file java_zip_path do
  action :create
  source node['java']['url']
end

java_bin_path = node['java']['path']['base']
seven_zip_archive java_bin_path do
  overwrite true
  source java_zip_path
  timeout 30
end
