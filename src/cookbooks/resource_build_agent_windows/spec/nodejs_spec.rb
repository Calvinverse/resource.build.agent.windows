# frozen_string_literal: true

require 'spec_helper'

describe 'resource_build_agent_windows::nodejs' do
  yarn_version = '1.17.3'

  context 'sets the NPM cache location' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'sets the npm_config_cache environment variable' do
      expect(chef_run).to create_env('npm_config_cache')
    end

    it 'sets the npm_config_progress environment variable' do
      expect(chef_run).to create_env('npm_config_progress')
    end

    it 'sets the npm_config_spin environment variable' do
      expect(chef_run).to create_env('npm_config_spin')
    end

    it 'sets the yarn_cache_folder environment variable' do
      expect(chef_run).to create_env('yarn_cache_folder')
    end
  end

  context 'installs nvm' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the node language directory' do
      expect(chef_run).to create_directory('c:/languages/node')
    end

    it 'extracts the NVM zip file to in the bin directory' do
      expect(chef_run).to extract_seven_zip_archive('c:/languages/node/nvm')
    end

    it 'sets the NVM_HOME environment variable' do
      expect(chef_run).to create_env('NVM_HOME')
    end

    it 'sets the NVM_SYMLINK environment variable' do
      expect(chef_run).to create_env('NVM_SYMLINK')
    end

    it 'adds NVM_HOME to the path' do
      expect(chef_run).to add_windows_path('%NVM_HOME%')
    end

    it 'adds NVM_SYMLINK to the path' do
      expect(chef_run).to add_windows_path('%NVM_SYMLINK%')
    end

    nvm_config_content = <<~TXT
      root: c:/languages/node/nvm
      path: c:/languages/node/nodejs
      arch: 64
      proxy: none
    TXT
    it 'creates settings.txt in the nvm bin directory' do
      expect(chef_run).to create_file('c:/languages/node/nvm/settings.txt').with_content(nvm_config_content)
    end
  end

  context 'installs node.js' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'installs node.js' do
      expect(chef_run).to run_powershell_script('install_node')
    end
  end

  context 'installs npm' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'installs npm' do
      expect(chef_run).to run_powershell_script('install_npm')
    end
  end

  context 'adds a label to the jenkins label file' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'adds the nodejs label' do
      expect(chef_run).to run_ruby_block('add_nodejs_label')
    end

    it 'deletes the labels.txt.old backup file' do
      expect(chef_run).to delete_file('d:/ci/labels.txt.old')
    end
  end

  context '' do
    it 'installs Yarn' do
      expect(chef_run).to install_windows_package('Yarn').with(
        installer_type: :msi,
        source: "https://github.com/yarnpkg/yarn/releases/download/v#{yarn_version}/yarn-#{yarn_version}.msi"
      )
    end
  end
end
