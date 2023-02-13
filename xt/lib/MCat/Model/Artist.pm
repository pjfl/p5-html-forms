package MCat::Model::Artist;

use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'artist';

sub create {
   my ($self, $context) = @_;

   my $options = { context => $context, item_class => 'Artist' };
   my $form    = $self->form->new_with_context('Artist', $options);

   $form->process( posted => $context->posted );

   return { form => $form };
}

sub delete {
   my ($self, $context) = @_;

   my $id     = $context->request->uri_params->(0);
   my $rs     = $context->schema->resultset('Artist');
   my $artist = $rs->find($id);

   $artist->delete;

   return { redirect => 'artist/list' };
}

sub edit {
   my ($self, $context) = @_;

   my $id      = $context->request->uri_params->(0);
   my $rs      = $context->schema->resultset('Artist');
   my $artist  = $rs->find($id);
   my $options = { context => $context, item => $artist };
   my $form    = $self->form->new_with_context('Artist', $options);

   $form->process( posted => $context->posted );

   return { form => $form };
}

sub list {
   my ($self, $context) = @_;


   return {};
}

sub view {
   my ($self, $context) = @_;

   my $id = $context->request->uri_params->(0);
   my $rs = $context->schema->resultset('Artist');

   return { artist => $rs->find($id) };
}

use namespace::autoclean;

1;
