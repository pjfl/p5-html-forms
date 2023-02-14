package MCat::Model::Page;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTTP::Status           qw( HTTP_NOT_FOUND );
use Unexpected::Functions  qw( exception PageNotFound );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'page';

sub not_found {
   my ($self, $context) = @_;

   my $request   = $context->request;
   my @options   = ( [$request->path], code => HTTP_NOT_FOUND );
   my $exception = exception PageNotFound, @options;

   return $self->exception_handler($request, $exception);
}

use namespace::autoclean;

1;
