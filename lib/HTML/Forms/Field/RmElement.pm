package HTML::Forms::Field::RmElement;

use HTML::Forms::Constants qw( META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Display';

has '+do_wrapper' => default => TRUE;

has '+value' => default => 'Remove';

has '+widget' => default => 'RepeatableControl';

around 'element_attributes' => sub {
   my ($orig, $self, $result) = @_;

   my $attr = $orig->($self, $result);

   push @{$attr->{class}}, ('remove-repeatable', 'input-button');
   $attr->{'data-repeatable-element-id'} = $self->parent->id;
   $attr->{id} = $self->id;

   return $attr;
};

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::RmElement - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Field::RmElement;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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
