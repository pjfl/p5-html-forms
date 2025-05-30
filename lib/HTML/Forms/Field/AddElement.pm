package HTML::Forms::Field::AddElement;

use HTML::Forms::Constants qw( EXCEPTION_CLASS META TRUE );
use HTML::Forms::Types     qw( Str );
use Unexpected::Functions  qw( throw );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Display';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::AddElement - Adds element to repeatable field

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'AddElement';

=head1 Description

Adds element to repeatable field

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item repeatable

=cut

has 'repeatable' => is => 'rw', isa => Str, required => TRUE;

=item do_wrapper

=cut

has '+do_wrapper' => default => TRUE;

=item value

=item has_value

Predicate

=cut

has '+value' => default => 'Add Element';

=item widget

=cut

has '+widget' => default => 'RepeatableControl';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item element_attributes

=cut

around 'element_attributes' => sub {
   my ($orig, $self, $result) = @_;

   my $field = $self->parent->field($self->repeatable);

   throw 'Invalid repeatable name in field [_1]', [$self->name] unless $field;

   my $attr = $orig->($self, $result);

   push @{$attr->{class}}, ('add-repeatable', 'input-button');
   $attr->{'data-repeatable-id'} = $field->id;
   $attr->{id} = $self->id;

   return $attr;
};

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Display>

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
