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

processFields();

printHeader("Money Sources", "Money Sources (such as bank accounts, cash , etc)");

displayForm();

printFooter();

database::mydbDisconnect();
