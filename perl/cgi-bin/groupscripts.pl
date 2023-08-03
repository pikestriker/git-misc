#!C:\strawberry\perl\bin\perl -w

use strict;
use database;
use CGI;
use CGI::Session;
use CGI::Carp qw( warningsToBrowser fatalsToBrowser );
use utilities qw( redirectIfNotPrivy
									printHeader
									processFields
									displayForm
									printFooter );
									
database::mydbConnect();

redirectIfNotPrivy();

printHeader("Group Scripts", "Groups and what scripts they have access to");

processFields();

displayForm();

printFooter();

database::mydbDisconnect();
