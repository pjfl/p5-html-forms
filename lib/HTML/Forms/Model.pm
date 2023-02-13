package HTML::Forms::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( Str );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( throw );
use Moo::Role;

has 'item' =>
   is      => 'rw',
   builder => 'build_item',
   clearer => 'clear_item',
   lazy    => TRUE,
   trigger => sub { shift->set_item( @_ ) };

has 'item_class' => is  => 'rwp', isa => Str;

has 'item_id' =>
   is      => 'rw',
   clearer => 'clear_item_id',
   trigger => sub { shift->set_item_id( @_ ) };

sub build_item { return }

sub clear_model {}

sub guess_field_type {
   # Not used. Was called by Model::CDBI
   throw "Don't know how to determine field type of [_1]", [ $_[1] ];
}

sub lookup_options {
   # Called by Field::Select when no options available
}

sub set_item {
   my ($self, $item) = @_; $self->_set_item_class( blessed $item ); return;
}

sub set_item_id {}

sub update_model {
   # Called by Forms::process if form was posted and it validated
}

sub validate_model {
   # Called by Forms::validate_form as part of form validation
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Model - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Model;
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

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
