package HTML::Forms::Role::RenderWithTT;

use HTML::Forms::Constants qw( DISTDIR EXCEPTION_CLASS TRUE TT_THEME SPC );
use HTML::Forms::Types     qw( ArrayRef HashRef Str Template );
use HTML::Forms::Util      qw( process_attrs );
use Scalar::Util           qw( weaken );
use Unexpected::Functions  qw( throw );
use Template;
use Moo::Role;
use MooX::HandlesVia;

requires qw( form );

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Role::RenderWithTT - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Role::RenderWithTT';


=head1 Description

Provides a render method that uses L<Template>

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item default_tt_vars

=cut

has 'default_tt_vars' =>
   is      => 'lazy',
   isa     => HashRef,
   builder => sub {
      my $self = shift;
      my $form = $self->form; weaken $form;

      return {
         form          => $form,
         get_tag       => sub { $form->get_tag( @_ ) },
         len           => sub { my $c = 0; map { $c += length $_ } @_; $c },
         localise      => sub { $form->localise( @_ ) },
         process_attrs => \&process_attrs,
         theme         => $self->tt_theme,
      };
   };

=item tt_config

=cut

has 'tt_config' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub {
      my $self = shift;

      return {
         %{ $self->tt_options },
         INCLUDE_PATH => [ @{$self->tt_include_path}, DISTDIR . '/templates/' ],
      };
   },
   lazy    => TRUE;

=item tt_engine

=cut

has 'tt_engine' =>
   is      => 'rw',
   isa     => Template,
   builder => sub {
      my $self = shift;

      return Template->new( $self->tt_config );
   },
   lazy    => TRUE;

=item tt_include_path

=cut

has 'tt_include_path' =>
   is          => 'rw',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => { add_tt_include_path => 'push', },
   lazy        => TRUE;

=item tt_options

=cut

has 'tt_options' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub { { ENCODING => 'utf8', TRIM => TRUE } },
   lazy    => TRUE;

=item tt_theme

=cut

has 'tt_theme' =>
   is      => 'rw',
   isa     => Str,
   builder => sub {
      my $self  = shift;
      my $theme = TT_THEME;

      $theme = $self->default_form_class if $self->can('default_form_class');

      return $theme;
   },
   lazy    => TRUE;

=item tt_template

=cut

has 'tt_template' =>
   is      => 'rw',
   isa     => Str,
   builder => sub {
      my $self = shift;

      return $self->tt_theme . '/form.tt';
   },
   lazy    => TRUE;

=item tt_vars

=cut

has 'tt_vars' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub { {} };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item render

=cut

sub render {
   my $self = shift;
   my $vars = { %{ $self->default_tt_vars }, %{ $self->tt_vars } };
   my $output;

   $self->tt_engine->process( $self->tt_template, $vars, \$output );

   if (my $exception = $self->tt_engine->{SERVICE}->{_ERROR}) {
      throw $exception->[0] . SPC . $exception->[1] . '.  So far => '
          . ${ $exception->[2] } . "\n";
   }

   return $output;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Template>

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
