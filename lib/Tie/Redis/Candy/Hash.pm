# This file was part of Redis, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
# Copyright (c) 2015 by Pedro Melo, Damien Krotkine.

package Tie::Redis::Candy::Hash;

# ABSTRACT: tie Perl hashes to Redis hashes - the candy way

use strict;
use warnings;
use Carp;
use CBOR::XS qw(encode_cbor decode_cbor);
use base 'Tie::Hash';

# VERSION

=head1 DESCRIPTION

Ties a Perl hash to Redis. Note that it doesn't use Redis Hashes, but implements a fake hash using regular keys like "prefix:KEY".

If no C<prefix> is given, it will tie the entire Redis database as a hash.

Future versions will also allow you to use real Redis hash structures.

=head1 SYNOPSYS

    my $redis = Redis->new(...);
    
    ## Create fake hash using keys like 'hash_prefix:KEY'
    tie %my_hash, 'Tie::Redis::Candy::Hash', 'hash_prefix', $redis;
    
    ## Treat the entire Redis database as a hash
    tie %my_hash, 'Tie::Redis::Candy::Hash', undef, $redis;
    
    $value = $my_hash{$key};
    $my_hash{$key} = $value;
    
    @keys   = keys %my_hash;
    @values = values %my_hash;
    
    %my_hash = reverse %my_hash;
    
    %my_hash = ();

=cut

sub TIEHASH {
    my ($class, $redis, $prefix) = @_;
    
    die "whaa: $redis" unless ref $redis eq 'Redis';
    
    $prefix = $prefix ? $prefix.':' : '';

    my $self = {
        prefix => $prefix,
        redis => $redis,
    };

    return bless($self, $class);
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->{redis}->set($self->{prefix} . $key, encode_cbor($value));
}

sub FETCH {
    my ($self, $key) = @_;
    my $data = $self->{redis}->get($self->{prefix} . $key);
    return unless defined $data;
    decode_cbor($data);
}

sub FIRSTKEY {
    my $self = shift;
    $self->{prefix_keys} = [ $self->{redis}->keys($self->{prefix} . '*') ];
    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;
    
    my $key = shift @{ $self->{prefix_keys} };
    return unless defined $key;
    
    my $p = quotemeta $self->{prefix};
    $key =~ s/^$p// if $p;
    return $key;
}

sub EXISTS {
    my ($self, $key) = @_;
    $self->{redis}->exists($self->{prefix} . $key);
}

sub DELETE {
    my ($self, $key) = @_;
    $self->{redis}->del($self->{prefix} . $key);
}

sub CLEAR {
    my ($self) = @_;
    $self->{redis}->del($_) for $self->{redis}->keys($self->{prefix} . '*');
    $self->{prefix_keys} = [];
}

=head1 HISTORY

This module is originally based on L<Redis::Hash> by I<Pedro Melo> and I<Damien Krotkine>.

=cut

1;
