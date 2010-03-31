USING: accessors arrays calendar continuations delegate
       delegate.protocols destructors fry io io.encodings.8-bit.latin1
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

: with-xbee* ( xbee quot -- )
    xbee swap with-variable ; inline

: with-xbee ( xbee quot -- )
    [ with-xbee* ] curry with-disposal ; inline

: <xbee> ( stream -- xbee )
    xbee new [ (>>stream) ] keep ;

: <remote-xbee> ( host port -- xbee )
    <inet> latin1 <client> drop <xbee> ;

: send-raw ( str -- )
    xbee get [ stream-write ] [ stream-flush ] bi ;

: checksum ( data -- c )
    sum 255 bitand 255 bitxor ;

: ,2 ( word -- )
    256 /mod [ , ] bi@ ;

: send-api ( data -- )
    [
        HEX: 7e ,
        [ length ,2 ]
        [ % ]
        [ checksum , ] tri
    ] "" make send-raw ;

ERROR: invalid-packet ;

: xbee-read1 ( -- c )
    xbee get stream-read1 ;

: xbee-read2 ( -- w )
    xbee-read1 256 * xbee-read1 bitor ;

: xbee-expect1 ( c -- )
    xbee-read1 = [ invalid-packet ] unless ;

: receive-packet ( -- pkt )
    HEX: 7e xbee-expect1 xbee-read2 iota [ drop xbee-read1 ] map
    dup checksum xbee-expect1 ;

: receive-api ( -- data )
    [ receive-packet ] [ drop receive-api ] recover ;

: send-at-id ( data command id -- )
    [ 8 , , % % ] "" make send-api ;

: send-at ( data command -- )
    0 send-at-id ;

: send-16-id ( data dst id -- )
    '[ 1 , , [ , ] each 0 , % ] "" make send-api ;

: send-16 ( data dst -- )
    0 send-16-id ;

CONSTANT: broadcast-16 { HEX: ff HEX: ff }

: enter-api-mode ( -- )
    "" "FR" send-at
    3.1 seconds sleep
    "+++" send-raw
    1.1 seconds sleep
    "ATAP1,CN\r\n" send-raw ;

: set-my ( my -- )
    "MY" send-at ;

: set-xbee-retries ( n -- )
    1array "RR" send-at ;

SYMBOL: input-buffer

: data-packet ( -- pkt )
    [ receive-api dup first HEX: 81 = ] [ drop ] until
    5 tail ;

: refill-buffer ( -- )
    input-buffer get data-packet append input-buffer set ;

: recv-line ( -- str )
    [ input-buffer get "\r\n" split dup length 1 = ] [ drop refill-buffer ] while
    [ rest "\n" join input-buffer set ] [ first ] bi
    dup empty? [ drop recv-line ] when ;
