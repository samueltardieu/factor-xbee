USING: accessors byte-arrays calendar continuations elec344.xbee
       elec344.xbee.api.messages elec344.xbee.api.utils io kernel math
       make namespaces sequences threads ;
IN: elec344.xbee.api

ERROR: invalid-packet ;

: xbee-read2 ( -- w )
    2 xbee get stream-read first2 [ 256 * ] [ bitor ] bi* ;

: receive-packet ( -- pkt )
    HEX: 7e xbee-expect1 xbee-read2 xbee get stream-read
    dup checksum xbee-expect1 ;

: receive-api ( -- data )
    [ receive-packet ] [ drop receive-api ] recover ;

: receive-message ( -- message )
    receive-api frame>message ;

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
