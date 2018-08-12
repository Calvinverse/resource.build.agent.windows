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

    Context 'has been made into a service' {
        $service = Get-Service jenkins

        It 'that is disabled' {
            $service.StartType | Should Match 'Disabled'
        }

        It 'and is not running' {
            $service.Status | Should Match 'Stopped'
        }
    }
}
