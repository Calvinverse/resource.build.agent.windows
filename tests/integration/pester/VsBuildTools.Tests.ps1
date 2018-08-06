Describe 'The .NET build tools application' {
    Context 'are installed' {
        It 'with binaries in c:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools' {
            'c:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools' | Should Exist
            'c:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\bin\msbuild.exe' | Should Exist
            'c:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\bin\amd64\msbuild.exe' | Should Exist
        }

        It 'is on the PATH' {
            (& msbuild /version) | Should Not Be ''
        }
    }
}
