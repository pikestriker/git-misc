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

printHeader("Income Expenses", "Income Expenses");

displayForm();

printFooter();

database::mydbDisconnect();
