# frozen_string_literal: true

#
# Cookbook Name:: resource_build_agent_windows
# Recipe:: jenkins
#
# Copyright 2018, P. van der Velde
#

# Configure the service user under which telegraf will be run
service_username = node['jenkins']['service']['user_name']
service_password = node['jenkins']['service']['user_password']

# Configure the service user under which jenkins will be run
# Make sure that the user password doesn't expire. The password is a random GUID, so it is unlikely that
# it will ever be guessed. And the user is a normal user who can't do anything so we don't really care about it
powershell_script 'jenkins_user_with_password_that_does_not_expire' do
  code <<~POWERSHELL
    $userName = '#{service_username}'
    $password = ConvertTo-SecureString -String '#{service_password}' -AsPlainText -Force
    $localUser = New-LocalUser `
      -Name $userName `
      -Password $password `
      -PasswordNeverExpires `
      -UserMayNotChangePassword `
      -AccountNeverExpires `
      -Verbose
  POWERSHELL
end

# Grant the user the LogOnAsService permission. Following this anwer on SO: http://stackoverflow.com/a/21235462/539846
# With some additional bug fixes to get the correct line from the export file and to put the correct text in the import file
powershell_script 'jenkins_user_grant_service_logon_rights' do
  code <<~POWERSHELL
    $ErrorActionPreference = 'Stop'

    $userName = '#{service_username}'

    $tempPath = "c:\\temp"
    if (-not (Test-Path $tempPath))
    {
        New-Item -Path $tempPath -ItemType Directory | Out-Null
    }

    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import)
    {
        Remove-Item -Path $import -Force
    }

    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export)
    {
        Remove-Item -Path $export -Force
    }

    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt)
    {
        Remove-Item -Path $secedt -Force
    }

    $sid = ((New-Object System.Security.Principal.NTAccount($userName)).Translate([System.Security.Principal.SecurityIdentifier])).Value

    secedit /export /cfg $export
    $line = (Select-String $export -Pattern "SeServiceLogonRight").Line
    $sids = $line.Substring($line.IndexOf('=') + 1).Trim()

    if (-not ($sids.Contains($sid)))
    {
        Write-Host ("Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $userName, $computerName)
        $lines = @(
                "[Unicode]",
                "Unicode=yes",
                "[System Access]",
                "[Event Audit]",
                "[Registry Values]",
                "[Version]",
                "signature=`"`$CHICAGO$`"",
                "Revision=1",
                "[Profile Description]",
                "Description=GrantLogOnAsAService security template",
                "[Privilege Rights]",
                "SeServiceLogonRight = $sids,*$sid"
            )
        foreach ($line in $lines)
        {
            Add-Content $import $line
        }

        secedit /import /db $secedt /cfg $import
        secedit /configure /db $secedt
        gpupdate /force
    }
    else
    {
        Write-Host ("User account: {0} on host: {1} already has SeServiceLogonRight." -f $userName, $computerName)
    }
  POWERSHELL
end

#
# DIRECTORIES
#

service_name = node['jenkins']['service']['name']
jenkins_bin_path = "#{node['paths']['ops']}/#{service_name}"
jolokia_bin_path = node['jolokia']['path']['jar']
%W[#{jenkins_bin_path} #{jolokia_bin_path}].each do |path|
  directory path do
    action :create
    inherits false
    rights :read_execute, service_username, applies_to_children: true, applies_to_self: true
    rights :full_control, 'Administrators', applies_to_children: true
  end
end

jenkins_logs_path = "#{node['paths']['logs']}/#{service_name}"
directory jenkins_logs_path do
  action :create
  rights :modify, service_username, applies_to_children: true, applies_to_self: false
end

jenkins_secrets_path = "#{node['paths']['secrets']}/#{service_name}"
directory jenkins_secrets_path do
  action :create
  inherits false
  rights :read_execute, service_username, applies_to_children: true, applies_to_self: false
  rights :full_control, 'Administrators', applies_to_children: true
end

#
# INSTALL JENKINS SWARM SLAVE
#

swarm_slave_jar = 'slave.jar'
swarm_slave_jar_path = "#{jenkins_bin_path}/#{swarm_slave_jar}"
remote_file swarm_slave_jar_path do
  action :create
  source node['jenkins']['url']['jar']
end

env 'JENKINS_HOME' do
  value jenkins_bin_path
end

#
# INSTALL JOLOKIA
#

jolokia_jar_path = node['jolokia']['path']['jar_file']
remote_file jolokia_jar_path do
  action :create
  source node['jolokia']['url']['jar']
end

#
# WINDOWS SERVICE
#

service_exe_name = node['jenkins']['service']['exe']
remote_file "#{jenkins_bin_path}/#{service_exe_name}.exe" do
  action :create
  source node['winsw']['url']
end

file "#{jenkins_bin_path}/#{service_exe_name}.exe.config" do
  action :create
  content <<~XML
    <configuration>
        <runtime>
            <generatePublisherEvidence enabled="false"/>
        </runtime>
    </configuration>
  XML
end

run_jenkins_script = "#{jenkins_bin_path}/Invoke-Jenkins.ps1"
file "#{jenkins_bin_path}/#{service_exe_name}.xml" do
  content <<~XML
    <?xml version="1.0"?>
    <service>
        <id>#{service_name}</id>
        <name>#{service_name}</name>
        <description>This service runs the jenkins build agent.</description>

        <executable>powershell.exe</executable>
        <argument>-NoLogo</argument>
        <argument>-NonInteractive</argument>
        <argument>-NoProfile</argument>
        <argument>-File</argument>
        <argument>"#{run_jenkins_script}"</argument>
        <stoptimeout>30sec</stoptimeout>

        <logpath>#{jenkins_logs_path}</logpath>
        <log mode="roll-by-size">
            <sizeThreshold>10240</sizeThreshold>
            <keepFiles>1</keepFiles>
        </log>
        <onfailure action="restart"/>
    </service>
  XML
  action :create
end

powershell_script 'jenkins_as_service' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    $securePassword = ConvertTo-SecureString "#{service_password}" -AsPlainText -Force

    # Note the .\\ is to get the local machine account as per here:
    # http://stackoverflow.com/questions/313622/powershell-script-to-change-service-account#comment14535084_315616
    $credential = New-Object pscredential((".\\" + "#{service_username}"), $securePassword)

    $service = Get-Service -Name '#{service_name}' -ErrorAction SilentlyContinue
    if ($service -eq $null)
    {
        New-Service `
            -Name '#{service_name}' `
            -BinaryPathName '#{jenkins_bin_path}/#{service_exe_name}.exe' `
            -Credential $credential `
            -DisplayName '#{service_name}' `
            -StartupType Disabled
    }

    # Set the service to restart if it fails
    sc.exe failure #{service_name} reset=86400 actions=restart/5000
  POWERSHELL
end

#
# NODE LABELS
#

jenkins_labels_file = node['jenkins']['file']['labels_file']
file jenkins_labels_file do
  action :create
  content <<~TXT
    windows
    windows_2016
    powershell
  TXT
end

#
# WORKSPACE SYMBOLIC LINK
#

# NOTE: this assumes that the workspace drive has the label 'workspace' as set in the packer config
# file. If you change the drive label, you have to change the script below as well.
powershell_script 'workspace_symbolic_link' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    $workspaceDrive = Get-Volume -FileSystemLabel 'workspace'
    $workspaceDriveLetter = $workspaceDrive.DriveLetter

    $workspaceDirectory = '#{jenkins_bin_path}/workspace'
    if (-not (Test-Path $workspaceDirectory))
    {
        New-Item -Path $workspaceDirectory -ItemType SymbolicLink -Value "$($workspaceDriveLetter):"
    }
  POWERSHELL
end

#
# CONSUL-TEMPLATE
#

consul_template_config_path = node['consul_template']['config_path']
consul_template_template_path = node['consul_template']['template_path']

jenkins_password_file = "#{jenkins_secrets_path}/user.txt"
jenkins_password_template_file = 'jenkins_swarm_password.ctmpl'
file "#{consul_template_template_path}/#{jenkins_password_template_file}" do
  action :create
  content <<~TXT
    {{ with secret "secret/environment/directory/users/build/agent" }}{{ if .Data.password }}{{ .Data.password }}{{ end }}{{ end }}
  TXT
end

file "#{consul_template_config_path}/jenkins_password_file.hcl" do
  action :create
  content <<~HCL
    # This block defines the configuration for a template. Unlike other blocks,
    # this block may be specified multiple times to configure multiple templates.
    # It is also possible to configure templates via the CLI directly.
    template {
      # This is the source file on disk to use as the input template. This is often
      # called the "Consul Template template". This option is required if not using
      # the `contents` option.
      source = "#{consul_template_template_path}/#{jenkins_password_template_file}"

      # This is the destination path on disk where the source template will render.
      # If the parent directories do not exist, Consul Template will attempt to
      # create them, unless create_dest_dirs is false.
      destination = "#{jenkins_password_file}"

      # This options tells Consul Template to create the parent directories of the
      # destination path if they do not exist. The default value is true.
      create_dest_dirs = false

      # This is the optional command to run when the template is rendered. The
      # command will only run if the resulting template changes. The command must
      # return within 30s (configurable), and it must have a successful exit code.
      # Consul Template is not a replacement for a process monitor or init system.
      command = ""

      # This is the maximum amount of time to wait for the optional command to
      # return. Default is 30s.
      command_timeout = "15s"

      # Exit with an error when accessing a struct or map field/key that does not
      # exist. The default behavior will print "<no value>" when accessing a field
      # that does not exist. It is highly recommended you set this to "true" when
      # retrieving secrets from Vault.
      error_on_missing_key = false

      # This is the permission to render the file. If this option is left
      # unspecified, Consul Template will attempt to match the permissions of the
      # file that already exists at the destination path. If no file exists at that
      # path, the permissions are 0644.
      perms = 0755

      # This option backs up the previously rendered template at the destination
      # path before writing a new one. It keeps exactly one backup. This option is
      # useful for preventing accidental changes to the data without having a
      # rollback strategy.
      backup = true

      # These are the delimiters to use in the template. The default is "{{" and
      # "}}", but for some templates, it may be easier to use a different delimiter
      # that does not conflict with the output file itself.
      left_delimiter  = "{{"
      right_delimiter = "}}"

      # This is the `minimum(:maximum)` to wait before rendering a new template to
      # disk and triggering a command, separated by a colon (`:`). If the optional
      # maximum value is omitted, it is assumed to be 4x the required minimum value.
      # This is a numeric time with a unit suffix ("5s"). There is no default value.
      # The wait value for a template takes precedence over any globally-configured
      # wait.
      wait {
        min = "2s"
        max = "10s"
      }
    }
  HCL
  mode '755'
end

jolokia_agent_host = node['jolokia']['agent']['host']
jolokia_agent_port = node['jolokia']['agent']['port']

jenkins_run_script_template_file = node['jenkins']['file']['consul_template_run_script_file']
file "#{consul_template_template_path}/#{jenkins_run_script_template_file}" do
  content <<~POWERSHELL
    [CmdletBinding()]
    param(
    )

    # =============================================================================

    function Invoke-Script
    {
        $process = New-JenkinsProcess
        while ($process -ne $null)
        {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Jenkins connection values not available"
            Start-Sleep -Seconds 5

            $process = New-JenkinsProcess
        }

        while (-not (Test-Path "#{jenkins_password_file}"))
        {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Connection credentials not available"
            Start-Sleep -Seconds 5
        }

        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Starting jenkins ... "
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Using arguments: $($startInfo.Arguments)"

        # Adding event handers for stdout and stderr.
        $writeToFileEvent = {
            if (-not ([String]::IsNullOrEmpty($EventArgs.Data)))
            {
                Out-File -FilePath $Event.MessageData -Append -InputObject $EventArgs.Data
            }
        }

        $stdOutEvent = Register-ObjectEvent `
          -InputObject $process `
          -Action $writeToFileEvent `
          -EventName 'OutputDataReceived' `
          -MessageData '#{jenkins_logs_path}/jenkins.out.log'
        $stdErrEvent = Register-ObjectEvent `
          -InputObject $process `
          -Action $writeToFileEvent `
          -EventName 'ErrorDataReceived' `
          -MessageData '#{jenkins_logs_path}/jenkins.err.log'

        try
        {
            $process.Start() | Out-Null
            try
            {
                $process.BeginOutputReadLine()
                $process.BeginErrorReadLine()

                while (-not ($process.HasExited))
                {
                    Start-Sleep -Seconds 5
                }
            }
            finally
            {
                if (-not ($process.HasExited))
                {
                    $process.Close()
                }
            }
        }
        finally
        {
            Unregister-Event -SourceIdentifier $stdOutEvent.Name
            Unregister-Event -SourceIdentifier $stdErrEvent.Name
        }

        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Jenkins stopped"
    }

    function New-JenkinsProcess
    {
        [CmdletBinding()]
        param()

    {{ if keyExists "config/services/consul/domain" }}
    {{ if keyExists "config/services/builds/protocols/http/host" }}
    {{ if keyExists "config/services/builds/protocols/http/port" }}
    {{ if keyExists "config/environment/directory/query/groups/builds/agent" }}
    {{ if keyExists "config/services/builds/protocols/http/virtualdirectory" }}
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = "java"
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        $arguments = '-server'
            + ' -XX:+AlwaysPreTouch'
            + ' -XX:+UseConcMarkSweepGC'
            + ' -XX:+ExplicitGCInvokesConcurrent'
            + ' -XX:+ParallelRefProcEnabled'
            + ' -XX:+UseStringDeduplication'
            + ' -XX:+CMSParallelRemarkEnabled'
            + ' -XX:+CMSIncrementalMode'
            + ' -XX:CMSInitiatingOccupancyFraction=75'
            + ' -Xmx500m'
            + ' -Xms500m'
            + ' -Djava.net.preferIPv4Stack=true'
            + ' -deleteExistingClients'
            + ' -disableClientsUniqueId'
            + ' -showHostName'
            + " -executors $($env:NUMBER_OF_PROCESSORS)"
            + ' -fsroot "#{jenkins_bin_path}"'
            + ' -labelsFile "#{jenkins_labels_file}"'
            + ' -master http://{{ key "config/services/builds/protocols/http/host" }}.service.{{ key "config/services/consul/domain" }}:{{ key "config/services/builds/protocols/http/port" }}/{{ key "config/services/builds/protocols/http/virtualdirectory" }}'
            + ' -mode EXCLUSIVE'
            + ' -username {{ key "config/environment/directory/query/groups/builds/agent" }}'
            + ' -passwordFile #{jenkins_password_file}'
            + ' -javaagent:#{jolokia_jar_path}=protocol=http,host=#{jolokia_agent_host},port=#{jolokia_agent_port},discoveryEnabled=false'
            + ' -jar #{swarm_slave_jar_path}'
        $startInfo.Arguments = $arguments

        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Starting jenkins ... "
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Using arguments: $($startInfo.Arguments)"
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo

        return $process

    {{ else }}
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/services/builds/protocols/http/virtualdirectory' not available. Will not start Jenkins."
        return $null
    {{ end }}
    {{ else }}
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/environment/directory/query/groups/builds/agent' not available. Will not start Jenkins."
        return $null
    {{ end }}
    {{ else }}
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/services/builds/protocols/http/port' not available. Will not start Jenkins."
        return $null
    {{ end }}
    {{ else }}
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/services/builds/protocols/http/host' not available. Will not start Jenkins."
        return $null
    {{ end }}
    {{ else }}
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/services/consul/domain' not available. Will not start Jenkins."
        return $null
    {{ end }}
    }

    # =============================================================================

    # Fire up
    Invoke-Script

    # Exit with a non-zero exit code so that the service never stops(?)
    exit(1)
  POWERSHELL
  action :create
end

file "#{consul_template_config_path}/jenkins_service_configuration.hcl" do
  action :create
  content <<~HCL
    # This block defines the configuration for a template. Unlike other blocks,
    # this block may be specified multiple times to configure multiple templates.
    # It is also possible to configure templates via the CLI directly.
    template {
      # This is the source file on disk to use as the input template. This is often
      # called the "Consul Template template". This option is required if not using
      # the `contents` option.
      source = "#{consul_template_template_path}/#{jenkins_run_script_template_file}"

      # This is the destination path on disk where the source template will render.
      # If the parent directories do not exist, Consul Template will attempt to
      # create them, unless create_dest_dirs is false.
      destination = "#{run_jenkins_script}"

      # This options tells Consul Template to create the parent directories of the
      # destination path if they do not exist. The default value is true.
      create_dest_dirs = false

      # This is the optional command to run when the template is rendered. The
      # command will only run if the resulting template changes. The command must
      # return within 30s (configurable), and it must have a successful exit code.
      # Consul Template is not a replacement for a process monitor or init system.
      command = "powershell.exe -noprofile -nologo -noninteractive -command \\"Restart-Service #{service_name}\\" "

      # This is the maximum amount of time to wait for the optional command to
      # return. Default is 30s.
      command_timeout = "15s"

      # Exit with an error when accessing a struct or map field/key that does not
      # exist. The default behavior will print "<no value>" when accessing a field
      # that does not exist. It is highly recommended you set this to "true" when
      # retrieving secrets from Vault.
      error_on_missing_key = false

      # This is the permission to render the file. If this option is left
      # unspecified, Consul Template will attempt to match the permissions of the
      # file that already exists at the destination path. If no file exists at that
      # path, the permissions are 0644.
      perms = 0755

      # This option backs up the previously rendered template at the destination
      # path before writing a new one. It keeps exactly one backup. This option is
      # useful for preventing accidental changes to the data without having a
      # rollback strategy.
      backup = true

      # These are the delimiters to use in the template. The default is "{{" and
      # "}}", but for some templates, it may be easier to use a different delimiter
      # that does not conflict with the output file itself.
      left_delimiter  = "{{"
      right_delimiter = "}}"

      # This is the `minimum(:maximum)` to wait before rendering a new template to
      # disk and triggering a command, separated by a colon (`:`). If the optional
      # maximum value is omitted, it is assumed to be 4x the required minimum value.
      # This is a numeric time with a unit suffix ("5s"). There is no default value.
      # The wait value for a template takes precedence over any globally-configured
      # wait.
      wait {
        min = "2s"
        max = "10s"
      }
    }
  HCL
  mode '755'
end

#
# CONSUL-TEMPLATE FILES FOR TELEGRAF
#

jolokia_agent_context = node['jolokia']['agent']['context']

telegraf_service = 'telegraf'
telegraf_config_directory = node['telegraf']['config_directory']
telegraf_jolokia_inputs_template_file = node['jolokia']['telegraf']['consul_template_inputs_file']
file "#{consul_template_template_path}/#{telegraf_jolokia_inputs_template_file}" do
  action :create
  content <<~CONF
    # Telegraf Configuration

    ###############################################################################
    #                            INPUT PLUGINS                                    #
    ###############################################################################

    [[inputs.jolokia2_agent]]
    urls = ["http://#{jolokia_agent_host}:#{jolokia_agent_port}/#{jolokia_agent_context}"]
      [inputs.jolokia2_agent.tags]
        influxdb_database = "services"
        service = "jenkins"
        build = "agent"

      # JVM metrics
      # Runtime
      [[inputs.jolokia2_agent.metric]]
        name  = "jvm_runtime"
        mbean = "java.lang:type=Runtime"
        paths = ["Uptime"]

      # Memory
      [[inputs.jolokia2_agent.metric]]
        name  = "jvm_memory"
        mbean = "java.lang:type=Memory"
        paths = ["HeapMemoryUsage", "NonHeapMemoryUsage", "ObjectPendingFinalizationCount"]

      # GC
      [[inputs.jolokia2_agent.metric]]
        name  = "jvm_garbage_collector"
        mbean = "java.lang:name=*,type=GarbageCollector"
        paths = ["CollectionTime", "CollectionCount"]
        tag_keys = ["name"]

      # MemoryPool
      [[inputs.jolokia2_agent.metric]]
        name  = "jvm_memory_pool"
        mbean = "java.lang:name=*,type=MemoryPool"
        paths = ["Usage", "PeakUsage", "CollectionUsage"]
        tag_keys = ["name"]
        tag_prefix = "pool_"

      # Operating system
      [[inputs.jolokia2_agent.metric]]
        name  = "jvm_operating_system"
        mbean = "java.lang:type=OperatingSystem"
        paths = [
          "CommittedVirtualMemorySize",
          "FreePhysicalMemorySize",
          "FreeSwapSpaceSize",
          "TotalPhysicalMemorySize",
          "TotalSwapSpaceSize",
          "AvailableProcessors",
          "SystemCpuLoad",
          "ProcessCpuTime",
          "ProcessCpuLoad",
          "SystemLoadAverage",
        ]

      # Java.nio
      # BufferPool
      [[inputs.jolokia2_agent.metric]]
        name  = "jvm_buffer_pool"
        mbean = "java.nio:name=*,type=MemoryPool"
        paths = ["TotalCapacity", "MemoryUsed", "Count"]
        tag_keys = ["name"]
        tag_prefix = "buffer_"
  CONF
  mode '755'
end

file "#{consul_template_config_path}/telegraf_jolokia_inputs.hcl" do
  action :create
  content <<~HCL
    # This block defines the configuration for a template. Unlike other blocks,
    # this block may be specified multiple times to configure multiple templates.
    # It is also possible to configure templates via the CLI directly.
    template {
      # This is the source file on disk to use as the input template. This is often
      # called the "Consul Template template". This option is required if not using
      # the `contents` option.
      source = "#{consul_template_template_path}/#{telegraf_jolokia_inputs_template_file}"

      # This is the destination path on disk where the source template will render.
      # If the parent directories do not exist, Consul Template will attempt to
      # create them, unless create_dest_dirs is false.
      destination = "#{telegraf_config_directory}/inputs_jolokia.conf"

      # This options tells Consul Template to create the parent directories of the
      # destination path if they do not exist. The default value is true.
      create_dest_dirs = false

      # This is the optional command to run when the template is rendered. The
      # command will only run if the resulting template changes. The command must
      # return within 30s (configurable), and it must have a successful exit code.
      # Consul Template is not a replacement for a process monitor or init system.
      command = "powershell.exe -noprofile -nologo -noninteractive -command \\"Restart-Service #{telegraf_service}\\" "

      # This is the maximum amount of time to wait for the optional command to
      # return. Default is 30s.
      command_timeout = "15s"

      # Exit with an error when accessing a struct or map field/key that does not
      # exist. The default behavior will print "<no value>" when accessing a field
      # that does not exist. It is highly recommended you set this to "true" when
      # retrieving secrets from Vault.
      error_on_missing_key = false

      # This is the permission to render the file. If this option is left
      # unspecified, Consul Template will attempt to match the permissions of the
      # file that already exists at the destination path. If no file exists at that
      # path, the permissions are 0644.
      perms = 0755

      # This option backs up the previously rendered template at the destination
      # path before writing a new one. It keeps exactly one backup. This option is
      # useful for preventing accidental changes to the data without having a
      # rollback strategy.
      backup = true

      # These are the delimiters to use in the template. The default is "{{" and
      # "}}", but for some templates, it may be easier to use a different delimiter
      # that does not conflict with the output file itself.
      left_delimiter  = "{{"
      right_delimiter = "}}"

      # This is the `minimum(:maximum)` to wait before rendering a new template to
      # disk and triggering a command, separated by a colon (`:`). If the optional
      # maximum value is omitted, it is assumed to be 4x the required minimum value.
      # This is a numeric time with a unit suffix ("5s"). There is no default value.
      # The wait value for a template takes precedence over any globally-configured
      # wait.
      wait {
        min = "2s"
        max = "10s"
      }
    }
  HCL
  mode '755'
end
