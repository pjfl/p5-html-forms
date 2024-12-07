# Name

HTML::Forms - HTML forms using Moo

# Synopsis

    my $form = HTML::Forms->new_with_traits(
       name => 'test_tt', traits => [ 'HTML::Forms::Role::Defaults' ],
    );

    $form->render;

# Description

Generates markup for and processes input from HTML forms. This is a [Moo](https://metacpan.org/pod/Moo)
based copy of [HTML::FormHandler](https://metacpan.org/pod/HTML%3A%3AFormHandler)

## JavaScript

Files `wcom-*.js` are included in the `share/js` directory of the source
tree. These will be installed to the `File::ShareDir` distribution level
shared data files. Nothing further is done with these files. They should be
concatenated in sort order by filename and the result placed under the
webservers document root. Link to this from the web applications pages. Doing
this is outside the scope of this distribution

When content is loaded the JS method `WCom.Form.Renderer.scan(content)` must
be called to inflate the otherwise empty HTML `div` element if the front end
rendering class is being used. The function
`WCom.Util.Event.onReady(callback)` is available to install the scan when the
page loads

## Styling

A file `hforms-minimal.less` is included in the `share/less` directory
of the source tree.  This will be installed to [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir) distribution
level shared data files. Nothing further is done with this file. It would need
compiling using the Node.js LESS compiler to produce a CSS file which should be
placed under the web servers document root and then linked to in the header of
the web applications pages. This is outside the scope of this distribution

# Configuration and Environment

Defines the following attributes;

- Mutable booleans defaulting false
    - did\_init\_obj - True when the result has been initialised
    - do\_form\_wrapper - If true wraps the form in a containing element
    - do\_label\_colon - If true a colon is appended to the label
    - do\_label\_colon\_right - If true place the label colon on the right
    - do\_label\_right - If true place the label on the right if the field
    - processed - True when the form has been processed
    - render\_js\_after - If true render the JS after the form
    - use\_init\_obj\_when\_no\_accessor\_in\_item - Self describing
    - verbose - When true emits diagnostics on stderr
- Immutable booleans defaulting false
    - html\_prefix - If true the form name is prepended to field names
    - is\_html5 - If true apply HTML5 attributes to fields
    - messages\_before\_start - If true display messages before the form start
    - no\_preload - If the true the result is not initialised on build
    - no\_widgets - If true widget roles are not applied to the form
    - quote\_bind\_value - If true quote the bind values in messages
- action

    URL for the action attribute on the form. A mutable string with no default

- active

    A mutable array reference of active field names with an empty default

    Handles; `add_active`, `clear_active`, and `has_active` via the array trait

- context

    An optional mutable weak reference to the context object

- clear\_context

    Clearer

- has\_context

    Predicate

- default\_locale

    If `context` is provided and has a `config` object use it's `locale`
    attribute, otherwise default to `en`. An immutable lazy string used as
    the default language in building the `language_handle`

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

    A mutable string without default. This string (if set) is rendered either
    before or near the start of the form if the form result `has_errors` or
    `has_form_errors`

- clear\_error\_messsage

    Clearer

- has\_error\_message

    Predicate

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

    A mutable hash reference with an empty default. Attributes and values applied
    to the form element

    Handles; `delete_form_element_attr`, `exists_form_element_attr`,
    `get_form_element_attr`, `has_form_element_attr`, and
    `set_form_element_attr` via the hash trait

- form\_element\_class

    A mutable array reference of strings with an empty default. List of classes
    to apply to the form element

    Handles `has_form_element_class` via the array trait

- form\_wrapper\_attr

    A mutable hash reference with an empty default. Attributes and values applied
    to the form wrapper

    Handles; `delete_form_wrapper_attr`, `exists_form_wrapper_attr`,
    `get_form_wrapper_attr`, `has_form_wrapper_attr`, and
    `set_form_wrapper_attr` via the hash trait

- form\_wrapper\_class

    A mutable array reference of strings with an empty default. List of classes
    to apply to the form wrapper

    Handles `has_form_wrapper_class` via the array trait

- form\_tags

    An immutable hash reference with an empty default. The optional tags are
    applied to the form HTML. Keys used;

    - `after` - Markup rendered at the very end of the form
    - `after_start` - Markup rendered after the form has been started
    - `before` - Markup rendered at the start before the form
    - `before_end` - Markup rendered before the end of the form
    - `error_class` - Error message class. Defaults to `alert alert-severe`
    - `info_class` - Info message class. Defaults to `alert alert-info`
    - `legend` - Content for the form's legend
    - `messages_wrapper_class` - Defaults to `form-messages`
    - `no_form_messages` - If true no form messages will be rendered
    - `success_class` - Defaults to `alert alert-success`
    - `wrapper_tag` - Tag to wrap the form in. Defaults to `fieldset`

    The keys that contain markup are only implemented by the
    [Template Tookit](https://metacpan.org/pod/HTML%3A%3AForms%3A%3ARender%3A%3AWithTT) renderer

    Handles; `has_tag`, `set_tag`, and `tag_exists` via the hash trait

    See ["get\_tag" in HTML::Forms](https://metacpan.org/pod/HTML%3A%3AForms#get_tag)

- http\_method

    An immutable string with a default of `post`. The method attribute on the
    form element

- inactive

    A mutable array reference of inactive field names with an empty default

    Handles; `add_inactive`, `clear_inactive`, and `has_inactive` via the array
    trait

- index

    An immutable hash reference of field objects with an empty default. Provides an
    index by field name to the field objects in the
    [fields](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AFields%3A%3Afields) array

    Handles; `add_to_index`, `field_from_index`, and `field_in_index` via the
    hash trait

- info\_message

    A mutable string with no default. The information message to display at the
    start of the form

- clear\_info\_message

    Clearer

- has\_info\_message

    Predicate

- init\_object

    A lazy untyped mutable attribute with no default. If `item` is not set and
    this attribute is, it will be used to initialise the `result` object

- clear\_init\_object

    Clearer

- language\_handle

    A lazy object built by `build_language_handle`. An instance of
    `language_handle_class` it is used to translate text into different
    languages via the calls to `maketext`

- language\_handle\_class

    A lazy loadable class which defaults to [HTML::Forms::I18N](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AI18N). The name of the
    class which implements language translation. Expected to be a subclass of
    [Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext)

- locales

    A lazy immutable array reference of strings. Defaults to the `locales` on
    the `request` object if available, empty otherwise

- has\_locales

    Predicate

- messages

    A mutable hash reference of string with an empty default. If set these messages
    will be used in preference to class messages by the `get_message` method on
    the field object

    Handles; `set_message` via the hash trait

- name

    A mutable string with a random default. The name of the form element

- no\_update

    A mutable bool without default. If set to true the call
    in `process` to update the model will be skipped

- clear\_no\_update

    Clearer

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

    A mutable boolean without default. Should be set to true if the form was posted

- clear\_posted

    Clearer

- has\_posted

    Predicate

- renderer\_args

    An immutable hash reference passed to the constructor of the `renderer` object
    empty by default

- renderer\_class

    A lazy loadable class which defaults to [HTML::Forms::Render::WithTT](https://metacpan.org/pod/HTML%3A%3AForms%3A%3ARender%3A%3AWithTT). The
    class name of the `renderer` object. Set to [HTML::Forms::Render::EmptyDiv](https://metacpan.org/pod/HTML%3A%3AForms%3A%3ARender%3A%3AEmptyDiv)
    form rendering will by done by JS in the browser

- result

    An lazy immutable [HTML::Forms::Result](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AResult) object constructed by the
    `build_result` method

    Handles; `add_result`, `all_form_errors`, `clear_form_errors`,
    `form_errors`, `has_form_errors`, `has_input`, `has_value`, `input`,
    `is_valid`, `num_form_errors`, `push_form_errors`, `ran_validation`,
    `results`, `validated`, and `value`

- clear\_result

    Clearer

- has\_result

    Predicate

- style

    A mutable string with no default. If set this is applied as the `style`
    attribute of the form

- success\_message

    A mutable string with no default. If set this is displayed near the start of
    the form

- clear\_success\_message

    Clearer

- has\_success\_message

    Predicate

- title

    An immutable string with no default. If set and [HTML::Forms::Role::Defaults](https://metacpan.org/pod/HTML%3A%3AForms%3A%3ARole%3A%3ADefaults)
    is applied to the form class this string will be used as the form legend

- update\_field\_list

    A mutable hash reference with an empty default. If set the keys are field
    names an the values are hash references of field attribute names and values.
    This will be applied to the fields in the form when `setup_form` is called

    Handles; `clear_update_field_list`, `has_update_field_list`, and
    `set_update_field_list` via the hash trait

- use\_defaults\_over\_obj

    A mutable boolean without default. If true will use the defaults on the field
    definition in preference to the `item` object

- clear\_use\_defaults\_over\_obj

    Clearer

- use\_fields\_for\_input\_without\_param

    A mutable boolean without default. Changes how the field object instantiates
    the result object

- use\_init\_obj\_over\_item

    A mutable boolean which defaults false. If true the `init_object` is used in
    preference to the `item` when initialising the `result` object

- clear\_use\_init\_obj\_over\_item

    Clearer

- widget\_form

    An immutable string which defaults to `Simple`. If set to `Complex` then
    the [HTML::Forms::Role::Widget::Form::Complex](https://metacpan.org/pod/HTML%3A%3AForms%3A%3ARole%3A%3AWidget%3A%3AForm%3A%3AComplex) role will be applied to the
    form and result objects

- widget\_name\_space

    An immutable array reference of string with an empty default. Additional name
    spaces to be search when looking for widget roles

    Handles; `add_widget_name_space` via the array trait

- widget\_wrapper

    An immutable string which defaults to `Simple`. Adds a `render` method to
    the field object

# Subroutines/Methods

Defines the following methods;

- BUILDARGS

    Additionally allows for construction from either an `item` object instance or
    an `item_id`

- BUILD

    Applies widget roles, builds the fields, sets the active field list, and
    initialises the result object. Will also dump the field definitions if
    `verbose` is true

    The methods `before_build_fields`, and `after_build_fields` are called either
    side of the above and are dummy methods in this class. Made for overriding in a
    form role

- add\_form\_element\_class

        $class = $self->add_form_element_class( @args );

    Takes either an array reference of a list. Pushes onto the `form_element`
    class list

- add\_form\_error

        $self->add_form_error( @message );

    Pushes the supplied message (after localising) onto form errors. Uses the
    `form is invalid` message if one is not supplied

- add\_form\_wrapper\_class

        $class = $self->add_form_wrapper_class( @args );

    Takes either an array reference of a list. Pushes onto the `form_wrapper`
    class list

- after\_build\_fields

    Dummy method called by `BUILD`. Expected to be decorated in the form classes

- after\_update\_model

    Called after the the call to `update_model`. Return without doing anything
    unless we `has_repeatable_fields` and we also has an `item`. This an attempt
    to reload the repeatable relationships after the database is updated, so that
    we get the primary keys of the repeatable elements. Otherwise, if a form is
    re-presented, repeatable elements without primary keys may be created
    again. There is no reliable way to connect up existing repeatable elements with
    their db-created primary keys.

- attributes

    A proxy for `form_element_attributes`

- before\_build\_fields

    Dummy method called at the start of the `BUILD` method. Expected to be
    decorated in the form classes

- build\_active

    Called at build time it clears the inactive status of any `active` fields and
    sets the inactive status on any `inactive` fields

- build\_errors

    Moves the errors to the `result` object

- build\_language\_handle

    Constructor for the `language_handle` attribute. Will use `locales` if
    available otherwise uses the environment variable `LANGUAGE_HANDLE`.
    Always appends `default_locale` to the list supplied to the
    `language_handle_class`'s `get_handle` constructor method

- build\_result

    Builds the `result` object an instance of [HTML::Forms::Result](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AResult)

- clear

    Calls all the clearers defined on the form object. Sets `processed` and
    `did_init_obj` to false

- fif

        $hash = $self->fif( @args );

    Fill in form. Returns a hash reference whose keys are the field names and
    whose values are take from the result

- form

    Returns the self referential object

- form\_element\_attributes

    Returns a hash reference of keys and values which are applied to the form
    element

    Also calls `html_attributes` with a 'type' of 'form\_element' returning it's
    returned hash reference if set. Allows for an overridden `html_attributes`
    to "fix things up" if required

- form\_wrapper\_attributes

    Returns a hash reference of keys and values which are applied to the form
    wrapper element

    Also calls `html_attributes` with a 'type' of 'form\_wrapper' returning it's
    returned hash reference if set. Allows for an overridden `html_attributes`
    to "fix things up" if required

- full\_accessor

    Dummy method returns the null string

- full\_name

    Dummy method returns the null string

- get\_default\_value

    Dummy method returns nothing

- get\_tag

        $tag_string = $self->get_tag( $name );

    Returns the `forms_tags` entry for the given name if it exists, otherwise
    returns null. Code references a called as a method and their values are
    returned. If the tag begins with a `%` and the following word is a named
    `block` call the blocks render method and return that. Return null otherwise

- has\_flag

        $bool = $self->has_flag( $flag_name );

    If the form object has a method `flag_name` call it and return it's value.
    Return undef otherwise

- html\_attributes

        $attrs = $self->html_attributes( $object, $type, $attrs, $result );

    Dummy method that returns the supplied `attrs`. Called by
    `form_element_attributes`. The `type` argument is one of; 'element',
    'element\_wrapper', 'form\_element', 'form\_wrapper', 'label', or 'wrapper'.

    Applied roles can modify this method to alter the attributes of the
    above list of form elements

- init\_value

        $self->init_value( $field, $value );

    Sets both the initial and current field values to the one supplied

- localise

        $message = $self->localise( $message, @args );

    Calls `maketext` on the `language_handle` to localise the supplied message.
    If localisation fails will substitute the placeholder variables and return
    that string

- new\_with\_traits

        $form = $self->new_with_traits( %args );

    Either a class or object method. Returns a new instance of this class with
    the list of supplied `traits` in the `args` hash applied. This rest of the
    `args` hash is supplied to the constructor of the new object

- process

        $validated = $self->process( @args );

    Calls ["clear"](#clear) if ["processed"](#processed) is true. Calls
    ["setup\_form"](#setup_form) with the supplied `@args`. If the form was
    ["posted"](#posted) calls ["validate\_form"](#validate_form). If
    ["validated"](#validated) is true and ["no\_update"](#no_update) is false call
    both ["update\_model"](#update_model) and then ["after\_update\_model"](#after_update_model).
    Set ["processed"](#processed) to true and return ["validated"](#validated)

    Consider this fragment from a controller/model method that processes a form
    `GET` or `POST`. It stashes the form object (for rendering in the HTML
    template) and if posted successfully stashes a redirect to the login page with
    a message that should be displayed to the user

        my $form = $self->new_form('Register', { context => $context });

        if ($form->process( posted => $context->posted )) {
           my $job     = $context->stash->{job};
           my $login   = $context->uri_for_action('page/login');
           my $message = 'Registration request [_1] dispatched';

           $context->stash(redirect $login, [$message, $job->label]);
           return;
        }

        $context->stash(form => $form);

- set\_active

    Set active fields to `active` and inactive fields to `inactive`

- setup\_form

        $self->setup_form( @args );

    Called from ["process"](#process). The `@args` is either a hash reference or
    a list of keys and values. The hash reference is used to instantiate the
    `params` hash reference, the list is used to set attributes on the form
    object. ["build\_item" in HTML::Forms::Model](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AModel#build_item) is called if we have an `item_id`
    and no `item`. The `result` object is cleared, fields have their activation
    state set, ["update\_fields"](#update_fields) is called, `posted` is set to true if
    we has `params` and `posted` wasn't supplied to the constructor. The
    `result` is initialised. If `posted` the result is cleared again and then
    initialised from the `params` provided

- update\_field

        $self->update_field( $field_name, $updates );

    Updates the named field's attributes using the keys and values provided in the
    `updates` hash reference

- update\_fields

    Called from ["process"](#process). If we `has_update_field_list` call
    `update_field` for each element in the list. If we `has_defaults` call
    `update_field` supplying those defaults

- validate

    Dummy method which always returns true. Decorate this method from the form
    class, it is called from ["validate\_form"](#validate_form)

- validate\_form

    Called from ["process"](#process) if the form was posted. Sets required
    dependencies, validates individual fields, calls the above `validate` method,
    calls ["validate\_model" in HTML::Forms::Model](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AModel#validate_model), sets field values, builds any
    errors, clears the dependencies, clears `posted`, sets `ran_validation` to
    true and returns the `validated` attribute

- values

    Returns ["value" in HTML::Forms::Result](https://metacpan.org/pod/HTML%3A%3AForms%3A%3AResult#value)

# Diagnostics

Setting ["verbose"](#verbose) to true will output diagnostic information to `stderr`

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
