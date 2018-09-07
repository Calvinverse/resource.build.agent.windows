# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::jenkins' do
  jenkins_logs_path = 'c:/logs/jenkins'
  jenkins_bin_path = 'c:/ops/jenkins'
  jolokia_bin_path = 'c:/ops/jolokia'
  jenkins_secrets_path = 'c:/secrets/jenkins'

  service_name = 'jenkins'
  run_jenkins_script = "#{jenkins_bin_path}/Invoke-Jenkins.ps1"

  context 'create the user to run the service with' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the jenkins user' do
      expect(chef_run).to run_powershell_script('jenkins_user_with_password_that_does_not_expire')
    end
  end

  context 'create the jenkins locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the jenkins base directory' do
      expect(chef_run).to create_directory(jenkins_bin_path)
    end

    it 'creates slave.jar in the jenkins ops directory' do
      expect(chef_run).to create_remote_file("#{jenkins_bin_path}/slave.jar")
    end
  end

  context 'create the jolokia locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the jolokia base directory' do
      expect(chef_run).to create_directory(jolokia_bin_path)
    end

    it 'creates jolokia.jar in the consul ops directory' do
      expect(chef_run).to create_remote_file("#{jolokia_bin_path}/jolokia.jar")
    end
  end

  context 'create the log locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the jenkins logs directory' do
      expect(chef_run).to create_directory(jenkins_logs_path)
    end
  end

  context 'create the secrets locations' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the jenkins secrets directory' do
      expect(chef_run).to create_directory(jenkins_secrets_path)
    end
  end

  context 'install jenkins as service' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    win_service_name = 'jenkins_service'
    it 'downloads the winsw file' do
      expect(chef_run).to create_remote_file("#{jenkins_bin_path}/#{win_service_name}.exe")
    end

    service_exe_config_content = <<~XML
      <configuration>
          <runtime>
              <generatePublisherEvidence enabled="false"/>
          </runtime>
      </configuration>
    XML
    it 'creates jenkins.exe.config in the jenkins ops directory' do
      expect(chef_run).to create_file("#{jenkins_bin_path}/#{win_service_name}.exe.config").with_content(service_exe_config_content)
    end

    jenkins_service_xml_content = <<~XML
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
    it 'creates jenkins.xml in the jenkins ops directory' do
      expect(chef_run).to create_file("#{jenkins_bin_path}/#{win_service_name}.xml").with_content(jenkins_service_xml_content)
    end

    it 'installs jenkins as service' do
      expect(chef_run).to run_powershell_script('jenkins_as_service')
    end
  end

  context 'creates the label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    labels_file_content = <<~TXT
      windows
      windows_2016
      powershell
    TXT
    it 'creates labels.txt in the jenkins ops directory' do
      expect(chef_run).to create_file("#{jenkins_bin_path}/labels.txt").with_content(labels_file_content)
    end
  end

  context 'create the consul-template files for jenkins' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    password_template_content = <<~TXT
      {{ with secret "secret/environment/directory/users/build/agent" }}{{ if .Data.password }}{{ .Data.password }}{{ end }}{{ end }}
    TXT
    it 'creates jenkins password file in the consul-template template directory' do
      expect(chef_run).to create_file('c:/config/consul-template/templates/jenkins_swarm_password.ctmpl')
        .with_content(password_template_content)
    end

    consul_template_jenkins_secrets_content = <<~CONF
      # This block defines the configuration for a template. Unlike other blocks,
      # this block may be specified multiple times to configure multiple templates.
      # It is also possible to configure templates via the CLI directly.
      template {
        # This is the source file on disk to use as the input template. This is often
        # called the "Consul Template template". This option is required if not using
        # the `contents` option.
        source = "c:/config/consul-template/templates/jenkins_swarm_password.ctmpl"

        # This is the destination path on disk where the source template will render.
        # If the parent directories do not exist, Consul Template will attempt to
        # create them, unless create_dest_dirs is false.
        destination = "#{jenkins_secrets_path}/user.txt"

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
    CONF
    it 'creates jenkins_password_file.hcl in the consul-template template directory' do
      expect(chef_run).to create_file('c:/config/consul-template/config/jenkins_password_file.hcl')
        .with_content(consul_template_jenkins_secrets_content)
    end

    jenkins_start_script_content = <<~POWERSHELL
      [CmdletBinding()]
      param(
      )

      # =============================================================================

      function Invoke-Script
      {
          $process = New-JenkinsProcess
          while ($process -eq $null)
          {
              Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Jenkins connection values not available"
              Start-Sleep -Seconds 5

              $process = New-JenkinsProcess
          }

          while (-not (Test-Path "#{jenkins_secrets_path}/user.txt"))
          {
              Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Connection credentials not available"
              Start-Sleep -Seconds 5
          }

          Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Starting jenkins ... "
          Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Using arguments: $($process.StartInfo.Arguments)"

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
      {{ if keyExists "config/environment/directory/users/builds/agent" }}
      {{ if keyExists "config/services/builds/protocols/http/virtualdirectory" }}
          $startInfo = New-Object System.Diagnostics.ProcessStartInfo
          $startInfo.FileName = "java"
          $startInfo.RedirectStandardOutput = $true
          $startInfo.RedirectStandardError = $true
          $startInfo.UseShellExecute = $false
          $startInfo.CreateNoWindow = $true

          $arguments = '-server' `
              + ' -XX:+AlwaysPreTouch' `
              + ' -XX:+UseConcMarkSweepGC' `
              + ' -XX:+ExplicitGCInvokesConcurrent' `
              + ' -XX:+ParallelRefProcEnabled' `
              + ' -XX:+UseStringDeduplication' `
              + ' -XX:+CMSParallelRemarkEnabled' `
              + ' -XX:+CMSIncrementalMode' `
              + ' -XX:CMSInitiatingOccupancyFraction=75' `
              + ' -Xmx500m' `
              + ' -Xms500m' `
              + ' -Djava.net.preferIPv4Stack=true' `
              + ' -Dfile.encoding=UTF8' `
              + ' -javaagent:#{jolokia_bin_path}/jolokia.jar=protocol=http,host=127.0.0.1,port=8090,discoveryEnabled=false' `
              + ' -jar #{jenkins_bin_path}/slave.jar' `
              + ' -deleteExistingClients' `
              + ' -disableClientsUniqueId' `
              + ' -showHostName' `
              + " -executors $($env:NUMBER_OF_PROCESSORS)" `
              + ' -fsroot "#{jenkins_bin_path}"' `
              + ' -labelsFile "#{jenkins_bin_path}/labels.txt"' `
              + ' -master http://{{ key "config/services/builds/protocols/http/host" }}.service.{{ key "config/services/consul/domain" }}:{{ key "config/services/builds/protocols/http/port" }}/{{ key "config/services/builds/protocols/http/virtualdirectory" }}' `
              + ' -mode exclusive' `
              + ' -username {{ key "config/environment/directory/users/builds/agent" }}' `
              + ' -passwordFile #{jenkins_secrets_path}/user.txt'
          $startInfo.Arguments = $arguments

          $process = New-Object System.Diagnostics.Process
          $process.StartInfo = $startInfo

          return $process

      {{ else }}
          Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/services/builds/protocols/http/virtualdirectory' not available. Will not start Jenkins."
          return $null
      {{ end }}
      {{ else }}
          Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - Consul K-V values at 'config/environment/directory/users/builds/agent' not available. Will not start Jenkins."
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
    it 'creates jenkins password file in the consul-template template directory' do
      expect(chef_run).to create_file('c:/config/consul-template/templates/jenkins_run_script.ctmpl')
        .with_content(jenkins_start_script_content)
    end

    consul_template_jenkins_startup_script_content = <<~CONF
      # This block defines the configuration for a template. Unlike other blocks,
      # this block may be specified multiple times to configure multiple templates.
      # It is also possible to configure templates via the CLI directly.
      template {
        # This is the source file on disk to use as the input template. This is often
        # called the "Consul Template template". This option is required if not using
        # the `contents` option.
        source = "c:/config/consul-template/templates/jenkins_run_script.ctmpl"

        # This is the destination path on disk where the source template will render.
        # If the parent directories do not exist, Consul Template will attempt to
        # create them, unless create_dest_dirs is false.
        destination = "#{jenkins_bin_path}/Invoke-Jenkins.ps1"

        # This options tells Consul Template to create the parent directories of the
        # destination path if they do not exist. The default value is true.
        create_dest_dirs = false

        # This is the optional command to run when the template is rendered. The
        # command will only run if the resulting template changes. The command must
        # return within 30s (configurable), and it must have a successful exit code.
        # Consul Template is not a replacement for a process monitor or init system.
        command = "powershell.exe -noprofile -nologo -noninteractive -command \\"Set-Service #{service_name} -StartupType Automatic; Restart-Service #{service_name}\\" "

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
    CONF
    it 'creates jenkins_service_configuration.hcl in the consul-template template directory' do
      expect(chef_run).to create_file('c:/config/consul-template/config/jenkins_service_configuration.hcl')
        .with_content(consul_template_jenkins_startup_script_content)
    end

    telegraf_jolokia_config_content = <<~CONF
      # Telegraf Configuration

      ###############################################################################
      #                            INPUT PLUGINS                                    #
      ###############################################################################

      [[inputs.jolokia2_agent]]
      urls = ["http://127.0.0.1:8090/jolokia"]
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
    it 'creates telegraf jolokia template file in the consul-template template directory' do
      expect(chef_run).to create_file('c:/config/consul-template/templates/telegraf_jolokia_inputs.ctmpl')
        .with_content(telegraf_jolokia_config_content)
    end

    consul_template_telegraf_jolokia_content = <<~CONF
      # This block defines the configuration for a template. Unlike other blocks,
      # this block may be specified multiple times to configure multiple templates.
      # It is also possible to configure templates via the CLI directly.
      template {
        # This is the source file on disk to use as the input template. This is often
        # called the "Consul Template template". This option is required if not using
        # the `contents` option.
        source = "c:/config/consul-template/templates/telegraf_jolokia_inputs.ctmpl"

        # This is the destination path on disk where the source template will render.
        # If the parent directories do not exist, Consul Template will attempt to
        # create them, unless create_dest_dirs is false.
        destination = "c:/config/telegraf/inputs_jolokia.conf"

        # This options tells Consul Template to create the parent directories of the
        # destination path if they do not exist. The default value is true.
        create_dest_dirs = false

        # This is the optional command to run when the template is rendered. The
        # command will only run if the resulting template changes. The command must
        # return within 30s (configurable), and it must have a successful exit code.
        # Consul Template is not a replacement for a process monitor or init system.
        command = "powershell.exe -noprofile -nologo -noninteractive -command \\"Restart-Service telegraf\\" "

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
    CONF
    it 'creates telegraf_jolokia_inputs.hcl in the consul-template template directory' do
      expect(chef_run).to create_file('c:/config/consul-template/config/telegraf_jolokia_inputs.hcl')
        .with_content(consul_template_telegraf_jolokia_content)
    end
  end
end
