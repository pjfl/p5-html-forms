# Name

HTML::Forms - Generates markup for and processes input from HTML forms

# Synopsis

    {
       package HTML::Forms::Renderer;

       use Moo::Role;

       with 'HTML::Forms::Render::WithTT';

       sub _build_tt_include_path { [ 'share/templates' ] }
    }

    my $form = HTML::Forms->new_with_traits(
       name => 'test_tt', traits => [ 'HTML::Forms::Renderer' ],
    );

    $form->render;

# Description

# Configuration and Environment

Defines the following attributes;

- action

    URL for the action attribute on the form

# Subroutines/Methods

# Diagnostics

# Dependencies

- [Moo](https://metacpan.org/pod/Moo)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Forms.
Patches are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
