Describe 'The git application' {
    Context 'is installed' {
        It 'with binaries in c:\Program Files\Git' {
            'C:\Program Files\Git\cmd\git.exe' | Should Exist
        }

        It 'is on the PATH' {
            (& git --version) | Should Not Be ''
        }
    }
}
