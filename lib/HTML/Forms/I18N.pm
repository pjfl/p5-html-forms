package HTML::Forms::I18N;

use strictures;
use parent 'Locale::Maketext';

use HTML::Forms::Constants qw( EXCEPTION_CLASS NUL );
use Unexpected::Functions  qw( throw );
use Try::Tiny;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::I18N - Translates text into different languages

=head1 Synopsis

   use HTML::Forms::I18N;

=head1 Description

Translates text into different languages

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<maketext>

=cut

sub maketext {
   my ($self, @message) = @_;

   return NUL unless scalar @message && defined $message[0];

   my $out;

   try   { $out = $self->SUPER::maketext(@message) }
   catch {
      throw 'Unable to do maketext on: ' . $message[0]
         . "\nIf the message contains brackets you may need to escape them "
         . "with a tilde.";
   };

   return $out;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Locale::Maketext>

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
