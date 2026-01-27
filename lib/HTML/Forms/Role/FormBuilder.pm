package HTML::Forms::Role::FormBuilder;

use Class::Usul::Cmd::Constants qw( DUMP_EXCEPT );
use HTML::Forms::Constants      qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use HTML::Forms::Types          qw( HashRef );
use Class::Usul::Cmd::Util      qw( ensure_class_loaded includes
                                    list_methods_of );
use JSON::MaybeXS               qw( encode_json );
use Ref::Util                   qw( is_arrayref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( throw );
use Moo::Role;

sub form_builder {
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
   my ($self, $object, $value, $map) = @_;

   my ($key) = reverse split m{ :: }mx, $value;
   my $attr  = $self->_get_attribute($object, $key);
   (my $name = $key) =~ s{ \A _ }{}mx;

   return if includes $name, [
      DUMP_EXCEPT, @{($object->can('DumpExcept') ? $object->DumpExcept : [])}
   ];

   return unless exists $attr->{type};

   $map->{$key} = { name => $name, %{$attr} };
   return;
}

sub _field_map {
   my ($self, $object) = @_;

   my $map = {};

   for my $value (@{list_methods_of $object, 'public'}) {
      $self->_attr_map($object, $value, $map);
   }

   for my $value (@{list_methods_of $object, 'private'}) {
      $self->_attr_map($object, $value, $map);
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

   return {
      reader    => ($attr->{reader} // $attr_name),
      subfields => [split m{ [ ] }mx, $attr->{documentation} // NUL],
      subtype   => ($subtype // 'Str'),
      type      => $types->[0],
   };
}

sub _make_label {
   my ($self, $key) = @_;

   return join SPC, map { ucfirst } split m{ _ }mx, $key;
}

sub _new_field {
   my ($self, $object, $attr, $count) = @_;

   return unless $attr;

   my $name    = $attr->{name};
   my $options = {
      form   => $self,
      label  => $attr->{label} // $self->_make_label($name),
      name   => "x_${name}",
      order  => $count,
      parent => $self,
   };
   my $class = $self->_set_default($object, $attr, $options) or return;

   ensure_class_loaded $class;

   my $field = $self->new_field_with_traits($class, $options);

   $field->icons($self->_icons) if $field->can('icons');

   $attr->{callback}->($self, $field) if $attr->{callback};

   return $field;
}

my $dispatch = {
   ArrayRef => {
      ArrayRef => \&_default_datastructure,
      HashRef  => \&_default_datastructure,
      Str      => \&_default_textarea,
   },
   Bool      => { Str => \&_default_boolean },
   Directory => { Str => \&_default_text },
   File      => { Str => \&_default_text },
   HashRef => {
      ArrayRef => FALSE,
      HashRef  => FALSE,
      Str      => \&_default_compound,
   },
   LoadableClass => { Str => \&_default_text },
   OctalNum      => { Str => \&_default_posint },
   Password      => { Str => \&_default_password },
   PositiveInt   => { Str => \&_default_posint },
   Str           => { Str => \&_default_text },
};

sub _default_boolean {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'Boolean';
   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _default_compound {
   my ($self, $object, $attr, $options) = @_;

   my $count = $options->{order} + 1;
   my $index = {};

   for my $subfield (@{$attr->{subfields}}) {
      my ($key, $type) = $subfield =~ m{ \A ([^=]+) \= (.+) \z }mx
         if $subfield =~ m{ \= }mx;

      $key = $key ? $key : $subfield;
      $index->{$key} = _ftype2ttype($type ? ucfirst($type) : 'Text');
   }

   $attr->{callback} = sub {
      my ($self, $compound) = @_;

      for my $key (sort keys %{$attr->{default}}) {
         next if $index->{$key} && $index->{$key} eq 'NoUpdate';

         my $attr  = {
            default => $attr->{default}->{$key},
            label   => $self->_make_label($key),
            name    => ($attr->{name} . '-' . $key),
            subtype => 'Str',
            type    => $index->{$key} // 'Str',
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

sub _default_datastructure {
   my ($self, $object, $attr, $options) = @_;

   my $structure = [];

   for my $key (@{$attr->{subfields}}) {
      my $type = 'text';

      ($key, $type) = $key =~ m{ \A ([^=]+) \= (.+) \z }mx if $key =~ m{ \= }mx;

      push @{$structure}, {
         label => ucfirst($key),
         name  => lc($key),
         type  => $type,
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
            my $type;

            ($key, $type) = $key =~ m{ \A ([^=]+) \= (.+) \z }mx
               if $key =~ m{ \= }mx;

            if ($type && $type eq 'boolean') {
               $item->{lc $key} = $tuple->[$index++] ? \1 : \0;
            }
            else { $item->{lc $key} = $tuple->[$index++] }
         }

         push @{$default}, $item;
      }

      $options->{default} = encode_json($default);
   }
   else { $options->{default} = encode_json($attr->{default}) }

   return;
}

sub _default_password {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'Password';
   $options->{default} = $attr->{default} . NUL;
   $options->{tags}    = { reveal => TRUE };
   return;
}

sub _default_posint {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'PosInteger';
   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _default_text {
   my ($self, $object, $attr, $options) = @_;

   $options->{default} = $attr->{default} . NUL;
   return;
}

sub _default_textarea {
   my ($self, $object, $attr, $options) = @_;

   $options->{class}   = 'TextArea';
   $options->{default} = join "\n", @{$attr->{default}};
   return;
}

sub _set_default {
   my ($self, $object, $attr, $options) = @_;

   my $reader = $attr->{reader};

   $attr->{default} //= $object->$reader() // NUL;

   my $handler = $dispatch->{$attr->{type}}->{$attr->{subtype}};

   return unless $handler;

   $handler->($self, $object, $attr, $options);

   my $namespace = 'HTML::Forms::Field::';

   return $namespace . (delete $options->{class}) if $options->{class};

   return "${namespace}Text";
}

# Private functions
sub _ftype2ttype {
   my $type = lc shift;

   return {
      boolean  => 'Bool',
      integer  => 'PositiveInt',
      noupdate => 'NoUpdate',
      password => 'Password',
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
