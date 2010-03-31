USING: accessors arrays calendar delegate delegate.protocols destructors fry io
       io.encodings.8-bit.latin1 io.sockets io.streams.duplex kernel make math
       math.parser namespaces prettyprint sequences threads ;
IN: elec344.xbee

TUPLE: zigbee < disposable stream ;

SYMBOL: zigbee

M: zigbee dispose* stream>> dispose* ;

CONSULT: input-stream-protocol zigbee stream>> ;

CONSULT: output-stream-protocol zigbee stream>> ;

M: zigbee in>> stream>> in>> ;
M: zigbee out>> stream>> out>> ;

: with-zigbee* ( zigbee quot -- )
    zigbee swap with-variable ; inline

: with-zigbee ( zigbee quot -- )
    [ with-zigbee* ] curry with-disposal ; inline

: <zigbee> ( stream -- zigbee )
    zigbee new [ (>>stream) ] keep ;

: <remote-zigbee> ( host port -- zigbee )
    <inet> latin1 <client> drop <zigbee> ;

: send-raw ( str -- )
    zigbee get [ stream-write ] [ stream-flush ] bi ;

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
