package MCat::Table::Artist;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'artist';

has_column 'id';

has_column 'name' =>
   label => 'Artist Name',
   link  => sub {
      my $self    = shift;
      my $request = $self->table->context->request;

      return  $request->uri_for('artist/*', [$self->result->id]);
   };

use namespace::autoclean -except => TABLE_META;

1;
