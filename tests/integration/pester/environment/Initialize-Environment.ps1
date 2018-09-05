function Get-IpAddress
{
    $ErrorActionPreference = 'Stop'

    $interface = Get-NetIPConfiguration |
        Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.NetProfile.IPv4Connectivity -ne 'NoTraffic' } |
        Select-Object -First 1
    return $interface.IPv4Address.IPAddress
}

function Initialize-Environment
{
    $ErrorActionPreference = 'Stop'

    try
    {
        Start-TestConsul

        Install-Vault -vaultVersion '0.9.1'
        Start-TestVault

        Write-Output "Waiting for 10 seconds for consul and vault to start ..."
        Start-Sleep -Seconds 10

        Set-VaultSecrets
        Set-ConsulKV

        Join-Cluster

        Write-Output "Waiting 30 seconds for Consul-Template to be active ..."
        $ts = New-TimeSpan -Seconds 30
        $killTime = (Get-Date) + $ts
        while ((Get-Date) -lt $killTime)
        {
            if (((Get-Service -Name 'consul-template').Status -eq 'Running'))
            {
                Write-Output "Consul-Template is running"
                break
            }
            else
            {
                Start-Sleep -Seconds 2
            }
        }

        Write-Output "Giving Consul-Template 90 seconds to process the data ..."
        Start-Sleep -Seconds 90
    }
    catch
    {
        $currentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        try
        {
            Write-Error $errorRecord.Exception
            Write-Error $errorRecord.ScriptStackTrace
            Write-Error $errorRecord.InvocationInfo.PositionMessage
        }
        finally
        {
            $ErrorActionPreference = $currentErrorActionPreference
        }

        # rethrow the error
        throw $_.Exception
    }
}

function Install-Vault
{
    [CmdletBinding()]
    param(
        [string] $vaultVersion
    )

    $ErrorActionPreference = 'Stop'

    #& wget "https://releases.hashicorp.com/vault/$($vaultVersion)/vault_$($vaultVersion)_linux_amd64.zip" --output-document /test/vault.zip
    #& unzip /test/vault.zip -d /test/vault
}

function Join-Cluster
{
    $ErrorActionPreference = 'Stop'

    Write-Output "Joining the local consul ..."

    # connect to the actual local consul instance
    $ipAddress = Get-IpAddress
    Write-Output "Joining: $($ipAddress):8351"

    Start-Process -FilePath 'c:\ops\consul\consul.exe' -ArgumentList "join $($ipAddress):8351"

    Write-Output "Getting members for client"
    & 'c:\ops\consul\consul.exe' members

    Write-Output "Getting members for server"
    & 'c:\ops\consul\consul.exe' members -http-addr=http://127.0.0.1:8550
}

function Set-ConsulKV
{
    $ErrorActionPreference = 'Stop'

    Write-Output "Setting consul key-values ..."

    # load config/environment/directory
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/environment/directory/users/builds/agent 'build.agent'

    # Load config/services/consul
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/consul/datacenter 'test-integration'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/consul/domain 'integrationtest'

    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/consul/metrics/statsd/rules '\"consul.*.*.* .measurement.measurement.field\",'

    # load config/services/builds
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/builds/protocols/http/host 'active.builds'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/builds/protocols/http/port '8080'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/builds/protocols/http/virtualdirectory 'builds'

    # Explicitly don't provide a metrics address because that means telegraf will just send the metrics to
    # a black hole
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/metrics/databases/system 'system'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/metrics/databases/statsd 'statsd'

    # load config/services/queue
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/http/host 'http.queue'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/http/port '15672'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/amqp/host 'amqp.queue'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/amqp/port '5672'

    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/queue/logs/syslog/username 'testuser'
    & 'c:\ops\consul\consul.exe' kv put -http-addr=http://127.0.0.1:8550 config/services/queue/logs/syslog/vhost 'testlogs'
}

function Set-VaultSecrets
{
    $ErrorActionPreference = 'Stop'

    Write-Output 'Setting vault secrets ...'

    # secret/services/queue/logs/syslog
}

function Start-TestConsul
{
    $ErrorActionPreference = 'Stop'

    Write-Output "Starting consul ..."
    $process = Start-Process `
        -FilePath 'c:\ops\consul\consul.exe' `
        -ArgumentList "agent -config-file c:\temp\pester\environment\consul.json" `
        -PassThru `
        -RedirectStandardOutput c:\temp\pester\environment\consuloutput.out `
        -RedirectStandardError c:\temp\pester\environment\consulerror.out

    Write-Output "Going to sleep for 10 seconds ..."
    Start-Sleep -Seconds 10
}

function Start-TestVault
{
    [CmdletBinding()]
    param(
    )

    $ErrorActionPreference = 'Stop'

    Write-Output "Starting vault ..."
    # $process = Start-Process `
    #     -FilePath '/test/vault/vault' `
    #     -ArgumentList "-dev" `
    #     -PassThru `
    #     -RedirectStandardOutput /test/vault/vaultoutput.out `
    #     -RedirectStandardError /test/vault/vaulterror.out
}
