#!/usr/bin/env ruby

require 'rubygems'
require 'net/smtp'
require 'socket'
require 'etc'
require 'zip'
require 'benchmark'

def compress(what,where)
  if File.exist?("#{where}#{File.basename(what)}.zip"); File.rename("#{where}#{File.basename(what)}.zip","#{where}#{File.basename(what)}_old.zip"); end

  Zip::File.open("#{where}#{File.basename(what)}.zip", Zip::File::CREATE) do |zipfile|
    Dir[File.join(what, '**', '**')].each do |file|
      zipfile.add(file.sub(what, ''), file)
    end
  end

  if File.exist?("#{where}#{File.basename(what)}_old.zip"); File.delete("#{where}#{File.basename(what)}_old.zip"); end
end

def check_path(path)
  if path.slice(-1).chr != "/";  path += "/"; end
  return path
end

def email_body(what,where,time)
  $body += "File: #{File.basename(what)}.zip\n"
  filesize = ''

  if (File.size("#{where}#{File.basename(what)}.zip").to_f / 1073741824.0).round(2) < 1
    filesize = (File.size("#{where}#{File.basename(what)}.zip").to_f / 1024000).round(2)
    # puts filesize.to_s
    $body += "Size: "
    $body += filesize.to_s
    $body += " MB \n"
  else
    # puts filesize.to_s
    filesize = (File.size("#{where}#{File.basename(what)}.zip").to_f / 1073741824.0).round(2)
    $body += "Size: " 
    $body += filesize.to_s
    $body += " GB \n"
  end
  $body += "Compression time: " << time.to_s << "\n\n"
end

def send_message(body)
message = <<MESSAGE_END
From: #{Etc.getlogin} <#{Socket.gethostname}>
To: <#{$email}>
Subject: BACKUP DIR : #{ARGV[0]}

#{body}
MESSAGE_END

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, "", "#{$email}"
  end
end

if ARGV[0].to_s.empty? && ARGV[1].to_s.empty? && ARGV[2].to_s.empty?
  puts "Usage: ./backup_dir.rb 'PATH WITH DIRECTORY' 'PATH TO STORE FILE' 'E-MAIL'"
  exit
end

what = check_path(ARGV[0])
where = check_path(ARGV[1])
$email = ARGV[2]
$body = ''

dirs = Dir.glob("#{what}**").select {|f| File.directory? f}
dirs.each do |loc|
  time = Benchmark.measure do
    compress(check_path(loc),where)
  end
  email_body(check_path(loc),where,time)
end

send_message($body)
