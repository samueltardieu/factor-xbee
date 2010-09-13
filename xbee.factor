USING: accessors byte-arrays calendar delegate delegate.protocols
       destructors io io.encodings.binary io.sockets io.streams.duplex
       kernel namespaces threads ;
IN: elec344.xbee

TUPLE: xbee < disposable stream ;

SYMBOL: xbee

M: xbee dispose* stream>> dispose* ;

CONSULT: input-stream-protocol xbee stream>> ;

CONSULT: output-stream-protocol xbee stream>> ;

M: xbee in>> stream>> in>> ;
M: xbee out>> stream>> out>> ;

: <xbee> ( stream -- xbee )
    xbee new [ stream<< ] keep ;

: <remote-xbee> ( host port -- xbee )
    <inet> binary <client> drop <xbee> ;

: send-raw ( seq -- )
    >byte-array xbee get [ stream-write ] [ stream-flush ] bi ;

: enter-command-mode ( -- )
    1.1 seconds sleep
    "+++" send-raw
    1.1 seconds sleep ;

: leave-command-mode ( -- )
    "ATCN\r\n" send-raw ;
