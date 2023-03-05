package MCat::Table::Artist;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Active';
with    'HTML::StateTable::Role::Downloadable';
with    'HTML::StateTable::Role::Filterable';
with    'HTML::StateTable::Role::CheckAll';
with    'HTML::StateTable::Role::Form';
with    'HTML::StateTable::Role::HighlightRow';

has '+active_control_location' => default => 'TopRight';

# TODO: Implement the selection attribute to form buttons
has '+form_buttons' => default => sub {
   return [
      { action    => 'artist/remove',
        class     => 'remove-item',
        selection => TRUE,
        value     => 'Remove Artists' },
   ];
};

set_table_name 'artist';

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   options     => { checkall => TRUE },
   value       => 'artistid';

has_column 'artistid' =>
   cell_traits => ['Numeric'],
   label       => 'ID',
   width       => '40px';

has_column 'name' =>
   filterable => TRUE,
   label => 'Artist Name',
   link  => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('artist/view', [$self->result->id]);
   },
   searchable => TRUE,
   sortable => TRUE,
   title => 'Sort by artist';

sub highlight_row {
   my ($self, $row) = @_;

   return $row->result->name eq 'Ozzy' ? TRUE : FALSE;
}

use namespace::autoclean -except => TABLE_META;

1;
