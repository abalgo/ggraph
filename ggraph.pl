#!/usr/bin/env perl
#
use POSIX;
use Getopt::Long;
sub usage {
print <<EOF ;
#------------------------------------------------------------------------------
#
#                   ggraph.pl : git graphical branch representation
#                   -----------------------------------------------
#
#      MIT License
#
#           Copyright (c) 2020 Arnaud Bertrand
#
#           Permission is hereby granted, free of charge, to any person obtaining a copy
#           of this software and associated documentation files (the "Software"), to deal
#           in the Software without restriction, including without limitation the rights
#           to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#           copies of the Software, and to permit persons to whom the Software is
#           furnished to do so, subject to the following conditions:
#
#           The above copyright notice and this permission notice shall be included in all
#           copies or substantial portions of the Software.
#
#           THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#           IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#           FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#           AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#           LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#           OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#           SOFTWARE.
#
#
#
#
#      Description: ggraph.pl - git graphical branch representation
#
#           This small script was written to overcome the often
#           incomprehensible representation of GIT.
#           As GIT does not record the evolution of branches, this script
#           requires some constraints in order to always work properly:
#
#           - always refuse fast-forward during merges (--no-ff option)
#           - do not modify automatic merge comments
#
#           Note: during a "pull", fast-forward may be used. In this case,
#           the different site branches will be considered as one.
#
#           It is also possible to help the script (and the user) to find
#           easily the name of the branches of each commit, it suffices
#           to precede each commit comment with the name of the branch followed by ":". For example:
#           git commit -m "MyBranchName: my comment of commit"
#           It is possible to do this automatically using hooks.
#           This script supports this "add-on" and can, in this case, be more
#           reliable, even when fast-forward was used.
#
#           Another way to help the script is to add tags on commits for
#           which branch in unknown. The tag must have the following format:
#           \@BranchName or \@BranchName\@xxx or \@BranchName--xxx or \@BranchName__xxx or \@BranchName##xxx
#           where xxx is whatever you want
#           the branchname is case sensitive
#
#           In the output representation:
#              \@ means the first commit of a branch
#              O means a commit in branch
#              V means the latest local commit of branch
#              The characters "-" "+" "|" ">" "<" draw simply arrows.
#
#              <= Branchname means the start commit of a branch
#              => Branchname means the end commit of a branch
#
#      output example with option -r -e:
#
#                     0377072 | |   |   V => bugfix1 : Tuning the scale (Arn.. : 2020-02-26)
#                             | |   |   |
#                     802ee87 | |   O<--+    feat1   : Merge branch bugfix1 (Arn.. : 2020-02-26)
#                             | |   |
#                     99bf14d O<----+        master  : Merge branch feat1 (Arn.. : 2020-02-26)
#                             | |   |
#                     29f4e58 | |   V     => feat1   : add gitignore (Arn.. : 2020-02-27)
#                             | |   |
#                     56392cc V<----+     =>*master  :*Merge branch feat1 (Arn.. : 2020-02-27)
#                               |
#                     d56bcdd   O            utils   : add option parser (Arn.. : 2020-03-03)
#                               |
#                     ff373dd   V         => utils   : change the default output (Arn.. : 2020-03-04)
#
#      In some situations, ggraph is unable to detect correctly the branch, in these case, 
#      some sumptions are done and branchname will be prefixed by ??? to notify the user 
#      about the uncertaintly
#
#      In other situations due to manipulations of commits or branches, some commits are issued from
#      2 commits of the same branch. It is, of course, impossible to represent this respecting the
#      linear representation of branches. The choice that was done is to notify the user that the 
#      commits and its parents are not correctly linked on the graph by adding the postfix !!!
#      to the name of the banch.
#
#      Usage:     ggraph.pl [-h] [-e] [-r] [-I] [-a] [-f format] -- [git log options]
#
#           --all            : include everything, stash and alone commit included
#           --expand, -e     : expand (add one line between each commit)
#           --delete, -d     : allow detection of deleted branches (represent a fictive branch)
#           --file  path     : for one file only
#           --format, -f "format"   : git pretty format to use as output
#                  in format, you can use the non standard placeholders:
#                  %Xz for the branch shape
#                  %Xb for the branch
#                  %Xw for the branch optimum width
#                  %XG the full graph + header + branchname with optimum width"
#                  %XB for the branch anchors (<= for starting branch, => for ending branch)
#                  %Xs for the stripped subject (subject without banch name in header)
#                  %Xc "*", mark the current
#                  %C(branch) for the branch color
#                  default format is : "%XG: %C(reset)%h %C(branch)%Xs"
#           --ignore, -I     : ignore all additional branch information
#           --help, -h       : Display this help page
#           --ignore-comment : ignore information about branch in comment
#           --ignore-mergecomment : ignore information about branch in merge comment
#           --ignore-tags    : ignore tags additional information
#           --ignore-Xb      : ignore internal branch information
#           --no-color, -n   : no color
#           --no-remote      : don't display remote only branches 
#           --reverse,  -r   : reverse order (latest commit at the end)
#           --this           : consider only this branch
#
#      Examples :
#           ggraph.pl -f "%C(blue)%XB %Xb%C(reset) - %Xs (%d)"
#           ggraph.pl -f "%XG: %C(reset)%h %C(branch)%Xs %C(reset) (%cn: %ar)"
#           ggraph.pl -ef "%h %XG: %Xs%C(reset) (%<(5,trunc)%cn : %ad)" -- --date=short
#           ggraph.pl -ef "%h %C(branch)%Xw%Xz%C(branch)%XB %Xs%C(reset) (%<(5,trunc)%cn : %ad)" -- --date=short
#
#
#------------------------------------------------------------------------------
EOF
exit;
} #end sun usage
use strict;

