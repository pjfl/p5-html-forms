package MCat::Table::Cd;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'cd';

has_column 'cdid' => label => 'ID';

has_column 'title' =>
   link => sub {
      my $self    = shift;
      my $request = $self->table->context->request;

      return  $request->uri_for('cd/*', [$self->result->cdid]);
   };

has_column 'year';

use namespace::autoclean -except => TABLE_META;

1;
