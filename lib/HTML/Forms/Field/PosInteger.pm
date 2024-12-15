package HTML::Forms::Field::PosInteger;

use HTML::Forms::Constants qw( META );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::Integer';

our $class_messages = {
    'integer_positive' => 'Value must be a positive integer',
};

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

apply([{
   check   => sub { $_[0] >= 0 },
   message => sub {
      my ($value, $field) = @_;

      return $field->get_message('integer_positive');
   },
}]);

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::PosInteger - An positive integer

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'PosInteger';

=head1 Description

An positive integer

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item get_class_messages

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field::Integer>

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
