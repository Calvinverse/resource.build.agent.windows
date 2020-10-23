function Initialize-CustomResource
{
    [CmdletBinding()]
    param()

    # When we sysprep the box the SIDs for the users are changes. All files on the OS volume are updated
    # but the ones on the non-OS volumes are not: see: http://technet.microsoft.com/en-us/library/hh825209.aspx
    # So the Jenkins user loses its access to the  d:\ci folder. So we have to put them back

    $ErrorActionPreference = 'Stop'

    # NOTE: this assumes that the workspace drive has the label 'workspace' as set in the packer config
    # file. If you change the drive label, you have to change the script below as well.
    $workspaceDrive = Get-Volume -FileSystemLabel 'workspace'
    $workspaceDriveLetter = $workspaceDrive.DriveLetter

    $ciPath = Join-Path "$($workspaceDriveLetter):" 'ci'
    $acl = Get-ACL -Path $ciPath

    $acl.SetAccessRuleProtection($True, $True)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'jenkins_user',
        "Modify",
        "ContainerInherit, ObjectInherit",
        "None",
        "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $ciPath $acl
}