my $flExp=0;
my $flDelete;
my $flRev=0;
my $flIgnore=0;
my $flIgnoreTags=0;
my $flIgnoreComments=0;
my $flIgnoreXb=0;
my $flNoRemotes=0;
my $flNoBranches=0;
my $flThis=0;
my $flAll=0;
my $flNocolor=0;
my $format = $ENV{'GGRAPH_FORMAT'} || "%C(reset)%h %XG:%Xc%C(branch)%Xs %C(reset)(%<(5,trunc)%cn : %ad)";
my $flDebug=0;
my $file="";
my $flIgnoreTags=0;
my $flIgnoreComments=0;
my $flIgnoreMergeComments=0;
my $flIgnoreXb=0;
my @clst=  (
   "\e[1;31m",
   "\e[1;32m",
   "\e[1;33m",
   "\e[1;34m",
   "\e[1;35m",
   "\e[1;36m",
   "\e[1;37m");
Getopt::Long::Configure ("gnu_getopt");
GetOptions("all|a",\$flAll,
           "delete|d",\$flDelete,
           "expand|e", \$flExp,
           "reverse|r", \$flRev,
           "no-color|n", \$flNocolor,
           "ignore|I", \$flIgnore,
           "format|f=s", \$format,
           "debug|dd",\$flDebug,
           "no-remote",\$flNoRemotes,
           "no-branches",\$flNoBranches,
           "ignore-tags",\$flIgnoreTags,
           "ignore-comments",\$flIgnoreComments,
           "ignore-mergecomments",\$flIgnoreMergeComments,
           "this",\$flThis,
           "file=s",\$file,
           "help|h", \&usage) or usage;
if ($flAll) {
    $flAll="--all ";
} else {
    $flAll = ($flNoRemotes ? "" : "--remotes ") . ($flNoBranches ? "" : "--branches ");
}

$flAll="" if $flThis;
@clst=  ("","","","","","","") if $flNocolor;

if ($flIgnore) {
   $flIgnoreComments=1;
   $flIgnoreMergeComments=1;
   $flIgnoreXb=1;
   $flIgnoreTags=1;
}

# %C(branch) is not natively recognised in git format
$format =~ s/\%C\(branch\)/%%C(branch)/g;
$file = " -- $file" if $file;
my %fg = (
  'default'      => "",
  'bold'         => "\e[1m",
  'black'        => "\e[30m",
  'red'          => "\e[31m",
  'blue'         => "\e[32m",
  'yellow'       => "\e[33m",
  'green'        => "\e[34m",
  'majenta'      => "\e[35m",
  'cyan'         => "\e[36m",
  'white'        => "\e[37m",
  'bold black'   => "\e[1;30m",
  'bold red'     => "\e[1;31m",
  'bold blue'    => "\e[1;32m",
  'bold yellow'  => "\e[1;33m",
  'bold green'   => "\e[1;34m",
  'bold majenta' => "\e[1;35m",
  'bold cyan'    => "\e[1;36m",
  'bold white'   => "\e[1;37m",
);

