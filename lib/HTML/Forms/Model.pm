package HTML::Forms::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( Str );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( throw );
use Moo::Role;

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

=item item

=item clear_item

Clearer

=cut

has 'item' =>
   is      => 'rw',
   builder => 'build_item',
   clearer => 'clear_item',
   lazy    => TRUE,
   trigger => sub { shift->set_item( @_ ) };

=item item_class

=cut

has 'item_class' => is  => 'rwp', isa => Str;

=item item_id

=item clear_item_id

=cut

has 'item_id' =>
   is      => 'rw',
   clearer => 'clear_item_id',
   trigger => sub { shift->set_item_id( @_ ) };

=back

=head1 Subroutines/Methods

Defines the following methods'

=over 3

=item build_item

=cut

sub build_item { return }

=item clear_model

=cut

sub clear_model {}

=item guess_field_type

=cut

sub guess_field_type {
   # Not used. Was called by Model::CDBI
   throw "Don't know how to determine field type of [_1]", [ $_[1] ];
}

=item lookup_label

=cut

sub lookup_label {
}

=item lookup_options

=cut

sub lookup_options {
   # Called by Field::Select when no options available
}

=item set_item


=cut

sub set_item {
   my ($self, $item) = @_; $self->_set_item_class( blessed $item ); return;
}

=item set_item_id

=cut

sub set_item_id {}

=item update_model

=cut

sub update_model {
   # Called by Forms::process if form was posted and it validated
}

=item validate_model

=cut

sub validate_model {
   # Called by Forms::validate_form as part of form validation
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
