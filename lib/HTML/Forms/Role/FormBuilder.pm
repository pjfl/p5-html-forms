package HTML::Forms::Role::FormBuilder;

use Class::Usul::Cmd::Constants qw( DUMP_EXCEPT );
use HTML::Forms::Constants      qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use HTML::Forms::Types          qw( Bool HashRef Str );
use Class::Usul::Cmd::Util      qw( ensure_class_loaded includes
                                    list_attr_of list_methods_of );
use Data::Validate::IP          qw( is_ip );
use HTML::Forms::Util           qw( json_bool );
use JSON::MaybeXS               qw( decode_json encode_json );
use Ref::Util                   qw( is_arrayref is_hashref );
use Scalar::Util                qw( blessed );
use Type::Utils                 qw( class_type );
use Unexpected::Functions       qw( throw );
use Pod::Markdown::Github;
use Text::MultiMarkdown;
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Role::FormBuilder - Generate fields from an object

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';
   with    'HTML::Forms::Role::FormBuilder';

=head1 Description

Generate fields from an object

=head1 Configuration and Environment

Defines no public attributes

=over 3

=item include_private

A boolean which defaults false. If true private attributes of the supplied
object will be listed

=cut

has 'include_private' => is => 'rw', isa => Bool, default => FALSE;

has '_md_formatter' =>
   is      => 'lazy',
   isa     => class_type('Text::MultiMarkdown'),
   default => sub { Text::MultiMarkdown->new };

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
         Boolean       => \&_update_boolean,
         Compound      => \&_update_compound,
         DataStructure => \&_update_datastructure,
         OctalNum      => \&_update_octalnum,
         PosInteger    => \&_update_posinteger,
         Password      => \&_update_text,
         Text          => \&_update_text,
         TextArea      => \&_update_textarea,
      };
   };

=back

=head1 Subroutines/Methods

=over 3

=cut

around 'html_attributes' => sub {
   my ($orig, $self, $obj, $type, $attrs, $result) = @_;

   $attrs = $orig->($self, $obj, $type, $attrs, $result);

   push @{$attrs->{class}}, 'right' if $type eq 'label';

   return $attrs;
};

=item changed_fields

   $hash_ref = $self->changed_fields($object);

Introspects the supplied object and compares it's values with that provided
by the posted form. Differences are returned

=cut

sub changed_fields {
   my ($self, $object, $for_update) = @_;

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
      my $type     = $item->{$key}->{type};
      my $value    = $item->{$key}->{value};
      my $accessor = $object->can("_${key}") ? "_${key}" : $key;
      my $handler  = $self->_update_dispatch->{$type};

      throw "Type ${type} not handled" unless $handler;

      my $result = $handler->($self, $object, $accessor, $value, $for_update);

      $changed->{$key} = $result if defined $result;
   }

   return $changed;
}

=item field_builder

   $list_ref = $self->field_builder($object);

Introspects the supplied object and generates a list of fields

=cut

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

=item merge_changed

=cut

sub merge_changed {
   my ($self, $object, $changed, $content) = @_;

   for my $key (keys %{$changed}) {
      my $accessor = blessed $object && $object->can("_${key}") ? "_${key}"
                   : $key;
      my $existing = exists $content->{$key} ? $content->{$key}
                   : blessed $object         ? $object->$accessor
                   : $object->{$accessor};

      if (is_arrayref $existing) {
         my $has_item = exists $content->{$key} && $content->{$key}->[0];
         my $subtype  = $has_item             ? $content->{$key}->[0]
                      : $changed->{$key}->[0] ? $changed->{$key}->[0]
                      : blessed $object       ? $object->$accessor->[0]
                      : $object->{$accessor}->[0];

         if (is_arrayref $subtype or is_hashref $subtype) {
            $content->{$key} = [];

            for my $item (@{$object->$accessor}, @{$changed->{$key}}) {
               push @{$content->{$key}}, $item;
            }
         }
         else { $content->{$key} = [@{$changed->{$key}}] }
      }
      elsif (is_hashref $existing) {
         $content->{$key} = $self->merge_changed(
            $object->$key, $changed->{$key}, {%{$existing}}
         );
      }
      else { $content->{$key} = $changed->{$key} }
   }

   return $content;
}

