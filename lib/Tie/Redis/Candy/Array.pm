# This file was part of Redis, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
# Copyright (c) 2015 by Pedro Melo, Damien Krotkine.

package Tie::Redis::Candy::Array;

# ABSTRACT: tie Perl arrays to Redis lists - the candy way

use strict;
use warnings;
use Carp;
use CBOR::XS qw(encode_cbor decode_cbor);
use base qw/Tie::Array/;

# VERSION

=head1 SYNOPSYS

    my $redis = Redis->new;
    
    tie @my_list, 'Tie::Redis::Candy::List', 'list_name', $redis;
    
    $value = $my_list[$index];
    $my_list[$index] = $value;
    
    $count = @my_list;
    
    push @my_list, 'values';
    $value = pop @my_list;
    unshift @my_list, 'values';
    $value = shift @my_list;
    
    ## NOTE: fourth parameter of splice is *NOT* supported for now
    @other_list = splice(@my_list, 2, 3);
    
    @my_list = ();

=cut

sub TIEARRAY {
    my ($class, $redis, $listname) = @_;
    
    my $self = {
        list => $listname,
        redis => $redis,
    };

    return bless($self, $class);
}

sub FETCH {
    my ($self, $index) = @_;
    decode_cbor($self->{redis}->lindex($self->{list}, $index));
}

sub FETCHSIZE {
    my ($self) = @_;
    $self->{redis}->llen($self->{list});
}

sub STORE {
    my ($self, $index, $value) = @_;
    $self->{redis}->lset($self->{list}, $index, encode_cbor($value));
}

sub STORESIZE {
  my ($self, $count) = @_;
  $self->{redis}->ltrim($self->{list}, 0, $count);
}

sub CLEAR {
    my ($self) = @_;
    $self->{redis}->del($self->{list});
}

sub PUSH {
    my ($self, @values) = @_;
    $self->{redis}->rpush($self->{list}, encode_cbor($_)) for @values;
}

sub POP {
    my ($self) = @_;
    map { decode_cbor($_) } $self->{redis}->rpop($self->{list});
}

sub SHIFT {
    my ($self) = @_;
    map { decode_cbor($_) } $self->{redis}->lpop($self->{list});
}

sub UNSHIFT {
    my ($self, @values) = shift;
    $self->{redis}->lpush($self->{list}, encode_cbor($_)) for @values;
}

sub SPLICE {
    my ($self, $offset, $length) = @_;
    confess "cannot replace elements in list (unimplemented)" if @_ > 3;
    $self->lrange($self->{list}, $offset, $length);
}

sub EXTEND {
    my ($self, $count) = @_;
    $self->{redis}->rpush($self->{list}, '') for ($self->FETCHSIZE .. ($count - 1));
}

sub DESTROY {
}

=head1 HISTORY

This module is originally based on L<Redis::List> by I<Pedro Melo> and I<Damien Krotkine>.

=cut

1;
