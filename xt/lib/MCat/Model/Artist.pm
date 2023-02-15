package MCat::Model::Artist;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Util      qw( redirect );
use Unexpected::Functions  qw( exception UnknownArtist Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'artist';

sub create {
   my ($self, $context) = @_;

   my $options = { context => $context, item_class => 'Artist' };
   my $form    = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $artistid    = $form->item->id;
      my $view_artist = $context->request->uri_for('artist/*', [$artistid]);

      return redirect $view_artist, ['Artist [_1] created', $form->item->name];
   }

   return { form => $form };
}

sub delete {
   my ($self, $context, $artistid) = @_;

   my $stash = $self->is_token_bad($context);

   return $stash if $stash;
   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $artist = $context->model('Artist')->find($artistid);

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   my $name = $artist->name;

   $artist->delete;

   my $list_artists = $context->request->uri_for('artist');

   return redirect $list_artists, ['Artist [_1] deleted', $name];
}

sub edit {
   my ($self, $context, $artistid) = @_;

   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $artist = $context->model('Artist')->find($artistid);

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   my $options = { context => $context, item => $artist };
   my $form    = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $view_artist = $context->request->uri_for('artist/*', [$artistid]);

      return redirect $view_artist, ['Artist [_1] updated', $form->item->name];
   }

   return { form => $form };
}

sub list {
   my ($self, $context) = @_;

   my $options = { context => $context, resultset => $context->model('Artist')};

   return { table => $self->table->new_with_context('Artist', $options) };
}

sub view {
   my ($self, $context, $artistid) = @_;

   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $artist = $context->model('Artist')->find($artistid);

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   my $cd_rs   = $context->model('Cd')->search({ artistid => $artistid });
   my $options = { context => $context, resultset => $cd_rs };

   return {
      artist => $artist,
      table  => $self->table->new_with_context('Cd', $options)
   };
}

use namespace::autoclean;

1;
