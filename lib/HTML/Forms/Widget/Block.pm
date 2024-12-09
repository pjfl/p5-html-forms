package HTML::Forms::Widget::Block;

use HTML::Forms::Constants qw( NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool CodeRef HashRef
                               HFs HFsArrayRefStr Str );
use HTML::Forms::Util      qw( process_attrs );
use Scalar::Util           qw( weaken );
use Moo;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::Block - Blocks

=head1 Synopsis

   use HTML::Forms::Widget::Block;

=head1 Description

Blocks

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item after_plist

=cut

has 'after_plist' => is => 'rw', isa => Str, default => NUL;

=item C<attr>

=cut

has 'attr' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      delete__attr => 'delete',
      has_attr     => 'count',
      set__attr    => 'set',
   };

=item build_render_list_method

=cut

has 'build_render_list_method' =>
   is          => 'rw',
   isa         => CodeRef,
   builder     => sub { shift->default_build_render_list },
   handles_via => 'Code',
   handles     => { build_render_list => 'execute_method', },
   lazy        => TRUE;

=item class

=cut

has 'class'    =>
   is          => 'rw',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_class => 'push',
      has_class => 'count',
   };

=item content

=cut

has 'content' => is => 'rw', isa => Str, default => NUL;

=item form

=cut

has 'form' => is => 'ro', isa => HFs, required => TRUE, weak_ref => TRUE;

=item label

=item has_label

Predicate

=cut

has 'label' => is => 'rw', isa => Str, predicate => 'has_label';

=item label_class

=cut

has 'label_class' =>
   is          => 'rw',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_label_class => 'push',
      has_label_class => 'count',
   };

=item label_tag

=cut

has 'label_tag' => is => 'rw', isa => Str, default => 'span';

=item name

=cut

has 'name' => is => 'ro', isa => Str, required => TRUE;

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

=item tag

=cut

has 'tag' => is => 'rw', isa => Str, default => 'div';

=item wrapper

=cut

has 'wrapper' => is => 'rw', isa => Bool, default => TRUE;

with 'HTML::Forms::Role::RenderWithTT';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item block_label_attributes

=cut

sub block_label_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{ $self->label_attr } };
   my $class = [ @{ $self->label_class } ];

   $self->add_standard_label_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   return $attr;
}

=item block_wrapper_attributes

=cut

sub block_wrapper_attributes {
   my ($self, $result) = @_;

   $result //= $self->result;

   my $attr  = { %{ $self->attr } };
   my $class = [ @{ $self->class } ];

   $self->add_standard_wrapper_classes( $result, $class );

   $attr->{class} = $class if scalar @{ $class };

   return $attr;
}

=item default_build_render_list

=cut

sub default_build_render_list {
   my $self = shift;

   return sub { [] };
}

# Private methods
sub _build_default_tt_vars {
   my $self = shift; weaken $self;
   my $form = $self->form; weaken $form;

   return {
      blockw        => $self,
      form          => $form,
      get_tag       => sub { $form->get_tag( @_ ) },
      localise      => sub { $form->localise( @_ ) },
      process_attrs => \&process_attrs,
   };
}

sub _build_tt_template {
   my $self = shift;

   return $self->tt_theme . '/block.tt';
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
