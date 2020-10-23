Describe 'The .NET build tools application' {
    Context 'are installed' {
        It 'with binaries in c:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise' {
            'c:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise' | Should Exist
            'c:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\bin\msbuild.exe' | Should Exist
            'c:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\bin\amd64\msbuild.exe' | Should Exist
        }

        $output = & msbuild /version
        It 'is on the PATH' {
            $output | Should Not Be $null
            $output.Length | Should BeGreaterThan 0
        }
    }
}
