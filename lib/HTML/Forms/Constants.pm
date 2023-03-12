package HTML::Forms::Constants;

use strictures;

use Digest::SHA1 qw( sha1_hex );
use English      qw( -no_match_vars );
use File::ShareDir;
use User::pwent  qw( getpwuid );
use HTML::Forms::Exception;

use Sub::Exporter -setup => { exports => [
   qw( BANG COLON COMMA DATE_FMT DATE_MATCH DATE_RE DISTDIR DOT EXCEPTION_CLASS
       FALSE META NBSP NUL PIPE SECRET SPC STAR TIME_FMT TIME_MATCH TIME_RE
       TRUE TT_THEME )
]};

sub BANG     () { q(!) }
sub COLON    () { q(:) }
sub COMMA    () { q(,) }
sub DISTDIR  () { File::ShareDir::dist_dir('HTML-Forms') }
sub DOT      () { q(.) }
sub FALSE    () { 0    }
sub META     () { '_html_forms_meta' }
sub NBSP     () { '&nbsp;' }
sub NUL      () { q()  }
sub PIPE     () { q(|) }
sub SECRET   () { sha1_hex( __PACKAGE__->Secret ) }
sub SPC      () { q( ) }
sub STAR     () { q(*) }
sub TRUE     () { 1    }
sub TT_THEME () { 'classic' }

sub DATE_FMT        () { '%Y-%m-%d' }
sub DATE_MATCH      () { '\d{4}-\d{2}-\d{2}' }
sub DATE_RE         () { qr{ \d{4}-\d{2}-\d{2} }mx }
sub TIME_FMT        () { '%H:%M' }
sub TIME_MATCH      () { '\d{2}:\d{2}' }
sub TIME_RE         () { qr{ \d{2}:\d{2} }mx }
sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }

my $exception_class = 'HTML::Forms::Exception';

sub Exception_Class {
   my ($self, $class) = @_;

   return $exception_class unless defined $class;

   $exception_class->throw(
      "Exception class ${class} is not loaded or has no throw method"
   ) unless $class->can('throw');

   return $exception_class = $class;
}

my $secret = getpwuid($EUID)->name . __FILE__;

sub Secret {
   my ($self, $value) = @_;

   return $secret unless defined $value;

   $exception_class->throw("Secret ${value} is not long enough")
      unless length $value > 16;

   return $secret = $value;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Constants - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Constants;
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
