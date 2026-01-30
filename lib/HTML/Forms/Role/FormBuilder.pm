package HTML::Forms::Role::FormBuilder;

use Class::Usul::Cmd::Constants qw( DUMP_EXCEPT );
use HTML::Forms::Constants      qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use HTML::Forms::Types          qw( HashRef Str );
use HTML::Forms::Util           qw( json_bool );
use Class::Usul::Cmd::Util      qw( ensure_class_loaded includes
                                    list_methods_of );
use JSON::MaybeXS               qw( decode_json encode_json );
use Ref::Util                   qw( is_arrayref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( throw );
use Moo::Role;

has '_type_dispatch' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub {
      return {
         ArrayRef => {
            ArrayRef => \&_type_datastructure,
            HashRef  => \&_type_datastructure,
            Str      => \&_type_textarea,
         },
         Bool      => { Str => \&_type_boolean },
         Directory => { Str => \&_type_text },
         File      => { Str => \&_type_text },
         HashRef => {
            ArrayRef => FALSE,
            HashRef  => FALSE,
            Str      => \&_type_compound,
         },
         LoadableClass => { Str => \&_type_text },
         OctalNum      => { Str => \&_type_octalnum },
         Password      => { Str => \&_type_password },
         PositiveInt   => { Str => \&_type_posinteger },
         Str           => { Str => \&_type_text },
      };
   };

has '_fieldspace' => is => 'ro', isa => Str, default => 'HTML::Forms::Field';

has '_update_dispatch' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub {
      return {
         Boolean       => \&_update_bool,
         Compound      => \&_update_hashref_scalar,
         DataStructure => \&_update_arrayref_ref,
         OctalNum      => \&_update_octal_num,
         PosInteger    => \&_update_int,
         Password      => \&_update_str,
         TextArea      => \&_update_arrayref_str,
         Text          => \&_update_str,
      };
   };

sub changed_fields {
   my ($self, $object) = @_;

   my $space = $self->_fieldspace;
   my $item  = {};

   for my $field ($self->all_fields) {
      next unless $field->name =~ m{ \A fb_ }mx;

      (my $name = $field->name) =~ s{ \A fb_ }{}mx;
      (my $type = $field->type) =~ s{ \A ${space}:: }{}mx;

      $item->{$name} = { type => $type, value => $field->value };
   }

   my $changed = {};

   for my $key (sort keys %{$item}) {
      my $type    = $item->{$key}->{type};
      my $value   = $item->{$key}->{value};
      my $attr    = $object->can("_${key}") ? "_${key}" : $key;
      my $handler = $self->_update_dispatch->{$type};

      throw "Type ${type} not handled\n" unless $handler;

      my $result = $handler->($self, $object, $attr, $value);

      $changed->{$key} = $result if defined $result;
   }

   return $changed;
}

sub field_builder {
   my ($self, $object) = @_;

   my $map   = $self->_field_map($object);
   my $sortf = sub {
      my $left  = $map->{$_[0]};
      my $right = $map->{$_[1]};

      if ($left->{type} eq 'HashRef' && $right->{type} eq 'HashRef') {
         return $left->{name} cmp $right->{name};
      }
      elsif ($left->{type} eq 'HashRef' || $right->{type} eq 'HashRef') {
         return $left->{type} eq 'HashRef' ? -1 : 1;
      }

      return $left->{name} cmp $right->{name};
   };
   my $count  = 1;
   my $fields = [];

   for my $key (sort { $sortf->($a, $b) } keys %{$map}) {
      my $field = $self->_new_field($object, $map->{$key}, $count) or next;

      push @{$fields}, $field;
      $count++;
   }

   return $fields;
}

# Private methods
sub _attr_map {
   my ($self, $object, $method, $map) = @_;

   my ($attr_name) = reverse split m{ :: }mx, $method;

   return if includes $attr_name, [
      DUMP_EXCEPT, @{($object->can('DumpExcept') ? $object->DumpExcept : [])}
   ];

   my $attr = $self->_get_attribute($object, $attr_name);

   $map->{$attr_name} = $attr if exists $attr->{type};

   return;
}

sub _field_map {
   my ($self, $object) = @_;

   my $map = {};

   for my $method (@{list_methods_of $object, 'public'}) {
      $self->_attr_map($object, $method, $map);
   }

   for my $method (@{list_methods_of $object, 'private'}) {
      $self->_attr_map($object, $method, $map);
   }

   return $map;
}

sub _get_attribute {
   my ($self, $object, $attr_name) = @_;

   my $target = blessed $object;

   throw 'Not a Moo class' unless $Moo::MAKERS{$target}
      && $Moo::MAKERS{$target}{is_class};

   my $con  = Moo->_constructor_maker_for($target);
   my $attr = $con->{attribute_specs}->{$attr_name};
   my $type = $attr->{isa} ? $attr->{isa}->display_name : NUL;

   return {} if $attr->{documentation} && $attr->{documentation} eq 'NoUpdate';
   return {} if !$attr->{init_arg} || !$type || $type eq '__ANON__';

   my $types = [map { s{ \[ [^\]]+ \] }{}gmx; $_ } split m{ [\|] }mx, $type];
   my ($subtype) = $type =~ m{ \[ ([^\]]+) \]}mx;
   my $reader    = $attr->{reader} // $attr_name;
   my $default   = $object->$reader() // NUL;
   (my $name     = $attr_name) =~ s{ \A _ }{}mx;

   return {
      default   => $default,
      name      => $name,
      subfields => [split m{ [ ] }mx, $attr->{documentation} // NUL],
      subtype   => ($subtype // 'Str'),
      type      => $types->[0],
   };
}

sub _get_field_class {
   my ($self, $object, $attr, $options) = @_;

   my $handler = $self->_type_dispatch->{$attr->{type}}->{$attr->{subtype}};

   return unless $handler;

   $handler->($self, $object, $attr, $options);

   my $space = $self->_fieldspace;

   return "${space}::" . (delete $options->{class}) if $options->{class};

   return "${space}::Text";
}

sub _make_label {
   my ($self, $key) = @_;

   return join SPC, map { ucfirst } split m{ [_\-] }mx, $key;
}

sub _new_field {
   my ($self, $object, $attr, $count) = @_;

   return unless $attr;

   my $name    = $attr->{name};
   my $options = {
      form   => $self,
      label  => $attr->{label} // $self->_make_label($name),
      name   => "fb_${name}",
      order  => $count,
      parent => $self,
   };

   $options->{input_param} = $attr->{input_param} if $attr->{input_param};

   my $class = $self->_get_field_class($object, $attr, $options) or return;

   ensure_class_loaded $class;

   my $field = $self->new_field_with_traits($class, $options);

   $field->icons($self->_icons) if $field->can('icons');

   $attr->{callback}->($self, $field) if $attr->{callback};

   return $field;
}

sub _type_boolean {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'Boolean';
   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _type_compound {
   my ($self, $object, $attr, $options) = @_;

   my $types = $self->_types_from_dmf($attr);
   my $count = $options->{order} + 1;
   my $index = {};

   for my $key (keys %{$types}) {
      $index->{lc $key} = _dmftype2type_tiny($types->{lc $key});
   }

   $attr->{callback} = sub {
      my ($self, $compound) = @_;

      for my $key (sort keys %{$attr->{default}}) {
         next if $index->{lc $key} && $index->{lc $key} eq 'NoUpdate';

         my $attr  = {
            default     => $attr->{default}->{$key},
            input_param => $key,
            label       => $self->_make_label($key),
            name        => ($attr->{name} . '.' . $key),
            subtype     => 'Str',
            type        => $index->{lc $key} // 'Str',
         };

         if (my $field = $self->_new_field($object, $attr, $count)) {
            $compound->add_field($field);
            $count += 1;
         }
      }
   };
   $options->{class} = 'Compound';
   $options->{info} = $self->_make_label($attr->{name});
   $options->{info_top} = TRUE;
   $options->{wrapper_class} = 'compound-field section';
   return;
}

sub _type_datastructure {
   my ($self, $object, $attr, $options) = @_;

   my $types     = $self->_types_from_dmf($attr);
   my $structure = [];

   for my $key (@{$attr->{subfields}}) {
      push @{$structure}, {
         label => $self->_make_label($key),
         name  => $key,
         type  => $types->{lc $key},
         width => '13rem', # TODO: Yuck. Make it go away
      };
   }

   $options->{class}     = 'DataStructure';
   $options->{structure} = $structure;

   if ($attr->{subtype} eq 'ArrayRef') {
      my $default = [];

      for my $tuple (@{$attr->{default}}) {
         my $index = 0;
         my $item  = {};

         for my $key (@{$attr->{subfields}}) {
            if ($types->{lc $key} eq 'boolean') {
               $item->{$key} = json_bool(!!$tuple->[$index++] ? TRUE : FALSE);
            }
            else { $item->{$key} = $tuple->[$index++] }
         }

         push @{$default}, $item;
      }

      $options->{default} = encode_json($default);
   }
   else {
      my $default = [];

      for my $item (@{$attr->{default}}) {
         for my $key (@{$attr->{subfields}}) {
            if ($types->{lc $key} eq 'boolean') {
               $item->{$key} = json_bool(!!$item->{$key} ? TRUE : FALSE);
            }
            else { $item->{$key} = $item->{$key} }
         }

         push @{$default}, $item;
      }

      $options->{default} = encode_json($default);
   }

   return;
}

sub _type_password {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'Password';
   $options->{default} = $attr->{default} . NUL;
   $options->{tags}    = { reveal => TRUE };
   return;
}

sub _type_octalnum {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'OctalNum';
   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _type_posinteger {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'PosInteger';
   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _type_text {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _type_textarea {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'TextArea';
   $options->{default} = join "\n", @{$attr->{default}};
   return;
}

sub _types_from_dmf {
   my ($self, $attr) = @_;

   my $hash = {};

   for my $key (@{$attr->{subfields}}) {
      my $type;

      ($key, $type) = $key =~ m{ \A ([^=]+) \= (.+) \z }mx if $key =~ m{ \= }mx;

      $hash->{lc $key} = $type // 'text';
   }

   return $hash;
}

sub _update_arrayref_ref {
   my ($self, $object, $attr, $encoded) = @_;

   my $attribute = $self->_get_attribute($object, $attr);
   my $types     = $self->_types_from_dmf($attribute);
   my $subfields = $attribute->{subfields};
   my $changed   = [];
   my $index     = 0;

   for my $item (@{decode_json($encoded)}) {
      if ($attribute->{subtype} eq 'ArrayRef') {
         my $updated  = FALSE;
         my $new_item = [];
         my $subindex = 0;

         for my $key (map { s{ = [^=]+ \z }{}mx; $_} @{$subfields}) {
            my $type      = $types->{lc $key} // 'text';
            my $current   = $object->$attr->[$index]->[$subindex];
            my $value     = $item->{$key};
            my $new_value = $self->_update_by_dmftype($type, $current, $value);

            $updated = TRUE if defined $new_value;

            push @{$new_item}, (
               defined $new_value ? $new_value : defined $current
                     ? $current   : $type eq 'boolean' ? FALSE : undef
            );
            $subindex++;
         }

         push @{$changed}, $new_item if $updated;
      }
      else { # HashRef
         my $new_item = {};

         for my $key (sort keys %{$item}) {
            my $type      = $types->{lc $key} // 'text';
            my $current   = $object->$attr->[$index]->{$key};
            my $value     = $item->{$key};
            my $new_value = $self->_update_by_dmftype($type, $current, $value);

            $new_item->{$key} = $new_value if defined $new_value;
         }

         push @{$changed}, $new_item  if scalar keys %{$new_item};
      }

      $index++;
   }

   return (scalar @{$changed}) ? $changed : undef;
}

sub _update_arrayref_str {
   my ($self, $object, $attr, $value) = @_;

   my $attr_val = join "\n", @{$object->$attr};

   $value =~ s{ [\r] }{}gmx;

   return $attr_val ne $value ? [split m{ [\n] }mx, $value] : undef;
}

sub _update_by_dmftype {
   my ($self, $type, $current, $updated) = @_;

   my $changed;

   if ($type eq 'boolean') {
      $current //= FALSE;
      $changed = (!!$updated ? TRUE : FALSE) if !!$current != !!$updated;
   }
   elsif ($type eq 'integer') {
      $current //= 0;
      $changed = $updated if $current != $updated;
   }
   elsif ($type eq 'ipaddress' || $type eq 'password' || $type eq 'text') {
      $current //= NUL;
      $changed = $updated if $current ne $updated;
   }
   elsif ($type eq 'noupdate') {
   }
   else { throw "Type ${type} not handled\n" }

   return $changed;
}

sub _update_bool {
   my ($self, $object, $attr, $value) = @_;

   return !!$object->$attr != !!$value ? $value : undef;
}

sub _update_hashref_scalar {
   my ($self, $object, $attr, $value) = @_;

   my $attribute = $self->_get_attribute($object, $attr);
   my $types     = $self->_types_from_dmf($attribute);
   my $subfields = $attribute->{subfields};
   my $changed   = {};

   for my $subkey (sort keys(%{$value}), @{$subfields}) {
      my $type      = $types->{lc $subkey} // 'text';
      my $current   = $object->$attr->{$subkey};
      my $updated   = $value->{$subkey};
      my $new_value = $self->_update_by_dmftype($type, $current, $updated);

      $changed->{$subkey} = $new_value if defined $new_value;
   }

   return (scalar keys %{$changed}) ? $changed : undef;
}

sub _update_int {
   my ($self, $object, $attr, $value) = @_;

   return $object->$attr != $value ? $value : undef;
}

sub _update_octal_num {
   my ($self, $object, $attr, $value) = @_;

   return $object->$attr ne $value ? "${value}" : undef;
}

sub _update_str {
   my ($self, $object, $attr, $value) = @_;

   return $object->$attr ne $value ? $value : undef;
}

# Private functions
sub _dmftype2type_tiny {
   my $type = lc shift;

   return {
      boolean  => 'Bool',
      integer  => 'PositiveInt',
      noupdate => 'NoUpdate',
      password => 'Password',
      text     => 'Str',
   }->{$type} // 'Str';
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Role::FormBuilder - HTML forms using Moo

=head1 Synopsis

   use HTML::Forms::Role::FormBuilder;
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

=item L<Class::Usul::Cmd>

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

Copyright (c) 2026 Peter Flanigan. All rights reserved

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
