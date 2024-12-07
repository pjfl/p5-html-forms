use strict;
use warnings;

use Module::Build 0.4004;

my $perl_ver = 5.010001;
my $name     = 'HTML-Forms'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'requires' => {
    'Class::Load' => '0.25',
    'Crypt::CBC' => '3.04',
    'Data::Clone' => '0.006',
    'DateTime' => '1.65',
    'DateTime::Format::Strptime' => '1.79',
    'DateTime::TimeZone' => '2.57',
    'Digest::SHA1' => '2.13',
    'Email::Valid' => '1.203',
    'File::ShareDir' => '1.118',
    'HTML::Parser' => '3.76',
    'HTML::Tiny' => '1.08',
    'HTTP::Message' => '6.44',
    'JSON::MaybeXS' => '1.004004',
    'Moo' => '2.005005',
    'MooX::HandlesVia' => '0.001009',
    'Path::Tiny' => '0.122',
    'Ref::Util' => '0.204',
    'Sub::Exporter' => '0.987',
    'Sub::HandlesVia' => '0.046',
    'Sub::Install' => '0.929',
    'Sub::Name' => '0.27',
    'Template' => '3.102',
    'Try::Tiny' => '0.31',
    'Type::Tiny' => '2.002001',
    'Unexpected' => 'v1.0.5',
    'namespace::autoclean' => '0.29',
    'perl' => '5.010001',
    'strictures' => '2.000006'
  },
  'test_requires' => {
    'File::Spec' => '0',
    'Module::Build' => '0.4004',
    'Module::Metadata' => '0',
    'Sys::Hostname' => '0',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
};
my $testing  = sub { $ENV{AUTOMATED_TESTING}
                  || $ENV{PERL_CPAN_REPORTER_CONFIG}
                  || $ENV{PERL5_CPANPLUS_IS_VERSION} };
my $whimper  = sub { print {*STDOUT} $_[ 0 ]."\n"; exit 0 };
my $stop     = sub {
   $testing->() or $whimper->( $_[ 0 ] );
   $prereqs->{build_requires} = { %{ $prereqs->{configure_requires} } };
   $prereqs->{test_requires } = { %{ $prereqs->{configure_requires} } };
   $prereqs->{test_requires }->{ 'Test::Requires' } = 0.06;
   delete $prereqs->{requires};
};

# Not interested in reports below min perl ver
$] < $perl_ver and $stop->( "Minimum required Perl version is ${perl_ver}" );

Module::Build->subclass( code => do { local $/; <DATA> } )->new(
   'module_name' => $name,
   'notes'       => { min_perl_version => $perl_ver, testing => $testing->() },
   %{ $prereqs },

)->create_build_script;

exit 0;

__DATA__

sub _added_to_INC { # CVE-2016-1238
  my $self = shift; my %seen;

  for ($self->_default_INC) { $seen{ $_ }++ }

  return grep { not $seen{ $_ }++ } $self->base_dir, @INC;
}
