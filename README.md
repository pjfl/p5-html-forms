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

- Mutable booleans defaulting false.
    - did\_init\_obj - True when the result has been initialised
    - do\_form\_wrapper - If true wraps the form in a containing element
    - do\_label\_colon - If true a colon is appended to the label
    - do\_label\_colon\_right - If true place the label colon on the right
    - do\_label\_right - If true place the label on the right if the field
    - processed - True when the form has been processed
    - render\_js\_after - If true render the JS after the form
    - use\_init\_obj\_when\_no\_accessor\_in\_item - Self describing
    - verbose - When true emits diagnostics on stderr
- Immutable booleans defaulting false.
    - html\_prefix - If true the form name is prepended to field names
    - is\_html5 - If true apply HTML5 attributes to fields
    - message\_before\_start - If true display messages before the form start
    - no\_preload - If the true the result is not initialised on build
    - no\_widgets - If true widget roles are not applied to the form
    - quote\_bind\_value - If true quote the bind values in messages
- action

    URL for the action attribute on the form. A mutable string with no default

- active

    A mutable array reference of active field names

    Handles; `add_active`, `clear_active`, and `has_active` via the array trait

- context

    An optional mutable weak reference to the context object with clearer and
    predicate

- default\_locale

    If `context` is provided and has a `config` object use it's `locale`
    attribute, otherwise default to `en`. An immutable lazy string used as
    the default language in building the `locale_handle`

- defaults

    A mutable hash reference of default values keyed by field name. These are
    applied to the field when the form is setup overriding the default value in
    the field definition

    Handles; `clear_defaults` and `has_defaults` via the hash trait

- dependency

    A mutable array reference of array references. Each inner reference should
    contain two or more field names. If the first named field has a value then
    the subsequent fields are required

- enctype

    A mutable string without default. Sets the encoding type on the form element

- error\_message

    A mutable string without default with clearer and predicate. This string (if
    set) is rendered either before or near the start of the form if the form result
    `has_errors` or `has_form_errors`

- field\_traits

    A lazy immutable array reference with an empty default. This list of
    `HTML::Forms::Widget::Field::Trait` roles are applied to all fields on the
    form

    Handles; `add_field_trait` and `has_field_traits` via the array trait

- for\_js

    A mutable hash reference with an empty default. Provides support for the
    `Repeatable` field type. Keyed by the repeatable field name contains a
    data structure used by the JS event handlers to add/remove repeatable fields
    to/from the form. Populated automatically by the `Repeatable` field type

    Handles; `clear_for_js`, `has_for_js`, and `set_for_js` via the hash trait

- form\_element\_attr
- form\_element\_class
- form\_wrapper\_attr
- form\_wrapper\_class
- form\_tags
- http\_method

    An immutable string with a default of `post`. The method attribute on the
    form element

- inactive
- index
- info\_message
- init\_object
- language\_handle
- language\_handle\_class
- locales
- messages
- name

    A mutable string with a random default. The name of the form element

- no\_update

    A mutable bool without default and with a clearer. If set to true the call
    in `process` to update the model will be skipped

- params

    A mutable hash reference with an empty default. Should be set to the keys
    and values of the form when it is posted back. Parameters are munged by the
    trigger. See [HTML::Forms::Params](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AParams)

    Handles; `clear_params`, `get_param`, `has_params`, and `set_param` via
    the hash trait

- params\_args

    An immutable array reference with an empty default. Arguments passed to the
    [HTML::Forms::Params](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AParams) constructor

- posted

    A mutable boolean without default with clearer and predicate. Should be set to
    true if the form was posted

- result
- style
- success\_message
- title
- update\_field\_list
- use\_defaults\_over\_obj
- use\_field\_for\_input\_without\_param
- use\_init\_obj\_over\_item
- widget\_form
- widget\_name\_space
- widget\_wrapper

# Subroutines/Methods

Defines the following methods;

- BUILDARGS

    Additionally allows for construction from either an `item` object instance or
    an `item_id`

- BUILD

    Applies widget roles, builds the fields, sets the active field list, and
    initialises the result object. Will also dump the field definitions if
    `verbose` is true

    The methods `before_build`, and `after_build` are called either side of
    the above and are dummy methods in this class. Made for overriding in a
    form role

- add\_form\_element\_class( @args )
- add\_form\_error( @message )

    Pushes the supplied message (after localising) onto form errors. Uses the
    `form is invalid` message if one is not supplied

- add\_form\_wrapper\_class( @args )
- after\_build

    Dummy method called by `BUILD`

- after\_update\_model
- attributes

    A proxy for `form_element_attributes`

- before\_build

    Dummy method called at the start of the `BUILD` method

- build\_active

    Called at build time it clears the inactive status of any `active` fields and
    sets the inactive status on any `inactive` fields

- build\_errors
- build\_language\_handle

    Constructor for the `language_handle` attribute. Will use `locales` if
    available otherwise uses the environment variable `LANGUAGE_HANDLE`.
    Always appends `default_locale` to the returned list

- build\_result
- clear

    Calls all the clearers defined on the form object. Sets `processed` and
    `did_init_obj` to false

- fif( @args )
- form
- form\_element\_attributes

    Returns a hash reference of keys and values which are applied to the form
    element

    Also calls `html_attributes` with a 'type' of 'form\_element' returning it's
    return hash reference if set. Allows for an overridden `html_attributes`
    to "fix things up" if required

- form\_wrapper\_attributes
- full\_accessor

    Dummy method returns the null string

- full\_name

    Dummy method returns the null string

- get\_default\_value

    Dummy method returns nothing

- get\_tag( $name )
- has\_flag( $flag\_name )
- html\_attributes( $object, $type, $attrs, $result )

    Dummy method that returns the supplied `attrs`. Called by
    `form_element_attributes`. The `type` argument is one of; 'element',
    'element\_wrapper', 'form\_element', 'form\_wrapper', 'label', or 'wrapper'.

    Applied roles can modify this method to alter the attributes of the
    above list of form elements

- init\_value( $field, $value )

    Sets both the initial and current field values to the one supplied

- localise( @message )

    Calls `maketext` on the `language_handle` to localise the supplied message.
    If localisation fails will substitute the placeholder variables and return
    that string

- new\_with\_traits( %args )

    Either a class or object method. Returns a new instance of this class with
    the list of supplied `traits` in the `args` hash applied. This rest of the
    `args` hash is supplied to the constructor of the new object

- process( @args )
- set\_active
- setup\_form( @args )
- update\_field( $field\_name, $updates )
- update\_fields
- validate
- validate\_form
- values

# Diagnostics

Set `verbose` to true to dump diagnostic information to stderr

# Dependencies

- [Data::Clone](https://metacpan.org/pod/Data%3A%3AClone)
- [Moo](https://metacpan.org/pod/Moo)
- [Unexpected](https://metacpan.org/pod/Unexpected)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Forms.
Patches are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

Gerda Shank <gshank@cpan.org> - Author of [HTML::FormHandler](https://metacpan.org/pod/HTML%3A%3AFormHandler) of
which this is a [Moo](https://metacpan.org/pod/Moo) based copy

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
