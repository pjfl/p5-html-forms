package MCat::Response;

use HTML::Forms::Constants qw( NUL );
use HTML::Forms::Types     qw( ArrayRef );
use Moo;

has 'body' => is => 'rw';

has '_headers' => is => 'ro', isa => ArrayRef, default => sub { [] };

sub header {
   my ($self, @header) = @_;

   push @{$self->_headers}, @header;

   return wantarray ? @{$self->_headers} : $self->_headers;
}

sub write {
   my ($self, $content) = @_;

   my $body = $self->body // NUL;

   $self->body($body . $content);
   return;
}

use namespace::autoclean;

1;
