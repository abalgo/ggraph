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

