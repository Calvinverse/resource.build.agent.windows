# frozen_string_literal: true

# Variables

config_path = 'c:/config'
languages_path = 'c:/languages'
logs_path = 'c:/logs'
ops_path = 'c:/ops'
secrets_path = 'c:/secrets'
temp_path = 'c:/temp'
tools_path = 'c:/tools'
ci_path = 'd:/ci'

#
# CONSULTEMPLATE
#

default['consul_template']['service']['name'] = 'consul-template'
default['consul_template']['config_path'] = "#{config_path}/#{node['consul_template']['service']['name']}/config"
default['consul_template']['template_path'] = "#{config_path}/#{node['consul_template']['service']['name']}/templates"

#
# FILESYSTEM
#

default['paths']['config'] = config_path
default['paths']['languages'] = languages_path
default['paths']['logs'] = logs_path
default['paths']['ops'] = ops_path
default['paths']['secrets'] = secrets_path
default['paths']['temp'] = temp_path
default['paths']['tools'] = tools_path
default['paths']['ci'] = ci_path

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

default['git']['version'] = '2.20.1'
default['git']['architecture'] = '64'
default['git']['checksum'] = '0dce453188d4aed938e3fd1919393a3600dd3dfe100f3fc92f54f80e372e031f'
default['git']['url'] = "https://github.com/git-for-windows/git/releases/download/v#{node['git']['version']}.windows.1/Git-#{node['git']['version']}-#{node['git']['architecture']}-bit.exe"
default['git']['display_name'] = "Git version #{node['git']['version']}"

#
# JAVA
#

default['java']['version']['major'] = '11'
default['java']['version']['complete'] = "#{node['java']['version']['major']}.0.2"
default['java']['architecture'] = '64'
default['java']['url'] = "https://download.java.net/java/GA/jdk#{node['java']['version']['major']}/9/GPL/openjdk-#{node['java']['version']['complete']}_windows-x#{node['java']['architecture']}_bin.zip"

default['java']['path']['base'] = "#{languages_path}/java"

#
# JENKINS
#

default['jenkins']['service']['exe'] = 'jenkins_service'
default['jenkins']['service']['name'] = 'jenkins'
default['jenkins']['service']['user_name'] = 'jenkins_user'
default['jenkins']['service']['user_password'] = SecureRandom.uuid

default['jenkins']['version'] = '3.15'
default['jenkins']['checksum'] = '6812E86A220D2D6C4D3FFFABD646B7BB19A4144693958B2A943FA6B845F081B1'
default['jenkins']['url']['jar'] = "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/#{node['jenkins']['version']}/swarm-client-#{node['jenkins']['version']}.jar"

default['jenkins']['file']['consul_template_run_script_file'] = 'jenkins_run_script.ctmpl'
default['jenkins']['file']['labels_file'] = "#{ops_path}/#{node['jenkins']['service']['name']}/labels.txt"

#
# JOLOKIA
#

default['jolokia']['path']['jar'] = "#{ops_path}/jolokia"
default['jolokia']['path']['jar_file'] = "#{node['jolokia']['path']['jar']}/jolokia.jar"

default['jolokia']['agent']['context'] = 'jolokia' # Set this to default because the runtime gets angry otherwise
default['jolokia']['agent']['host'] = '127.0.0.1' # Windows prefers going to IPv6, but Jolokia hates IPv6
default['jolokia']['agent']['port'] = 8090

default['jolokia']['telegraf']['consul_template_inputs_file'] = 'telegraf_jolokia_inputs.ctmpl'

default['jolokia']['version'] = '1.6.0'
default['jolokia']['checksum'] = '40123D4728CB62BF7D4FD3C8DE7CF3A0F955F89453A645837E611BA8E6924E02'
default['jolokia']['url']['jar'] = "http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/#{node['jolokia']['version']}/jolokia-jvm-#{node['jolokia']['version']}-agent.jar"

#
# .NET BUILD TOOLS
#

default['net_visual_studio']['url'] = 'https://aka.ms/vs/16/release/vs_enterprise.exe'

#
# NODE / NPM / YARN
#

default['nodejs']['path']['base'] = "#{languages_path}/node"
default['nodejs']['version'] = '8.14.1'

default['nvm']['version'] = '1.1.7'
default['nvm']['checksum'] = 'E849BD99ACE4C4D4D194409C3FB2858DF2B775423ACF6B099A8ACF3443ABD17C'
default['nvm']['url'] = "https://github.com/coreybutler/nvm-windows/releases/download/#{node['nvm']['version']}/nvm-noinstall.zip"

default['nvm']['path']['bin'] = "#{node['nodejs']['path']['base']}/nvm"
default['nvm']['path']['symlink'] = "#{node['nodejs']['path']['base']}/nodejs"
default['nvm']['path']['exe'] = "#{node['nvm']['path']['bin']}/nvm.exe"

default['npm']['version'] = '6.5.0'
default['npm']['path']['cache'] = 'e:/npm'
default['yarn']['path']['cache'] = 'e:/yarn'

#
# NUGET
#

default['nuget']['version'] = '4.9.2'
default['nuget']['checksum'] = 'DD283B92D03FAFF8F8816D631A8C859FEAE6C0CE260FE68AE7E61849A157821F'
default['nuget']['url'] = "https://dist.nuget.org/win-x86-commandline/v#{node['nuget']['version']}/nuget.exe"

default['nuget']['path']['exe'] = "#{tools_path}/nuget"
default['nuget']['path']['exe_file'] = "#{node['nuget']['path']['exe']}/nuget.exe"
default['nuget']['path']['cache'] = 'e:/nuget'

#
# PROVISIONING
#

default['provisioning']['path']['bin'] = "#{node['paths']['ops']}/provisioning"

#
# TELEGRAF
#

default['telegraf']['service']['name'] = 'telegraf'
default['telegraf']['config_directory'] = "#{config_path}/#{node['telegraf']['service']['name']}"

#
# WINSW
#

default['winsw']['version'] = '2.1.2'
default['winsw']['url'] = "https://github.com/kohsuke/winsw/releases/download/winsw-v#{node['winsw']['version']}/WinSW.NET4.exe"

default['winsw']['path']['bin'] = "#{ops_path}/winsw"
