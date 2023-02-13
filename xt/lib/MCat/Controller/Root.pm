package MCat::Controller::Root;

use Web::Simple;

with 'Web::Components::Role';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request {
   return (
      'GET | POST + /artist/create + ?*' => sub {['artist/create', @_]},
      'GET | POST + /artist/*/edit + ?*' => sub {['artist/edit',   @_]},
      'POST + /artist/*/delete + ?*'     => sub {['artist/delete', @_]},
      'GET + /artist/* + ?*'             => sub {['artist/view',   @_]},
      'GET + /artist + ?*'               => sub {['artist/list',   @_]},

      'GET + /** + ?*' => sub {['page/not_found', @_]},
      'HEAD + ?*'      => sub {['artist/list', @_]},
      'GET + ?*'       => sub {['artist/list', @_]},
      'PUT + ?*'       => sub {['page/not_found', @_]},
      'POST + ?*'      => sub {['page/not_found', @_]},
      'DELETE + ?*'    => sub {['page/not_found', @_]},
   );
}

1;
