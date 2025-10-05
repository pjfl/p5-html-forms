package HTML::Forms::Field::TextArea;

use HTML::Forms::Types qw( Int );
use Moo;

extends 'HTML::Forms::Field::Text';

has 'cols'    => is => 'rw', isa => Int;

has 'rows'    => is => 'rw', isa => Int;

has '+widget' => default => 'Textarea';

has '+wrapper_class' => default => 'input-textarea';

sub BUILD {
   my $self = shift;

   $self->add_label_class('input-textarea');
   return;
}

sub html_element {
   return 'textarea';
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::TextArea - A text area

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'TextArea';

=head1 Description

A text area

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item cols

=item rows

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=item html_element

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Text>

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
