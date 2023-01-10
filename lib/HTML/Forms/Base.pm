package HTML::Forms::Base;

use namespace::autoclean;

use HTML::Forms::Constants qw( FALSE );
use Moo;

with 'HTML::Forms::Widget::Form::Simple';

sub has_render_list {
   return FALSE;
}

sub build_render_list {
   return [];
}

1;

__END__

