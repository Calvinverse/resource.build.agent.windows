# frozen_string_literal: true

# Variables

config_path = 'c:/config'
logs_path = 'c:/logs'
ops_path = 'c:/ops'
temp_path = 'c:/temp'
tools_path = 'c:/tools'

#
# CONSULTEMPLATE
#

default['consul_template']['config_path'] = "#{config_path}/#{node['consul_template']['service']['name']}/config"
default['consul_template']['template_path'] = "#{config_path}/#{node['consul_template']['service']['name']}/templates"

#
# FILESYSTEM
#

default['paths']['config'] = config_path
default['paths']['logs'] = logs_path
default['paths']['ops'] = ops_path
default['paths']['temp'] = temp_path
default['paths']['tools'] = tools_path

#
# FIREWALL
#

# Allow communication via WinRM
default['firewall']['allow_winrm'] = true

# Allow communication on the loopback address (127.0.0.1 and ::1)
default['firewall']['allow_loopback'] = true

# Do not allow MOSH connections
default['firewall']['allow_mosh'] = false

# do not allow SSH
default['firewall']['allow_ssh'] = false

# No communication via IPv6 at all
default['firewall']['ipv6_enabled'] = false

default['firewall']['paths']['logs'] = "#{logs_path}/firewall"

#
# GIT
#

default['git']['version'] = '2.18.0'
default['git']['architecture'] = '64'
default['git']['checksum'] = 'aa81c9f2a81fd07ba0582095474365821880fd787b1cbe03abaf71d9aa69d359'
default['git']['url'] = 'https://github.com/git-for-windows/git/releases/download/v%{version}.windows.1/Git-%{version}-%{architecture}-bit.exe'
default['git']['display_name'] = "Git version #{node['git']['version']}"

#
# TELEGRAF
#

default['telegraf']['config_directory'] = "#{config_path}/#{node['telegraf']['service']['name']}"
