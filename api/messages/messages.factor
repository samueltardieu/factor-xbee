USING: accessors byte-arrays combinators elec344.xbee.api kernel macros make sequences ;
IN: elec344.xbee.api.messages

<PRIVATE

: format ( message quot -- data )
    B{ } make make-frame ; inline

MACRO: cut-each ( specification -- quot )
    [ [ cut ] curry ] [ compose ] map-reduce ;

PRIVATE>

GENERIC: message>api ( message -- data )

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

M: at-command message>api
    [ 8 , [ id>> , ] [ name>> % ] [ data>> % ] tri ] format ;

TUPLE: at-command-queue { id initial: 0 } name { data initial: B{ } } ;

M: at-command-queue message>api
    [ 9 , [ id>> , ] [ name>> % ] [ data>> % ] tri ] format ;

TUPLE: at-response id name status data ;

CONSTANT: ok 0
CONSTANT: error 1
CONSTANT: invalid-command 2
CONSTANT: invalid-parameter 3

TUPLE: remote-at-command < api-out destination network options name
    { data initial: B{ } } ;

M: remote-at-command message>api
    [ HEX: 17 , { [ id>> , ] [ destination>> % ] [ network>> % ]
                  [ options>> , ] [ name>> % ]
                  [ data>> % ] } cleave ] format ;

TUPLE: remote-at-response id source network name status data ;

TUPLE: tx-request < api-out destination { options initial: 0 } data ;

M: tx-request message>api
    dup destination>> length 8 = 0 1 ?
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

PRIVATE>

: api>message ( data -- message )
    dup first {
        { HEX: 80 [ { 8 1 1 } rx separate ] }
        { HEX: 81 [ { 2 1 1 } rx separate ] }
        { HEX: 88 [ { 1 2 1 } at-response separate ] }
        { HEX: 89 [ first2 tx-status boa ] }
        { HEX: 8a [ second modem-status boa ] }
        { HEX: 97 [ { 1 8 2 2 1 } remote-at-response separate ] }
        [ unknown-message ]
    } case ;
