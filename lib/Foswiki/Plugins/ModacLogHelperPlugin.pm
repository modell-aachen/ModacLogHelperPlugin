# See bottom of file for default license and copyright information

package Foswiki::Plugins::ModacLogHelperPlugin;

use strict;
use warnings;

use Foswiki::Func    ();
use Foswiki::Plugins ();

use Foswiki::Plugins::ModacHelpersPlugin;

use JSON;
use Crypt::CBC;
use Compress::Zlib;
use MIME::Base64;

our $VERSION = '1.0';
our $RELEASE = '1.0';

our $SHORTDESCRIPTION = 'Modell Aachen log-files helper plugin';

our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.3 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    Foswiki::Func::registerRESTHandler(
        'loginfo', \&_restLogInfo,
        authenticate => 1, http_allow => 'POST,GET', validate => 0 );

    Foswiki::Func::registerRESTHandler(
        'decrypt', \&_restDecrypt,
        authenticate => 1, http_allow => 'POST,GET', validate => 0 );

    Foswiki::Func::registerTagHandler(
        'LOGDECODER', \&_logDecoder );

    Foswiki::Func::registerTagHandler(
        'LOGEXPORTER', \&_logExporter );

    # Plugin correctly initialized
    return 1;
}

sub _logExporter {
    my ( $session, $attributes, $topic, $web ) = @_;

    my $text = $attributes->{linktext} || '';
    $text =~ s#[^\w\d\s]##g;
    return '%TMPL:P{"LIBJS" id="ModacLogHelperPlugin/exporter" requires="VUEJSPLUGIN"}%'
        . '<div class="ModacLogHelperPlugin vue-logexporter foswikiHidden" data-text="' . $text . '"></div>';
}

sub _logDecoder {
    return '%TMPL:P{"LIBJS" id="ModacLogHelperPlugin/decoder" requires="VUEJSPLUGIN"}%'
        . '<div class="ModacLogHelperPlugin vue-logdecoder foswikiHidden"></div>';
}

sub _restReadLogs {
    my ($session, $plugin, $verb, $response) = @_;

    my $query = Foswiki::Func::getCgiQuery();

}

sub _restLogInfo {
    my ($session, $plugin, $verb, $response) = @_;

    my $query = Foswiki::Func::getCgiQuery();


    my $time = time();
    my $logStartTime = $query->param('logsstart');
    if($logStartTime) {
        $logStartTime = Foswiki::Time::parseTime($logStartTime);
    } else {
        $logStartTime = $time - 60 * 30;
    }
    my $logEndTime = $query->param('logsend');
    if($logEndTime) {
        $logEndTime = Foswiki::Time::parseTime($logEndTime);
    }

    my $logs = {};
    my @levels = ('notice', 'event', 'debug', 'warning', 'error', 'fatal');
    push @levels, 'info' if $query->param('useinfologs');
    foreach my $level (@levels) {
        $logs->{$level} = [];
        my $logIterator = $session->logger->eachEventSince({start => $logStartTime, end => $logEndTime}, $level, 1);
        $logs->{$level} = [$logIterator->all()]
    }
    my $data = {
        logs => $logs,
        servertime => $time,
        logsstart => $logStartTime,
        logsend => $logEndTime,
    };

    my $compressed = Compress::Zlib::memGzip(
        Foswiki::encode_utf8(
            to_json($data)
        )
    );

    my ($user, $key) = Foswiki::Plugins::ModacHelpersPlugin::getRmsCredentials();
    unless($user && $key) {
        return 'Could not get rms data';
    }

    my $cypher = Crypt::CBC->new(
        -key => $key,
        -cipher => 'Crypt::Rijndael',
    );

    return encode_base64($user) . "\n" . encode_base64($cypher->encrypt($compressed));
}

sub _restDecrypt {
    my ($session, $plugin, $verb, $response) = @_;

    my $query = Foswiki::Func::getCgiQuery();

    my $data = $query->param('data');

    my $key = $query->param('key');
    $key =~ s#^\s+##;
    $key =~ s#\s+$##;

    my $uncompressed;
    eval {
        my $cypher = Crypt::CBC->new(
            -key => $key,
            -cipher => 'Crypt::Rijndael',
        );

        my $decrypted = $cypher->decrypt(decode_base64($data));
        $uncompressed = Compress::Zlib::memGunzip($decrypted);
    };
    if($@) {
        Foswiki::Func::writeWarning("Error while decrypting: $@");
    }

    return $uncompressed;
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
