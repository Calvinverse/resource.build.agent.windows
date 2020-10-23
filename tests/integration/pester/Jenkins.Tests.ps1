Describe 'The jenkins application' {
    Context 'is installed' {
        It 'with binaries in d:\ci' {
            'd:\ci\jenkins_service.exe' | Should Exist
            'd:\ci\jenkins_service.exe.config' | Should Exist
            'd:\ci\jenkins_service.xml' | Should Exist
            'd:\ci\slave.jar' | Should Exist
            'd:\ci\labels.txt' | Should Exist
            'd:\ci\labels.txt.old' | Should Not Exist
        }

        It 'with jolokia binaries in c:\ops\jolokia' {
            'c:\ops\jolokia\jolokia.jar' | Should Exist
        }
    }

    Context 'has a ci directory' {
        It 'has a ci directory' {
            'd:\ci' | Should Exist
        }

        $acl = Get-Acl 'd:/ci'
        $access = $acl.Access
        It 'has the correct permissions' {
            $access[0].IdentityReference | Should Be 'BUILTIN\Administrators'
            $access[0].FileSystemRights | Should Be 'FullControl'
            $access[0].AccessControlType | Should Be 'Allow'

            $access[1].IdentityReference | Should Be 'BUILTIN\Administrators'
            $access[1].FileSystemRights | Should Be '268435456'
            $access[1].AccessControlType | Should Be 'Allow'

            $access[2].IdentityReference | Should BeLike '*\jenkins_user'
            $access[2].FileSystemRights | Should Be 'Modify, Synchronize'
            $access[2].AccessControlType | Should Be 'Allow'
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
