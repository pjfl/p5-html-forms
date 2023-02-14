package MCat::Model::Artist;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Util      qw( redirect );
use Unexpected::Functions  qw( exception UnknownArtist );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'artist';

sub create {
   my ($self, $context) = @_;

   my $request = $context->request;
   my $options = { context => $context, item_class => 'Artist' };
   my $form    = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $uri  = $request->uri_for('artist/*', [$form->item->id]);
      my $name = $form->item->name;

      return redirect $uri, ['Artist [_1] created', $name];
   }

   return { form => $form, list_uri => $request->uri_for('artist') };
}

sub delete {
   my ($self, $context) = @_;

   my $request = $context->request;
   my $id      = $request->args->[0];
   my $artist  = $context->model('Artist')->find($id);

   unless ($artist) {
      my $exception = exception UnknownArtist, [$id];

      return $self->exception_handler($request, $exception);
   }

   my $name = $artist->name;

   $artist->delete;

   return redirect $request->uri_for('artist'), ['Artist [_1] deleted', $name];
}

sub edit {
   my ($self, $context) = @_;

   my $request  = $context->request;
   my $id       = $request->args->[0];
   my $rs       = $context->model('Artist');
   my $options  = { context => $context, item => $rs->find($id) };
   my $form     = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $view_uri = $request->uri_for('artist/*', [$id]);
      my $name     = $form->item->name;

      return redirect $view_uri, ['Artist [_1] updated', $name];
   }

   return { form => $form, list_uri => $request->uri_for('artist') };
}

sub list {
   my ($self, $context) = @_;

   my $options = { context => $context, resultset => $context->model('Artist')};

   return {
      create_uri => $context->request->uri_for('artist/create'),
      table      => $self->table->new_with_context('Artist', $options),
   };
}

sub view {
   my ($self, $context) = @_;

   my $request = $context->request;
   my $id      = $request->args->[0];

   return {
      artist     => $context->model('Artist')->find($id),
      delete_uri => $request->uri_for('artist/*/delete', [$id]),
      edit_uri   => $request->uri_for('artist/*/edit',   [$id]),
      list_uri   => $request->uri_for('artist'),
   };
}

use namespace::autoclean;

1;
