# Configuration for Nagios server
class nagios::config::server (
  $allowed_hosts    = ['127.0.0.1'],
  $admins           = {
    'admin01' => {
      contact_name => 'admin01',
      alias        => 'Admin for life',
      email        => 'admin01@bristol.ac.uk',
    }
  }
  ,
  $hostgroups       = {
    'default' => {
      alias => 'default-hostgroup',
      tag   => $::domain,
    }
  }
  ,
  $servicegroups    = {
    'cpu' => {
      alias => 'CPU',
      tag   => $::domain,
    }
  }
  ,
  $use_mod_auth_cas = true,
  $cas_login_url    = undef,
  $cas_users        = [],
  $cas_validate_url = undef,
  $enable_firewall  = true, ) {

  include nagios::commands
  include nagios::plugins::all
  include nagios::plugins::server
  include nagios::templates
  # A server is also a client
  class { 'nagios::config::client': allowed_hosts => $allowed_hosts, }

  # define contacts
  class { 'nagios::config::contacts':
    admins => $admins,
  }

  # define host and service groups
  class { 'nagios::config::hostgroups':
    hostgroups => $hostgroups,
  }

  class { 'nagios::config::servicegroups':
    additional_servicegroups => $servicegroups,
  }

  # These configs are the ones that can't be dynamically generated by puppet,
  # for things that aren't managed by puppet, eg ESXi. These are managed by
  # puppet in the traditional way.
  # Nagios master config
  file { '/etc/nagios/nagios.cfg':
    alias   => 'nagios.cfg',
    mode    => '0640',
    owner   => 'root',
    group   => 'nagios',
    source  => 'puppet:///modules/nagios/nagios.cfg',
    require => Package['nagios'],
    notify  => Service['nagios'],
    before  => Service['nagios'],
  }

  # NSCA config
  file { '/etc/nagios/nagios_services.d':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'nagios',
    require => Package['nagios'],
  }


  file { '/etc/nagios/nsca.cfg':
    alias   => 'nsca.cfg',
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/nagios/nsca.cfg',
    require => Package['nsca'],
    notify  => Service['nsca'],
  }

  file { '/etc/nagios/private/resource.cfg':
    alias   => 'resource.cfg',
    mode    => '0640',
    owner   => 'root',
    group   => 'nagios',
    content => template('nagios/resource.cfg.erb'),
    require => Package['nagios'],
    notify  => Service['nagios'],
    before  => Service['nagios'],
  }

  file { '/etc/nagios/cgi.cfg':
    alias   => 'cgi.cfg',
    mode    => '0640',
    owner   => 'root',
    group   => 'nagios',
    source  => 'puppet:///modules/nagios/cgi.cfg',
    require => Package['nagios'],
    notify  => Service['nagios'],
    before  => Service['nagios'],
  }

  # Install some custom icons for the web interface
  nagios::icon { 'CentOS': }

  nagios::icon { 'Fedora': }

  nagios::icon { 'RedHat': }

  nagios::icon { 'Ubuntu': }

  nagios::icon { 'VMware': }

  nagios::icon { 'Windows': }

  nagios::icon { 'Debian': }

  nagios::icon { 'Scientific': }
  
  if $enable_firewall {

  # Auto-add a firewall rule in the NRPE clients just for us
  @@firewall { "100-nrpe-${::fqdn}":
    proto  => 'tcp',
    dport  => '5666',
    tag    => 'nrpe',
    source => $::ipaddress,
    action => 'accept',
  }

  @@firewall { "100-nrpe-v6-${::fqdn}":
    proto    => 'tcp',
    dport    => '5666',
    tag      => 'nrpe',
    source   => $::ipaddress6,
    provider => 'ip6tables',
    action   => 'accept',
  }

  # Firewall rules for NSCA
  # Automatically grant NSCA access to any managed host
  Firewall <<| tag == 'nsca' |>>

  }

  # collect resources and populate /etc/nagios/nagios_*.cfg
  Nagios_host <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_service <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_hostextinfo <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_servicedependency <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_hostdependency <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_contact <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_contactgroup <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_command <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_servicegroup <<| |>> {
    notify => Service['nagios'],
  }
  Nagios_hostgroup <<| |>> {
    notify => Service['nagios'],
  }

  # Purge old configs
  resources { [
    'nagios_host',
    'nagios_service',
    'nagios_hostextinfo',
    'nagios_servicedependency',
    'nagios_contact',
    'nagios_contactgroup',
    'nagios_command',
    'nagios_servicegroup',
    'nagios_hostgroup',
    'nagios_hostdependency']:
    purge  => true,
    notify => Service['nagios'],
  }

  # Make sure Nagios can read its own configs
  file { '/etc/nagios/conf.d':
    recurse => true,
    mode    => '0644',
    owner   => 'root',
    group   => 'nagios',
  }

  # create virtual hosts
  if $use_mod_auth_cas {
  class { 'nagios::config::vhosts':
    use_mod_auth_cas => $use_mod_auth_cas,
    cas_validate_url => $cas_validate_url,
    cas_login_url    => $cas_login_url,
    cas_users        => $cas_users,
  }
  } else { 
  class { 'nagios::config::sslvhosts' :

  }
 }
}
