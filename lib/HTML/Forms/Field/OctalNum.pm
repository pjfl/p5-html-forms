package HTML::Forms::Field::OctalNum;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( OctalNum );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Field::PosInteger';

our $class_messages = {
    'octal_number' => 'Value must be an octal number',
};

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages  } };
}

apply([{
   check => sub {
      my $value = shift; return OctalNum->check("${value}") ? TRUE : FALSE;
   },
   message => sub {
      my ($value, $field) = @_; return $field->get_message('octal_number');
   }
}, {
   transform => sub {
      my $v = shift; return $v =~ m{ \A 0 }mx ? "${v}" : "0${v}";
   }
}]);

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::OctalNum - HTML forms using Moo

=head1 Synopsis

   use HTML::Forms::Field::OctalNum;
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

=item L<Class::Usul::Cmd>

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

Copyright (c) 2026 Peter Flanigan. All rights reserved

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
