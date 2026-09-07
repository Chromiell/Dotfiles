#!/usr/bin/expect -f
#Dependency on `expect` package.
#
#The set timeout 30 sets 30s of timeout to each expect statement.
#If you want to set a global timeout call this script with the following syntax:
#    timeout 30 ./sftpGrab.sh
#This sets a global 30s timeout for the script, if it takes longer it will time out and terminate.
set timeout 30
# Default configuration values
set host ""
set user ""
set password ""
set remote_file ""
set local_dir [pwd]

# Locate config.env in ScriptsData directory
set script_dir [file dirname [file normalize [info script]]]
set config_file [file normalize "$script_dir/../ScriptsData/config.env"]
if {![file exists $config_file] && [info exists env(HOME)]} {
    set config_file "$env(HOME)/Documents/ScriptsData/config.env"
}

# Parse config.env if it exists
if {[file exists $config_file]} {
    set fp [open $config_file r]
    while {[gets $fp line] >= 0} {
        set line [string trim $line]
        if {[string match "#*" $line] || $line eq ""} { continue }
        if {[regexp {^([A-Za-z0-9_]+)=(.*)$} $line -> key val]} {
            set val [string trim $val]
            set val [string trim $val "\""]
            set val [string trim $val "'"]
            if {$key eq "SFTP_HOST"} { set host $val }
            if {$key eq "SFTP_USER"} { set user $val }
            if {$key eq "SFTP_PASSWORD"} { set password $val }
            if {$key eq "SFTP_REMOTE_FILE"} { set remote_file $val }
            if {$key eq "SFTP_LOCAL_DIR"} { set local_dir $val }
        }
    }
    close $fp
}

# Environment variable overrides
if {[info exists env(SFTP_HOST)]} { set host $env(SFTP_HOST) }
if {[info exists env(SFTP_USER)]} { set user $env(SFTP_USER) }
if {[info exists env(SFTP_PASSWORD)]} { set password $env(SFTP_PASSWORD) }
if {[info exists env(SFTP_REMOTE_FILE)]} { set remote_file $env(SFTP_REMOTE_FILE) }
if {[info exists env(SFTP_LOCAL_DIR)]} { set local_dir $env(SFTP_LOCAL_DIR) }

if {$host eq "" || $user eq "" || $password eq "" || $remote_file eq ""} {
    puts stderr "Error: SFTP configuration (host, user, password, remote_file) is missing or incomplete in config.env."
    exit 1
}

spawn sftp $user@$host
expect "password:"
send "$password\r"
expect "sftp>"
send "get $remote_file $local_dir\r"
expect "sftp>"
send "bye\r"
