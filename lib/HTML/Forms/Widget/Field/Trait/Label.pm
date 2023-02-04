package HTML::Forms::Widget::Field::Trait::Label;

use HTML::Forms::Constants qw( COLON FALSE SPC TRUE );
use Moo::Role;

requires qw( form );

after 'after_build' => sub {
   my $self = shift;
   my $form = $self->form;

   if ($form && $form->do_label_right) {
      $self->merge_tags({ label_right => TRUE });
   }

   if ($form && $form->do_label_colon) {
      if ($self->get_tag('label_right')) {
          $self->merge_tags({ label_before => COLON . SPC })
      }
      else { $self->merge_tags({ label_after => COLON }) }
   }

   return;
};

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::Field::Trait::Label - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Widget::Field::Trait::Label;
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
