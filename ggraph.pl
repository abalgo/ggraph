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
#           
#           This script supports this "add-on" and can, in this case, be more
#           reliable, even when fast-forward was used.
#
#           In the output representation:
#              @ means the first commit of a branch
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
#              
#
#      Usage:     ggraph.pl [-h] [-e] [-r] [-I] [-a] [-f format] -- [git log options]
#       
#           -a   : --all commits
#           -e   : expand (add one line between each commit)
#           -r   : reverse order (latest commit at the end)
#           -n   : no color
#           -f   : git pretty format to use as output
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
#           -I   : ignore additional branch information 
#           
#
#      Examples : 
#           ggraph.pl -a -f "%C(blue)%XB %Xb%C(reset) - %Xs (%d)"
#           ggraph.pl -a -f "%XG: %C(reset)%h %C(branch)%Xs %C(reset) (%cn: %ar)"
#           ggraph.pl  -e -a -f "%h %XG: %Xs%C(reset) (%<(5,trunc)%cn : %ad)" -- --date=short
#           ggraph.pl  -e -a -f "%h %C(branch)%Xw%Xz%C(branch)%XB %Xs%C(reset) (%<(5,trunc)%cn : %ad)" -- --date=short
#
#
#------------------------------------------------------------------------------
EOF
exit;
} #end sun usage
use strict;

my $flExp=0;
my $flRev=0;
my $flIgnore=0;
my $flAll=1;
my $flNocolor=0;
my $format = $ENV{'GGRAPH_FORMAT'} || "%C(reset)%h %XG:%Xc%C(branch)%Xs %C(reset)(%<(5,trunc)%cn : %ad)"; 
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
           "expand|e", \$flExp,
           "reverse|r", \$flRev,
           "no-color|n", \$flNocolor,
           "ignore|I", \$flIgnore,
           "format|f=s", \$format,
           "help|h", \&usage) or usage;
$flAll="--all " if $flAll;
@clst=  ("","","","","","","") if $flNocolor;

# %C(branch) is not natively recognised in git format
$format =~ s/\%C\(branch\)/%%C(branch)/g;

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

my %strcol;
my %strinterlinecol={};
my $hhead;

# reading the refs to assign branch when unique
# When is is not unique, it means that a fast-forward was
# used and there is an uncertaintly about the branch name
open(F,'git show-ref |') || die $!;
while(<F>) {
   chop;
   chomp;
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

for my $bra (keys(%brid)) {
   my $h = $brid{$bra};
   $nidbr{$h}++;   
   $idbr{$h} .= "$bra ";
   # Must be checked when multiple branch point to one commit
   $commit{$h}{'branch'}=$bra;
}




# Now parsing the git log output
# to establish the branchname 

my @logs = `git log $flAll --color --date-order @ARGV --pretty=format:"%Xb: %P: %H: %s ::: $format"`;
@logs =grep(s/[\r\n]*//g, @logs);
my $curref = `git rev-parse HEAD`;
$curref =~ s/[\r\n]*//g;
my $cn=0; # commit reverse number

foreach my $l (@logs) {
   #my($Xb,$p,$h,$cb, $txt, $output) = split(/: /,$l);
   my($Xb,$p,$h,$cb, $txt, $output) = ($1, $2, $3, $5, $6, $7) if $l =~ /^(.*?): (.*?): (.*?): ((.*?): )?(.+?) ::: (.*)$/;
   $txt=$cb unless $txt;
   $commit{$h}{'number'}=$cn++;
   
   #reset the additional info when Ignore is activated
   if ($flIgnore) {
      $Xb="";
      $cb="";
   }
   else {
       # When branch in commit is not supported, %Xb is not relevant
       $Xb = "" if $Xb eq "%Xb"; 
       
       # when hook is used to add in branchname: in header of the subject
       # we can recover it easily but it must match with an existing branchname   
       # So, is must be reset when it does not match with a branchname
       $cb= "" unless $brid{$cb}; 
   }
   
   # Assignment of a branch when possible   
   $commit{$h}{'branch'} = $commit{$h}{'branch'}||$Xb||$cb;
   $commit{$h}{'parent'} = $p;
   $commit{$h}{'subject'} = $txt;
   $commit{$h}{'output'} = $output;
   $commit{$_}{'child'} .= "$h " for (split(/ /, $p));  
}

# second pass try to identify the branch, based
# on the standard Merge comment
 foreach my $l (@logs) {
   my($Xb,$p,$h) = split(/: /,$l);
   if ($commit{$h}{'subject'} =~ /Merge branch '([^']+)'( into (.+))*/i ) {
      if ($brid{$1}) {
	     my $hp=substr($commit{$h}{'parent'},-40);
         $commit{$hp}{'branch'}=$1 unless $commit{$hp}{'branch'} ne "";		 
	     $commit{$h}{'branch'} = $3 if $2 && $brid{$3} ne "" && (!$commit{$h}{'branch'}) ;
	  }
   }
   elsif ($commit{$h}{'subject'} =~ /Merge branch *(\S+) *( into (.+))*/i ) {
      if ($brid{$1}) {
	     my $hp=substr($commit{$h}{'parent'},-40);
         $commit{$hp}{'branch'}=$1 unless $commit{$hp}{'branch'} ne "";		 
	     $commit{$h}{'branch'} = $3 if $2 && $brid{$3} ne "" && (!$commit{$h}{'branch'}) ;
	  }
   }
}  



