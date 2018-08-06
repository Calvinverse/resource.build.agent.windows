Describe 'The nuget application' {
    Context 'is installed' {
        It 'with binaries in c:\tools\nuget' {
            'C:\tools\nuget\nuget.exe' | Should Exist
        }

        It 'is on the PATH' {
            (& nuget) | Should Not Be ''
        }
    }
}
