package Mail::SendGrid::WebAPI;
use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;
use JSON::PP;
use Encode;
use URI::Escape;

{
  $Mail::SendGrid::WebAPI = '0.1';
}

sub new {
    my $class = shift;
    my %args  = @_;
    my $obj = bless {}, $class;
    my $method = $args{ method } || 'GET';
    $obj->{ method } = uc( $method );
    $obj->{ endpoint } = $args{ endpoint } || 'https://api.sendgrid.com';
    $obj->{ api_key } = $args{ api_key };
    $obj->{ version } = $args{ version } || 'v3';
    if ( exists( $args{ ssl_opt } ) ) {
        $obj->{ ssl_opt } = $args{ ssl_opt };
    }
    $obj;
}

sub request {
    my ( $obj, $path, $params ) = @_;
    my $api = $obj->{ endpoint };
    if ( $path && ( $path !~ m!^\/! ) ) {
        $path = '/' . $path;
    }
    $path = '/' . $obj->{ version } . $path;
    $api .= $path;
    my $body;
    if ( defined $params ) {
        if ( $obj->{ method } eq 'GET' ) {
            my @query_params;
            for my $key( keys %$params ) {
                my $value = uri_escape( $params->{ $key } );
                push( @query_params, "${key}=${value}" );
            }
            if ( $api =~ m/\?/ ) {
                $api .= '&';
            } else {
                $api .= '?';
            }
            $api .= join( '&', @query_params );
        } else {
            $body = encode_json( $params );
        }
    }
    my $api_key = $obj->{ api_key };
    if ( $api_key !~ m!^Bearer\s! ) {
        $api_key = "Bearer ${api_key}";
    }
    my $req = HTTP::Request->new( $obj->{ method }, $api );
    $req->content( $body ) if $body;
    $req->header( 'Authorization' => $api_key,
                  'Content-Type'  => 'application/json',
                  'Accept' => '*/*' );
    my $ua = LWP::UserAgent->new();
    if ( exists( $obj->{ ssl_opt } ) ) {
        $ua->ssl_opts( @{ $obj->{ ssl_opt } } );
    }
    my $res = $ua->request( $req );
    $res;
}

1;

__END__

=head1 NAME

Mail::SendGrid::WebAPI - Client for SendGrid RESTful APIs.

=head1 SYNOPSIS

    my $api_key = 'Your.API.Key';
    my @ssl_opt = ( verify_hostname => 0 );
    my %args = (
        method => 'GET',
        api_key => $api_key,
        ssl_opt => \@ssl_opt,
        version => 'v3',
    );
    my $client = Mail::SendGrid::WebAPI->new( %args );
    my $path = 'suppression/bounces';
    my $res = $client->request( $path );

=head1 METHODS

=head2 request

Send API Request with path and params. return HTTP::Response object.

    my $path = 'suppression/bounces';
    my $end_time = time;
    my $start_time = $end_time - 24*60*60*7; # 1 Week
    my $params = { start_time => $start_time, end_time => $end_time };
    my $res = $client->request( $path, $params );
    if ( $res->is_error ) {
       die $res->status_line;
    }
    print $res->content;

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT

Copyright (C) 2017, Junnama Noda.

=head1 LICENSE

This program is free software;
you can redistribute it and modify it under the same terms as Perl itself.

=cut
