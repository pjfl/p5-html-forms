package HTML::Forms::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS TRUE );
use HTML::Forms::Types     qw( Str );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( throw );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Model - Model base class

=head1 Synopsis

   use Moo;

   extends 'HTML::Forms::Model';

=head1 Description

Model base class which does nothing. Applied to the L<HTML::Forms> class it is
expected that these methods will be overridden thereby implementing a concrete
storage model

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item item

A mutable untyped attribute. The object used to instantiate and edit form

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

An immutable string without default. The class of the item created by the
create form

=cut

has 'item_class' => is  => 'rwp', isa => Str;

=item item_id

A mutable untyped attribute. Can be supplied in place of the C<item>

=item clear_item_id

=cut

has 'item_id' =>
   is      => 'rw',
   clearer => 'clear_item_id',
   trigger => sub { shift->set_item_id( @_ ) };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item build_item

Dummy method returns undef

=cut

sub build_item { return }

=item clear_model

Dummy method

=cut

sub clear_model {}

=item guess_field_type

Will raise an exception if called

=cut

sub guess_field_type {
   # Not used. Was called by Model::CDBI
   throw "Don't know how to determine field type of [_1]", [ $_[1] ];
}

=item lookup_label

Dummy method

=cut

sub lookup_label {
}

=item lookup_options

Dummy method

=cut

sub lookup_options {
   # Called by Field::Select when no options available
}

=item set_item

   $self->set_item($item);

Sets the C<item_class> attribute to the class of the supplied C<item>

=cut

sub set_item {
   my ($self, $item) = @_; $self->_set_item_class( blessed $item ); return;
}

=item set_item_id

Dummy method

=cut

sub set_item_id {}

=item update_model

Dummy Method

=cut

sub update_model {
   # Called by Forms::process if form was posted and it validated
}

=item validate_model

Dummy method

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
