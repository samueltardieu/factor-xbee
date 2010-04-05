USING: accessors byte-arrays calendar continuations elec344.xbee
       elec344.xbee.api.messages elec344.xbee.api.utils fry io kernel
       math make namespaces sequences threads ;
IN: elec344.xbee.api

TUPLE: bad-checksum ;
TUPLE: bad-preambule ;

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

: receive-frame ( -- data )
    [ receive-packet ] [ bad-preambule? ] [ drop receive-frame ] recover-one ;

: receive-message* ( -- message )
    receive-frame frame>message ;

: receive-message ( -- message )
    [ receive-message* ] [ bad-checksum? ] [ drop receive-message ] recover-one ;

: send-message ( message -- )
    message>frame send-raw ;

: send-at-id ( data command id -- )
    [ <at-command> ] [ >>id ] bi* send-message ;

: send-at ( data command -- )
    0 send-at-id ;

: send-16-id ( data dst id -- )
    [ <tx-request> ] [ >>id ] bi* send-message ;

: send-16 ( data dst -- )
    0 send-16-id ;

: enter-api-mode ( -- )
    "" "FR" send-at
    2 seconds sleep
    enter-command-mode
    "ATAP1\r\n" send-raw
    1 seconds sleep
    leave-command-mode ;

: set-my ( my -- )
    "MY" send-at ;

: set-xbee-retries ( n -- )
    1byte-array "RR" send-at ;
