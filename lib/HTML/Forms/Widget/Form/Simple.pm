package HTML::Forms::Widget::Form::Simple;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use Unexpected::Functions  qw( throw );
use Moo::Role;

sub renderx {
   my ($self, %args) = @_;

   if (keys %args > 0) {
      while (my ($key, $value) = each %args) {
         throw "Invalid attribute '${key}' passed to renderx"
            unless $self->can( $key );

         $self->$key( $value );
      }
   }

   $self->render;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::Form::Simple - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Widget::Form::Simple;
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

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
