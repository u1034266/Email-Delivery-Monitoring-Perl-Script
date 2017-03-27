#!/usr/bin/perl

# ####################################################################################################################
# Script name: email_delivery_monitoring_via_linux.pl
# Author: David Tekwie <tekwie.david@gmail.com>
# Creation Date: 01 Sept 2016 
# Description: 
#   This script can be used to monitor email delivery from an API / Webservice function that is used in an application 
#   for triggering / sending emails.
#
# DISCLAIMER:
#   The author is the original creator of this script. This script is being shared for informative and educational purposes 
#   only. This script does not contain malicious intent, nor intended to cause harm or loss of business to anyone who uses it. 
#   All emailaddress and user authentication used in this script are purely hypothetical and used for example only.
#   You are free to copy, add to, and distribute this code at 'your own risk'.
#
# ####################################################################################################################

# ========================================================== 
# Modules
# ========================================================== 
use LWP 5.64; # Loads all important LWP classes, and makes
              #  sure your version is reasonably recent.
use strict;
use warnings;
use English qw( -no_match_vars );
use POSIX qw( strftime );
use File::Basename;
use File::Temp;
use File::Copy;
use IO::Dir;
use Scalar::Util qw(looks_like_number);
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Getopt::Long;
use Switch;
use MIME::Base64;
use MIME::Lite;
use LWP::UserAgent;
use HTTP::Headers;

# To check file creation time
use Time::localtime;
use File::stat;
# ========================================================== 

# ========================================================== 
# Golbals
# ========================================================== 
my %PARAMS = ();
my $recipient = '#recipient@mailserver.com#';
my $notifications = '#notifications@mailserver.com#';
my $error_emailMsg = 'Email Delivery Error alert: No emails were delivered in the last minute.';
my $error_dir_dne = 'Directory does not exist.';
my $error_dir_open = 'Cannot open directory.';
our $start_unix_time = time();
my $version = "1.0";
my $now = time();
my $file_counter = 0;

# Webservice Authentication Variables
my $webservice = LWP::UserAgent->new;
my $username = 'username';
my $password = 'password';
my $realm = 'Application Realm';
my $webserviceAccess_errorMsg = 'Authentication failed for the provided credentials. Webservice Access Denied.';

# ======================================= For Dev =======================================
# Hostname
my $hostname = 'yourAppUrl.com:#portNumber#'; # Note: Use port '80' if in http, If accessing https then use port 4043.
# Mail Directory
my $mail_dir = '/home/user/path/to/Maildir/new/'; # Note: This path depends on how your individual directory is set up.
# Email Monitoring
my $url = 'http://yourAppUrl.com/path/to/webservice?.......&emailaddress=' . $recipient;
# Error Notifications
my $url2 = 'http://yourAppUrl.com/path/to/webservice?.......&errorMsg=' . $error_emailMsg . '...&emailaddress=' . $notifications;
# ======================================= / For Dev =======================================

# Turn off bufferring.
$| = 1;

# ========================================================== 
# Start Program
# ========================================================== 
prep_definitions();
# ========================================================== 

