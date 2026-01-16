package HTML::Forms::Field::Select;

use HTML::Forms::Constants qw( DOT FALSE META NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool CodeRef HFsSelectOptions
                               Int Num Str Undef );
use HTML::Entities         qw( encode_entities );
use HTML::Forms::Util      qw( convert_full_name get_meta );
use Ref::Util              qw( is_arrayref is_hashref );
use Scalar::Util           qw( weaken );
use Moo;
use HTML::Forms::Moo;
use Sub::HandlesVia;

extends 'HTML::Forms::Field';

our $class_messages = {
   'select_invalid_value' => '[_1] is not a valid value',
   'select_not_multiple'  => 'This field does not take multiple values',
};

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Select - Select from options

=head1 Synopsis

   use Moo;
   use HTML::Forms::Moo;

   extends 'HTML::Forms';

   has_field 'field_name' => type => 'Select';

=head1 Description

Select from options

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item auto_widget_size

=cut

has 'auto_widget_size' => is => 'ro', isa => Int, default => 0;

=item do_not_reload

=cut

has 'do_not_reload' => is => 'ro', isa => Bool, default => FALSE;

=item empty_select

=cut

has 'empty_select' => is => 'rw', isa => Str;

=item has_many

=cut

has 'has_many' => is => 'rw', isa => Str;

=item label_column

Used by L<HTML::Forms::Model::DBIC>. TODO: This shouldn't be here

=cut

has 'label_column' => is => 'ro', isa => Str, default => 'name';

=item multiple

=cut

has 'multiple' => is => 'rw', isa => Bool, default => FALSE;

=item no_option_validation

=cut

has 'no_option_validation' => is => 'rw', isa => Bool, default => FALSE;

=item options

=cut

has 'options'   =>
    is          => 'rw',
    isa         => HFsSelectOptions,
    builder     => 'build_options',
    coerce      => TRUE,
    handles_via => 'Array',
    handles     => {
        all_options   => 'elements',
        clear_options => 'clear',
        has_options   => 'count',
        num_options   => 'count',
        reset_options => 'clear',
    },
    lazy        => TRUE;

=item options_from

=cut

has 'options_from' => is => 'rw', isa => Str, default => 'none';

=item options_index

=cut

has 'options_index' =>
   is          => 'rw',
   isa         => Num,
   default     => 0,
   handles_via => 'Counter',
   handles     => {
      inc_options_index   => 'inc',
      dec_options_index   => 'dec',
      reset_options_index => 'reset'
   };

=item options_method

=item has_options_method

Predicate

=cut

has 'options_method' =>
   is          => 'ro',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { get_options => 'execute' },
   predicate   => 'has_options_method',
   writer      => '_set_options_method';

=item set_options

=cut

has 'set_options' => is => 'ro', isa => Str;

=item size

=cut

has 'size' => is => 'rw', isa => Int|Undef;

=item sort_column

=cut

has 'sort_column' => is => 'ro', isa => ArrayRef[Str]|Str;

=item sort_options_method

=item has_sort_options_method

Predicate

=cut

has 'sort_options_method' =>
   is          => 'rw',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { sort_options => 'execute' },
   predicate   => 'has_sort_options_method';

=item value_when_empty

=cut

has 'value_when_empty' => is => 'lazy', builder => 'build_value_when_empty';

=item deflate_method

=item has_deflate_method

Predicate

=cut

has '+deflate_method' => default => sub { _build_deflate_method( shift ) };

=item input_without_param

=item has_input_without_param

Predicate

=cut

has '+input_without_param' =>
   builder => 'build_input_without_param',
   lazy    => TRUE;

=item widget

=cut

has '+widget' => default => 'Select';

=item wrapper_class

=cut

has '+wrapper_class' => default => 'input-select';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

=cut

sub BUILD {
   my $self = shift;

   $self->select_widget;
   $self->build_options_method;

   if ($self->options && $self->has_options) {
      $self->options_from('build');
      $self->default_from_options($self->options);
   }

   $self->input_without_param;

   if ($self->multiple) {
      $self->add_label_class('select-multiple');
      $self->add_element_class('select-multiple');
   }

   return;
}

=item clear_data

=cut

after 'clear_data' => sub { shift->reset_options_index };

=item value

=cut

before 'value' => sub {
   my $self = shift;

   return unless $self->has_result && $self->result;

   my $value = $self->result->value;

   if ($self->multiple) {
      if (!defined $value || $value eq NUL
          || (is_arrayref $value && scalar @{$value} == 0)) {
         $self->_set_value( $self->value_when_empty );
      }
      elsif ($self->has_many && scalar @{$value} && !is_hashref $value->[0]) {
         my @new_values;

         for my $has_many (@{$value}) {
            push @new_values, { $self->has_many => $has_many };
         }

         $self->_set_value(\@new_values);
      }
   }

   return;
};

=item build_input_without_param

=cut

sub build_input_without_param {
   my $self = shift;

   if ($self->multiple) {
      $self->not_nullable(TRUE);
      return [];
   }

   return NUL;
}

=item build_options

Return an empty array reference

=cut

sub build_options { [] }

=item build_options_method

=cut

