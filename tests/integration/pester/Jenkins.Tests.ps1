Describe 'The jenkins application' {
    Context 'is installed' {
        It 'with binaries in c:\ops\jenkins' {
            'c:\ops\jenkins\jenkins_service.exe' | Should Exist
            'c:\ops\jenkins\jenkins_service.exe.config' | Should Exist
            'c:\ops\jenkins\jenkins_service.xml' | Should Exist
            'c:\ops\jenkins\slave.jar' | Should Exist
            'c:\ops\jenkins\labels.txt' | Should Exist
            'c:\ops\jenkins\labels.txt.old' | Should Not Exist
        }

        It 'with jolokia binaries in c:\ops\jolokia' {
            'c:\ops\jolokia\jolokia.jar' | Should Exist
        }
    }

    Context 'has a redirected workspace directory' {
        It 'has a workspace directory' {
            'c:\ops\jenkins\workspace' | Should Exist
        }

        $dir = Get-Item 'c:\ops\jenkins\workspace'

        It 'is a symbolic link' {
            $dir.LinkType | Should Match 'SymbolicLink'
        }

        It 'that points to the correct target' {
            $dir.Target | Should Be 'd:\'
        }
    }

    Context 'has been made into a service' {
        $service = Get-Service jenkins

        It 'that is enabled' {
            $service.StartType | Should Match 'Automatic'
        }

        It 'and is running' {
            $service.Status | Should Match 'Running'
        }
    }
}
