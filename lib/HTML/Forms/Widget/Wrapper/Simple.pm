package HTML::Forms::Widget::Wrapper::Simple;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Util      qw( process_attrs );
use Scalar::Util           qw( weaken );
use Moo::Role;

with 'HTML::Forms::Render::WithTT';

# Private methods
sub _build_default_tt_vars {
   my $self = shift;

   weaken $self;

   my $attr = {
      field         => $self,
      get_tag       => sub { $self->get_tag( @_ ) },
      localise      => sub { @_ },
      multiple      => $self->can('fields') ? TRUE : FALSE,
      process_attrs => \&process_attrs,
   };

   if (my $form = $self->form) {
      weaken $form;
      $attr->{form} = $form;
      $attr->{localise} = sub { $form->localise( @_ ) };
   }

   return $attr;
}

sub _build_tt_template {
   my $self = shift;

   return $self->tt_theme . '/fields.tt';
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::Wrapper::Simple - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Widget::Wrapper::Simple;
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
