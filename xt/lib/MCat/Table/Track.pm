package MCat::Table::Track;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'track';

has_column 'trackid' => label => 'ID';

has_column 'cdid' => label => 'CD ID';

has_column 'title';

use namespace::autoclean -except => TABLE_META;

1;
