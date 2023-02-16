use utf8;
package MCat::Schema::Result::Track;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MCat::Schema::Result::Track

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

=head1 TABLE: C<track>

=cut

__PACKAGE__->table("track");

=head1 ACCESSORS

=head2 trackid

  data_type: 'integer'
  is_nullable: 0

=head2 cdid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "trackid",
  { data_type => "integer", is_nullable => 0, is_auto_increment => 1 },
  "cdid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</trackid>

=back

=cut

__PACKAGE__->set_primary_key("trackid");

=head1 UNIQUE CONSTRAINTS

=head2 C<track_title_cdid>

=over 4

=item * L</title>

=item * L</cdid>

=back

=cut

__PACKAGE__->add_unique_constraint("track_title_cdid", ["title", "cdid"]);

=head1 RELATIONS

=head2 cdid

Type: belongs_to

Related object: L<MCat::Schema::Result::Cd>

=cut

__PACKAGE__->belongs_to(
  "cd",
  "MCat::Schema::Result::Cd",
  { cdid => "cdid" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-02-11 04:03:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AlGdX7uqrGcTVLr3wh94Ow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
