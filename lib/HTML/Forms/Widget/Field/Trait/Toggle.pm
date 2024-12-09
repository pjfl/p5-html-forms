package HTML::Forms::Widget::Field::Trait::Toggle;

use HTML::Forms::Constants qw( TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Str );
use HTML::Forms::Util      qw( encode_only_entities );
use JSON::MaybeXS          qw( encode_json );
use List::Util             qw( first );
use Ref::Util              qw( is_coderef );
use Moo::Role;
use MooX::HandlesVia;

requires qw( form input name validate widget );

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::Field::Trait::Toggle - Toggle trait

=head1 Synopsis

   use Moo;

   with 'HTML::Forms::Widget::Field::Trait::Toggle';

=head1 Description

Toggle trait

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item toggle

=cut

has 'toggle' =>
   is          => 'ro',
   isa         => HashRef[ArrayRef],
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      add_toggle   => 'push',
      clear_toggle => 'clear',
      has_toggle   => 'count',
   };

=item toggle_class

=cut

has 'toggle_class' => is => 'ro', isa => Str, default => 'toggle';

=item toggle_config

=cut

has 'toggle_config' =>
   is      => 'lazy',
   isa     => HashRef,
   builder => sub {
      my $self  = shift;
      my $event = $self->has_toggle_event      ? $self->toggle_event
                : lc $self->widget eq 'select' ? 'onchange'
                : 'onclick';

      return { config => $self->toggle, event => $event };
   };

=item toggle_config_encoded

=cut

has 'toggle_config_encoded' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self = shift;

      return encode_only_entities( encode_json( $self->toggle_config ) );
   };

=item toggle_config_key

=cut

has 'toggle_config_key' =>
   is      => 'ro',
   isa     => Str,
   default => 'data-toggle-config';

=item toggle_event

=item has_toggle_event

Predicate

=cut

has 'toggle_event' =>
   is        => 'ro',
   isa       => Str,
   predicate => 'has_toggle_event',
   writer    => '_toggle_event';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

sub BUILD {
   my $self = shift;

   return unless $self->has_toggle;

   $self->set_element_attr(
      $self->toggle_config_key, $self->toggle_config_encoded
   );

   $self->add_element_class( $self->toggle_class )
      unless first { $_ eq $self->toggle_class } @{$self->element_class};

   my $form = $self->form;

   $form->load_js_package('WCom.Form.Toggle')
      if $form && $form->can('load_js_package');

   return;
};

=item validate

=cut

before 'validate' => sub {
   my $self = shift;

   $self->clear_disabled_fields if $self->has_toggle;

   return;
};

=item clear_disabled_fields

=cut

sub clear_disabled_fields {
   my $self = shift;

   for my $field_name (@{ $self->get_disabled_fields( $self->input ) }) {
      my $field = $self->form->field( $field_name );

      if ($field) {
         $field->input( $field->init_value );

         $field->clear_disabled_fields
            if $field->does( 'HTML::Forms::Widget::Field::Trait::Toggle' );
      }
      else {
         warn "Field '${field_name}' in toggle config for "
            . $self->name . " but doesn't exist\n";
      }
   }
}

=item get_disabled_fields

=cut

sub get_disabled_fields {
   my ($self, $value) = @_;

   my @all_fields;
   my %seen = ();

   for my $fields (values %{ $self->toggle }) {
      for my $field (@{ $fields }) {
         push @all_fields, $field if !$seen{ $field };
         $seen{ $field }++;
      }
   }

   return [] unless @all_fields;

   my @disabled_fields;
   my $enabled_fields = $self->_get_enabled( $value );
   my %enabled_hash = map { $_ => TRUE } @{ $enabled_fields };

   for my $field (@all_fields) {
      push @disabled_fields, $field unless exists $enabled_hash{ $field };
   }

   return \@disabled_fields;
}

# Private methods
sub _get_enabled {
   my ($self, $value) = @_;

   my $toggle = $self->toggle;

   return $toggle->{ $value } if $value && exists $toggle->{ $value };

   if ($self->isa( 'HTML::Forms::Field::Checkbox' )) {
      return $toggle->{-checked  } || [] if $value;
      return $toggle->{-unchecked} || [];
   }

   if (defined $value) {
      if (exists $toggle->{-first}
         && defined $self->options->[ 0 ]{value}
         && $self->options->[ 0 ]{value} eq $value) {
         return $toggle->{-first};
      }

      return $toggle->{-set} if exists $toggle->{-set};
   }
   else {
      return $toggle->{-first} if exists $toggle->{-first};
      return $toggle->{-unset} if exists $toggle->{-unset};
   }

   return $toggle->{-other} || [];
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

Copyright (c) 2018 Peter Flanigan. All rights reserved

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
