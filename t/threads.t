use strict;
use warnings;

# XXX: at the moment testing only the survival of GTop objects with
# threads, see the TODO file for remaining parts

my $threads;
BEGIN {
    use Test::More;
    use Config;
    unless ($] >= 5.008 && $Config{useithreads}) {
        plan skip_all => 'perl 5.8+ w/ ithreads is required';
    }
    else {
        $threads = 3;
        plan tests => 2 + ($threads+1);
    }
}

BEGIN { use_ok('GTop') };

# the object is intentionally global, so perl won't destroy it right
# away
our $gtop = GTop->new;

require threads;

access_test();

# as the new threads are spawned they will inherit the count from the
# main thread
threads->new(\&access_test)->detach for 1..$threads;

sub access_test {
    print "# $$ mem size: \n";
    my $proc_mem = $gtop->proc_mem($$);
    my $mem_size = $proc_mem->size;
    print "# $$ mem size: $mem_size\n";

    ok $mem_size > 0;
}

# workaround the situations where the main thread exits before the
# child threads, which shouldn't be a problem since all threads are
# detached, but something is broken in perl
select(undef, undef, undef, 0.25); # sleep 0.25sec

END { ok 1; }

