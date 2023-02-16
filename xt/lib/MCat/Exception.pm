package MCat::Exception;

use DateTime;
use HTML::Forms::Types    qw( Object );
use HTTP::Status          qw( HTTP_NOT_FOUND );
use Type::Utils           qw( class_type );
use Unexpected::Functions qw( has_exception );
use MCat;
use Moo;

extends 'HTML::Forms::Exception';

has 'created' => is => 'ro', isa => class_type('DateTime'), default => sub {
   return DateTime->now( time_zone => 'local' );
};

has 'version' => is => 'ro', isa => Object, default => sub { $MCat::VERSION };

my $class = __PACKAGE__;

has_exception $class;

has_exception 'NoMethod' => parent => [$class],
   error => 'Class [_1] has no method [_2]';

has_exception 'PageNotFound' => parent => [$class],
   error => 'Page [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownArtist' => parent => [$class],
   error => 'Artist [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownCd' => parent => [$class],
   error => 'CD [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTrack' => parent => [$class],
   error => 'Track [_1] not found', rv => HTTP_NOT_FOUND;

use namespace::autoclean;

1;
