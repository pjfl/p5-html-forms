package HTML::Forms::Manager;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( ArrayRef Str );
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

Class prefix of where to find the field classes. Required string

=cut

has 'namespace' => is => 'ro', isa => Str, required => TRUE;

=item renderer_class

An immutable string. The name of the non default renderer class

=item has_renderer_class

Predicate

=cut

has 'renderer_class' =>
   is        => 'ro',
   isa       => Str,
   predicate => 'has_renderer_class';

=item schema

An optional instance of L<DBIx::Class::Schema>

=item has_schema

Predicate

=cut

has 'schema' =>
   is        => 'ro',
   isa       => class_type('DBIx::Class::Schema'),
   predicate => 'has_schema';

=back

=head1 Subroutines/Methods

=over 3

=item new_with_context

   $form = $manager->new_with_context( $name, \%options )

=cut

sub new_with_context {
   my ($self, $name, $options) = @_;

   my $class = $self->namespace . '::' . $name;
   my $exception;

   try   { load_class($class) }
   catch { $exception = $_ };

   throw $exception if $exception;

   my $context = $options->{context};

   throw Unspecified, ['context'] unless $context;
   throw 'Not an object reference [_1]', ['context'] unless blessed($context);
   throw 'Context no request attribute' unless $context->can('request');
   throw 'Context no body_parameters'   unless $context->can('body_parameters');
   throw 'Context no posted attribute'  unless $context->can('posted');

   my $args = { %{$options} };

   $args->{action} //= $context->request->uri->as_string;

   $args->{params} //= $context->body_parameters if $context->posted;

   $args->{renderer_class} = $self->renderer_class if $self->has_renderer_class;

   $args->{schema} //= $self->schema if $self->has_schema;

   return $class->new($args);
}

use namespace::autoclean;

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

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

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
