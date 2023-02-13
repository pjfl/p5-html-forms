package MCat::Form::Artist;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Artist';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'You know what to do';

has_field 'artist_name' => label => 'Name', accessor => 'name';

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
