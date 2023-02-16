use utf8;
package MCat::Schema::Result::Cd;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MCat::Schema::Result::Cd

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

=head1 TABLE: C<cd>

=cut

__PACKAGE__->table("cd");

=head1 ACCESSORS

=head2 cdid

  data_type: 'integer'
  is_nullable: 0

=head2 artistid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 year

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cdid",
  { data_type => "integer", is_nullable => 0, is_auto_increment => 1 },
  "artistid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "year",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cdid>

=back

=cut

__PACKAGE__->set_primary_key("cdid");

=head1 UNIQUE CONSTRAINTS

=head2 C<cd_title_artistid>

=over 4

=item * L</title>

=item * L</artistid>

=back

=cut

__PACKAGE__->add_unique_constraint("cd_title_artistid", ["title", "artistid"]);

=head1 RELATIONS

=head2 artistid

Type: belongs_to

Related object: L<MCat::Schema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "artist",
  "MCat::Schema::Result::Artist",
  { artistid => "artistid" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tracks

Type: has_many

Related object: L<MCat::Schema::Result::Track>

=cut

__PACKAGE__->has_many(
  "tracks",
  "MCat::Schema::Result::Track",
  { "foreign.cdid" => "self.cdid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-02-11 04:03:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UBoScONhHQPc0CiEx5bdeQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
