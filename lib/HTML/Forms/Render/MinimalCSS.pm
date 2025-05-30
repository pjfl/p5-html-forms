package HTML::Forms::Render::MinimalCSS;

use HTML::Forms::Constants qw( DISTDIR EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( HashRef Object Str );
use Path::Tiny             qw( path );
use Unexpected::Functions  qw( NotFound ReadFailed throw );
use HTML::Tiny;
use Try::Tiny;
use Moo::Role;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Render::MinimalCSS - Adds CSS to a form

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Render::MinimalCSS';

=head1 Description

Adds CSS to a form. Only used in testing standalone forms

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=cut

has '_html' => is => 'ro', isa => Object, default => sub { HTML::Tiny->new };

=item style_name

=cut

has 'style_name' => is => 'ro', isa => Str, default => 'hforms-minimal';

has '_styles' =>
   is          => 'ro',
   isa         => HashRef[Str],
   default     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      _add_style => 'set',
      _has_style => 'exists',
   };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item before_build_fields

=cut

around 'before_build_fields' => sub {
   my ($orig, $self) = @_;

   $orig->($self);
   $self->_load_style($self->style_name);

   my $style  = $self->_styles->{$self->style_name};
   my $before = $self->get_tag('before') || NUL;

   $self->set_tag( before => $before . $self->_wrap_style($style) );
   return;
};

sub _load_style {
   my ($self, $style) = @_;

   my $path = [ DISTDIR, 'css', _to_filename($style) ];
   my $file;

   try   { $file = path(@{$path})->assert(sub { $_->exists }) }
   catch { throw NotFound, [ (join '/', @{$path}), $_ ] };

   my $content;

   try   { $content = $file->slurp }
   catch { throw ReadFailed, [ (join '/', @{$path}), $_ ] };

   $self->_add_style($style, $content);
   return;
}

sub _wrap_style {
   my ($self, $content) = @_; return $self->_html->style("\n${content}") . "\n";
}

sub _to_filename {
   my $file = lc shift; $file =~ s{ \. }{-}gmx; return "${file}.css";
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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
