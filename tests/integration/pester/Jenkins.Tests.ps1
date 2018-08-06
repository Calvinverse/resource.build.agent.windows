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

        It 'with environment variable pointing to the install location' {
            $env:JENKINS_HOME | Should Be 'c:\ops\jenkins'
        }
    }

    Context 'has been made into a service' {
        $service = Get-Service jenkins

        It 'that is enabled' {
            $service.StartType | Should Match 'Automatic'
        }

        It 'and is not running' {
            $service.Status | Should Match 'Stopped'
        }
    }
}
