# manifests/sonar/runner.pp

define jenkins::sonar::runner (
  $version='2.3'
) {

  $base_dir = '/opt/sonar-runner'
  $url = "http://repo1.maven.org/maven2/org/codehaus/sonar/runner/sonar-runner-dist/${version}/sonar-runner-dist-${version}.zip"

  exec {'sonar.runner.download':
    creates => '/opt/sonar-runner',
    cwd     => '/tmp',
    command => "wget -P /tmp ${url}; unzip /tmp/sonar-runner-dist-${version}.zip; mv /tmp/sonar-runner-2.3 /opt/sonar-runner",
    path    => ['/bin','/usr/bin','/usr/sbin'],
    }

  file {'sonar.environment':
    ensure  => file,
    path    => '/etc/profile.d/sonar.sh',
    content => "export SONAR_RUNNER_HOME=${base_dir}\nexport PATH=\$PATH:/opt/sonar-runner/bin",
    mode    => '0755',
    owner   => 'root',
    group   => 'root'
  }

  file {'sonar.runner':
    ensure => present,
    path   => "${base_dir}/bin/sonar-runner",
  }

  file {'sonar.runner.conf':
    ensure => file,
    source => "puppet:///modules/${module_name}/sonar.runner.config",
    path   => '/opt/sonar-runner/conf/sonar-runner.properties'
  }

  augeas {'sonar.runner.conf':
    incl    => "${base_dir}/conf/sonar-runner.properties",
    lens    => 'Properties.lns',
    changes => [
      "set sonar.host.url http://${jenkins::sonar::web_host}:${jenkins::sonar::web_port}${jenkins::sonar::web_context}",
      "set sonar.jdbc.url ${jenkins::sonar::sonar_jdbc_url}",
      "set sonar.jdbc.username ${jenkins::sonar::db_user}",
      "set sonar.jdbc.password ${jenkins::sonar::db_pass}",
    ],
    notify  => Service['sonar'],
    require => File['sonar.runner.conf'],
  }

  file {'jenkins.config.sonarrunner':
    ensure => file,
    mode   => '0664',
    path   => '/srv/jenkins/data/hudson.plugins.sonar.SonarRunnerInstallation.xml',
    source => "puppet:///modules/${module_name}/jenkins.config.sonarrunner",
    owner  => 'jenkins',
    group  => 'nogroup',
    notify => Service['jenkins'],
  }

  file {'jenkins.config.sonarpublisher':
    ensure => file,
    mode   => '0664',
    path   => '/srv/jenkins/data/hudson.plugins.sonar.SonarPublisher.xml',
    source => "puppet:///modules/${module_name}/jenkins.config.sonarpublisher",
    owner  => 'jenkins',
    group  => 'nogroup',
    notify => Service['jenkins'],
  }
}
