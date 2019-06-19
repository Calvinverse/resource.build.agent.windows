# frozen_string_literal: true

chef_version '>= 14.0' if respond_to?(:chef_version)
description 'Environment cookbook that configures a base windows build agent with all the shared tools and applications.'
issues_url '${ProductUrl}/issues' if respond_to?(:issues_url)
license 'Apache-2.0'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
name '${NameCookbook}'
maintainer '${CompanyName} (${CompanyUrl})'
maintainer_email '${EmailDocumentation}'
source_url '${ProductUrl}' if respond_to?(:source_url)
version '${VersionSemantic}'

supports 'windows', '>= 2016'

depends 'firewall', '= 2.7.0'
depends 'git', '= 9.0.1'
depends 'windows', '= 5.3.1'
