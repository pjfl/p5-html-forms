package HTML::Forms::Fields;

use namespace::autoclean;

use Class::Load            qw( load_optional_class );
use Data::Clone            qw( clone );
use HTML::Forms::Constants qw( DOT EXCEPTION_CLASS FALSE META NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef
                               HFsArrayRefStr HFsField Str Undef );
use HTML::Forms::Util      qw( get_meta merge );
use Ref::Util              qw( is_arrayref is_hashref );
use Unexpected::Functions  qw( throw );
use Moo::Role;
use MooX::HandlesVia;

# requires qw( add_repeatable_field add_to_index field_traits form get_widget_role
#              has_flag no_widgets widget_wrapper );

has '_field_list' =>
   is       => 'rw',
   isa      => HashRef|ArrayRef,
   default  => sub { {} },
   init_arg => 'field_list';

has 'field_name_space' =>
   is          => 'rw',
   isa         => HFsArrayRefStr,
   builder     => sub { [] },
   coerce      => TRUE,
   handles_via => 'Array',
   handles     => {
      add_field_name_space => 'push',
   },
   lazy        => TRUE;

has 'fields' =>
   is          => 'rw',
   isa         => ArrayRef[HFsField],
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => {
      add_field    => 'push',
      all_fields   => 'elements',
      clear_fields => 'clear',
      has_fields   => 'count',
      num_fields   => 'count',
      push_field   => 'push',
      set_field_at => 'set',
      _pop_field   => 'pop',
   },
   lazy         => TRUE;

has 'fields_from_model' => is => 'rw', isa => Bool;

has 'include' =>
   is          => 'rw',
   isa         => ArrayRef,
   builder     => sub { [] },
   handles_via => 'Array',
   handles     => { has_include => 'count' },
   lazy        => TRUE;

has 'update_subfields' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      clear_update_subfields => 'clear',
      has_update_subfields   => 'count',
   };

has 'widget_tags' =>
   is          => 'rw',
   isa         => HashRef,
   builder     => sub { {} },
   handles_via => 'Hash',
   handles     => {
      has_widget_tags => 'count',
   };

# Public methods
sub build_fields {
   my $self = shift;
   my $meta_flist = $self->_build_meta_field_list;

   $self->_process_field_array( $meta_flist, 0 ) if $meta_flist;

   if (my $flist = $self->_has_field_list) {
      if (is_arrayref( $flist ) && is_hashref( $flist->[ 0 ] )) {
         $self->_process_field_array( $flist );
      }
      else { $self->_process_field_list( $flist ) }
   }

   my $mlist = $self->model_fields if $self->fields_from_model;

   $self->_process_field_list( $mlist ) if $mlist;

   $self->_order_fields if $self->has_fields;

   return;
}

sub clean_fields {
   my ($self, $fields) = @_;

   return clone( $fields ) unless $self->has_include;

   my %include = map { $_ => 1 } @{ $self->include };
   my @fields;

   for my $field ( @{ $fields } ) {
      push @fields, clone( $field ) if exists $include{ $field->{name} };
   }

   return \@fields;
}

sub clear_data {
   my $self = shift;

   $self->clear_result;
   $self->clear_active;

   $_->clear_data for $self->all_fields;

   return;
}

sub dump_fields { shift->dump( @_ ) }

sub dump {
   my $self = shift;

   warn "HFs: Fields for ", $self->name, "\n";

   for my $field ($self->sorted_fields) { $field->dump }

   return;
}

sub dump_validated {
   my $self = shift;

   warn "HFs: fields validated:\n";

   for my $field ($self->sorted_fields) {
      $field->dump_validated if $field->can('dump_validated');

      my $message = $field->has_errors
         ? join ' | ', $field->all_errors : 'validated';

      warn "HFs: ", $field->name, ": ${message}\n";
   }

   return;
}

