class nagios::profile::nagios_server {

   include nagios::services::ping
   include nagios::services::load
   include nagios::services::zombies
   include nagios::services::disk_space
   include nagios::services::yum
  # include nagios::services::memory
   include nagios::services::nrpe
  # include nagios::services::aaaa_record
  # include nagios::services::cpu

  # ### Puppet client
#   include nagios::services::puppet
  # Now add the check for each individual interface on this machine
  # $interfaces_array = split($::interfaces, ',')
  # nagios::services::tcpcheck { [$interfaces_array]: }
  # Now add the check for each individual disk on this machine
# $  disks_array = split($::disks, ',')
# nagios::services::iocheck { [$disks_array]: }

}
