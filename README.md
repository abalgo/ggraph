# ggraph
Git Graph script - a branch oriented representatiion

This is a really first version of this script.

The motivation was this: http://www.abalgo.com/en/node/10

You will find here the graph.pl script which is a simple perl script that you can put in your path.

Personnaly, I've done an alias gg = '/local/bin/ggraph.pl -a -- --date=short'

I provided also the hooks I'm using to directly add the branch name as prefix
of my commit comments:

Simply copy these hooks in .git/hooks repository or in a central place and use
the hookpath config variable:

hooksPath = /local/githooks




     Description: ggraph.pl - git graphical branch representation

          This small script was written to overcome the often
          incomprehensible representation of GIT.
          As GIT does not record the evolution of branches, this script
          requires some constraints in order to always work properly:

          - always refuse fast-forward during merges (--no-ff option)
          - do not modify automatic merge comments

          Note: during a "pull", fast-forward may be used. In this case,
          the different site branches will be considered as one.

          It is also possible to help the script (and the user) to find
          easily the name of the branches of each commit, it suffices
          to precede each commit comment with the name of the branch followed by ":". For example:
          git commit -m "MyBranchName: my comment of commit"
          It is possible to do this automatically using hooks.

          This script supports this "add-on" and can, in this case, be more
          reliable, even when fast-forward was used.

          In the output representation:
             @ means the first commit of a branch
             O means a commit in branch
             V means the latest local commit of branch
             The characters "-" "+" "|" ">" "<" draw simply arrows.

             <= Branchname means the start commit of a branch
             => Branchname means the end commit of a branch

     output example with option -r -e:

                    0377072 | |   |   V => bugfix1 : Tuning the scale (Arn.. : 2020-02-26)
                            | |   |   |
                    802ee87 | |   O<--+    feat1   : Merge branch bugfix1 (Arn.. : 2020-02-26)
                            | |   |
                    99bf14d O<----+        master  : Merge branch feat1 (Arn.. : 2020-02-26)
                            | |   |
                    29f4e58 | |   V     => feat1   : add gitignore (Arn.. : 2020-02-27)
                            | |   |
                    56392cc V<----+     =>*master  :*Merge branch feat1 (Arn.. : 2020-02-27)
                              |
                    d56bcdd   O            utils   : add option parser (Arn.. : 2020-03-03)
                              |
                    ff373dd   V         => utils   : change the default output (Arn.. : 2020-03-04)



     Usage:     ggraph.pl [-h] [-e] [-r] [-I] [-a] [-f format] -- [git log options]

          -a   : --all commits
          -e   : expand (add one line between each commit)
          -r   : reverse order (latest commit at the end)
          -n   : no color
          -f   : git pretty format to use as output
                 in format, you can use the non standard placeholders:
                 %Xz for the branch shape
                 %Xb for the branch
                 %Xw for the branch optimum width
                 %XG the full graph + header + branchname with optimum width"
                 %XB for the branch anchors (<= for starting branch, => for ending branch)
                 %Xs for the stripped subject (subject without banch name in header)
                 %Xc "*", mark the current
                 %C(branch) for the branch color
                 default format is : "%XG: %C(reset)%h %C(branch)%Xs"
          -I   : ignore additional branch information


     Examples :
          ggraph.pl -a -f "%C(blue)%XB %Xb%C(reset) - %Xs (%d)"
          ggraph.pl -a -f "%XG: %C(reset)%h %C(branch)%Xs %C(reset) (%cn: %ar)"
          ggraph.pl  -e -a -f "%h %XG: %Xs%C(reset) (%<(5,trunc)%cn : %ad)" -- --date=short
          ggraph.pl  -e -a -f "%h %C(branch)%Xw%Xz%C(branch)%XB %Xs%C(reset) (%<(5,trunc)%cn : %ad)" -- --date=short
