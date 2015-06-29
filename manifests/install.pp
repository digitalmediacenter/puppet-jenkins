# installs jenkins on a debian system
define jenkins::install (
  $update_plugins           = false,
  $dir                      = '/srv/jenkins',
  $active_directory_domain  = 'dmc.local',
  $acl_anonymous_read       = false,
  $acl_puppet_admin_user    = 'dmc-hudson',
  $acl_puppet_admin_users   = [],
  $acl_puppet_user_group    = 'authenticated',
  $proxy_server             = 'none',
  $proxy_server_port        = 'none',
  $extra_plugins            = [],
  $type                     = 'lts',
  $service_name             = $::fqdn,
  $admin_mailaddress        = 'v-u-hot-sysad-customer@dmc.local',
  $with_nginx               = [],
  $with_apache2             = [],
  $with_sonar               = false,
){
  $temp_acl_puppet_admin_users = concat($acl_puppet_admin_users, ['dmc-ma-admins', ])
  $admin_user_augeas_array = prefix($temp_acl_puppet_admin_users, 'set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Hudson.Administer:')

  if ($type == 'lts') {
    $cli = '/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar'
  } elsif ($type == 'current') {
    $cli = '/tmp/jetty-127.0.0.1-80-jenkins.war--any-/webapp/WEB-INF/jenkins-cli.jar'
  }

$initial_plugins = ['active-directory', 'ant', 'build-timeout', 'chucknorris', 'ci-game', 'cobertura', 'copy-to-slave', 'copyartifact', 'credentials', 'external-monitor-job', 'disk-usage', 'greenballs', 'htmlpublisher', 'project-stats-plugin', 'scp', 'ssh', 'ssh-credentials', 'ssh-slaves', 'subversion', 'warnings', 'ldap', 'mailer', 'ws-cleanup', 'maven-plugin', 'performance', 'discard-old-build', 'jabber', 'createjobadvanced', 'sauce-ondemand' ,'jira' , 'javadoc', 'WebSVN2', 'job-import-plugin' ]

  $restart_reference = '/tmp/jenkins-puppet-restart-reference'
  $restart_needed    = '/tmp/jenkins-puppet-restart-needed'

  if ($type == 'lts'){
    apt::source {'jenkins':
      location    => 'http://pkg.jenkins-ci.org/debian',
      release     => 'binary/',
      repos       => '',
      key         => '150FDE3F7787E7D11EF4E12A9B7D32F2D50582E6',
      key_source  => 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key',
      include_src => false,
    }
  }elsif ($type == 'current'){
    apt::source {'jenkins':
      location    => 'http://pkg.jenkins-ci.org/debian',
      release     => 'binary/',
      repos       => '',
      key         => '150FDE3F7787E7D11EF4E12A9B7D32F2D50582E6',
      key_source  => 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key',
      include_src => false,
    }
  }else{
    fail('Only valid option for parameter type is lts or current')
  }

  file {'jenkins.rundir':
    ensure => directory,
    mode   => '0755',
    path   => '/var/run/jenkins/',
    notify => Package['jenkins'],
  }

  file {'facter.dir':
    ensure => directory,
    mode   => '0755',
    path   => '/etc/facter',
    notify => Package['jenkins'],
  }

  file {'facter.dir.facts':
    ensure  => directory,
    mode    => '0755',
    path    => '/etc/facter/facts.d',
    require => File ['facter.dir'],
  }

  file {'facter.jenkinsplugins':
    ensure  => file,
    mode    => '0755',
    path    => '/etc/facter/facts.d/jenkinsplugins.rb',
    source  => "puppet:///modules/${module_name}/jenkinsplugins.rb",
    require => File['facter.dir.facts'],
  }

  package {'openjdk-7-jdk':
    ensure => present,
    notify => Package['jenkins'],
  }
  package {'openjdk-6-jdk':
    ensure => absent,
  }
  package {'openjdk-6-jre':
    ensure => absent,
  }

  package {'jenkins':
    ensure  => present,
    require => Apt::Source['jenkins'],
  }

  file {'jenkins.default':
    ensure  => file,
    mode    => '0644',
    path    => '/etc/default/jenkins',
    content => template("${module_name}/jenkins.default.erb"),
    require => Package['jenkins'],
    notify  => Service['jenkins'],
  }

  file {'jenkins.logrotate.d':
    ensure  => file,
    mode    => '0644',
    path    => '/etc/logrotate.d/jenkins',
    source  => "puppet:///modules/${module_name}/jenkins.logrotate.d",
    require => Package['jenkins'],
  }

  file {'jenkins.profile':
    ensure  => file,
    mode    => '0644',
    path    => '/var/lib/jenkins/.profile',
    content => 'export LANG=\'en_US.utf8\'',
    require => Package['jenkins'],
  }

  file {'jenkins.dir':
    ensure  => directory,
    mode    => '0755',
    path    => $dir,
    owner   => 'jenkins',
    group   => 'nogroup',
    require => Package['jenkins'],
  }

  file {'jenkins.dir.data':
    ensure  => directory,
    mode    => '0755',
    path    => "${dir}/data/",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir'],
  }

  file {'jenkins.dir.users':
    ensure  => directory,
    mode    => '0755',
    path    => "${dir}/data/users",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
  }

  file {'jenkins.dir.admin':
    ensure  => directory,
    mode    => '0755',
    path    => "${dir}/data/users/${acl_puppet_admin_user}",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.users'],
  }

  file {'admin.key':
    ensure  => file,
    mode    => '0400',
    path    => "${dir}/data/users/${acl_puppet_admin_user}/identity.key",
    source  => "puppet:///modules/${module_name}/admin.key",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.admin'],
  }

  file {'admin.xml':
    ensure  => file,
    mode    => '0400',
    path    => "${dir}/data/users/${acl_puppet_admin_user}/config.xml",
    source  => "puppet:///modules/${module_name}/admin.xml",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.admin'],
  }

  file {'jenkins.config':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/config.xml",
    source  => "puppet:///modules/${module_name}/jenkins.config",
    owner   => 'jenkins',
    group   => 'nogroup',
    replace => false,
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

  file {'jenkins.config.proxy':
    ensure  => file,
    mode    => '0400',
    path    => "${dir}/data/proxy.xml",
    source  => "puppet:///modules/${module_name}/jenkins.config.proxy",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
  }
  # Create a timestamp for for later comparison
  exec {'jenkins.restart.timestamp':
    command => "touch ${restart_reference};rm -f ${restart_needed}",
    path    => ['/bin', '/usr/bin', '/usr/sbin',],
  }

  # modify the file, the timestamp does not change if file has not changed
  augeas {'jenkins.config.security':
    incl    => "${dir}/data/config.xml",
    lens    => 'XML.lns',
    changes => [
      'set hudson/authorizationStrategy/#attribute/class hudson.security.GlobalMatrixAuthorizationStrategy',
      'set hudson/securityRealm/#attribute/class hudson.plugins.active_directory.ActiveDirectorySecurityRealm',
      "set hudson/securityRealm/domain/#text ${active_directory_domain}",
  ],
  require   => Package['jenkins'],
                #File['jenkins.config']
  notify    => Service['jenkins'],
  }


  if ($acl_anonymous_read){
    $augeas_anonymous_read = [
      'set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Hudson.Read:anonymous',
      'set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Item.Read:anonymous',
      'set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.View.Read:anonymous',
    ]
  }else{
    $augeas_anonymous_read = []
  }

  # modify the file, the timestamp does not change if file has not changed
  augeas {'jenkins.config.acl':
    incl    => "${dir}/data/config.xml",
    lens    => 'XML.lns',
    changes => [
      'rm hudson/authorizationStrategy/permission',
      'rm hudson/authorizationStrategy/#text',
      "set hudson/authorizationStrategy/permission[1]/#text hudson.model.Hudson.Administer:${acl_puppet_admin_user}",
      $admin_user_augeas_array,
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Computer.Build:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Computer.Connect:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Computer.Disconnect:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Hudson.Read:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Hudson.RunScripts:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Item.Build:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Item.Cancel:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Item.Configure:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Item.Read:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.Item.Workspace:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.View.Configure:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.model.View.Read:${acl_puppet_user_group}",
      "set hudson/authorizationStrategy/permission[last()+1]/#text hudson.scm.SCM.Tag:${acl_puppet_user_group}",
      $augeas_anonymous_read,
    ],
    require => [
                Package['jenkins'],
                #File['jenkins.config']
              ],
    notify  => Service['jenkins'],
  }

  file {'jenkins.config.createjobadvanced':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/createjobadvanced.xml",
    source  => "puppet:///modules/${module_name}/jenkins.createjobadvanced",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

  file {'jenkins.config.jabber':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/hudson.plugins.jabber.im.transport.JabberPublisher.xml",
    source  => "puppet:///modules/${module_name}/jenkins.config.jabber",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

  file {'jenkins.config.jira':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/hudson.plugins.jira.JiraProjectProperty.xml",
    source  => "puppet:///modules/${module_name}/jenkins.config.jira",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

  file {'jenkins.config.sauce':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/sauce-ondemand.xml",
    source  => "puppet:///modules/${module_name}/jenkins.config.sauce",
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

#  file {'jenkins.config.svn':
#    ensure  => file,
#    mode    => '0644',
#    path    => "${dir}/data/hudson.scm.SubversionSCM.xml",
#    source  => "puppet:///modules/${module_name}/jenkins.config.svn",
#    owner   => 'jenkins',
#    group   => 'nogroup',
#    require => File['jenkins.dir.data'],
#    notify  => Service['jenkins'],
#  }

  file {'jenkins.config.location':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/jenkins.model.JenkinsLocationConfiguration.xml",
    content => template("${module_name}/jenkins.config.location.erb"),
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

  file {'jenkins.config.mailer':
    ensure  => file,
    mode    => '0644',
    path    => "${dir}/data/hudson.tasks.Mailer.xml",
    content => template("${module_name}/jenkins.config.mailer.erb"),
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['jenkins.dir.data'],
    notify  => Service['jenkins'],
  }

  service {'jenkins':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
  }

  file { "${dir}/data/updates":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'nogroup',
  }

  if $proxy_server != 'none' {
    $prx_env =  [ "http_proxy=http://${proxy_server}:${proxy_server_port}",
                  "https_proxy=http://${proxy_server}:${proxy_server_port}",
                  'no_proxy=localhost, 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16',
                ]
  }else{
    $prx_env = [ 'no_proxy_configured=true' ]
  }

  exec {'jenkins.updatecenter':
    command     => 'wget --timeout=30 -O default.js http://updates.jenkins-ci.org/update-center.json; sed \'1d;$d\' default.js > default.json && curl -m 30 -X POST -H \"Accept: application/json\" -d @default.json http://127.0.0.1:80/updateCenter/byId/default/postBack --retry 5 --retry-delay 5',
    cwd         => '/srv/jenkins/data/updates/',
    creates     => '/srv/jenkins/data/updates/default.json',
    timeout     => 0,
    path        => ['/bin', '/usr/bin', '/usr/sbin',],
#    require     => [ Service['jenkins'], Package['curl'], Package['wget'], Package['openjdk-7-jdk'], ],
    require     => [ Service['jenkins'], Package['openjdk-7-jdk'], ],
    tries       => 5,
    try_sleep   => 5,
    environment => [ $prx_env ],
  }

  exec {'jenkins.restart':
    command => "timeout -s SIGTERM -k 600 300 java -jar ${cli} -i ${dir}/data/users/${acl_puppet_admin_user}/identity.key -s http://localhost:80 safe-restart",
    path    => ['/bin', '/usr/bin', '/usr/sbin',],
    onlyif  => "test -f ${restart_needed}",
#    require => [ Service['jenkins'], Package['curl'], Package['wget'], Package['openjdk-7-jdk'], ],
    require => [ Service['jenkins'], Package['openjdk-7-jdk'], ],
  }

  file { '/usr/local/bin/jenkins-cli':
    content => "#!/bin/bash
set -x
java -jar ${cli} -i ${dir}/data/users/${acl_puppet_admin_user}/identity.key -s http://localhost:80 $@
      ",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }


  file { '/etc/cron.d/jenkins-job-backup':
    content => "
4 * * * * root /usr/local/bin/backup-jobs >/tmp/backup.txt 2>&1
      ",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/local/bin/backup-jobs':
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    source => "puppet:///modules/${module_name}/backup-jobs",
  }

# Wird in roles Jenkins entschieden ob Apache oder nginx //hallemel
#  jenkins::apache2 {'apache2':
#      service_name      => $service_name,
#      admin_mailaddress => $admin_mailaddress,
#      notify            =>  Package['jenkins'],
#}

  jenkins::plugin{ [ $initial_plugins, $extra_plugins ] :
    require => Exec['jenkins.updatecenter'],
  }

  if ($with_sonar == true) {
    include jenkins::sonar
    jenkins::plugin { 'sonar': }
  }
}
