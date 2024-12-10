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
       TRUE TT_THEME USERID USERNAME )
]};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Constants - Exports the constants used in the distribution

=head1 Synopsis

   use HTML::Forms::Constants qw( BANG );

=head1 Description

Exports the constants used in the distribution

=head1 Configuration and Environment

Defines the following class attributes;

=over 3

=item C<Exception_Class>

   $class = HTML::Forms::Constants->Exception( $class );

=cut

my $exception_class = 'HTML::Forms::Exception';

sub Exception_Class {
   my ($self, $class) = @_;

   return $exception_class unless defined $class;

   $exception_class->throw(
      "Exception class ${class} is not loaded or has no throw method"
   ) unless $class->can('throw');

   return $exception_class = $class;
}

sub USERNAME () { getpwuid($EUID)->name }

=item C<Secret>

   $secret = HTML::Forms::Constants->Exception_Class( $secret );

=cut

my $secret = USERNAME . __FILE__;

sub Secret {
   my ($self, $value) = @_;

   return $secret unless defined $value;

   $exception_class->throw("Secret ${value} is not long enough")
      unless length $value > 16;

   return $secret = $value;
}

=back

=head1 Subroutines/Methods

Defines the following exported functions;

=over 3

=item C<BANG>

=cut

sub BANG () { q(!) }

=item C<COLON>

=cut

sub COLON () { q(:) }

=item C<COMMA>

=cut

sub COMMA () { q(,) }

=item C<DISTDIR>

=cut

sub DISTDIR () { File::ShareDir::dist_dir('HTML-Forms') }

=item C<DOT>

=cut

sub DOT () { q(.) }

=item C<EXCEPTION_CLASS>

=cut

sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }

=item C<FALSE>

=cut

sub FALSE () { 0    }

=item C<META>

=cut

sub META () { '_html_forms_meta' }

=item C<NBSP>

=cut

sub NBSP () { '&nbsp;' }

=item C<NUL>

=cut

sub NUL () { q()  }

=item C<PIPE>

=cut

sub PIPE () { q(|) }

=item C<SECRET>

=cut

sub SECRET () { sha1_hex( __PACKAGE__->Secret ) }

=item C<SPC>

=cut

sub SPC () { q( ) }

=item C<STAR>

=cut

sub STAR () { q(*) }

=item C<TRUE>

=cut

sub TRUE () { 1    }

=item C<TT_THEME>

=cut

sub TT_THEME () { 'classic' }

=item C<USERID>

=cut

sub USERID () { getpwuid($EUID)->id }

=item C<USERNAME>

=cut

=item C<DATE_FMT>

=cut

sub DATE_FMT () { '%Y-%m-%d' }

=item C<DATE_MATCH>

=cut

sub DATE_MATCH () { '\d{4}-\d{2}-\d{2}' }

=item C<DATE_RE>

=cut

sub DATE_RE () { qr{ \d{4}-\d{2}-\d{2} }mx }

=item C<TIME_FMT>

=cut

sub TIME_FMT () { '%H:%M' }

=item C<TIME_MATCH>

=cut

sub TIME_MATCH () { '\d{2}:\d{2}' }

=item C<TIME_RE>

=cut

sub TIME_RE () { qr{ \d{2}:\d{2} }mx }

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Sub::Exporter>

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
