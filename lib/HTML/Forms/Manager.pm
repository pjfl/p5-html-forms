package HTML::Forms::Manager;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( Str );
use Class::Load            qw( load_class );
use Scalar::Util           qw( blessed );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw Unspecified );
use Try::Tiny;
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Manager - Factory class for forms

=head1 Synopsis

   use HTML::Forms::Manager;

=head1 Description

Factory class for forms

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item namespace

=cut

has 'namespace' => is => 'ro', isa => Str, required => TRUE;

=item schema

=cut

has 'schema' =>
   is        => 'ro',
   isa       => class_type('DBIx::Class::Schema'),
   predicate => 'has_schema';

=back

=head1 Subroutines/Methods

=over 3

=item new_with_context( $name, \%options )

=cut

sub new_with_context {
   my ($self, $name, $options) = @_;

   my $class = $self->namespace . '::' . $name;
   my $exception;

   try   { load_class($class) }
   catch { $exception = $_ };

   return HTML::Forms::Error->new($exception) if $exception;

   my $context = $options->{context};

   throw Unspecified, ['context'] unless $context;
   throw 'Not an object reference [_1]', ['context'] unless blessed($context);
   throw 'Context object has no request method' unless $context->can('request');

   my $args = { %{$options} };

   $args->{action} //= $context->request->uri->as_string;

   $args->{params} //= $self->get_body_parameters($context)
      if lc $context->request->method eq 'post';

   $args->{schema} //= $self->schema if $self->has_schema;

   return $class->new($args);
}

=item get_body_parameters( $context )

=cut

sub get_body_parameters {
   my ($self, $context) = @_;

   my $request = $context->request;

   return { %{$request->body_parameters->mixed // {}} }
      if $request->isa('Plack::Request');

   return { %{$request->body_parameters // {}} }
      if $request->isa('Catalyst::Request')
      || $request->isa('Web::ComposableRequest::Base');

   return $request->parameters if $request->can('parameters');

   return {};
}

use namespace::autoclean;

package
   HTML::Forms::Error;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Type::Utils            qw( class_type );
use HTML::Tiny;
use Moo;

has 'exception' => is => 'ro', isa => Str, required => TRUE;

has '_html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   return $orig->($self, { exception => $args[0] });
};

sub process() { FALSE }

sub render() {
   my $self = shift;

   return $self->_html->div({ class => 'form-error' }, $self->exception);
}

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Load>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Forms.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
