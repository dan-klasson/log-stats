#!/usr/bin/env ruby


log = '2014-01-09T06:16:53.748849+00:00 heroku[router]: at=info method=POST path=/api/online/platforms/facebook_canvas/users/100002266342173/add_ticket host=services.pocketplaylab.com fwd="94.66.255.106" dyno=web.12 connect=12ms service=21ms status=200 bytes=78'

File.foreach('/home/dan/Downloads/sample.log') do |line|
  #puts line.split().partition('=').last
  puts line.gsub(/[^\s=]+=/, '')
end
