package MCat::Table::Artist;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'artist';

has_column 'name';

use namespace::autoclean -except => TABLE_META;

1;
