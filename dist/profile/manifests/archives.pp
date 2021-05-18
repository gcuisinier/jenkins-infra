#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives {
  include ::stdlib
  include profile::apachemisc
  include profile::letsencrypt

  $archives_dir = '/srv/releases'

  package { 'lvm2':
    ensure => present,
  }

  package { 'libapache2-mod-bw':
    ensure => present,
  }


  file { $archives_dir:
    ensure  => directory,
    owner   => 'www-data',
    require => Package['httpd'],
  }


  file { '/var/log/apache2/archives.jenkins-ci.org':
    ensure => directory,
  }

  file { '/var/log/apache2/archives.jenkins.io':
    ensure => directory,
  }

  apache::mod { 'bw':
    require => Package['libapache2-mod-bw'],
  }

  apache::vhost { 'archives.jenkins-ci.org non-ssl':
    servername      => 'archives.jenkins-ci.org',
    vhost_name      => '*',
    port            => '80',
    docroot         => $archives_dir,
    access_log      => false,
    error_log_file  => 'archives.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/archives/vhost.conf"),
    options         => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/archives.jenkins-ci.org'],
                        File[$archives_dir],
                        Apache::Mod['bw']],
  }

  apache::vhost { 'archives.jenkins-ci.org':
    port            => '443',
    ssl             =>  true,
    docroot         => $archives_dir,
    access_log      => false,
    error_log_file  => 'archives.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/archives/vhost.conf"),

    notify          => Service['apache2'],
    require         => File['/var/log/apache2/archives.jenkins-ci.org'],
  }


  apache::vhost { 'archives.jenkins.io non-ssl':
    # redirect non-SSL to SSL
    servername      => 'archives.jenkins.io',
    port            => '80',
    docroot         => $archives_dir,
    redirect_status => 'temp',
    redirect_dest   => 'https://archives.jenkins.io'
  }

  apache::vhost { 'archives.jenkins.io':
    port            => '443',
    ssl             =>  true,
    docroot         => $archives_dir,
    access_log      => false,
    error_log_file  => 'archives.jenkins.io/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/archives/vhost.conf"),

    notify          => Service['apache2'],
    require         => File['/var/log/apache2/archives.jenkins-ci.org'],
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { 'archives.jenkins.io':
        domains     => ['archives.jenkins.io','archives.jenkins-ci.org'],
        plugin      => 'apache',
        manage_cron => true,
    }
    Apache::Vhost <| title == 'archives.jenkins.io' |> {
    # When Apache is upgraded to >= 2.4.8 this should be changed to
    # fullchain.pem
      ssl_key       => '/etc/letsencrypt/live/archives.jenkins.io/privkey.pem',
      ssl_cert      => '/etc/letsencrypt/live/archives.jenkins.io/fullchain.pem',
      ssl_chain     => '/etc/letsencrypt/live/archives.jenkins.io/chain.pem',
    }
    Apache::Vhost <| title == 'archives.jenkins-ci.org' |> {
      ssl_key       => '/etc/letsencrypt/live/archives.jenkins.io/privkey.pem',
      ssl_cert      => '/etc/letsencrypt/live/archives.jenkins.io/fullchain.pem',
      ssl_chain     => '/etc/letsencrypt/live/archives.jenkins.io/chain.pem',
    }
  }


}
