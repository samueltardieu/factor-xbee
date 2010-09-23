USING: accessors arrays byte-arrays calendar combinators continuations
       xbee fry io kernel macros math make namespaces
       sequences threads ;
IN: xbee.api

TUPLE: bad-checksum ;

<PRIVATE

TUPLE: bad-preambule ;

: ,2 ( word -- )
    256 /mod [ , ] bi@ ;

: checksum ( data -- c )
    sum 255 bitand 255 bitxor ;

: make-frame ( data -- frame )
    [ HEX: 7e , [ length ,2 ] [ % ] [ checksum , ] tri ] B{ } make ;

: xbee-read1 ( -- c )
    xbee get stream-read1 ;

: xbee-expect1 ( error c -- )
    xbee-read1 = [ drop ] [ new throw ] if ;

: xbee-read2 ( -- w )
    2 xbee get stream-read first2 [ 256 * ] [ bitor ] bi* ;

: receive-packet ( -- pkt )
    bad-preambule HEX: 7e xbee-expect1
    xbee-read2 xbee get stream-read
    bad-checksum over checksum xbee-expect1 ;

: recover-one ( quot error-check cleanup -- )
    '[ dup @ _ [ rethrow ] if ] recover ; inline

PRIVATE>

CONSTANT: broadcast-16 B{ HEX: ff HEX: ff }
CONSTANT: broadcast-64 B{ HEX: 00 HEX: 00 HEX: 00 HEX: 00
                          HEX: 00 HEX: 00 HEX: ff HEX: ff }

ERROR: bad-address address ;

<PRIVATE

: format ( message quot -- data )
    B{ } make make-frame ; inline

MACRO: cut-each ( specification -- quot )
    [ [ cut ] curry ] [ compose ] map-reduce ;

PRIVATE>

GENERIC: message>frame ( message -- data )

TUPLE: modem-status cmd-data ;

CONSTANT: hardware-reset 0
CONSTANT: watchdog-timer-reset 1
CONSTANT: associated 2
CONSTANT: disassociated 3
CONSTANT: synchronization-lost 4
CONSTANT: coordinator-realignment 5
CONSTANT: coordinator-started 6

ERROR: unknown-message data ;

TUPLE: api-out { id initial: 0 } ;

TUPLE: at-command < api-out name { data initial: B{ } } ;

: <at-command> ( data name -- at-command )
    [ at-command new ] 2dip [ >>data ] [ >>name ] bi* ;

M: at-command message>frame
    [ 8 , [ id>> , ] [ name>> % ] [ data>> % ] tri ] format ;

TUPLE: at-command-queue { id initial: 0 } name { data initial: B{ } } ;

M: at-command-queue message>frame
    [ 9 , [ id>> , ] [ name>> % ] [ data>> % ] tri ] format ;

TUPLE: at-response id name status data ;

CONSTANT: ok 0
CONSTANT: error 1
CONSTANT: invalid-command 2
CONSTANT: invalid-parameter 3

TUPLE: remote-at-command < api-out destination options name
    { data initial: B{ } } ;

<PRIVATE

MACRO: choose-destination ( quot-16 quot-64 -- seq )
    [ 2 swap 2array ] [ 8 swap 2array ] bi* [ bad-address ] 3array
    '[ destination>> dup length _ case ] ;

: destination-64 ( message -- seq )
    [ drop B{ 0 0 0 0 0 0 0 0 } ] [ ] choose-destination ;

: destination-16 ( message -- seq )
    [ ] [ drop B{ HEX: ff HEX: fe } ] choose-destination ;

PRIVATE>

M: remote-at-command message>frame
    [ HEX: 17 , { [ id>> , ] [ destination-64 % ] [ destination-16 % ]
                  [ options>> , ] [ name>> % ]
                  [ data>> % ] } cleave ] format ;

TUPLE: remote-at-response id source name status data ;

TUPLE: tx-request < api-out destination { options initial: 0 } data ;

: <tx-request> ( data destination -- tx-request )
    [ tx-request new ] 2dip [ >>data ] [ >>destination ] bi* ;

M: tx-request message>frame
    dup [ drop 1 ] [ drop 0 ] choose-destination
    [ , { [ id>> , ] [ destination>> % ] [ options>> , ] [ data>> % ] } cleave ] format ;

CONSTANT: disable-ack 1
CONSTANT: broadcast-pan-id 4

TUPLE: tx-status id status ;

CONSTANT: success 0
CONSTANT: no-ack 1
CONSTANT: cca-failure 2
CONSTANT: purged 3

TUPLE: rx source rssi options data ;

CONSTANT: address-broadcast 2
CONSTANT: pan-broadcast 4

<PRIVATE

: separate ( data seq class -- message )
    [ rest ] [ cut-each ] [ boa ] tri* ; inline

: select-address ( 64-bits 16-bits -- addr )
    dup B{ HEX: ff HEX: fe } = ? ;

: fix-rx ( message -- message' )
    [ first ] change-rssi [ first ] change-options ;

: fix-at-response ( message -- message' )
    [ first ] change-id [ first ] change-status ;

: analyze-rx ( data seps -- message )
    rx separate fix-rx ; inline

PRIVATE>

: frame>message ( data -- message )
    dup first {
        { HEX: 80 [ { 8 1 1 } analyze-rx ] }
        { HEX: 81 [ { 2 1 1 } analyze-rx ] }
        { HEX: 88 [ { 1 2 1 } at-response separate fix-at-response ] }
        { HEX: 89 [ rest first2 tx-status boa ] }
        { HEX: 8a [ second modem-status boa ] }
        { HEX: 97 [ rest { 1 8 2 2 1 } cut-each [ select-address ] 3dip
                    remote-at-response boa fix-at-response ] }
        [ unknown-message ]
    } case ;

: receive-frame ( -- data )
    [ receive-packet ] [ bad-preambule? ] [ drop receive-frame ] recover-one ;

: receive-message* ( -- message )
    receive-frame frame>message ;

: receive-message ( -- message )
    [ receive-message* ] [ bad-checksum? ] [ drop receive-message ] recover-one ;

: send-message ( message -- )
    message>frame send-raw ;

: enter-api-mode ( -- )
    B{ } "FR" <at-command> send-message
    2 seconds sleep
    enter-command-mode
    "ATAP1\r\n" send-raw
    leave-command-mode ;
