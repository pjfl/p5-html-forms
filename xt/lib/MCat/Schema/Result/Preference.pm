package MCat::Schema::Result::Preference;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );
use JSON::MaybeXS          qw( decode_json encode_json );

__PACKAGE__->table('preference');

__PACKAGE__->add_columns(
   id    => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE
   },
   name  => { data_type => 'text', is_nullable => FALSE },
   value => { data_type => 'text', is_nullable => TRUE },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('preference_name', ['name']);

__PACKAGE__->inflate_column('value', {
   deflate => sub { encode_json(shift) },
   inflate => sub { decode_json(shift) },
});

1;

