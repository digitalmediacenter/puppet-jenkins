
$packages = [ 'wget', 'curl' ]

package {$packages:
  ensure => 'installed',
}

class {'jenkins':
  service_name      => $::fqdn,
  update_plugins    => true,
  type              => 'lts',
  admin_mailaddress => 'v-u-hot-sysad-customer@dmc.local',
}

