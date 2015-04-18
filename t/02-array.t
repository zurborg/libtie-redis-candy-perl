use Test::More;
use Tie::Redis::Candy qw(redis_array);
use t::Redis;
 
test_redis(sub {
    my ($redis) = @_;
    plan tests => 1;
    
    my $A = redis_array($redis, 'A', 1, 2, 3);
    
    push @$A => 4, 5, 6;
    
    is_deeply($A => [qw[ 1 2 3 4 5 6 ]]);
    
    @$A = ();
});

done_testing;