# Private methods
sub _attr_map {
   my ($self, $object, $method, $map) = @_;

   my ($attr_name) = reverse split m{ :: }mx, $method;
   my $except      = [
      DUMP_EXCEPT, @{($object->can('DumpExcept') ? $object->DumpExcept : [])}
   ];

   return if includes $attr_name, $except;

   my $attr = $self->_get_attribute($object, $attr_name);

   $attr->{documentation} = $self->_get_documentation($object, $method);

   $map->{$attr_name} = $attr if exists $attr->{type};

   return;
}

sub _field_map {
   my ($self, $object) = @_;

   my $map = {};

   for my $method (@{list_methods_of $object, 'public'}) {
      $self->_attr_map($object, $method, $map);
   }

   if ($self->include_private) {
      for my $method (@{list_methods_of $object, 'private'}) {
         $self->_attr_map($object, $method, $map);
      }
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

   my $types     = [map { s{ \[ [^\]]+ \] }{}gmx; $_ } split m{ [\|] }mx,$type];
   my ($subtype) = $type =~ m{ \[ ([^\]]+) \]}mx;
   my $reader    = $attr->{reader} // $attr_name;
   my $default   = $object->$reader() // NUL;
   (my $name     = $attr_name) =~ s{ \A _ }{}mx;
   my $subfields = [ split m{ [ ] }mx, $attr->{documentation} // NUL ];
   my $subftypes = $self->_types_from_dmf($subfields);

   return {
      default   => $default,
      name      => $name,
      subfields => [ map { s{ = [^=]+ \z }{}mx; $_} @{$subfields}],
      subftypes => $subftypes,
      subtype   => ($subtype // 'Str'),
      type      => $types->[0],
   };
}

sub _get_documentation {
   my ($self, $object, $method) = @_;

   my $pod = [list_attr_of $object, [$method]]->[0]->[2] // NUL;

   if ($pod eq 'Undocumented') {
      my ($attr_name, @rest) = reverse split m{ :: }mx, $method;

      $attr_name =~ s{ \A _ }{}mx;

      if ($object->can($attr_name)) {
         $method = join '::', reverse(@rest), $attr_name;
         $pod = [list_attr_of $object, [$method]]->[0]->[2] // NUL;
      }
   }

   my $parser = Pod::Markdown::Github->new;

   $parser->output_string(\my $markdown);
   $parser->parse_string_document("=pod\n\n${pod}\n\n=cut\n");


   if (includes 'tooltips', $self->features) {
      return $self->_md_formatter->markdown("${markdown}\n");
   }

   return $markdown;
}

sub _get_field_class {
   my ($self, $object, $attr, $options) = @_;

   my $handler = $self->_type_dispatch->{$attr->{type}}->{$attr->{subtype}};

   return unless $handler;

   my $class = $handler->($self, $object, $attr, $options);
   my $space = $self->_fieldspace;

   return "${space}::${class}";
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
      title  => $attr->{documentation} // NUL,
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

   $options->{default} = $attr->{default} . NUL;
   return 'Boolean';
}

sub _type_compound {
   my ($self, $object, $attr, $options) = @_;

   my $count = $options->{order} + 1;
   my $types = {};

   for my $key (keys %{$attr->{subftypes}}) {
      $types->{lc $key} = _dmftype2type_tiny($attr->{subftypes}->{$key});
   }

   $attr->{callback} = sub {
      my ($self, $compound) = @_;

      for my $key (sort keys %{$attr->{default}}) {
         next if $types->{lc $key} && $types->{lc $key} eq 'NoUpdate';

         my $attr  = {
            default     => $attr->{default}->{$key},
            input_param => $key,
            label       => $self->_make_label($key),
            name        => ($attr->{name} . '.' . $key),
            subtype     => 'Str',
            type        => $types->{lc $key} // 'Str',
         };

         if (my $field = $self->_new_field($object, $attr, $count)) {
            $compound->add_field($field);
            $count += 1;
         }
      }
   };

   $options->{info}          = $self->_make_label($attr->{name});
   $options->{info_top}      = TRUE;
   $options->{wrapper_class} = ['compound-field', 'section'];
   return 'Compound';
}

sub _type_datastructure {
   my ($self, $object, $attr, $options) = @_;

   $options->{structure} = [];

   for my $key (@{$attr->{subfields}}) {
      push @{$options->{structure}}, {
         label => $self->_make_label($key),
         name  => $key,
         type  => $attr->{subftypes}->{lc $key},
      };
   }

   my $type   = lc $attr->{subtype};
   my $method = "_type_ds_${type}";
   my $name   = $attr->{name};

   throw "Attr ${name} DS type ${type} not handled" unless $self->can($method);

   $options->{default} = $self->$method($attr);
   $options->{validate_method} = \&_validate_ds;
   return 'DataStructure';
}

sub _type_ds_arrayref {
   my ($self, $attr) = @_;

   my $default = [];

   for my $tuple (@{$attr->{default}}) {
      my $index = 0;
      my $item  = {};

      for my $key (@{$attr->{subfields}}) {
         if ($attr->{subftypes}->{lc $key} eq 'boolean') {
            $item->{$key} = json_bool(!!$tuple->[$index++] ? TRUE : FALSE);
         }
         else { $item->{$key} = $tuple->[$index++] }
      }

      push @{$default}, $item;
   }

   return encode_json($default);
}

sub _type_ds_hashref {
   my ($self, $attr) = @_;

   my $default = [];

   for my $item (@{$attr->{default}}) {
      for my $key (@{$attr->{subfields}}) {
         if ($attr->{subftypes}->{lc $key} eq 'boolean') {
            $item->{$key} = json_bool(!!$item->{$key} ? TRUE : FALSE);
         }
         else { $item->{$key} = $item->{$key} }
      }

      push @{$default}, $item;
   }

   return encode_json($default);
}

sub _type_password {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = $attr->{default} . NUL;
   $options->{tags}    = { reveal => TRUE };
   return 'Password';
}

sub _type_octalnum {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = $attr->{default} . NUL;
   return 'OctalNum';
}

sub _type_posinteger {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = $attr->{default} . NUL;
   return 'PosInteger';
}

sub _type_text {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = $attr->{default} . NUL;
   return 'Text';
}

sub _type_textarea {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = join "\n", @{$attr->{default}};
   return 'TextArea';
}

sub _types_from_dmf { # Documentation attribute micro format
   my ($self, $subfields) = @_;

   my $hash = {};

   for my $key (@{$subfields}) {
      my $type;

      ($key, $type) = $key =~ m{ \A ([^=]+) \= (.+) \z }mx if $key =~ m{ \= }mx;

      $hash->{lc $key} = $type // 'text';
   }

   return $hash;
}

sub _update_boolean {
   my ($self, $object, $attr, $value, $for_updt) = @_;

   return $self->_update__scalar('boolean', $object->$attr, $value, $for_updt);
}

sub _update_compound {
   my ($self, $object, $attr, $value) = @_;

   my $attribute = $self->_get_attribute($object, $attr);
   my $changed   = {};

   for my $subkey (sort keys(%{$value}), @{$attribute->{subfields}}) {
      my $type      = $attribute->{subftypes}->{lc $subkey} // 'text';
      my $hash      = $object->$attr;
      my $current   = exists $hash->{$subkey} ? $hash->{$subkey} : undef;
      my $updated   = $value->{$subkey};
      my $new_value = $self->_update__scalar($type, $current, $updated);

      $changed->{$subkey} = $new_value if defined $new_value;
   }

   return (scalar keys %{$changed}) ? $changed : undef;
}

sub _update_datastructure {
   my ($self, $object, $attr, $value) = @_;

   my $attribute = $self->_get_attribute($object, $attr);
   my $subtype   = lc $attribute->{subtype} // 'not_supplied';
   my $method    = "_update_ds_${subtype}";

   throw "Subtype ${subtype} not handled" unless $self->can($method);

   my $changed = $self->$method($object, $attr, decode_json($value));

   return (scalar @{$changed}) ? $changed : undef;
}

sub _update_ds_arrayref {
   my ($self, $object, $attr, $value) = @_;

   my $attribute = $self->_get_attribute($object, $attr);
   my $changed   = [];
   my $index     = 0;

   for my $item (@{$value}) {
      my $updated  = FALSE;
      my $new_item = [];
      my $subindex = 0;

      for my $key (@{$attribute->{subfields}}) {
         my $type      = $attribute->{subftypes}->{lc $key} // 'text';
         my $array     = $object->$attr->[$index];
         my $current   = defined $array ? $array->[$subindex] : undef;
         my $input     = $item->{$key};
         my $new_value = $self->_update__scalar($type, $current, $input);

         $updated = TRUE if defined $new_value;

         push @{$new_item}, (
            defined $new_value ? $new_value :
            defined $current   ? $current   :
            $type eq 'boolean' ? FALSE      : undef
         );
         $subindex++;
      }

      push @{$changed}, $new_item if $updated;
      $index++;
   }

   return $changed;
}

sub _update_ds_hashref {
   my ($self, $object, $attr, $value) = @_;

   my $attribute = $self->_get_attribute($object, $attr);
   my $changed   = [];
   my $index     = 0;

   for my $item (@{$value}) {
      my $new_item = {};

      for my $key (sort keys %{$item}) {
         my $type      = $attribute->{subftypes}->{lc $key} // 'text';
         my $hash      = $object->$attr->[$index];
         my $current   = exists $hash->{$key} ? $hash->{$key} : undef;
         my $input     = $item->{$key};
         my $new_value = $self->_update__scalar($type, $current, $input);

         $new_item->{$key} = $new_value if defined $new_value;
      }

      push @{$changed}, $new_item  if scalar keys %{$new_item};
      $index++;
   }

   return $changed;
}

sub _update_octalnum {
   my ($self, $object, $attr, $value) = @_;

   return $self->_update__scalar('octalnum', $object->$attr, $value);
}

sub _update_posinteger {
   my ($self, $object, $attr, $value) = @_;

   return $self->_update__scalar('integer', $object->$attr, $value);
}

sub _update_text {
   my ($self, $object, $attr, $value) = @_;

   return $self->_update__scalar('text', $object->$attr, $value);
}

sub _update_textarea {
   my ($self, $object, $attr, $value) = @_;

   $value =~ s{ [\r] }{}gmx;

   my $attr_val = join "\n", @{$object->$attr};
   my $changed  = $self->_update__scalar('text', $attr_val, $value);

   return $changed ? [split m{ [\n] }mx, $changed] : undef;
}

sub _update__scalar {
   my ($self, $type, $current, $updated, $for_update) = @_;

   my $method = lc "_update__${type}";

   throw "Type ${type} not handled" unless $self->can($method);

   return $self->$method($current, $updated, $for_update);
}

sub _update__boolean {
   my ($self, $current, $updated, $for_update) = @_;

   if (!!$current != !!$updated) {
      if ($for_update) { return json_bool(!!$updated ? TRUE : FALSE) }
      else { return !!$updated ? TRUE : FALSE }
   }

   return;
}

sub _update__integer {
   my ($self, $current, $updated) = @_;

   $current //= 0; $updated //= 0;

   return $current != $updated ? $updated : undef;
}

sub _update__ipaddress {
   my ($self, $current, $updated) = @_;

   $current //= NUL; $updated //= NUL;

   return $current ne $updated ? $updated : undef;
}

sub _update__noupdate {
   my ($self, $current, $updated) = @_; return;
}

sub _update__octalnum {
   my ($self, $current, $updated) = @_;

   $current //= "0"; $updated //= "0";

   return $current ne $updated ? $updated : undef;
}

sub _update__password {
   my ($self, $current, $updated) = @_;

   $current //= NUL; $updated //= NUL;

   return $updated ne NUL ? $updated : undef;
}

sub _update__text {
   my ($self, $current, $updated) = @_;

   $current //= NUL; $updated //= NUL;

   return $current ne $updated ? $updated : undef;
}

sub _validate_ds {
   my $field = shift;
   my $types = {};

   for my $item (@{$field->structure}) {
      $types->{$item->{name}} = $item->{type};
   }

   for my $row (@{decode_json($field->result->value // '[]')}) {
      for my $key (sort keys %{$row}) {
         my $value = $row->{$key};
         my $type  = $types->{$key};

         if ($type eq 'ipaddress') {
            $field->add_error('Bad IP address') if $value && !is_ip($value);
         }
      }
   }

   return;
}

# Private functions
sub _dmftype2type_tiny {
   my $type = lc shift;

   return {
      boolean   => 'Bool',
      integer   => 'PositiveInt',
      ipaddress => 'Str',
      noupdate  => 'NoUpdate',
      password  => 'Password',
      text      => 'Str',
   }->{$type} // 'Str';
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

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

Peter Flanigan, C<< <pjfl@cpan.org> >>

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
