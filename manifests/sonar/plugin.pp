# manifests/sonar/plugin.pp
# - subfolder for plugins like the php plugin that is located
# in
#   http://repository.codehaus.org/org/codehaus/sonar-plugins/php/sonar-php-plugin/
# instead of
#   http://repository.codehaus.org/org/codehaus/sonar-plugins/sonar-php-plugin/
#
# jenkins::sonar::plugin {'sonar-php-plugin':
#    version => '1.2',
#    subfolder => 'php/'
# }

define jenkins::sonar::plugin (
  $version   = 0,
  $subfolder = '',
  $repo      = '',
) {

  $plugin_dir = '/opt/sonar/extensions/plugins'
  $repo_base = 'http://repository.codehaus.org/org/codehaus/sonar-plugins'

  if $repo == '' {
    $download = "${repo_base}/${subfolder}${name}/${version}/${name}-${version}.jar"
  } else {
    $download = $repo
  }

  exec {"sonar.${name}.download":
    creates => "${plugin_dir}/${name}-${version}.jar",
    command => "wget -P ${plugin_dir} ${download}",
    path    => ['/bin','/usr/bin','/usr/sbin'],
    notify  => Service['sonar'],
  }

  file {"sonar.${name}":
    ensure  => file,
    mode    => '0644',
    owner   => 'sonar',
    group   => 'adm',
    path    => "${plugin_dir}/${name}-${version}.jar",
    require => Exec["sonar.${name}.download"],
  }

}
