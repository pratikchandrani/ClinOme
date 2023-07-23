# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Set-IntervalTree.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Set::IntervalTree') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
$|=1;

my $tree = Set::IntervalTree->new;
ok($tree);

my $count = 1000;
my $domain = 1000;
print "Inserting $count nodes into [0,$domain].\n";
srand(time);

my $i;
for $i (0..$count-1) {
  my $low = int(rand() * $domain);
  my $high = int((rand() * ($domain-$low))+$low);
  $tree->insert($i,$low,$high);
#  print "Added: [$low,$high]\n";
  print "*" if !($i%25000);
}
print "\n";
# print "Tree: ".$tree->str;

my $low = $domain * 0.4;
my $high = $domain * 0.5;
print "Enumerating intervals between $low and $high\n";
my $results = $tree->fetch($low,$high);
ok($results);
print scalar(@$results)." intervals found.\n";

# for my $i (0..$#$results) {
#   print $results->[$i].","; 
# }
print "\n";

exit 0;

