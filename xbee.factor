USING: accessors arrays byte-arrays calendar continuations delegate
       delegate.protocols destructors elec344.xbee.api
       elec344.xbee.api.messages fry io io.encodings.binary
       io.sockets io.streams.duplex kernel make math math.parser
       namespaces prettyprint sequences splitting threads ;
IN: elec344.xbee

TUPLE: xbee < disposable stream ;

SYMBOL: xbee

M: xbee dispose* stream>> dispose* ;

CONSULT: input-stream-protocol xbee stream>> ;

CONSULT: output-stream-protocol xbee stream>> ;

M: xbee in>> stream>> in>> ;
M: xbee out>> stream>> out>> ;

: <xbee> ( stream -- xbee )
    xbee new [ (>>stream) ] keep ;

: <remote-xbee> ( host port -- xbee )
    <inet> binary <client> drop <xbee> ;

: send-raw ( seq -- )
    >byte-array xbee get [ stream-write ] [ stream-flush ] bi ;

: send-message ( message -- )
    message>frame send-raw ;

: send-api ( data -- )
    make-frame send-raw ;

ERROR: invalid-packet ;

: xbee-read1 ( -- c )
    xbee get stream-read1 ;

: xbee-read2 ( -- w )
    2 xbee get stream-read first2 [ 256 * ] [ bitor ] bi* ;

: xbee-expect1 ( c -- )
    xbee-read1 = [ invalid-packet ] unless ;

: receive-packet ( -- pkt )
    HEX: 7e xbee-expect1 xbee-read2 xbee get stream-read
    dup checksum xbee-expect1 ;

: receive-api ( -- data )
    [ receive-packet ] [ drop receive-api ] recover ;

: send-at-id ( data command id -- )
    [ <at-command> ] [ >>id ] bi* send-message ;

: send-at ( data command -- )
    0 send-at-id ;

: send-16-id ( data dst id -- )
    [ <tx-request> ] [ >>id ] bi* send-message ;

: send-16 ( data dst -- )
    0 send-16-id ;

CONSTANT: broadcast-16 B{ HEX: ff HEX: ff }

: enter-command-mode ( -- )
    1.1 seconds sleep
    "+++" send-raw
    1.1 seconds sleep ;

: leave-command-mode ( -- )
    "ATCN\r\n" send-raw ;

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
