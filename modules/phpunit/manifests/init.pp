# PHPUnit extension for Chassis
class phpunit (
	$config,
	$install_path = '/usr/local/src/phpunit',
) {

	if ( !empty($config[disabled_extensions]) and 'chassis/phpunit' in $config[
		disabled_extensions] ) {
		$phpunit = absent
	} else {
		$phpunit = present
	}

	if ( present == $phpunit ) {
		# Create the install path
		file { $install_path:
			ensure => directory,
		}
		if ( ! empty( $config[phpunit] ) and ! empty( $config[phpunit][version] ) ) {
			$phpunit_repo_url = "https://phar.phpunit.de/phpunit-${config[phpunit][version]}.phar"
			$phpunit_version = $config[phpunit][version]
		} elsif versioncmp( $config[php], 5.6 ) == 0 {
			$phpunit_repo_url = 'https://phar.phpunit.de/phpunit-4.8.phar'
			$phpunit_version = 4.8
		} elsif versioncmp( $config[php], '7.0' ) == 0 {
			$phpunit_repo_url = 'https://phar.phpunit.de/phpunit-6.5.phar'
			$phpunit_version = 6.5
		} else {
			$phpunit_repo_url = 'https://phar.phpunit.de/phpunit-7.5.phar'
			$phpunit_version = 7.5
		}

		# Download phpunit
		exec { 'phpunit download':
			command => "/usr/bin/curl -o ${install_path}/phpunit.phar -L ${phpunit_repo_url}",
			require => [ Package[ 'curl' ], File[ $install_path ] ],
			unless  => "/usr/bin/phpunit phpunit --version | grep 'PHPUnit '${phpunit_version}"
		}

		# Ensure we can run phpunit
		file { "${install_path}/phpunit.phar":
			ensure  => present,
			mode    => 'a+x',
			require => Exec[ 'phpunit download' ]
		}

		# Symlink it across
		file { '/usr/bin/phpunit':
			ensure  => link,
			target  => "${install_path}/phpunit.phar",
			require => Exec[ 'phpunit download' ]
		}
	} else {
		file { $install_path:
			ensure => $phpunit,
			force  => true
		}
		file { '/usr/bin/phpunit':
			ensure => absent
		}
	}
}
