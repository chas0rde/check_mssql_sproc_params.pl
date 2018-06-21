#!/usr/bin/perl -w
# ======================================================================
#
# Perl Source File -- Created with SAPIEN Technologies PrimalScript 3.1
#
# NAME: check_mssql_sproc_params.pl
#
# ORIGINAL AUTHOR: Jeremy D. Pavleck , Capella University <jeremy@pavleck.com>
# ORIGINAL DATE  : 10/25/2005
#
# AUTHOR: I.Pohlschneider <info(at)chas0r.de
# DATE:   06/21/2018
#
# Modified to expect special result set to do plain output
#
# PURPOSE: Runs a stored proc on a remote MS SQL server and returns the result.
# 	   Assumes returned result set consists of three columns:
#			status
#			msg
#			perfdata 
#
# AUTHOR: Bruno Cardoso Cantisano <bruno.cantisano@gmail.com>
# DATE  : 04/25/2017
# DATE  : 12/14/2017: Adding custom html page
# DATE  : 05/04/2018: Fixing html. It's not using anymore a file to 
# DATE  : 14/06/2018: Changing ODBC version
# AUTHOR: Ingo Pohlschneider <info(at)chas0r.de>
# DATE  : 06/21/2018: Refactored original script flow. Removed HTML support and altered to interpret specific result set
# ======================================================================
use DBI;
use Getopt::Long;
use HTML::Entities;


# If you have a universal 'support' login for MS SQL server, set $hardcoded to 1
# and then set the SQL username and password.
my ($hardcoded, $sql_server, $sql_database, $sql_user, $sql_pass, $sql_proc);
$hardcoded    = 1;
$sql_server   = "ctx-xd.db.grimme.local";
$sql_database = "CitrixGrimme-XD-Mon";
$sql_user     = "icinga";
$sql_pass     = "uv72AfZTw0OA";
$sql_proc     = "GRM_Monitoring_LoadIndex";

# declare variable for result storage
my $status;
my $msg = "";
my $perfdata = "";

my ($opt_h, $opt_proc, $opt_host, $opt_user, $opt_pw, $opt_ver);
Getopt::Long::Configure('bundling');
GetOptions(
           "h"     => \$opt_h,       "help"  => \$opt_h,
           "p=s"   => \$opt_proc,    "procedure=s"  => \$opt_proc,
           "H=s"   => \$opt_host,    "hostname=s"  => \$opt_host,
           "d=s"   => \$opt_db,      "database=s"  => \$opt_db,
           "u=s"   => \$opt_user,    "user=s"  => \$opt_user,
           "P=s"   => \$opt_pw,      "password=s"  => \$opt_pw,
           "v"     => \$opt_ver,     "version"  => \$opt_ver,
);

# print help if requested
if ($opt_h) {
	print_help();
}

# print version if requested
if ($opt_ver) {
        print_version();
}

# set SQL credentials if hardcoded flag is set true
if ($hardcoded) {
        $opt_user = $sql_user;
        $opt_pw   = $sql_pass;
        $opt_host = $sql_server;
        $opt_db   = $sql_database;
        $opt_proc = $sql_proc;
}

# check if all mandatory flags are set. If not exit with error
if ($opt_host eq "" or $opt_proc eq "" or $opt_db eq "" or $opt_user eq "" or $opt_pw eq "" ) {
	$status = 2;
    	$msg = "Error - Mandatory arguments -H, -u, -P, -d, -p, -c and -w are required.\nPlease see '$0 --help' for addtional informaton\n";
    	print_output();
}

# create MSSQL connection
my $conn;

$conn{"username"} = $opt_user;
$conn{"server"} = $opt_host;
$conn{"database"} = $opt_db;
$conn{"password"} = $opt_pw;
$conn{"dsn"} = "dbi:ODBC:Driver={ODBC Driver 17 for SQL Server};SERVER=" . $conn{"server"} . ";DATABASE=" . $conn{"database"};
$conn{"dbh"} = DBI->connect( $conn{"dsn"}, $conn{"username"}, $conn{"password"})
        or die "Error: Unable to connect to MS-SQL server $opt_host with DB $opt_db!\n", $DBI::errstr,"\n";

# prepare the stored procedure
#$nomeProc =  substr $opt_proc, 0, index($opt_proc, ' ');
#$paramsProc = join("", split(/[aA-zZ]|[0-9]|"/, $opt_proc, -1));
#$paramsProc = substr $paramsProc, 2, length($paramsProc)-2;
#$paramsProc =~ s/ /?/g;

# prepare execution and set query properties
my $sql = qq{ exec $opt_proc };
my $sth = $conn{"dbh"}->prepare( $sql );

$sth->{"LongReadLen"} = 0;
$sth->{"LongTruncOk"} = 1;

# execute statement
$sth->execute() 
	or die "Error: Unable to connect to MS-SQL database $opt_db!\n", $DBI::errstr,"\n";

# read results and interpret columns
$i = 1;
while($ref = $sth->fetchrow_hashref) {
	if($i > 1) {
		$status = 2;
            	$msg = "Result set not formatted properly. More then one result row found. See help for result set format.";
            	print_output();
        }
        foreach my $field ( keys %{ $ref } ) {
            if($field eq 'status') {
            	$status = $ref->{ $field };
            } elsif($field eq 'message') {
            	$msg = $ref->{ $field };
            } elsif($field eq 'perfdata'){
            	$perfdata = $ref->{ $field };
            } else{
            	$status = 2;
            	$msg = "Result set not formatted properly. Unknown column $field found. See help for result set format.";
            	print_output();
            }
        }
        $i = $i + 1;
}

# close DB connection
$sth->finish();
$conn{"dbh"}->disconnect();

print_output();

# subroutine to print plain output
sub print_output {
	my $output = $msg;
	if ($perfdata ne "") {
		$output .= "|" . $perfdata;
	}
	print $output;
	exit $status;
}

# subroutine to print the help message
sub print_help {
    print "Usage: $0 -H HOSTNAME -p PROCEDURE -d database -u user -P password -w <warn> -c <crit>\n";
    print "
    $0 1.02
    Copyright (c) 2005 Jeremy D. Pavleck <jeremy\@pavleck.com>
    This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
-p, --procedure
        Stored procedure to execute
-H, --hostname
        Hostname of database server
-d  --database
        Database to run Stored Procedure against
-u, --user
    SQL Username
-P, --password
    SQL Password
-h, --help
        Display detailed help
-v, --version
    Show version information

    
    This program will connect to a remote MS SQL server, execute a stored procedure, and then process the results
    to determine if there is an error state or not.
    Currently it only works if the stored procedure returns a single result in three columns. The columns have to be named
    status, msg, perfdata and are then interpreted accordingly
    Additional Notes & Tips: If you don't wish to have your SQL passwords exposed to the world you can do one of two
    things - 1. Set \$USERx\$ in resource.cfg to the password - this will be passed to the program by Nagios, but will
    not be visible from the web console or 2. If you have a universal SQL login for all of your Nagios queries, then
    you may hardcode the username & password into the beginning of this script.
    Send email to jeremy\@pavleck.com or nagios-users\@lists.sourceforge.net if you have questions regarding the use of this
    software. To submit patches or suggest improvements, please email jeremy\@pavleck.com or visit www.Pavleck.com";
    
    exit;
}

# subroutine to print the version
sub print_version {
    print "
    $0  version 1.02 - June 21th, 2018
    Copyright (c) 2005 Jeremy D. Pavleck <jeremy\@pavleck.com>
    Copyright (c) 2018 I.Pohlschneider <info\@chas0r.de>
    This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.";
    
    
    exit;
}
