/var/log/jenkins/jenkins.log {
        weekly
        copytruncate
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
}

/var/log/jenkins/java_gc.log {
        weekly
        copytruncate
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
}
