function Initialize-CustomResource
{
    [CmdletBinding()]
    param()

    # For some reason we lose the workspace symbolic link if we create it with Chef. So we don't and create it
    # when provisioning the box

    $ErrorActionPreference = 'Stop'

    # NOTE: this assumes that the workspace drive has the label 'workspace' as set in the packer config
    # file. If you change the drive label, you have to change the script below as well.
    $workspaceDrive = Get-Volume -FileSystemLabel 'workspace'
    $workspaceDriveLetter = $workspaceDrive.DriveLetter

    $workspaceDirectory = 'c:\ops\jenkins\workspace'

    Write-Output "Creating the workspace directory as a symbolic link to $($workspaceDriveLetter)"
    New-Item -Path $workspaceDirectory -ItemType SymbolicLink -Value "$($workspaceDriveLetter):\\"

    $dir = Get-Item $workspaceDirectory
    Write-Output "Directory link type is: $($dir.LinkType)"
    Write-Output "Directory link target is: $($dir.Target)"
}
