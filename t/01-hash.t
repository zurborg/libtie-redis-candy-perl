use Test::More;
use Tie::Redis::Candy qw(redis_hash);
use t::Redis;
 
test_redis(sub {
    my ($redis) = @_;
    plan tests => 6;
    
    my $W = redis_hash($redis, 'H', init_W => 'x', foo => 1);
    my $R = redis_hash($redis, 'H', init_R => 'y', foo => 2);
    
    ok $W->{scalar} = 42;
    is $R->{scalar} , 42;
    
    ok $W->{hash} = { a => 16 };
    is $R->{hash}->{a}, 16;

    is $R->{nonexistent} => undef;

    is_deeply $R => {
        scalar => 42,
        hash => { a => 16 },
        init_W => 'x',
        init_R => 'y',
        foo => 2,
    };
});

done_testing;
