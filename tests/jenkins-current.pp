#
# apt-get -y remove apache2 jenkins openjdk-7-jdk dmc-certs libapache2-mod-proxy-html cronolog apache2.2-bin apache2-utils apache2-mpm-worker apache2.2-common libapache2-mod-proxy-html
# rm -rf /etc/apt/sources.list.d//jenkins.list /srv/jenkins /etc/apache2
# rm -rf /etc/default/jenkins /etc/default/apache2

$packages = [ 'wget', 'curl' ]

package {$packages:
  ensure => 'installed',
}

class {'jenkins':
  service_name      => $::fqdn,
  update_plugins    => true,
  type              => 'current',
  admin_mailaddress => 'v-u-hot-sysad-customer@dmc.local',
  proxy_server      => 'proxy.intra.dmc.de',
  proxy_server_port => '3128',
}

