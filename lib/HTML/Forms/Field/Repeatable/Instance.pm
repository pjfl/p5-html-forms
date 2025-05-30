package HTML::Forms::Field::Repeatable::Instance;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Compound';

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Repeatable::Instance - Instance of a repeatable field group

=head1 Synopsis

   use HTML::Forms::Field::Repeatable::Instance;

=head1 Description

Instance of a repeatable field group

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item do_label

=cut

has '+do_label' => default => FALSE;

=item do_wrapper

=cut

has '+do_wrapper' => default => TRUE;

=item no_value_if_empty

=cut

has '+no_value_if_empty' => default => TRUE;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

sub BUILD {
   my $self = shift;

   $self->add_wrapper_class( $self->parent->instance_wrapper_class )
      unless $self->has_wrapper_class;

   return;
}

=item build_tags

=cut

sub build_tags {
   return { wrapper => TRUE };
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Compound>

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
