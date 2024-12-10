package HTML::Forms::Field::NoValue;

use HTML::Forms::Constants qw( NUL META TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field';


=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::NoValue - A field with no result value

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'NoValue';

=head1 Description

A field with no result value

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<html>

=cut

has 'html' => is => 'rw', isa => Str, default => NUL;

=item C<noupdate>

=cut

has '+noupdate' => default => TRUE;

=item value

=item has_value

Predicate

=cut

has 'value'  =>
   is        => 'rw',
   clearer   => 'clear_value',
   predicate => 'has_value';

=item widget

=cut

has '+widget' => default => 'NoValue';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<fif>

=cut

sub fif { }

=item validate_field

=cut

sub validate_field { }

# Private methods
sub _result_from_fields {
   my ($self, $result) = @_;

   my $value = $self->get_default_value;

   $self->value( $value ) if $value;
   $self->_set_result( $result );
   $result->_set_field_def( $self );
   return $result;
}

sub _result_from_input {
   my ($self, $result, $input, $exists) = @_;

   $self->_set_result( $result );
   $result->_set_field_def( $self );
   return $result;
}

sub _result_from_object {
   my ($self, $result, $value) = @_;

   $self->_set_result( $result );
   $result->_set_field_def( $self );
   return $result;
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

None

=over 3

=item L<HTML::Forms::Field>

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
