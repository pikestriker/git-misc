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

printHeader("User Groups", "Which groups users have access to");

processFields();

displayForm();

printFooter();

database::mydbDisconnect();

##!/usr/bin/perl -w
#
#use strict;
#use database;		# my defined perl module
#use CGI;
#use CGI::Session;
#use POSIX;		# using this for dates
#
#my $cgi        = new CGI();
#my $curSess    = CGI::Session->load();
#my $websiteURL = "http://localhost/";
#my $scriptName = "usergroups.pl";
#my $thisScript = $websiteURL . "cgi-bin/$scriptName";
#my $loginURL   = $websiteURL . "cgi-bin/login.pl";
#my $formName   = "usergroups";
#
#if (!defined($curSess) || $curSess->is_empty() || $curSess->is_expired())
#{
#  print $cgi->redirect($loginURL . "?referer=$thisScript");
#}
#
## get all the session parameters and cgi parameters
#my $firstName    = $curSess->param('first_nm');
#my $surName      = $curSess->param('sur_nm');
#my $userId       = $curSess->param('user_id');
#my $groupCd      = $cgi->param('group_cd');
#my $oldGroupCd   = $cgi->param('old_group_cd');
#my $formUser     = $cgi->param('form_user');
#my $oldFormUser  = $cgi->param('old_form_user');
#my $groupCdMark  = "";
#my $formUserMark = "";
#
#my $submitVal    = $cgi->param('submit');
#
#my $err = 0;
#my $formError = 0;
#my $addOrUpdate = "Add";
#my $numRegEx = "[+-]?\\d+\\.?\\d{0,2}";
#my $dateRegEx = "\\d{4}-\\d{2}-\\d{2}";
#
#sub processFields
#{
#  if ($submitVal eq "Add" or $submitVal eq "Update")
#  {
#    # all records should be present
#    if (defined($groupCd) && defined($formUser) &&
#        $groupCd ne "" &&  $formUser ne "")
#    {
#      if ($submitVal eq "Add" && !$formError)
#      {
#        $err = database::addUserGroup($formUser, $groupCd, $userId);
#      }
#      elsif ($submitVal eq "Update" && !$formError)
#      {
#        $err = database::updateUserGroup($formUser, $groupCd, $oldFormUser, $oldGroupCd, $userId);
#      }
#    }
#    else
#    {
#      if (!defined($formUser) || $formUser eq "")
#      {
#        $formUserMark = "Required field";
#      }
#      
#      if (!defined($groupCd) || $groupCd eq "")
#      {
#        $groupCdMark = "Required field";
#      }
#      
#      $formError = 1;
#    }
#  }
#  elsif ($submitVal eq "Delete")
#  {
#    $err = database::deleteUserGroup($formUser, $groupCd);
#  }
#}
#
#database::mydbConnect();
#
#if ($submitVal)
#{
#  processFields();
#}
#
#print $curSess->header(),
#      $cgi->start_html(-title => "User/Groups Relationship",
#                       -style => {'src' => '/css/mainstyles'});
#
#print "<p>Currently logged in as $surName, $firstName</p>\n";
#print "<h1>User/Groups Relationship</h1>\n";
#
#if ($err)
#{
#  print $cgi->p($database::dbErrMsg);
#  $formError = 1;
#}
#
#$err = database::getAllUserGroups();
#
#if ($err < 0 && $err != database::NO_REC)
#{
#  print $cgi->p($database::dbErrMsg . database::NO_REC);
#}
#else
#{
#  $err = 0;
#  my $records = $database::resRef;
#  print <<endTag;
#        <table class="basic">
#        <tr>
#        <td class="basic"><b>User</b></td><td class="basic"><b>Group</b></td>
#        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
#        </tr>
#endTag
#  foreach my $ref (@$records)
#  { 
#    print <<endTag;
#          <tr>
#endTag
#    database::getUserById($ref->{'userid'});
#    my $userRec = $database::resRef;
#    
#    print "<td class=\"basic\">$userRec->[0]->{'user_nickname'}</td>\n";
#    print <<endTag;
#          <td class="basic">$ref->{'group_cd'}</td>
#          <td class="basic"><a href="/cgi-bin/$scriptName?form_user=$ref->{'userid'}&group_cd=$ref->{'group_cd'}&submit=UpdateRec">Update</a></td>
#          <td class="basic"><a href="/cgi-bin/$scriptName?form_user=$ref->{'userid'}&group_cd=$ref->{'group_cd'}&submit=Delete">Delete</a></td>
#          </tr>
#endTag
#  }
#  print "</table>\n";
#  my $singleRec;
#  if ($submitVal eq "UpdateRec")
#  {
#    $err = database::getUserGroup($formUser, $groupCd);
#    $singleRec = $database::resRef->[0];
#    $addOrUpdate = "Update";
#  }
#  
#  if ($err)
#  {
#    print $cgi->p($database::dbErrMsg);
#  }
#  else
#  {
#    database::getAllListofValuesByCatCd("GROUP");
#    my $groupList = $database::resRef;
#    if ($submitVal eq "UpdateRec")
#    {
#       $groupCd = $singleRec->{'group_cd'};
#       $formUser = $singleRec->{'userid'};
#       $oldGroupCd = $groupCd;
#       $oldFormUser = $formUser;
#    }
#    elsif (!$submitVal || !$formError)
#    {
#      $groupCd = "";
#      $formUser = "";
#      $oldGroupCd = "";
#      $oldFormUser = "";
#    }
#
#    print <<endTag;
#          <form name="$formName" method="POST" action="/cgi-bin/$scriptName">
#          <input type="hidden" name="old_form_user" value="$oldFormUser" />
#          <input type="hidden" name="old_group_cd" value="$oldGroupCd" />
#          <table><tr><td>User Nickname:</td><td>
#          <input type="text" name="form_user" size="15" maxlength="15" value="$formUser" />
#          </td><td><div class="mark">$formUserMark</div></td></tr>
#          <tr><td>Group Code:</td><td>
#          <select name="group_cd">
#endTag
#    foreach my $ref (@$groupList)
#    {
#      print "<option value=\"$ref->{'lov_cd'}\"";
#      
#      if ($groupCd eq $ref->{'lov_cd'})
#      {
#        print " selected";
#      }
#      print ">$ref->{'lov_cd'}</option>\n";
#    }
#    print <<endTag;
#          </select></td><td><div class="mark">$groupCdMark</div></td></tr>
#          </table>
#          <input type="reset" name="reset" />
#          <input type="submit" name="submit" value="$addOrUpdate" />
#          </form>
#endTag
#      
#  }
#}
#
#print $cgi->end_html();
#
#database::mydbDisconnect();