sub field {
   my ($self, $name, $fatal, $f) = @_;

   # If this is a full_name for a compound field walk through the fields to get
   # to it
   return unless defined $name;

   return $self->index->{ $name }
       if $self->form && $self == $self->form && exists $self->index->{ $name };

   if ($name =~ m{ \. }mx) {
      my @names = split m{ \. }mx, $name;

      $f ||= $self->form || $self;

      for my $fname (@names) { $f = $f->field( $fname ) or return }

      return $f;
   }
   else { # Not a compound name
      for my $field ($self->all_fields) {
         return $field if $field->name eq $name;
      }
   }

   throw 'Field [_1] not found in [_2]', [ $name, $self ] if $fatal;

   return;
}

sub field_index {
   my ($self, $name) = @_;

   my $index = 0;

   for my $field ($self->all_fields) {
      return $index if $field->name eq $name;
      $index++;
   }

   return;
}

sub fields_fif {
   my ($self, $result, $prefix) = @_;

   $result //= $self->result;

   return unless $result;

   $prefix //= NUL;
   $prefix   = $self->name . DOT
      if $self->isa( 'HTML::Forms' ) && $self->html_prefix;

   my %params;

   for my $fld_result ($result->results) {
      my $field = $fld_result->field_def;

      next if $field->is_inactive || $field->password;

      my $fif = $fld_result->fif;

      next if !defined( $fif ) || (is_arrayref $fif && !scalar @{ $fif });

      if ($fld_result->has_results) {
         my $next_params = $fld_result->fields_fif(
            $prefix . $field->name . DOT
         ) or next;

         %params = (%params, %{ $next_params });
      }
      else { $params{ $prefix . $field->name } = $fif }
   }

   return %params ? \%params : undef;
}

sub fields_set_value {
   my $self = shift;
   my %value_hash;

   for my $field ($self->all_fields) {
      next if $field->is_inactive || !$field->has_result;

      $value_hash{ $field->accessor } = $field->value
         if $field->has_value && !$field->noupdate;
   }

   return $self->_set_value( \%value_hash );
}

sub new_field_with_traits {
   my ($self, $class, $field_attr) = @_;

   my $traits = delete $field_attr->{traits} || [];

   $class = Moo::Role->create_class_with_roles( $class, @{ $traits } )
      if scalar @{ $traits };

   return $class->new( %{ $field_attr } );
}

sub propagate_error {
   my ($self, $result) = @_;
   # References to fields with errors are propagated up the tree.
   # All fields with errors should end up being in the form's
   # error_results. Once.
   my ($found) = grep { $_ == $result } $self->result->all_error_results;

   unless ($found) {
      $self->result->add_error_result( $result );
      $self->parent->propagate_error( $result )
         if $self->can('parent') && $self->parent;
   }

   return;
}

sub sorted_fields {
   my $self = shift;

   my @fields = sort { $a->order <=> $b->order }
                grep { $_->is_active } $self->all_fields;

   return wantarray ? @fields : \@fields;
}

sub subfield {
   my ($self, $name) = @_;

   return $self->field( $name, undef, $self );
}

# Private methods
sub _array_fields {
   my ($self, $fields) = @_;

   $fields = clone( $fields );

   my @new_fields;

   while (@{ $fields }) {
      my $name = shift @{ $fields };
      my $attr = shift @{ $fields };

      $attr = { type => $attr } unless is_hashref $attr;

      push @new_fields, { name => $name, %{ $attr } };
   }

   return \@new_fields;
}

sub _build_meta_field_list {
   my $self       = shift;
   my $field_list = [];

   if (my $meta = get_meta($self)) {
      if ($meta->has_field_list) {
         for my $fld_def (@{ $meta->field_list }) {
            push @{ $field_list }, $fld_def;
         }
      }
   }

   push @{ $field_list }, @{ $self->_array_fields( $self->field_list ) }
      if $self->can( 'field_list' );

   return scalar @{ $field_list } ? $field_list : undef;
}

