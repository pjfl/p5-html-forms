package HTML::Forms::Field::Select;

use HTML::Entities         qw( encode_entities );
use HTML::Forms::Constants qw( DOT FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Bool CodeRef HFsSelectOptions
                               Int Num Str Undef );
use HTML::Forms::Util      qw( convert_full_name get_meta );
use Ref::Util              qw( is_arrayref is_hashref );
use Scalar::Util           qw( weaken );
use Moo;
use HTML::Forms::Moo;
use Sub::HandlesVia;

extends 'HTML::Forms::Field';

has 'auto_widget_size' => is => 'ro', isa => Int, default => 0;

has 'do_not_reload' => is => 'ro', isa => Bool, default => FALSE;

has 'empty_select' => is => 'rw', isa => Str;

has 'has_many' => is => 'rw', isa => Str;

has 'multiple' => is => 'rw', isa => Bool, default => FALSE;

has 'no_option_validation' => is => 'rw', isa => Bool, default => FALSE;

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

has 'options_from' => is => 'rw', isa => Str, default => 'none';

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

has 'options_method' =>
   is          => 'ro',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { get_options => 'execute' },
   predicate   => 'has_options_method',
   writer      => '_set_options_method';

has 'set_options' => is => 'ro', isa => Str;

has 'size' => is => 'rw', isa => Int|Undef;

has 'sort_options_method' =>
   is          => 'rw',
   isa         => CodeRef,
   handles_via => 'Code',
   handles     => { sort_options => 'execute' },
   predicate   => 'has_sort_options_method';

has 'value_when_empty' => is => 'lazy', builder => 'build_value_when_empty';

has '+deflate_method' => default => sub { _build_deflate_method( shift ) };

has '+input_without_param' =>
   builder => 'build_input_without_param',
   lazy    => TRUE;

has '+widget' => default => 'Select';

has '+wrapper_class' => default => 'input-select';

our $class_messages = {
   'select_invalid_value' => '[_1] is not a valid value',
   'select_not_multiple'  => 'This field does not take multiple values',
};

after 'clear_data' => sub { shift->reset_options_index };

before 'value' => sub {
   my $self = shift;

   return unless $self->has_result;

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

sub build_input_without_param {
   my $self = shift;

   if ($self->multiple) {
      $self->not_nullable(TRUE);
      return [];
   }

   return NUL;
}

sub build_options { [] }

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

sub build_value_when_empty {
   my $self = shift;

   return $self->multiple ? [] : undef;
}

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

sub get_class_messages {
   my $self = shift;

   return { %{ $self->next::method }, %{ $class_messages } };
}

sub html_element {
   return 'select';
}

sub next_option_id {
   my $self = shift;
   my $id   = $self->id . DOT . $self->options_index;

   $self->inc_options_index;
   return $id;
}

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

sub _build_deflate_method {
   my $self = shift;

   return sub {
      my $value = shift;

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
      my $full_accessor = $self->parent->full_accessor if $self->parent;

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

=pod

=encoding utf-8

=head1 Name

HTML::Forms::Field::Select - One-line description of the modules purpose

=head1 Synopsis

   use HTML::Forms::Field::Select;
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
