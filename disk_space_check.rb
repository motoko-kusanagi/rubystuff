#!/usr/bin/env ruby

require 'rubygems'
require 'net/smtp'
require 'socket'
require 'etc'

$email_body = ''
$disk_warning = 90
$disk_low_space = 'false'

$v1 = ARGV[0]
$v2 = ARGV[1]

def send_message()
message = <<MESSAGE_END
From: #{Etc.getlogin} <#{Socket.gethostname}>
To: <#{$v2}>
Subject: LOW DiSK SPACE WARNiNG : #{Socket.gethostname}
#{$email_body}
MESSAGE_END

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, "", "#{$v2}"
  end
end

def send_message_html()
message = <<MESSAGE_END
From: #{Etc.getlogin} <#{Socket.gethostname}>
To: <#{$v2}>
MIME-Version: 1.0
Content-type: text/html
Subject: LOW DiSK SPACE WARNiNG : #{Socket.gethostname}
#{$email_body}
MESSAGE_END

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, "", "#{$v2}"
  end
end

def fix_length(text)
  if text.length == 2
    text << " &nbsp; &nbsp; &nbsp; "
  end
  if text.length == 3
    text << " &nbsp; &nbsp; "
  end
  if text.length == 4
    text << " &nbsp; "
  end
  if text.include? "."
    text << " &nbsp; "
  end
  return text
end

def check_disks()
  exec = `df -h | grep -v tmpfs | grep -v udev | grep /dev/`
  result = exec.split("\n")

  if $v1.to_s.eql? "html"
    $email_body << '<FONT FACE="Calibri">'
    result.each do |line|
      if line.split[4].chop.to_i > $disk_warning
        $email_body << '<FONT COLOR="red"><b>'
      else
        $email_body << '<FONT COLOR="black">'
      end
      $email_body << fix_length(line.split[4]) << " &nbsp; &nbsp; &nbsp; " << fix_length(line.split[3]) << " &nbsp; &nbsp; " << line.split[5]
      if line.split[4].chop.to_i > $disk_warning
	$disk_low_space = "true"
        $email_body << " " << '** LOW DiSK SPACE **</b>'
      end
      $email_body << "<br> </font>"
    end
    if $disk_low_space == "true"
      send_message_html()
    end
  end
  
  if $v1.to_s.eql? "txt"
    result.each do |line|
      if line.split[4].chop.to_i > $disk_warning
	$disk_low_space = "true"
        $email_body << line.split[4] << "\t \t" << line.split[3] << "\t \t" << line.split[5] << " ** LOW DiSK SPACE ** \n"
      else
        $email_body << line.split[4] << "\t \t" << line.split[3] << "\t \t" << line.split[5] << "\n"
      end
    end
    if $disk_low_space == "true"
      send_message()
    end
  end

end

if ARGV[0].to_s.empty? && ARGV[1].to_s.empty?
  puts "\033[32mUsage: ./disk_space_check.rb 'html/txt' 'e-mail'\033[37m"
  exit
end

if ARGV[0].to_s.empty?
  puts "\033[32mFool! Choose raport version: 'html' or 'txt'\037[31m"
else
  if ARGV[0].to_s != "html" && ARGV[0].to_s != "txt"
    puts "\033[32mFool! choose 'html' or 'txt' only!!\033[31m"
    exit
  end
  if ARGV[1].to_s.empty?
    puts "\033[32mDamn! Gimme e-mail address!\033[31m"
    exit
  end
  check_disks()
end
