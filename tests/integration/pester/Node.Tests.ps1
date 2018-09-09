Describe 'The node application' {
    Context 'node.js is installed' {
        It 'with binaries in c:\languages\node\nodejs' {
            'c:\languages\node\nodejs\node.exe' | Should Exist
        }

        It 'is on the PATH' {
            (& node --version) | Should Not Be ''
        }
    }

    Context 'npm is installed' {
        It 'with binaries in c:\languages\node\nodejs' {
            'c:\languages\node\nodejs\npm.cmd' | Should Exist
        }

        It 'is on the PATH' {
            (& npm --version) | Should Not Be ''
        }
    }
}
