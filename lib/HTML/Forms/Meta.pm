package HTML::Forms::Meta;

use mro;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Moo::Attribute;
use HTML::Forms::Util      qw( get_meta );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( throw );
use Unexpected::Types      qw( ArrayRef Bool Str );
use Moo;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Meta::Role - Form meta class

=head1 Synopsis

   use HTML::Forms::Meta::Role;

=head1 Description

Form meta class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item apply_list

=cut

has 'apply_list' =>
   is            => 'rw',
   isa           => ArrayRef,
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_to_apply_list => 'push',
      clear_apply_list  => 'clear',
      has_apply_list    => 'count',
   };

=item block_list

=cut

has 'block_list' =>
   is            => 'rw',
   isa           => ArrayRef,
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_to_block_list => 'push',
      clear_block_list  => 'clear',
      has_block_list    => 'count',
   };

=item field_list

=cut

has 'field_list' =>
   is            => 'rw',
   isa           => ArrayRef,
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_to_field_list => 'push',
      clear_field_list  => 'clear',
      has_field_list    => 'count',
   };

=item found_hfs

=cut

has 'found_hfs' => is => 'rw', isa => Bool, default => 0;

=item page_list

=cut

has 'page_list' =>
   is           => 'rw',
   isa          => ArrayRef,
   default      => sub { [] },
   handles_via  => 'Array',
   handles      => {
      add_to_page_list => 'push',
      clear_page_list  => 'clear',
      has_page_list    => 'count',
   };

=item target

=cut

has 'target' =>
   is        => 'ro',
   isa       => Str,
   required  => TRUE;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item calculate_all_roles

=cut

sub calculate_all_roles {
   my $self = shift;
   my @roles;

   for my $class ($self->linearised_isa) {
      next unless exists $Role::Tiny::APPLIED_TO{ $class };

      for my $role (keys %{ $Role::Tiny::APPLIED_TO{ $class } }) {
         push @roles, $role if Role::Tiny->is_role( $role );
      }
   }

   return @roles;
}

=item find_attribute_by_name

=cut

sub find_attribute_by_name {
   my ($self, $attr_name) = @_;

   for my $class ($self->linearised_isa) {
      my $meta = get_meta($class);

      next unless $meta;

      return $meta->get_attribute( $attr_name )
          if $meta->has_attribute( $attr_name );
   }

   return;
}

=item get_attribute

=cut

sub get_attribute {
   my ($self, $attr_name) = @_;

   my $target = $self->target;

   throw 'Not a Moo class'
      unless $Moo::MAKERS{ $target } && $Moo::MAKERS{ $target }{is_class};

   my $con  = Moo->_constructor_maker_for( $target );
   my $attr = $con->{attribute_specs}->{ $attr_name };

   return HTML::Forms::Moo::Attribute->new( $attr );
}

=item has_attribute

=cut

sub has_attribute {
   my ($self, $attr_name) = @_;

   my $target = $self->target;

   throw 'Not a Moo class'
      unless $Moo::MAKERS{ $target } && $Moo::MAKERS{ $target }{is_class};

   my $con = Moo->_constructor_maker_for( $target );

   return exists $con->{attribute_specs}->{ $attr_name } ? TRUE : FALSE;
}

=item linearised_isa

=cut

sub linearised_isa {
   my $self = shift;
   my $target = $self->target;
   my @target_isa = @{ mro::get_linear_isa( $target ) };
   my %seen = ();

   return map { $seen{ $_ }++; $_ } grep { !exists $seen{ $_ } } @target_isa;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

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
