# check_mssql_sproc_params.pl
Icinga / nagios checkplugin to execute MSSQL stored procedures

based on
https://github.com/brunocantisano/check_mssql_sproc_parameters/blob/master/check_mssql_sproc_parameters.pl

This program will connect to a remote MS SQL server, execute a stored procedure, and then process the results
to determine if there is an error state or not.
Currently it only works if the stored procedure returns a single result in three columns. The columns have to be named
status, msg, perfdata and are then interpreted accordingly
Additional Notes & Tips: If you don't wish to have your SQL passwords exposed to the world you can do one of two
things - 1. Set \$USERx\$ in resource.cfg to the password - this will be passed to the program by Nagios, but will
not be visible from the web console or 2. If you have a universal SQL login for all of your Nagios queries, then
you may hardcode the username & password into the beginning of this script.

# Usage
	check_mssql_sproc_params -H HOSTNAME -p PROCEDURE -d database -u user -P password -w <warn> -c <crit>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

	-p, --procedure		Stored procedure to execute
	-H, --hostname		Hostname of database server
	-d  --database		Database to run Stored Procedure against
	-u, --user		SQL Username
	-P, --password		SQL Password
	-h, --help		Display detailed help
	-v, --version		Show version information

# Todo
- allow stored procedures to have parameters
