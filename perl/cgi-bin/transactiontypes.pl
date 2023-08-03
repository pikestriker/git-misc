#!C:\strawberry\perl\bin\perl -w

use strict;
use database;
use CGI;
use CGI::Session;
use CGI::Carp qw( warningsToBrowser fatalsToBrowser );
use utilities qw( redirectIfNotPrivy
									printHeader
									displayForm
									processFields
									printFooter );
									
database::specialSpecialConnect();

redirectIfNotPrivy();

processFields();

printHeader("Transaction Types", "Transaction Types");

displayForm();

printFooter();

database::specialSpecialDisconnect();