sub build_options_method {
   my $self        = shift;
   my $form        = $self->form; weaken $form;
   my $set_options = $self->set_options;

   $set_options ||= 'options_' . convert_full_name($self->full_name);

   if ($form && $form->can($set_options)) {
      if (get_meta($self)->has_attribute($set_options)) {
         $self->_set_options_method(sub { $form->$set_options });
      }
      else {
         $self->_set_options_method(sub { $form->$set_options($self) });
      }
   }

   return;
}

=item build_value_when_empty

=cut

sub build_value_when_empty {
   my $self = shift;

   return $self->multiple ? [] : undef;
}

=item default_from_options

=cut

sub default_from_options {
   my ($self, $options) = @_;

   my @defaults = map { $_->{value} } grep { $_->{checked} || $_->{selected} }
                     @{$options};

   if (scalar @defaults) {
      if ($self->multiple) { $self->default(\@defaults) }
      else { $self->default($defaults[0]) }
   }

   return;
}

=item get_class_messages

=cut

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages } };
}

=item html_element

=cut

sub html_element {
   return 'select';
}

=item next_option_id

=cut

sub next_option_id {
   my $self = shift;
   my $id   = $self->id . DOT . $self->options_index;

   $self->inc_options_index;
   return $id;
}

=item select_widget

If this is a C<Select> widget, C<auto_widget_size> is non zero, and there are
fewer options than the C<auto_widget_size>, change the widget to
C<CheckboxGroup> if C<multiple> is true, change the widget to C<RadioGroup>
otherwise. This is called at object construction time

=cut

sub select_widget {
    my $self = shift;
    my $size = $self->auto_widget_size;

    return unless $self->widget eq 'Select' && $size;
    return if scalar @{$self->options || []} > $size;

    $self->hide_info(TRUE);

    if ($self->multiple) {
       $self->widget('CheckboxGroup');
       $self->html5_type_attr('checkbox');
       $self->type_attr('checkbox');
    }
    else {
       $self->widget('RadioGroup');
       $self->html5_type_attr('radio');
       $self->type_attr('radio');
    }

    return;
}

# Private methods
sub _build_deflate_method {
   my $self = shift;

   return sub {
      my ($self, $value) = @_;

      return $value unless $self->has_many && $self->multiple;

      return $value unless is_arrayref $value
         && scalar @{$value} && is_hashref $value->[0];

      return [ map { $_->{$self->has_many} } @{$value} ];
   };
}

sub _inner_validate_field {
   my $self  = shift;
   my $value = $self->value;

   return unless defined $value;

   if (is_arrayref $value && !$self->multiple) {
      $self->add_error($self->get_message('select_not_multiple'));
      return;
   }
   elsif (!is_arrayref $value && $self->multiple) {
      $value = [$value];
      $self->_set_value($value);
   }

   return if $self->no_option_validation;

   my %options;

   for my $opt (@{ $self->options }) {
      if (exists $opt->{group}) {
         for my $opt_group (@{ $opt->{options} }) {
            $options{ $opt_group->{value} } = TRUE;
         }
      }
      else { $options{ $opt->{value} } = TRUE }
   }

   if ($self->has_many) {
      $value = [ map { $_->{ $self->has_many } } @{ $value } ];
   }

   for my $value (is_arrayref $value ? @{ $value } : ($value)) {
      unless ($options{$value}) {
         $self->add_error(
            $self->get_message('select_invalid_value'), encode_entities($value)
         );
         return;
      }
   }

   return TRUE;
}

sub _load_options {
   my $self = shift;

   return if $self->options_from eq 'build' ||
      ($self->has_options && $self->do_not_reload);

   my @options;

   if ($self->has_options_method) {
      @options = $self->get_options;
      $self->options_from('method');
   }
   elsif ($self->form) {
      my $full_accessor;

      $full_accessor = $self->parent->full_accessor if $self->parent;
      @options = $self->form->lookup_options($self, $full_accessor);
      $self->options_from('model') if scalar @options;
   }

   return unless @options;

   my $opts = is_arrayref $options[0] ? $options[0] : \@options;

   $self->default_from_options($opts) if is_hashref $opts->[0];

   if ($opts = $self->options($opts)) {
      $opts = $self->sort_options($opts) if $self->has_sort_options_method;
      $self->options($opts);
   }

   return;
}

sub _result_from_fields {
   my ($self, $result) = @_;

   $result = $self->next::method($result);
   $self->_load_options;
   $result->_set_value($self->default)
      if defined $self->default && !$result->has_value;

   return $result;
}

sub _result_from_input {
   my ($self, $result, $input, $exists) = @_;

   $input = is_arrayref $input ? $input : [$input] if $self->multiple;
   $result = $self->next::method($result, $input, $exists);
   $self->_load_options;
   $result->_set_value($self->default)
      if defined $self->default && !$result->has_value;

   return $result;
}

sub _result_from_object {
   my ($self, $result, $item) = @_;

   $result = $self->next::method($result, $item);
   $self->_load_options;
   $result->_set_value($self->default)
      if defined $self->default && !$result->has_value;

   return $result;
}

use namespace::autoclean -except => META;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Field>

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
