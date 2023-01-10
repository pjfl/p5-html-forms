package HTML::Forms::Widget::Field::Trait::Toggle;

use namespace::autoclean;

use HTML::Forms::Constants qw( TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Str );
use HTML::Forms::Util      qw( encode_only_entities );
use JSON::MaybeXS          qw( encode_json );
use Moo::Role;
use MooX::HandlesVia;

requires qw( form input name validate widget );

has 'toggle' =>
   is          => 'ro',
   isa         => HashRef[ArrayRef],
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      has_toggle => 'count',
   };

has 'toggle_class' => is => 'ro', isa => Str, default => 'toggle';

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

has 'toggle_config_encoded' =>
   is      => 'lazy',
   isa     => Str,
   builder => sub {
      my $self = shift;

      return encode_only_entities( encode_json( $self->toggle_config ) );
   };

has 'toggle_config_key' =>
   is      => 'ro',
   isa     => Str,
   default => 'data-toggle-config';

has 'toggle_event' =>
   is        => 'ro',
   isa       => Str,
   predicate => 'has_toggle_event',
   writer    => '_toggle_event';

around '_build_element_attr' => sub {
   my ($orig, $self) = @_;

   my $attr = $orig->( $self );

   $attr->{$self->toggle_config_key} = $self->toggle_config_encoded
      if $self->has_toggle;

   return $attr;
};

before 'validate' => sub {
   my $self = shift;

   $self->clear_disabled_fields if $self->has_toggle;

   return;
};

# Public methods
sub BUILD {
   my $self = shift;

   $self->add_element_class( $self->toggle_class ) if $self->has_toggle;

   return;
}

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

sub get_disabled_fields {
   my ($self, $value) = @_; my @all_fields; my %seen = ();

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
   my ($self, $value) = @_; my $toggle = $self->toggle;

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

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Widget::Field::Trait::Toggle - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Widget::Field::Trait::Toggle;
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
