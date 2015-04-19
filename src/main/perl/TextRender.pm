# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package EDG::WP4::CCM::TextRender;

use strict;
use warnings;
use CAF::TextRender qw($YAML_BOOL_PREFIX);

use base qw(CAF::TextRender Exporter);

our @EXPORT_OK = qw(%ELEMENT_CONVERT);

Readonly::Hash our %ELEMENT_CONVERT => {
    'json_boolean' => sub {
        my $value = shift;
        return $value ? \1 : \0;
    },
    'yaml_boolean' => sub {
        my $value = shift;
        #return $value ? $YAML_BOOL->{yes} : $YAML_BOOL->{no};
        return $YAML_BOOL_PREFIX .
            ($value ? 'true' : 'false');
    },
    'yesno_boolean' => sub {
        my $value = shift;
        return $value ? 'yes' : 'no';
    },
    'YESNO_boolean' => sub {
        my $value = shift;
        return $value ? 'YES' : 'NO';
    },
    'doublequote_string' => sub {
        my $value = shift;
        return "\"$value\"";
    },
    'singlequote_string' => sub {
        my $value = shift;
        return "'$value'";
    },
};

=pod

=head1 NAME

    CCM::TextRender - Class for rendering structured text using Element instances

=head1 DESCRIPTION

This class is an extension of the C<CAF::TextRender> class; with the main 
difference the support of a C<EDG::WP4::CCM:Element> instance as contents.

=head2 Private methods

=over

=item C<_initialize>

Initialize the process object. Arguments:

=over

=item module

The rendering module to use (see C<CAF::TextRender> for details).

=item contents

C<contents> is either a hash reference holding the contents to pass to the rendering module;
or a C<EDG::WP4::CCM:Element> instance, on which C<getTree> is called with any C<element>
options.

=back

All optinal arguments from C<CAF::TextRender> are supported unmodified:

=over

=item log

=item includepath

=item relpath

=item eol

=item usecache

=item ttoptions

=back

Extra optional arguments: 

=over

=item element

A hashref holding any C<getTree> options to pass. These can be the
anonymous convert methods C<convert_boolean>, C<convert_string>,
C<convert_long> and C<convert_double>; or one of the
predefined convert methods (key is the name, value a boolean
wheter or not to use them). The C<convert_> methods take precedence over
the predefined ones in case there is any overlap.

The predefined convert methods are:

=over

=item json

Enable JSON output, in particular JSON boolean (the other types should
already be in proper format). This is automatically enabled when the json 
module is used (and not explicilty set).

=item yaml

Enable YAML output, in particular YAML boolean (the other types should
already be in proper format). This is automatically enabled when the yaml 
module is used (and not explicilty set).

=item yesno

Convert boolean to (lowercase) 'yes' and 'no'.

=item YESNO

Convert boolean to (uppercase) 'YES' and 'NO'.

=item doublequote

Convert string to doublequoted string.

=item singlequote

Convert string to singlequoted string.

=back

Other C<getTree> options

=over

=item depth

Only return the next C<depth> levels of nesting (and use the
Element instances as values). A C<depth == 0> is the element itself,
C<depth == 1> is the first level, ...

Default or depth C<undef> returns all levels.

=back

=back

=cut

sub _initialize
{
    my ($self, $module, $contents, %opts) = @_;

    if (defined($opts{element})) {
        # Make a (modifiable) copy
        $self->{elementopts} = { %{$opts{element}} };
        delete $opts{element};
    } else {
        $self->{elementopts} = {};
    }

    return $self->SUPER::_initialize($module, $contents, %opts);
}

# Return the validated contents. Either the contents are a hashref
# (in that case they are left untouched) or a C<EDG::WP4::CCM::Element> instance
# in which case C<getTree> is called together with the relevant C<elementopts>
sub make_contents
{
    my ($self) = @_;

    my $contents;

    my $ref = ref($self->{contents});

    if($ref && ($ref eq "HASH")) {
        $contents = $self->{contents};
    } elsif ($ref && UNIVERSAL::can($self->{contents},'can') &&
             $self->{contents}->isa('EDG::WP4::CCM::Element')) {
        # Test for a blessed reference with UNIVERSAL::can
        # UNIVERSAL::can also return true for scalars, so also test
        # if it's a reference to start with
        $self->debug(3, "Contents is a Element instance");
        my $depth = $self->{elementopts}->{depth};

        if ($self->{module} && $self->{module} eq 'json' && 
            ! defined( $self->{elementopts}->{json})) {
            $self->{elementopts}->{json} = 1;
        } elsif ($self->{module} && $self->{module} eq 'yaml' && 
            ! defined( $self->{elementopts}->{yaml})) {
            $self->{elementopts}->{yaml} = 1;
        }

        my %opts;

        # predefined convert_
        if ($self->{elementopts}->{json}) {
            $opts{convert_boolean}  = $ELEMENT_CONVERT{json_boolean};
        } 
        
        if ($self->{elementopts}->{yaml}) {
            $opts{convert_boolean}  = $ELEMENT_CONVERT{yaml_boolean};
        } 

        if ($self->{elementopts}->{yesno}) {
            $opts{convert_boolean}  = $ELEMENT_CONVERT{yesno_boolean};
        } elsif ($self->{elementopts}->{YESNO}) {
            $opts{convert_boolean}  = $ELEMENT_CONVERT{YESNO_boolean};
        }

        if ($self->{elementopts}->{doublequote}) {
            $opts{convert_string}  = $ELEMENT_CONVERT{doublequote_string};
        } elsif ($self->{elementopts}->{singlequote}) {
            $opts{convert_string}  = $ELEMENT_CONVERT{singlequote_string};
        }

        # The convert_ anonymous methods precede the predefined ones
        foreach my $type (qw(boolean string long double)) {
            my $am_name = "convert_$type";
            my $am = $self->{elementopts}->{$am_name};
            $opts{$am_name} = $am if (defined ($am));
        }

        $contents = $self->{contents}->getTree($depth, %opts);
    } else {
        return $self->fail("Contents passed is neither a hashref or ",
                           "a EDG::WP4::CCM::Element instance ",
                           "(ref ", ref($self->{contents}), ")");
    }

    return $contents;
}

=pod

=back

=cut

1;

