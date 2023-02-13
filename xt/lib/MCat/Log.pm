package MCat::Log;

use Moo;

sub error {
   my ($self, $message) = @_;

   warn "${message}\n";
}

sub info {
   my ($self, $message) = @_;

   warn "${message}\n";
}

use namespace::autoclean;

1;
