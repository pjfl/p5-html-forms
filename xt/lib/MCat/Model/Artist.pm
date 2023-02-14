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

   my $id     = $context->request->args->[0];
   my $rs     = $context->schema->resultset('Artist');
   my $artist = $rs->find($id);

   $artist->delete if $artist;

   return {
      redirect => { location => 'artist/list', message => 'Artist deleted' }
   };
}

sub edit {
   my ($self, $context) = @_;

   my $id      = $context->request->args->[0];
   my $rs      = $context->schema->resultset('Artist');
   my $options = { context => $context, item => $rs->find($id) };
   my $form    = $self->form->new_with_context('Artist', $options);

   $form->process( posted => $context->posted );

   return { form => $form };
}

sub list {
   my ($self, $context) = @_;

   my $options = { context => $context };
   my $table   = $self->table->new_with_context('Artist', $options);

   return { table => $table };
}

sub view {
   my ($self, $context) = @_;

   my $id = $context->request->args->[0];
   my $rs = $context->schema->resultset('Artist');

   return { artist => $rs->find($id) };
}

use namespace::autoclean;

1;
