package MCat::Table::Artist;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable'; # Buddhist table - One with everything
with    'HTML::StateTable::Role::Active';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::Downloadable';
with    'HTML::StateTable::Role::Filterable';
with    'HTML::StateTable::Role::CheckAll';
with    'HTML::StateTable::Role::Form';
with    'HTML::StateTable::Role::HighlightRow';
with    'HTML::StateTable::Role::ForceRowLimit';
with    'HTML::StateTable::Role::Tag';
with    'HTML::StateTable::Role::Reorderable';

has '+active_control_location' => default => 'TopRight';

has '+download_display' => default => FALSE;

has '+form_buttons' => default => sub {
   return [{
      action    => 'artist/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove Artist',
   }];
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
   label      => 'Artist Name',
   link       => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('artist/view', [$self->result->id]);
   },
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by artist';

has_column 'tags' =>
   append_to   => 'name',
   cell_traits => ['Tag'],
   search_type => 'tag',
   searchable  => TRUE,
   value       => 'tag_string.name';

sub highlight_row {
   my ($self, $row) = @_;

   return $row->result->name eq 'Police' ? TRUE : FALSE;
}

use namespace::autoclean -except => TABLE_META;

1;