sub _by_flag_updates {
   my ($self, $field_attr, $class, $field_updates, $all_updates) = @_;

   my $by_flag = $field_updates->{by_flag};

   if (exists $by_flag->{contains} && $field_attr->{is_contains}) {
      $all_updates = merge(
         $field_updates->{by_flag}->{contains}, $all_updates
      );
   }
   elsif (exists $by_flag->{repeatable}
          && get_meta($class)->find_attribute_by_name( 'is_repeatable' )) {
      $all_updates = merge(
         $field_updates->{by_flag}->{repeatable}, $all_updates
      );
   }
   elsif (exists $by_flag->{compound}
          && get_meta($class)->find_attribute_by_name( 'is_compound' )) {
      $all_updates = merge(
         $field_updates->{by_flag}->{compound}, $all_updates
      );
   }

   return $all_updates;
}

sub _fields_validate {
   my $self = shift;

   return unless $self->has_fields;

   my %value_hash;

   for my $field ($self->all_fields) {
      next if $field->is_inactive || $field->disabled || !$field->has_result;

      # Validate each field and "inflate" input -> value.
      $field->validate_field;    # this calls the field's 'validate' routine

      $value_hash{ $field->accessor } = $field->value
         if $field->has_value && !$field->noupdate;
   }

   return $self->_set_value( \%value_hash );
}

sub _find_field_class {
   my ($self, $type, $name) = @_;

   my $field_ns = $self->field_name_space;

   my @classes;

   push @classes, $type if $type =~ s{ \A \+ }{}mx;

   for my $ns (@{ $field_ns }, 'HTML::Forms::Field', 'HTML::FormsX::Field') {
      push @classes, "${ns}::${type}";
   }

   for my $class (@classes) {
      return $class if load_optional_class( $class );
   }

   throw 'Field [_1] has no field class [_2]', [ $name, $type ];
}

sub _find_parent {
   my ($self, $field_attr) = @_;

   my $parent;

   if ($field_attr->{name} =~ m{ \. }mx) {
      my @names       = split m{ \. }mx, $field_attr->{name};
      my $simple_name = pop @names;
      my $parent_name = join '.', @names;

      $parent = $self->field( $parent_name, undef, $self );

      if ($parent) {
         throw 'Field [_1] has a parent which is not a Compound Field',
            [ $field_attr->{name} ]
               unless $parent->isa( 'HTML::Forms::Field::Compound' );
         $field_attr->{name} = $simple_name;
      }
      else { throw 'Field [_1] has no parent', [ $field_attr->{name} ] }
   }
   elsif (my $parent_name = $field_attr->{field_group}) {
      $parent = $self->field( $parent_name, undef, $self );

      throw 'Field [_1] has a parent which is not a Group field',
         [ $field_attr->{name} ]
            unless $parent->isa( 'HTML::Forms::Field::Group' );
   }
   elsif (!($self->form && $self == $self->form)) { $parent = $self }

   my $full_name = $field_attr->{name};

   $full_name = join '.', $parent->full_name, $field_attr->{name} if $parent;

   $field_attr->{full_name} = $full_name;

   return $parent;
}

sub _has_field_list {
   my ($self, $field_list) = @_;

   $field_list //= $self->_field_list;

   if (is_hashref $field_list) {
      return $field_list if scalar keys %{ $field_list };
   }
   elsif (is_arrayref $field_list) {
      return $field_list if scalar @{ $field_list };
   }

   return;
}

sub _make_adhoc_field {
   my ($self, $class, $field_attr) = @_;

   # Remove and save form & parent, because if the form class has a 'clone'
   # method, Data::Clone::clone will clone the form
   my $parent = delete $field_attr->{parent};
   my $form   = delete $field_attr->{form};

   $field_attr = $self->_merge_updates( $field_attr, $class );
   $field_attr->{parent} = $parent;
   $field_attr->{form} = $form;

   my $field = $self->new_field_with_traits( $class, $field_attr );

   return $field;
}

