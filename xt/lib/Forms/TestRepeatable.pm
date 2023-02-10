package Forms::TestRepeatable;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'HTML::Forms::Role::MinimalCSS';
with    'HTML::Forms::Render::Javascript';

has '+title'               => default => 'Test Repeatable Field';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'You know what to do';

has_field 'subject_name' => label => 'Name';

has_field 'repeat'        => type => 'Repeatable',
   do_wrapper => TRUE, tags => { controls_div => 1 };
has_field 'repeat.age'    => type => 'PosInteger';
has_field 'repeat.sex'    => type => 'Select', auto_widget_size => 3;
has_field 'repeat.remove' => type => 'RmElement';

has_field 'add_repeat' => type => 'AddElement', repeatable => 'repeat';

sub options_repeat_sex {
   return ( f => 'Female', m => 'Male', o => 'Other' );
}

use namespace::autoclean -except => META;

1;

__END__

=pod

=encoding utf-8

=head1 Name

[% module %] - [% abstract %]

=head1 Synopsis

   use [% module %];
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
http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% distname %].
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

[% author %], C<< <[% author_email %]> >>

=head1 License and Copyright

Copyright (c) [% copyright_year %] [% copyright %]. All rights reserved

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