# a third pass is done to assign branch to commit having only one child
# having only one branch
foreach my $l (@logs) {
   my($Xb,$p,$h) = split(/: /,$l);
   $commit{$h}{'branch'} = $commit{substr($commit{$h}{'child'},0,40)}{'branch'} unless $commit{$h}{'branch'} || length($commit{$h}{'child'})!=41;
}

# now that all direct branch assignment are done,
# a third pass is necessary to identify the branch of 
# commit for which branch are not correctly identified
my %lastreftobranch={};
foreach my $l (@logs) {
   my($Xb,$p,$h) = split(/: /,$l);

   $commit{$h}{'branch'} = branchsearch($h,"") unless $commit{$h}{'branch'};
   $lastreftobranch{$commit{$h}{'branch'}} = $h unless $lastreftobranch{$commit{$h}{'branch'}} ne "";
   for my $tmp (split(/ +/, $p)) {
      $lastreftobranch{$commit{$tmp}{'branch'}} = $h unless $lastreftobranch{$commit{$tmp}{'branch'}} ne "";
   }
}
my %branchcol={};
my %branchfirst={};
my %colbusy={};

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
my $fl=1;
my $maxcol=0;
my %colbr;
my %branchcol;


foreach my $l (reverse @logs) {
   my($Xb,$p,$h) = split(/: /,$l);
   $commit{$h}{'branch'}="master" if ($fl==1);
   if ($commit{$h}{'branch'} eq "") {
      if ($fl==1) {
	     $commit{$h}{'branch'}="master";
	  }
	  else{
	     $commit{$h}{'branch'}=$commit{substr($commit{$h}{'parent'},0,40)}{'branch'}
	  }
   }
   $fl=0;
}



# graph string construction
# for each commit, parsing is done to
# determine relationship with
# branches

$fl=1;
foreach my $l (reverse @logs) {
   my($Xb,$p,$h) = split(/: /,$l);
   my $br=$commit{$h}{'branch'};
   if ($h =~/7e21efa/) {
       print "stop\n";
   }
   if ($branchcol{$br}==0) {
      if ($fl==1) {
	      $branchcol{$br}=1;
	  }
	  else {
	      # in case of first commit of a branch, there is only one parent
		  # so, no need to extract a substring         
	      $branchcol{$br}=firstfreecolumn($branchcol{$commit{substr($commit{$h}{'parent'},0,40)}{'branch'}}+1);
	  }
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
            for my $tmp (split(/ +/, $p)) {
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
             $char = "V";
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
   $fl=0;
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
foreach my $l ($flRev ? reverse @logs : @logs) {
   my($Xb,$p,$h) = split(/: /,$l);
   my $oe;
   my $head= "  ";
   my $bcol=$clst[$branchcol{$commit{$h}{'branch'}} %7 ];
   my $br = $commit{$h}{'branch'};
   my $subject = $commit{$h}{'subject'};
   my $g = $strcol{$h};
   my $strbranch = sprintf("%-" . ($maxlen) . "s", $br );
   $head = "=>" if $strcol{$h} =~ /V/;
   $head = "<=" if $strcol{$h} =~ /\@/;
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

