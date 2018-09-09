Describe 'The nuget application' {
    Context 'is installed' {
        It 'with binaries in c:\tools\nuget' {
            'C:\tools\nuget\nuget.exe' | Should Exist
        }

        $output = & nuget
        It 'is on the PATH' {
            $output | Should Not Be $null
            $output.Length | Should BeGreaterThan 0
        }
    }
}
