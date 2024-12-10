package HTML::Forms::Blocks;

use HTML::Forms::Constants qw( EXCEPTION_CLASS NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Object Str );
use HTML::Forms::Util      qw( get_meta );
use Unexpected::Functions  qw( throw );
use HTML::Forms::Widget::Block;
use Moo::Role;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Blocks - Blocks

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Blocks';

=head1 Description

Blocks

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item block_list

=cut

has 'block_list' =>
   is          => 'rw',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => { has_block_list => 'count' },
   lazy        => TRUE;

=item blocks

=cut

has 'blocks' =>
   is          => 'lazy',
   isa         => HashRef[Object],
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      add_block    => 'set',
      block        => 'get',
      block_exists => 'exists',
      has_blocks   => 'count',
   };

=item render_list

=cut

has 'render_list' =>
   is          => 'rw',
   isa         => ArrayRef[Str],
   builder     => 'build_render_list',
   handles_via => 'Array',
   handles     => {
      add_to_render_list => 'push',
      all_render_list    => 'elements',
      get_render_list    => 'get',
      has_render_list    => 'count',
   },
   lazy        => TRUE;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item build_fields

=cut

after 'build_fields' => sub {
   my $self = shift;
   my $meta_blist = $self->_build_meta_block_list;

   if (scalar @{ $meta_blist }) {
      for my $block_attr (@{ $meta_blist }) {
         $self->make_block( $block_attr );
      }
   }

   my $blist = $self->block_list;

   if (scalar @{ $blist }) {
      for my $block_attr (@{ $blist }) {
         $self->make_block( $block_attr );
      }
   }

   return;
};

=item get_renderer

=cut

sub get_renderer {
   my ($self, $name) = @_;

   throw 'Must provide a name to get_renderer' unless $name;

   my $obj = $self->block( $name );

   return $obj if blessed $obj;

   $obj = $self->field_from_index( $name );

   return $obj if blessed $obj;

   throw "Did not find a field or block with name ${name}\n";
}

=item make_block

=cut

sub make_block {
   my ($self, $block_attr) = @_;

   my $name = $block_attr->{name}
      or throw 'You must supply a name for a block';

   my $do_update = 0;

   if ($name =~ m{ \A \+ (.*) }mx) {
      $block_attr->{name} = $name = $1; $do_update = 1;
   }

   $block_attr->{form} = $self->form if $self->form;

   my $block = $self->form->block( $block_attr->{name} );

   if (defined $block && $do_update) {
      delete $block_attr->{name};

      for my $key (keys %{ $block_attr }) {
         $block->$key( $block_attr->{ $key } ) if $block->can( $key );
      }
   }
   else { # new block
      my $type = $block_attr->{type} //= NUL; my $class;

      if ($type) { $class = $self->get_widget_role( $type, 'Block' ) }
      else { $class = 'HTML::Forms::Widget::Block' }

      $block = $class->new( %{ $block_attr } );
      $self->add_block( $name, $block );
   }

   return;
}

# Private methods
# loops through all inherited classes and composed roles
# to find blocks specified with 'has_block'
sub _build_meta_block_list {
   my $self = shift;

   return [] unless get_meta($self);

   my @block_list = ();

   if ($self->can( 'block_list' ) && $self->has_block_list) {
      for my $block_def (@{ $self->block_list }) {
         push @block_list, $block_def;
      }
   }

   for my $class (reverse get_meta($self)->linearised_isa) {
      my $meta = get_meta($class);

      next unless $meta;

      if ($meta->can( 'block_list' ) && $meta->has_block_list) {
         for my $block_def (@{ $meta->block_list }) {
            push @block_list, $block_def;
         }
      }
   }

   return \@block_list;
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
