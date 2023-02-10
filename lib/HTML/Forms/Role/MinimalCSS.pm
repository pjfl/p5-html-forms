package HTML::Forms::Role::MinimalCSS;

use English                qw( -no_match_vars );
use HTML::Forms::Constants qw( NUL );
use HTML::Forms::Types     qw( Str );
use Moo::Role;

my $CSS = do { local $RS = undef; <DATA> };

has 'css' => is => 'ro', isa => Str, default => $CSS;

before 'before_build' => sub {
   my $self   = shift;
   my $before = $self->get_tag('before') || NUL;

   $self->set_tag( before => $before . $self->css );
   return;
};

use namespace::autoclean;

1;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Role::MinimalCSS - Generates markup for and processes input from HTML forms

=head1 Synopsis

   use HTML::Forms::Role::MinimalCSS;
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

__DATA__
<style>
form.classic .field-label {
  display: inline-block;
  width: 150px;
}
form.classic .input-captcha input,
form.classic .input-captcha .field-label,
form.classic .field-label.select-multiple,
form.classic .field-label.input-textarea {
  vertical-align: top;
}
form.classic .label-right .field-label {
  position: absolute;
  left: 375px;
}
form.classic .input-button,
form.classic .input-duration .input-select-integer,
form.classic .input-interval .input-group,
form.classic .input-time-with-zone .input-group {
  display: inline-block;
}
form.classic .input-captcha input,
form.classic .input-integer input,
form.classic .input-interval input,
form.classic .input-money input,
form.classic .input-number input {
  text-align: right;
}
form.classic .field-label .label-sep-after {
  float: right;
}
form.classic .input-duration .option-label .label-sep-after,
form.classic .input-duration .option-label .label-sep-before {
  display: none;
}
</style>
