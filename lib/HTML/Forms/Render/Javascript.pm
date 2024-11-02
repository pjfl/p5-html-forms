package HTML::Forms::Render::Javascript;

use HTML::Forms::Constants qw( DISTDIR EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef CodeRef HashRef Object Str );
use HTML::Tiny;
use Path::Tiny             qw( path );
use Ref::Util              qw( is_coderef );
use Try::Tiny;
use Unexpected::Functions  qw( NotFound PackageUndefined
                               ReadFailed throw UnknownPackage );
use Moo::Role;
use MooX::HandlesVia;

has '+render_js_after' => is => 'rw', default => TRUE;

has '_html' => is => 'ro', isa => Object, default => sub { HTML::Tiny->new };

has '_packages' =>
   is          => 'ro',
   isa         => HashRef[Str],
   default     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      _add_package => 'set',
      _has_package => 'exists',
   };

has '_wanted_packages' =>
   is          => 'ro',
   isa         => ArrayRef[CodeRef|Str],
   default     => sub { [] },
   handles_via => 'Array',
   handles     => {
      load_js_package => 'push',
   };

before 'render' => sub {
   my $self = shift;
   my @dependencies;

   if ($self->render_js_after) {
      for my $package (@{$self->_wanted_packages}) {
         if (!is_coderef $package) {
            next if $self->_has_package($package);

            $self->_load_package($package);
            throw UnknownPackage, [$package]
               unless $self->_has_package($package);

            push @dependencies, @{_dependencies($self->_packages->{$package})};
         }
      }
   }

   for my $package (@dependencies, @{$self->_wanted_packages}) {
      my $after = $self->get_tag('after');
      my $js;

      if (!is_coderef $package) {
         next unless $self->render_js_after;
         next if _contains_package($package, $after);

         $self->_load_package($package)   unless $self->_has_package($package);
         throw UnknownPackage, [$package] unless $self->_has_package($package);

         $js = $self->_packages->{$package};
      }
      else { $js = $package->() }

      $self->set_tag( after => $after . $self->_wrap_script($js) );
   }

   return;
};

sub _load_package {
   my ($self, $package) = @_;

   my $path = [ DISTDIR, 'js', _to_filename($package) ];
   my $file;

   try   { $file = path(@{$path})->assert(sub { $_->exists }) }
   catch { throw NotFound, [ (join '/', @{$path}), $_ ] };

   my $js;

   try   { $js = $file->slurp }
   catch { throw ReadFailed, [ (join '/', @{$path}), $_ ] };

   throw PackageUndefined, [$package, (join '/', @{$path})]
      unless _contains_package($package, $js);

   $self->_add_package($package, $js);
   return;
}

sub _contains_package {
   my ($package, $js) = @_;

   return $js =~ m{ // \s+ Package \s+ \Q$package\E }imx ? TRUE : FALSE;
}

sub _dependencies {
   my $js = shift;
   my ($dependencies) = $js =~ m{ ^ // \s+ Dependencies \s+ (.+) $ }imx;

   return [ split m{ \s }mx, $dependencies // NUL ];
}

sub _to_filename {
   my $file = lc shift;

   $file =~ s{ \. }{-}gmx;

   return {
      'hforms-util'       => 'hforms-0-util.js',
      'hforms-repeatable' => 'hforms-1-repeatable.js',
      'hforms-toggle'     => 'hforms-2-toggle.js',
   }->{$file};
}

sub _wrap_script {
   my ($self, $js) = @_; return $self->_html->script("\n${js}") . "\n";
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Render::Javascript - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Render::Javascript;
   # Brief but working code examples

=head1 Description

Only used when creating standalone forms to include the necessary JS

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
