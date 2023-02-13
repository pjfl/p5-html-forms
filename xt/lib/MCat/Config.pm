package MCat::Config;

use File::DataClass::IO    qw( io );
use HTML::Forms::Constants qw( SECRET TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Object PositiveInt Str );
use Moo;

has 'appclass' => is => 'ro', isa => Str, default => 'MCat';

has 'basedir' => is => 'ro', isa => Str, default => 'xt';

has 'connect_info' => is => 'lazy', isa => ArrayRef, builder => sub {
   my $self = shift;

   return [$self->dsn, $self->db_username, $self->db_password];
};

has 'db_password' => is => 'ro', isa => Str, default => 'shit';

has 'db_username' => is => 'ro', isa => Str, default => 'mcat';

has 'default_route' => is => 'ro', isa => Str, default => '/mcat/artist';

has 'default_view' => is => 'ro', isa => Str, default => 'html';

has 'deflate_types' =>
   is      => 'ro',
   isa     => ArrayRef[Str],
   builder => sub {
      [ qw( text/css text/html text/javascript application/javascript ) ]
   };

has 'dsn' => is => 'ro', isa => Str, default => 'dbi:Pg:dbname=mcat';

has 'encoding' => is => 'ro', isa => Str, default => 'utf-8';

has 'layout' => is => 'ro', isa => Str, default => 'not_found';

has 'mount_point' => is => 'ro', isa => Str, default => '/mcat';

has 'name' => is => 'ro', isa => Str, required => TRUE;

has 'prefix' => is => 'ro', isa => Str, default => 'mcat';

has 'request_roles'   => is => 'ro',   isa => ArrayRef[Str],
   builder => sub { [ 'L10N', 'Session', 'JSON', 'Cookie' ] };

has 'root' => is => 'lazy', isa => Object,
   default => sub { io[shift->basedir, 'var/root'] };

has 'secret' => is => 'ro', isa => Str, default => SECRET;

has 'session_attr' => is => 'lazy', isa => HashRef[ArrayRef], builder => sub {
   return {
      id => [ PositiveInt, 0 ],
   };
};

has 'skin' => is => 'ro', isa => Str, default => 'classic';

has 'static' =>
   is      => 'ro',
   isa     => Str,
   default => 'css | favicon.ico | fonts | img | js | less';

has 'tempdir' => is => 'lazy', isa => Object,
   default => sub { io[shift->basedir, 'var/tmp'] };

use namespace::autoclean;

1;
