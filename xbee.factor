USING: accessors byte-arrays delegate delegate.protocols destructors
       elec344.xbee.api elec344.xbee.api.messages io
       io.encodings.binary io.sockets io.streams.duplex kernel
       namespaces ;
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

: xbee-read1 ( -- c )
    xbee get stream-read1 ;

: xbee-expect1 ( c -- )
    xbee-read1 = [ invalid-packet ] unless ;
