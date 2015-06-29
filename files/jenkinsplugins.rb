#!/usr/bin/ruby
plugins = []
if File.exists?('/srv/jenkins/data/plugins')
   Dir.foreach('/srv/jenkins/data/plugins') do |f|
      if f =~ /(.*).(jpi|hpi)/
         if !plugins.include?(f.sub(/\.(.*)/, ''))
            plugins.push(f.sub(/\.(.*)/, ''))
         end
      end
   end
   print 'jenkinsplugins=' + plugins.sort.join(',')
else
   print 'jenkinsplugins='
end
