use utf8;
package MCat::Schema::Result::Artist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MCat::Schema::Result::Artist

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<artist>

=cut

__PACKAGE__->table("artist");

=head1 ACCESSORS

=head2 artistid

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "artistid",
  { data_type => "integer", is_nullable => 0, is_auto_increment => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</artistid>

=back

=cut

__PACKAGE__->set_primary_key("artistid");

=head1 UNIQUE CONSTRAINTS

=head2 C<artist_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("artist_name", ["name"]);

=head1 RELATIONS

=head2 cds

Type: has_many

Related object: L<MCat::Schema::Result::Cd>

=cut

__PACKAGE__->has_many(
  "cds",
  "MCat::Schema::Result::Cd",
  { "foreign.artistid" => "self.artistid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-02-11 04:03:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I6gkd54UI2eUTbY7aGxQFA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
