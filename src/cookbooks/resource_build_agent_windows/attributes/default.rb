# frozen_string_literal: true

# Variables

config_path = 'c:/config'
languages_path = 'c:/languages'
logs_path = 'c:/logs'
ops_path = 'c:/ops'
secrets_path = 'c:/secrets'
temp_path = 'c:/temp'
tools_path = 'c:/tools'

# Make sure the casing of the D-drive is the same as what Windows thinks it should be because
# jenkins will use the value of this variable but NPM builds that run on the box will use
# the windows path, which means path comparisons will go wrong because NPM doesn't understand
# that Windows paths are case-insensitive (or probably more likely the tests don't understand
# that)
ci_path = 'D:/ci'

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

default['git']['version'] = '2.24.0.2'
default['git']['architecture'] = '64'
default['git']['checksum'] = 'AF679D8B3DBEB84C95C6C7F3BE2F200A58D85201552CA0594FB7A3F4EE99CB38'
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
default['jenkins']['service']['user_name'] = 'jenkins_user' # This user name is also in the Initialize-CustomResource.ps1 script
default['jenkins']['service']['user_password'] = SecureRandom.uuid

default['jenkins']['version'] = '3.17'
default['jenkins']['checksum'] = 'F5480B39BB54F8D7A91749E61D34199AA533F9CEB1D329EDCC6D404BEEC3A617'
default['jenkins']['url']['jar'] = "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/#{node['jenkins']['version']}/swarm-client-#{node['jenkins']['version']}.jar"

default['jenkins']['file']['consul_template_run_script_file'] = 'jenkins_run_script.ctmpl'
default['jenkins']['file']['labels_file'] = "#{ci_path}/labels.txt"

#
# JOLOKIA
#

default['jolokia']['path']['jar'] = "#{ops_path}/jolokia"
default['jolokia']['path']['jar_file'] = "#{node['jolokia']['path']['jar']}/jolokia.jar"

default['jolokia']['agent']['context'] = 'jolokia' # Set this to default because the runtime gets angry otherwise
default['jolokia']['agent']['host'] = '127.0.0.1' # Windows prefers going to IPv6, but Jolokia hates IPv6
default['jolokia']['agent']['port'] = 8090

default['jolokia']['telegraf']['consul_template_inputs_file'] = 'telegraf_jolokia_inputs.ctmpl'

default['jolokia']['version'] = '1.6.2'
default['jolokia']['checksum'] = '95EEF794790AA98CFA050BDE4EC67A4E42C2519E130E5E44CE40BF124584F323'
default['jolokia']['url']['jar'] = "http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/#{node['jolokia']['version']}/jolokia-jvm-#{node['jolokia']['version']}-agent.jar"

#
# .NET BUILD TOOLS
#

default['net_visual_studio']['url'] = 'https://aka.ms/vs/16/release/vs_enterprise.exe'
default['msbuild']['path']['bin']['x64'] = 'C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/Bin/amd64'
default['msbuild']['path']['bin']['x86'] = 'C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/Bin'

default['net_48_sdk']['url'] = 'https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe'

#
# NODE / NPM / YARN
#

default['nodejs']['path']['base'] = "#{languages_path}/node"
default['nodejs']['version'] = '10.16.0'

default['nvm']['version'] = '1.1.7'
default['nvm']['checksum'] = 'E849BD99ACE4C4D4D194409C3FB2858DF2B775423ACF6B099A8ACF3443ABD17C'
default['nvm']['url'] = "https://github.com/coreybutler/nvm-windows/releases/download/#{node['nvm']['version']}/nvm-noinstall.zip"

default['nvm']['path']['bin'] = "#{node['nodejs']['path']['base']}/nvm"
default['nvm']['path']['symlink'] = "#{node['nodejs']['path']['base']}/nodejs"
default['nvm']['path']['exe'] = "#{node['nvm']['path']['bin']}/nvm.exe"

default['npm']['version'] = '6.9.0'
default['npm']['path']['cache'] = 'e:/npm'

default['yarn']['version'] = '1.17.3'
default['yarn']['checksum'] = '46E618592076FF2882A5D7E1D4F8D0FFB8B29918A6366A1FEA0F0BBDF145A4FA'
default['yarn']['url'] = "https://github.com/yarnpkg/yarn/releases/download/v#{node['yarn']['version']}/yarn-#{node['yarn']['version']}.msi"

default['yarn']['path']['cache'] = 'e:/yarn'

#
# NUGET
#

# default['nuget']['version'] = '5.1.0'
# default['nuget']['checksum'] = '0ACE4F53493332C9A75291EE96ACD76B371B4E687175E4852BF85948176D7152'
default['nuget']['version'] = '4.3.1'
default['nuget']['checksum'] = '17923EBA46EC6FFF200928F862DAA9038742417034353E2407C3B46B3491E206'
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
# BUILDSCRIPTS
#

default['buildscripts']['path']['config'] = "#{config_path}/builds"

#
# WINSW
#

default['winsw']['version'] = '2.2.0'
default['winsw']['url'] = "https://github.com/kohsuke/winsw/releases/download/winsw-v#{node['winsw']['version']}/WinSW.NET4.exe"

default['winsw']['path']['bin'] = "#{ops_path}/winsw"
