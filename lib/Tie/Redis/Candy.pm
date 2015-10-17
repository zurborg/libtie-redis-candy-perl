use strictures 2;

package Tie::Redis::Candy;

# ABSTRACT: Tie Redis to HashRef or ArrayRef

use Redis;
use Tie::Redis::Candy::Hash;
use Tie::Redis::Candy::Array;
use Exporter qw(import);

# VERSION

our @EXPORT_OK = qw(redis_hash redis_array);

=head1 SYNOPSIS

    use Tie::Redis::Candy qw(redis_hash redis_array);
    
    my $redis = Redis->new(...);
    
    my $hashref = redis_hash($redis, $prefix, %initial_values);
    $hashref->{foo} = 'bar';
    
    my $arrayref = redis_array($redis, $listname, @initial_values);
    push @$arrayref => ('foo', 'bar');

=head1 DESCRIPTION

This module is inspired by L<Tie::Redis> and L<Redis::Hash>/L<Redis::List>.

=head1 SERIALIZATION

Serialization is done by L<CBOR::XS> which is fast and light.

=head1 EXPORTS

Nothing by default. L</redis_hash> and L</redis_array> can be exported on request.

=cut

=func redis_hash ($redis, $prefix, %initial_values);

C<$redis> must be an instance of L<Redis> or L<AnyEvent::Redis>. C<$prefix> is optional. With prefix, all keys in the hashref will prefixed with C<"$prefix:">. Set to undef when you want use the entire Redis DB as data source.

=cut

sub redis_hash {
    my ($redis, $prefix, %init) = @_;
    tie(my %hash, 'Tie::Redis::Candy::Hash', $redis, $prefix);
    $hash{$_} = delete $init{$_} for keys %init;
    bless(\%hash, 'Tie::Redis::Candy::Hash');
}

=func redis_array ($redis, $listname, @initial_values);

Behaves similiar to L</redis_hash>, except that C<$listname> is required.

=cut

sub redis_array {
    my ($redis, $listname, @init) = @_;
    tie(my @array, 'Tie::Redis::Candy::Array', $redis, $listname);
    while (my $item = shift @init) {
        push @array => $item;
    }
    bless(\@array, 'Tie::Redis::Candy::Array');
}

1;