# Prepare the definitions
sub prep_definitions {

  # Log script iteration tracking message.
  logM(3,"Entering prep_definitions().");

  # Validate script usage
  if ( $#ARGV > 0 ) { print_usage(); }

  # Arguments syntax declaration
  GetOptions(   'help|?'    => sub{ print_usage() },
                'v|version' => sub{ print_version() },
                'debug'     => \$PARAMS{'Debug'}
              );

  # Call the main subroutine.
  main();
}

# Main Program
sub main {

  # Log script iteration tracking message.
  logM(3,"Entering main().");

  # Call the sendMsg2()
  call_emailFunction();

  # Log a end program message.
  logM(3,"Script execution completed. Program end.");

  # Program Ends
  exit(0);
}

# Messages Log
sub logM {
  my ($level,$message) = @_;
  if ( $level == 3 and ! defined $PARAMS{'Debug'} ) { return; }
  my $prefix;
  switch( $level ) {
    case 0 { $prefix = "[Info]"; }
    case 1 { $prefix = "[Warning]"; }
    case 2 { $prefix = "[Error]"; }
    case 3 { $prefix = "[Debug]"; }
  } #switch
  print $0 . $prefix . " " . $message . "\n";
  switch( $level ) {
    case 2 { exit(2) }
  } #switch
}

# Function to Print script usage
sub print_usage {
        print "Usage:\n";
        print "\t$0 [options]\n\n";
        print "Options: (If no option is chosen when running the script, it will execute without any debug output.)\n";
        print "-v,--version\t\tprint version and exit\n";
        print "-debug\t\t\tenter debug mode\n";
        exit(0);
} #print_usage

## Function to Print script version
sub print_version {
    print $0 . " version: " . $version . "\n";
    exit(0);
}

# Function to call the Email Deliver webservice function.
sub call_emailFunction {

  # Log script iteration tracking message.
  logM(3,"Entering call_emailFunction().");

  # Authenticate Webservice Access
  my $response_emailFunction = webservice_auth( $url, $hostname, $realm, $username, $password);

  # Validate Response
  if ( $response_emailFunction->is_success ) {
    logM(0,"Webservice Access Response: " . $response_emailFunction->status_line . ". Email sent Successfully.");

    # Pause for a few seconds to allow for the email to be delvered.
    print "Waiting for email to be delivered ...\n";
    sleep(xx); # Note: 'xx' can be any amount of buffer time in 'seconds', based on your systems performance. Eg: 60, 120, 180, etc...

    # Check the mail dir to confirm that the mail was received.
    check_mail($mail_dir);

  } else {

    # Log webservice access error message
    logM(2, $webserviceAccess_errorMsg . "Failed to deliver email.");
  }
}

# Function to authentication webservice function access
sub webservice_auth {

  # Log script iteration tracking message.
  logM(3,"Entering webservice_auth().");
  
  # Authenticating Process
  my $thisURL = $_[0];
  my $thisHost = $_[1];
  my $thisRealm = $_[2];
  my $thisUser = $_[3];
  my $thisPswd = $_[4];

  # Set the Credentials To Authenticate Access
  $webservice->credentials( $thisHost, $thisRealm, $thisUser, $thisPswd );
  my $response = $webservice->get( $thisURL );
}

# Function to Check the recipient Mailbox
sub check_mail {

  # Log script iteration tracking message.
  logM(3,"Entering check_mail().");

  # Get the directory
  my ( $mail_in_dir ) = @_;
  
  # Go to the directory location
  chdir $mail_in_dir or die "chdir $mail_in_dir: $error_dir_dne\n";
  my $dir = IO::Dir->new(q{.}) or die "OpenDir: $error_dir_open\n";
  my $filename = $dir->read();

  # Stdout output
  print "\n[Mail]\t\t\t\t\t[Age]\n";

  # Loop through Maildir
  while ( defined( my $filename = $dir->read() ) ) {
    
    # Only get valid filenames, and exclude directory / hidden files.
    next if not -f $filename;

    #Get the Files Age in "Days" from localtime() now.
    my $fileAge_days = -M $filename;

    # Convert filename age from days to seconds.
    my $fileAge_secs = $fileAge_days * 24 * 60 * 60;

    # Output Mails to stdout.
    print $filename . "\t\t" . $fileAge_secs . "\n";

    # Check for new files ie. less than XXseconds old.
    if ( $fileAge_secs < #XXseconds# ) {
      # Increment the counter
      $file_counter++;
    }

    # Pause for a few secs between each loop iteration.
    # Note: the pausse time depends on system performance. Time can be increases or reduced accordingly.
    sleep(3);

  }

  # Check new files counter and send notification email if counter is still 0.
  if ( $file_counter eq 0) {

    # Log an info message.
    logM(0, "No new mails in Maildir.");

    # Send notification email.
    my $response_sendNotification = webservice_auth( $url2, $hostname, $realm, $username, $password);

    # Validate Response
    if ( $response_sendNotification->is_success ) {

      # Log a info message.
      logM(0,"Webservice Access Response: " . $response_sendNotification->status_line . ". Notification Email Successfully Sent.");

    } else {

      # Log webservice access error message
      logM(2, $webserviceAccess_errorMsg . " Error Notification Failed.");
    }
  } else {

    #Log an info message.
    logM(0, "There are " . $file_counter . " new mail(s) in Maildir.");
  }

  # Log a debug message.
  logM(3,"Mail directory checking completed.");
  return;
}