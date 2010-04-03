USING: accessors arrays assocs combinators concurrency.messaging
       elec344.challenge.logging elec344.xbee elec344.xbee.api.messages
       kernel math math.parser namespaces sequences strings threads vectors ;
IN: elec344.xbee.dispatcher

SYMBOL: sender-thread
SYMBOL: recipients
SYMBOL: packets
SYMBOL: id

CONSTANT: max-retransmissions 50

! A store packet is { pkt dst retransmissions }

: next-id ( -- id )
    id get 1 + dup 256 = [ drop 1 ] when [ id set ] keep ;

: store-packet ( pkt -- id )
    next-id [ packets get set-nth ] keep ;

: retrieve-packet ( id -- pkt )
    packets get nth ;

: sender ( -- ? )
    receive [ first2 ] [ store-packet ] bi send-16-id t ;

: dispatch-16-retransmissions ( data dst n -- )
    3array sender-thread get send ;

: dispatch-16 ( data dst -- )
    0 dispatch-16-retransmissions ;

: retransmit ( data dst retransmissions -- )
    1 +
    [ number>string "<retransmission " ">" surround swap log-for ]
    [ dispatch-16-retransmissions ] 2bi ;

: maybe-retransmit ( id -- )
    retrieve-packet first3 dup max-retransmissions >=
    [ drop nip "<retransmission aborted>" swap log-for ] [ retransmit ] if ;

: check-for-negative-ack ( pkt -- )
    dup status>> no-ack = [ id>> maybe-retransmit ] [ drop ] if ;

: receive-data-packet ( -- pkt ? )
    receive-message
    {
        { [ dup rx? ] [ t ] }
        { [ dup tx-status? ] [ dup check-for-negative-ack f ] }
        [ f ]
    } cond ;

: receiver ( -- ? )
    [ receive-data-packet ] [ drop ] until
    dup source>> >string recipients get at
    [ [ data>> >string ] [ send ] bi* ] [ drop ] if* t ;

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