sub _make_field {
   my ($self, $field_attr) = @_;

   my $name = $field_attr->{name};
   my $type = $field_attr->{type} //= 'Text';
   my $do_update = FALSE;

   if ($name =~ m{ \A \+ (.*) }mx ) {
      $field_attr->{name} = $name = $1;
      $do_update = TRUE;
   }

   my $class = $self->_find_field_class( $type, $name );
   my $parent = $self->_find_parent( $field_attr );

   $field_attr = $self->_merge_updates( $field_attr, $class ) unless $do_update;

   my $field = $self->_update_or_create(
      $parent, $field_attr, $class, $do_update
   );

   $self->form->add_to_index( $field->full_name => $field ) if $self->form;

   return;
}

sub _merge_updates {
   my ($self, $field_attr, $class) = @_;

   my $form = $self->form;

   # If there are field_traits at the form level, prepend them
   unshift @{ $field_attr->{traits} }, @{ $form->field_traits }
      if $form and $form->has_field_traits;

   # Use full_name for updates from form, name for updates from compound field
   my $full_name = delete $field_attr->{full_name} || $field_attr->{name};
   my $name = $field_attr->{name};
   my $single_updates = {}; # Updates that apply to a single field
   my $all_updates = {};    # Updates that apply to all fields
   my $field_updates;

   # Get updates from form update_subfields and widget_tags
   if ($form) {
      $field_updates = $form->update_subfields;

      if (keys %{ $field_updates }) {
         $all_updates = $field_updates->{all} // {};
         $single_updates = $field_updates->{ $full_name };

         if (exists $field_updates->{by_flag}) {
            $all_updates = $self->_by_flag_updates(
               $field_attr, $class, $field_updates, $all_updates
            );
         }

         if (exists $field_updates->{by_type}
             && exists $field_updates->{by_type}->{ $field_attr->{type} }) {
            $all_updates = merge(
               $field_updates->{by_type}->{ $field_attr->{type} }, $all_updates
            );
         }
      }

      # Merge widget tags into 'all' updates
      $form->has_widget_tags and $all_updates = merge( $all_updates, {
         tags => $self->form->widget_tags,
      } );
   }

   # Get updates from compound field update_subfields and widget_tags
   if ($self->has_flag( 'is_compound' )) {
      my $comp_field_updates = $self->update_subfields;
      my $comp_all_updates = {};
      my $comp_single_updates = {};

      # Compound 'all' updates
      if (keys %{ $comp_field_updates }) {
         $comp_all_updates = $comp_field_updates->{all} // {};
         # Don't use full_name. varies depending on parent field name
         $comp_single_updates = $comp_field_updates->{$name} // {};

         if (exists $field_updates->{by_flag}) {
            $comp_all_updates = $self->_by_flag_updates(
               $field_attr, $class, $comp_field_updates, $comp_all_updates
            );
         }

         if (exists $comp_field_updates->{by_type} &&
             exists $comp_field_updates->{by_type}->{ $field_attr->{type} }) {
            $comp_all_updates = merge(
               $comp_field_updates->{by_type}->{ $field_attr->{type} },
               $comp_all_updates
            );
         }
      }

      if ($self->has_widget_tags) {
         $comp_all_updates = merge( $comp_all_updates, {
            tags => $self->widget_tags,
         } );
      }

      # Merge form 'all' updates, compound field higher precedence
      $all_updates = merge( $comp_all_updates, $all_updates )
         if keys %{ $comp_all_updates };
      # Merge single field updates, compound field higher precedence
      $single_updates = merge( $comp_single_updates, $single_updates )
         if keys %{ $comp_single_updates };
   }

   # Attributes set on a specific field through update_subfields override
   # has_fields.  Attributes set by 'all' only happen if no field attributes
   $field_attr = merge( $field_attr, $all_updates ) if keys %{ $all_updates };
   $field_attr = merge( $single_updates, $field_attr )
      if keys %{ $single_updates };

   return $field_attr if $form && $form->no_widgets;

   # Get the widget and widget_wrapper from form
   my $meta = get_meta($class);

   throw 'Class [_1] has no "' . META . '" method. Did you forget to '
      .  'inherit from HTML::Forms::Field?', [ $class ]
      unless $meta;

   my $widget = $field_attr->{widget};

   unless ($widget) {
      my $attr = $meta->find_attribute_by_name( 'widget' );

      $widget = $attr->default if $attr;
   }

   my $widget_wrapper = $field_attr->{widget_wrapper};

   unless ($widget_wrapper) {
      my $attr = $meta->find_attribute_by_name( 'widget_wrapper' );

      $widget_wrapper = $attr->default if $attr;

      $widget_wrapper ||= $form->widget_wrapper if $form;
      $field_attr->{widget_wrapper} = $widget_wrapper ||= 'Simple';
   }

   # Add widget and wrapper roles to field traits
   if ($widget and $widget ne 'None') {
      my $widget_role = $self->get_widget_role( $widget, 'Field' );

      push @{ $field_attr->{traits} }, $widget_role if $widget_role;
   }

   if ($widget_wrapper) {
      my $wrapper_role = $self->get_widget_role( $widget_wrapper, 'Wrapper' );

      push @{ $field_attr->{traits} }, $wrapper_role if $wrapper_role;
   }

   return $field_attr;
}

