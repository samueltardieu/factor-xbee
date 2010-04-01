USING: arrays assocs combinators concurrency.messaging
       elec344.challenge.logging elec344.xbee kernel math math.parser
       namespaces sequences strings threads vectors ;
IN: elec344.xbee.dispatcher

SYMBOL: sender-thread
SYMBOL: recipients
SYMBOL: packets
SYMBOL: id

: next-id ( -- id )
    id get 1 + dup 256 = [ drop 1 ] when [ id set ] keep ;

: store-packet ( pkt -- id )
    next-id [ packets get set-nth ] keep ;

: retrieve-packet ( id -- pkt )
    packets get nth ;

: sender ( -- ? )
    receive [ first2 ] [ store-packet ] bi send-16-id t ;

: dispatch-16 ( data dst -- )
    2array sender-thread get send ;

: retransmit ( id -- )
    [ retrieve-packet first2 ]
    [ number>string "<retransmitting packet " ">" surround ] bi
    swap [ dispatch-16 ] [ log-for ] bi-curry bi* ;

: recipient ( pkt -- id )
    3 head 1 tail >string ;

: content ( pkt -- content )
    5 tail ;

: check-for-negative-ack ( pkt -- )
    dup third 1 = [ second retransmit ] [ drop ] if ;

: receive-data-packet ( -- pkt ? )
    receive-api dup first
    {
        { HEX: 81 [ t ] }
        { HEX: 89 [ dup check-for-negative-ack f ] }
        [ drop f ]
    } case ;

: receiver ( -- ? )
    [ receive-data-packet ] [ drop ] until
    dup recipient recipients get at
    [ [ content ] [ send ] bi* ] [ drop ] if* t ;

: register-recipient ( thread-id recipient -- )
    recipients get set-at ;

: unregister-recipient ( recipient -- )
    recipients get delete-at ;

: start-dispatcher ( -- )
    H{ } clone recipients set
    0 id set
    256 f <array> >vector packets set
    [ sender ] "XBee sender" spawn-server sender-thread set
    [ receiver ] "XBee receiver" spawn-server drop ;