my %bg = (
  'default'      => "",
  'black'        => "\e[40m",
  'red'          => "\e[41m",
  'blue'         => "\e[42m",
  'yellow'       => "\e[43m",
  'green'        => "\e[44m",
  'majenta'      => "\e[45m",
  'cyan'         => "\e[46m",
  'white'        => "\e[47m");
my $crst = "\e[0m";
# when color are not used, crst must be emptied
$crst = "" unless $clst[1];

my %brid={};
my %idbr={};
my %nidbr={};

my %commit={};
my $maxlen=0;
my %brDeleted={};
my %strcol;
my %strinterlinecol={};
my $hhead;
my %brTags;
my @hashes;

# reading the refs to assign branch when unique
# When is is not unique, it means that a fast-forward was
# used and there is an uncertaintly about the branch name
open(F,'git show-ref |') || die $!;
while(<F>) {
   chop;
   chomp;
   # add the branch identifier by tagging helper
   # the branchname is case sensitive
   # the syntax of the tag must be @BranchName or @BranchName@xxx or @BranchName--xxx or @BranchName__xxx or @BranchName##xxx
   # where xxx is whatever
   # it does not indicate if a branch is local or remote
   # we differentiate local and remote only when both are defined in the refs
   if (!$flIgnoreTags && m=(.+) refs/tags/\@(.+?)((--|__|\@|\#\#).*)?$=) {
      $brTags{$1}=$2;
      print STDERR "DBG: tag detected $1 $2\n" if $flDebug;
   }
   next if m|/tags/|;
   my ($h, $br)= split(/ +/);
   if (m|refs/heads/(.*)|) {
      $br=$1;
   }
   elsif (m|refs/remotes/origin/(.*)|) {
       # when there is alreay a hash for a branch,
       # we keep the local one
	   $br=$1;	
       next if $brid{$br};
   }
   else {
       next;
   }
   if ($br eq "HEAD") {
      $hhead=$h;
      next;
   }
   $brid{$br}=$h;
   $maxlen = length($br) if length($br)>$maxlen;
}
close(F);

# Assign the branch heads
for my $bra (keys(%brid)) {
   my $h = $brid{$bra};
   $nidbr{$h}++;
   $idbr{$h} .= "$bra ";
   # Must be checked when multiple branch point to one commit
   $commit{$h}{'branch'}=$bra;
}

# assign branchname of a commit when correct tag is found
foreach my $h (keys(%brTags)) {
    my $bra=$brTags{$h};
    print STDERR "DBG3: $bra - $h\n" if $flDebug;
    print STDERR "DBG4: brid $brid{$bra} \n" if $flDebug;
    if (!$brid{$bra} && $flDelete) {
       $brDeleted{$bra}=1;
       $brid{$bra}=$h;
    }
    next unless $brid{$bra}; # skip when branchname is unknown
    $commit{$h}{'branch'}=$bra;
    print STDERR "DBG: branch set $bra  => $h\n" if $flDebug;
}

# Now parsing the git log output
# to establish the branchname
print STDERR "git log $flAll   --date-order --topo-order --color @ARGV --pretty=format:\"%Xb: %P: %H: %s ::: $format\"  $file\n" if $flDebug;
my @logs = `git log $flAll  --date-order --color @ARGV --pretty=format:"%Xb: %P: %H: %s ::: $format"  $file`;
@logs =grep(s/[\r\n]*//g, @logs);

my $curref = `git rev-parse HEAD`;
$curref =~ s/[\r\n]*//g;
my $cn=0; # commit reverse number
my $idx=@logs;
foreach my $l (@logs) {
   #my($Xb,$p,$h,$cb, $txt, $output) = split(/: /,$l);
   my($Xb,$p,$h,$cb, $txt, $output) = ($1, $2, $3, $5, $6, $7) if $l =~ /^(.*?): (.*?): (.*?): ((.*?): )?(.+?) ::: (.*)$/;
   $hashes[--$idx]=$h;
   $txt=$cb unless $txt;
   $commit{$h}{'number'}=$cn++;

   #reset the additional info when Ignore is activated
   $Xb="" if $flIgnoreXb;
   $cb="" if $flIgnoreComments;

   # When branch in commit is not supported, %Xb is not relevant
   $Xb = "" if $Xb eq "%Xb";

   # when hook is used to add in branchname: in header of the subject
   # we can recover it easily but it must match with an existing branchname
   # So, is must be reset when it does not match with a branchname or create a
   # delete one if flDelete is activated
   $cb = $Xb if $Xb;
   if (!$brid{$cb}) {
       if ($flDelete) {
           $brDeleted{$cb}=1;
           $brid{$cb}=$h;
       }
       else {
           $cb="";
       }
   }

   # Assignment of a branch when possible
   $commit{$h}{'branch'} = $commit{$h}{'branch'}||$cb;
   $commit{$h}{'parent'} = $p;
   $commit{$h}{'subject'} = $txt;
   $commit{$h}{'output'} = $output;
   $commit{$_}{'child'} .= "$h " for (split(/ /, $p));
}
showall("after direct pass");

# second pass try to identify the branch, based
# on the standard Merge comment
if (!$flIgnoreMergeComments) {
    foreach my $h (@hashes) {
        if ($commit{$h}{'subject'} =~ /Merge branch *'*([^\s']+).*?( into (\S+).*)*$/i ) {
              print STDERR "DBG Merge detected : $1 ::: $3\n" if $flDebug;
              if ($flDelete && !$brid{$3}) {
                  $brid{$3}=$h;
                  $brDeleted{$3}=1;
              }
              if ($brid{$1} || $flDelete) {
                 my $hp=substr($commit{$h}{'parent'},-40);
                 if (!$brid{$1}) {
                     $brid{$1}=$hp;
                     $brDeleted{$1}=1;
                 }
                 $commit{$hp}{'branch'}=$1 unless $commit{$hp}{'branch'} ne "";		
                 $commit{$h}{'branch'} = $3 if $2 && $brid{$3} ne "" && (!$commit{$h}{'branch'}) ;
              }
         }
    }
}

showall("after second (merge comment)");
# a third pass is done to assign branch to commit having only one child
# having only one branch
foreach my $h (reverse @hashes) {
   $commit{$h}{'branch'} = $commit{substr($commit{$h}{'child'},0,40)}{'branch'} unless $commit{$h}{'branch'} || length($commit{$h}{'child'})!=41;
}
showall("after third");

# a fourth pass is used to assign branch to unique child that don't have branchname
foreach my $h (@hashes) {
   my $hp = substr($commit{$h}{'parent'},0,40);
   $commit{$h}{'branch'} = $commit{$hp}{'branch'} unless $commit{$h}{'branch'}     # already has a branchname
                                               || length($commit{$hp}{'child'})!=41  # parent has more than one child
                                               || $idbr{$hp};                      # parent is a head
}
showall("after fourth");

my @undef = grep(!$commit{$_}{'branch'}, @hashes);
my %undefh;
my $unknownprefix="";
if (@undef) {
    $unknownprefix="   ";
    print "after standard analysis, there is $clst[0]some commits whithout assigned branch !$crst\n";
    print "please try to tag some known commit to help ggraph to assign branches.\n";
    print "ggraph will make some asumptions that $clst[0]COULD BE ERRONEOUS!$crst\n\n";
    print "The concerned commit branches are marked with prefix ???\n\n\n";

    # now that all direct branch assignment are done,
    # a third pass is necessary to identify the branch of
    # commit for which branch are not correctly identified

    foreach my $h (reverse @undef) {
       $undefh{$h}=1;
       $commit{$h}{'branch'} = branchsearch($h,"") unless $commit{$h}{'branch'};
    }
    showall("after extra");

    # a last pass is done to assign branch to commit having only one child and
    # having only one branch
    # base on new element determined in extra
    foreach my $h (reverse @hashes) {
       $commit{$h}{'branch'} = $commit{substr($commit{$h}{'child'},0,40)}{'branch'} unless $commit{$h}{'branch'} || length($commit{$h}{'child'})!=41;
    }
    showall("after super extra");
}

my %lastreftobranch={};
my %branchcol={};
my %branchfirst={};
my %colbusy={};

# Now the hashes must be smartly sorted to be sure that when
# there are more than one children, all belonging another branches
# are before. It avoid a false representation: e.g.
#    +>@ <= C   : first in C
#    V   => B   : first after fork but done before in B
#    O      B   : created in B
#
# instead of
#    V | => B   : first after fork but done before in B
#    +>@ <= C   : first in C
#    O      B   : created in B
#
# So, in summary: when same parent, branch identical to parent
# must be after others
my %hidx={};
my $cidx=@hashes;
my %placedhashes;
my @newhashes=();
sub isParentPlaced($) {
   my ($h) = @_;
   my @Parents = split(/ /, $commit{$h}{'parent'});
   foreach my $c (@Parents) {
      return(0) unless $placedhashes{$c};
   }
   return(1);
}

sub isBrotherPlaced($) {
   my ($h) = @_;
   my @Parents = split(/ /, $commit{$h}{'parent'});
   my $children = "";
   for my $p (@Parents) {
       if ($commit{$p}{'branch'} eq $commit{$h}{'branch'}) {
           $children .= $commit{$p}{'child'};
       }
   }
   my @children = split(/ /, $children);
   foreach my $c (@children) {
       return(0) if !$placedhashes{$c} && ($c ne $h);
   }
   return(1);
}  

sub placeHash($) {
   my ($h) = @_;
   if (!$placedhashes{$h}) {
       $placedhashes{$h}=1;
       push(@newhashes,$h);
       prthash( "DBG: placing $h \n") if $flDebug;
   }
}
sub prthash($) {
   my ($p)=@_;
   $p =~ s/ (\S{4})\S{36}\b/ $1/g;
   print STDERR $p;
}

foreach my $h (reverse @hashes) {
    $hidx{$h}=--$cidx;
}

# can be placed only when 
# - all parents are placed
# - all children of same branch parents are placed

# - Each time there is one unplaced, loop start from first unplaced and place ony one and recheck

placeHash($hashes[0]);
my $firstunplaced=1;
my $nbunplaced=@hashes-1;
my $exception=0;
while($nbunplaced!=0) {
   my $flUnplaced=0;
   print STDERR "#Loop $firstunplaced $hashes[$firstunplaced]\n" if $flDebug;
   my $ii;
   for($ii=$firstunplaced; $ii<@hashes; $ii++) {
      next if $placedhashes{$hashes[$ii]};
      prthash("DBG: trying $hashes[$ii] $nbunplaced ".  isParentPlaced($hashes[$ii]) .  isBrotherPlaced($hashes[$ii]) . "\n") if $flDebug; 
      
      if (isParentPlaced($hashes[$ii]) && ($exception || isBrotherPlaced($hashes[$ii]) )) {
          placeHash($hashes[$ii]);
          $undefh{$hashes[$ii]}=2 if $exception;
          $nbunplaced--;   
          last if $flUnplaced;
          $exception=0;
      }
      else {
          $firstunplaced=$ii unless $flUnplaced;
          $flUnplaced=1;
      }
   }
   if ($ii==@hashes && $flUnplaced) {
       # in this condition, it means there is an impossibility
       # So, the first unplaced is placed
       print STDERR "DBG: mpossibility detected\n" if $flDebug ;
       $exception=1;
   }
}

 for(my $i=0; $i<@hashes; $i++) {
     $hashes[$i]=$newhashes[$i];
 }

foreach my $h (reverse @hashes) {
  $lastreftobranch{$commit{$h}{'branch'}} = $h unless $lastreftobranch{$commit{$h}{'branch'}} ne "";
   for my $tmp (split(/ +/, $commit{$h}{'parent'})) {
      $lastreftobranch{$commit{$tmp}{'branch'}} = $h unless $lastreftobranch{$commit{$tmp}{'branch'}} ne "";
   }
}

# this function return the first free column at the
# right of a given column
sub firstfreecolumn($) {
   my ($i)=@_;
   while($colbusy{$i}==1) { $i++; }
   return $i;
}

# now we assume the first commit is from master
# and each commit with unknown branch has the branch from
# its parent
my $maxcol=0;
my %colbr;
my %branchcol;

$commit{$hashes[0]}="master" unless $commit{$hashes[0]};
foreach my $h (@hashes) {
   if ($flDelete  && $brDeleted{$commit{$h}{'branch'}}) {
       $commit{$h}{'branch'} = "~".$commit{$h}{'branch'};
       $brid{$commit{$h}{'branch'}}=$h;
       $maxlen = length($commit{$h}{'branch'}) if length($commit{$h}{'branch'})>$maxlen;
   }
   if ($commit{$h}{'branch'} eq "") {
	     $commit{$h}{'branch'}=$commit{substr($commit{$h}{'parent'},0,40)}{'branch'};
   }
}
foreach my $bra (keys(%lastreftobranch)) {
   $lastreftobranch{"~$bra"} = $lastreftobranch{$bra} if $brDeleted{$bra};
}
# graph string construction
# for each commit, parsing is done to
# determine relationship with
# branches

$branchcol{$commit{$hashes[0]}{'branch'}}=0;
$branchfirst{$commit{$hashes[0]}{'branch'}}=$hashes[0];
$colbusy{0}=1;
$colbr{0}=$commit{$hashes[0]}{'branch'};
foreach my $h (@hashes) {
   my $br=$commit{$h}{'branch'};

   if ($branchcol{$br}==0) {
      # in case of first commit of a branch, there is only one parent
      # so, no need to extract a substring but it is done in case of false first
      # due to bad meta information
	  $branchcol{$br}=firstfreecolumn($branchcol{$commit{substr($commit{$h}{'parent'},0,40)}{'branch'}}+1);
	  $maxcol = $branchcol{$br} if $branchcol{$br}>$maxcol;
	  $branchfirst{$br}=$h;
	  $colbusy{$branchcol{$br}}=1;
	  $colbr{$branchcol{$br}}=$br;
   }

   my $col = $branchcol{$br}; # the column of the current branch;

   my $mergeleft=0;
   my $mergeright=0;
   # in case of horizontal link, colparent is different of col
   my $colparent=$branchcol{$commit{substr($commit{$h}{'parent'},0,40)}{'branch'}};

   # situation is identical in case of merge, the second parent is the horizontal
   # column to consider
   $colparent = $branchcol{$commit{substr($commit{$h}{'parent'},41,40)}{'branch'}} if length($commit{$h}{'parent'})>41;
   $strcol{$h} = "";
   $strinterlinecol{$h} = "";
   for(my $i=1; $i<=$maxcol;$i++) {
      my $char = " ";
      my $linkchar = " ";
      my $flIn = 0;
      if ($colparent != $col) { # there is an horizontal link
         $flIn = ($i>=$colparent && $i<$col) || ($i>=$col && $i<$colparent);
         if ($flIn) {
            if ($i+1==$col) {
               $linkchar=">";
            }
            elsif ($i==$col) {
               $linkchar="<";
            }
            else {
               $linkchar="-" if $i != $colparent || $colparent < $col;
            }
            # test when the column is the column of a parent
			$char = "-";
            for my $tmp (split(/ +/, $commit{$h}{'parent'})) {
                $char = "+" if $branchcol{$commit{$tmp}{'branch'}}==$i;
            }			
         }
         $char="+" if $i==$colparent; # needed when parent is on the right
      }

      if ($colbusy{$i}) {
          if($branchfirst{$br} eq $h && $col==$i) {
             $char = "@";
          }
           elsif($brid{$br} eq $h && $col==$i) {
             $char = "#";
          }
		  elsif($lastreftobranch{$br} eq $h && $col==$i) {
              ## $char =  = "+";
          }
          elsif($i ne $col) {
             $char = "|" if $char eq " ";
          }
          elsif($i eq $col) {
             $char = "O";
          }
      }
      $colbusy{$i}=0 if $h eq $lastreftobranch{$colbr{$i}};
	  my $c=$clst[$i % 7];
	  $c=$clst[$colparent % 7] if $flIn && $col != $i;
      $strcol{$h} .= $c.$char.$clst[$colparent % 7].$linkchar.$crst;

      $strinterlinecol{$h}.= ($colbusy{$i} ?$clst[$i % 7]. "| ".$crst : "  ");
   }
}

#optimize graph length :
# due to color chars, the printf formatting does not work
# So, it is necessary to format it manually.
# note that the $maxcol variable contains the information of the max
my $i=@logs-1;
my $factor= ($crst eq "" ? 2 : 20);
my $maxtest = $maxcol * $factor;
my $fillstr = $clst[1] . $clst[1]  . $crst . "  " ;
foreach my $x (keys(%commit)) {
    if (length($strcol{$x})<$maxtest) {
        $strcol{$x} .= $fillstr x ($maxcol - length($strcol{$x})/$factor);
    }
}

# Display results
#-----------------
foreach my $h ($flRev ? @hashes : reverse @hashes) {
   my $oe;
   my $head= "  ";
   my $bcol=$clst[$branchcol{$commit{$h}{'branch'}} %7 ];
   my $br = $unknownprefix . $commit{$h}{'branch'};
   $br = "???" . $commit{$h}{'branch'} if $undefh{$h}==1;
   $br =  $commit{$h}{'branch'} . " !!!"  if $undefh{$h}==2;
   my $subject = $commit{$h}{'subject'};
   my $g = $strcol{$h};
   my $strbranch = sprintf("%-" . ($maxlen) . "s", $br );
   $head = "=>" if $strcol{$h} =~ /\@/;
   $head = "<=" if $strcol{$h} =~ /\#/;
   my $o = $commit{$h}{'output'};
   my $cur = ($curref eq $h ? "*" : " ");
   $o =~ s/\%C\(branch\)/$bcol/g;
   $o =~ s/\%Xb/$br/g;
   $o =~ s/\%Xw/$strbranch/g;
   $o =~ s/\%XB/$head/g;
   $o =~ s/\%Xz/$g/g;
   $o =~ s/\%XG/$g$bcol$head$cur$strbranch/g;
   $o =~ s/\%Xs/$subject/g;
   $o =~ s/\%Xc/$cur/g;
   if ($flExp) {
      $oe = $o;
      $oe =~ s/^(.*)\Q$g\E.*$/$1/;
      #$oe =~ s/\$crst\E//g;
      $oe =~ s/\x1b\[[0-9;]*[mG]//g;
      $oe =~ s/./ /g;

   }
   print "$oe$strinterlinecol{$h}\n" if $flExp && !$flRev;
   print "$o\n";
   print "$oe$strinterlinecol{$h}\n" if $flExp && $flRev;
}

# recursive function branchsearch
sub branchsearch($ $) {
   my ($h,$full) = (@_);
   return $commit{$h}{'branch'} if $commit{$h}{'branch'} ne "";

   #circular search detection
   return "" if $full =~ /$h /;

   if ($commit{$h}{'subject'} =~ /Merge branch '([^']+)'( into (.+))*/ ) {
      if ($brid{$1}) {
	     my $hp=substr($commit{$h}{'parent'},-40);
         $commit{$hp}{'branch'}=$1 unless $commit{$hp}{'branch'} ne "";		
	     return $3 if $2 && $brid{$3} ne "";
	  }
   }

   # in case of multiple children, take assumption that the last one
   # (first encounted in log) is the branch
   # It can be erronenous in some case
   return branchsearch(substr($commit{$h}{'child'},0,40), "$full$h ") if length($commit{$h}{'child'})>41;

   return "";

}

sub abbrev {
    #return substr($_[0],0,2)." ";
    return join(" ", map {substr($_,0,2)} split(/ /,$_[0]));
}

sub showall($) {
   return unless $flDebug;
   my ($x)=@_;

   print "\n$x\n##########################################################\n";
   foreach my $h (@hashes) {
      print abbrev($h). " => $commit{$h}{branch} : $commit{$h}{subject}   PARENT:". abbrev($commit{$h}{'parent'})."    CHILD:". abbrev($commit{$h}{'child'}). "\n";
   }
}
