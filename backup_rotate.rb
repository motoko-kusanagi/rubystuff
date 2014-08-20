#!/usr/bin/env ruby

require 'rubygems'
require 'net/smtp'
require 'socket'
require 'etc'

$v1 = ARGV[0] # path
$v2 = ARGV[1] # filename
$v3 = ARGV[2] # e-mail
$v4 = ARGV[3].to_i # backups to keep

$backups_to_keep = $v4
$email_body = ''

def list_files(path)
  files_to_del = []
  files_to_keep = []
  files = []

  files = Dir.glob(File.join(path, "#{$v2}*"))  
  files.sort_by! {|filename| File.mtime(filename) }

  while files.size > $backups_to_keep do
    files_to_del << files[0]
    files.shift
  end

  files_to_keep = files

  $email_body << "DELETING... #{files_to_del.size} BACKUP(S)\n"
  create_body(files_to_del)
  delete_files(files_to_del)
  $email_body << "\n"
  $email_body << "KEEPING... #{files_to_keep.size} BACKUP(S)\n"
  create_body(files_to_keep)
  send_message()
  #puts $email_body
end

def create_body(items)
  items.each do |file|
    $email_body << File.ctime(file).to_s << " " << File.basename(file) << " " << (File.size(file).to_f / 1073741824.0).round(2).to_s << "GB \n"
  end
end

def delete_files(items)
  items.each do |file|
    File.delete(file)
  end
end

def send_message()
message = <<MESSAGE_END
From: #{Etc.getlogin} <#{Socket.gethostname}>
To: <#{$v3}>
Subject: BACKUP ROTATE : #{$v2}
#{$email_body}
MESSAGE_END

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, "", "#{$v3}"
  end
end

if ARGV[0].to_s.empty? && ARGV[1].to_s.empty? && ARGV[2].to_s.empty? && ARGV[3].to_s.empty?
  puts "Usage: ./backup_rotate.rb 'PATH' 'FILE MASK' 'E-MAIL' 'FILES TO KEEP'"
  exit
end

if ARGV[0].to_s.empty?
  puts "damn, please gimme path to check!!"
  exit
elsif ARGV[1].to_s.empty?
  puts "u fool! gimme file mask! (type \"*\" for all files)"
elsif ARGV[2].to_s.empty?
  puts "damn it! gimme e-mail address!!"
  exit
elsif ARGV[3].to_s.empty?
  puts "damn it! gimme number of files to keep!"
  exit
end

list_files($v1)
