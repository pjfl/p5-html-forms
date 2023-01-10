package HTML::Forms::Render::WithTT;

use namespace::autoclean;

use File::ShareDir;
use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE SPC );
use HTML::Forms::Types     qw( ArrayRef HashRef Str Template );
use HTML::Forms::Util      qw( process_attrs );
use Scalar::Util           qw( weaken );
use Template;
use Unexpected::Functions  qw( throw );
use Moo::Role;
use MooX::HandlesVia;

has 'default_tt_vars' =>
   is      => 'lazy',
   isa     => HashRef,
   builder => sub {
      my $self = shift;
      my $form = $self->form; weaken $form;

      return {
         form          => $form,
         get_tag       => sub { $form->get_tag( @_ ) },
         localise      => sub { $form->localise( @_ ) },
         process_attrs => \&process_attrs,
      };
   };

has 'tt_config' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub {
      my $self = shift;

      return {
         %{ $self->tt_options },
         INCLUDE_PATH => [
            @{ $self->tt_include_path },
            File::ShareDir::dist_dir( 'HTML-Forms' ) . '/templates/'
         ],
      };
   },
   lazy    => TRUE;

has 'tt_engine' =>
   is      => 'rw',
   isa     => Template,
   builder => sub {
      my $self = shift;

      return Template->new( $self->tt_config );
   },
   lazy    => TRUE;

has 'tt_include_path' =>
   is          => 'rw',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => { add_tt_include_path => 'push', },
   lazy        => TRUE;

has 'tt_options' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub { { TRIM => TRUE } },
   lazy    => TRUE;

has 'tt_template' =>
   is      => 'rw',
   isa     => Str,
   builder => sub { 'classic/form.tt' },
   lazy    => TRUE;

has 'tt_vars' =>
   is      => 'rw',
   isa     => HashRef,
   builder => sub { {} };

sub render {
   my $self = shift;
   my $vars = { %{ $self->default_tt_vars }, %{ $self->tt_vars } };
   my $output;

   $self->tt_engine->process( $self->tt_template, $vars, \$output );

   if (my $exception = $self->tt_engine->{SERVICE}->{_ERROR}) {
      throw $exception->[ 0 ] . SPC . $exception->[ 1 ] . '.  So far => '
          . ${ $exception->[ 2 ] } . "\n";
   }

   return $output;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Render::WithTT - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Render::WithTT;
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

Copyright (c) 2018 Peter Flanigan. All rights reserved

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