sub _order_fields {
   my $self  = shift;
   my $order = 0;

   # There's a hole in this... if child fields are defined at a level above the
   # containing parent, then they won't exist when this routine is called and
   # won't be ordered.  This probably needs to be moved out of here into a
   # separate recursive step that's called after build_fields.
   # Get highest order number
   for my $field ($self->all_fields) {
      $order = $field->order if $field->order > $order;
   }

   $order++;

   # Number all unordered fields
   for my $field ($self->all_fields) {
      $field->order( $order ) unless $field->order;
      $order++;
   }
}

sub _process_field_array {
   my ($self, $fields) = @_;

   $fields = $self->clean_fields( $fields );

   my $num_fields   = scalar @{ $fields };
   my $num_dots     = 0;
   my $count_fields = 0;

   while ($count_fields < $num_fields) {
      for my $field (@{ $fields }) {
         my $count = ( $field->{name} =~ tr/\.// );

         next unless $count == $num_dots;

         $self->_make_field($field);
         $count_fields++;
      }

      $num_dots++;
   }

   return;
}

sub _process_field_list {
   my ($self, $flist) = @_;

   $self->_process_field_array( $self->_array_fields( $flist ) )
      if is_arrayref $flist;

   return;
}

# Update, replace, or create field.  Create makes the field object and passes
# in the properties as constructor args.  Update changed properties on a
# previously created object.  Replace overwrites a field with a different
# configuration.  (The update/replace business is much the same as you'd see
# with inheritance.)  This function populates/updates the base object's 'field'
# array.
sub _update_or_create {
   my ($self, $parent, $field_attr, $class, $do_update) = @_;

   $parent //= $self->form;
   $field_attr->{parent} = $parent;

   $field_attr->{form} = $self->form if $self->form;

   my $index = $parent->field_index( $field_attr->{name} );
   my $field;

   if (defined $index) {
      if ($do_update) { # This field started with '+'. Update.
         throw 'Field to update [_1] not found', [ $field_attr->{name} ]
            unless $field = $parent->field( $field_attr->{name} );

         for my $key (keys %{ $field_attr }) {
            next if $key eq 'name' || $key eq 'form' || $key eq 'parent' ||
               $key eq 'full_name' || $key eq 'type';

            $field->$key( $field_attr->{ $key } ) if $field->can( $key );
         }
      }
      else { # Replace existing field
         $field = $self->new_field_with_traits( $class, $field_attr );
         $parent->set_field_at( $index, $field );
      }
   }
   else { # New field
      $field = $self->new_field_with_traits( $class, $field_attr );
      $parent->add_field( $field );
   }

   $field->form->add_repeatable_field( $field )
      if $field->form && $field->has_flag( 'is_repeatable' );

   return $field;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Fields - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Fields;
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

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
