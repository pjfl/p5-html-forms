package MCat::Model::Cd;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Util      qw( redirect );
use Unexpected::Functions  qw( exception UnknownCd Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'cd';

sub create {
   my ($self, $context, $artistid) = @_;

   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $options = {
      artistid   => $artistid,
      context    => $context,
      item_class => 'Cd',
   };
   my $form = $self->form->new_with_context('Cd', $options);

   if ($form->process( posted => $context->posted )) {
      my $view_cd = $context->request->uri_for('cd/*', [$form->item->id]);

      return redirect $view_cd, ['CD [_1] created', $form->item->title];
   }

   return { form => $form };
}

sub delete {
   my ($self, $context, $cdid) = @_;

   my $stash = $self->is_token_bad($context);

   return $stash if $stash;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $title = $cd->title;

   $cd->delete;

   my $list_cds = $context->request->uri_for('cd');

   return redirect $list_cds, ['CD [_1] deleted', $title];
}

sub edit {
   my ($self, $context, $cdid) = @_;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $artistid = $cd->artistid->artistid;
   my $options  = { artistid => $artistid, context => $context, item => $cd };
   my $form     = $self->form->new_with_context('Cd', $options);

   if ($form->process( posted => $context->posted )) {
      my $view_cd = $context->request->uri_for('cd/*', [$cdid]);

      return redirect $view_cd, ['CD [_1] updated', $form->item->title];
   }

   return { form => $form };
}

sub list {
   my ($self, $context, $artistid) = @_;

   my $cd_rs = $context->model('Cd');

   $cd_rs = $cd_rs->search({ artistid => $artistid }) if $artistid;

   my $options = { context => $context, resultset => $cd_rs };

   return {
      artistid => $artistid,
      table    => $self->table->new_with_context('Cd', $options),
   };
}

sub view {
   my ($self, $context, $cdid) = @_;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $track_rs = $context->model('Track')->search({ cdid => $cdid });
   my $options  = { context => $context, resultset => $track_rs };

   return {
      cd    => $cd,
      table => $self->table->new_with_context('Track', $options)
   };
}

use namespace::autoclean;

1;
