USING: accessors arrays assocs combinators concurrency.messaging
       kernel logging math math.parser namespaces
       sequences strings threads vectors xbee xbee.api ;
IN: xbee.dispatcher

SYMBOL: sender-thread
SYMBOL: recipients
SYMBOL: packets
SYMBOL: id

CONSTANT: max-retransmissions 50

! A stored packet is { message retransmissions }

: next-id ( -- id )
    id get 1 + dup 256 = [ drop 1 ] when [ id set ] keep ;

: store-packet ( pkt -- id )
    next-id [ packets get set-nth ] keep ;

: retrieve-packet ( id -- pkt )
    packets get nth ;

: sender ( -- ? )
    receive dup store-packet [ first ] [ >>id ] bi* send-message t ;

: dispatch-retransmission ( message n -- )
    2array sender-thread get send ;

: dispatch ( data dst -- )
    <tx-request> 0 dispatch-retransmission ;

<PRIVATE

: log-debug ( msg id word -- )
    [ ": " append prepend ] dip DEBUG log-message ;

PRIVATE>

: retransmit ( message retransmissions -- )
    1 +
    [ number>string "<retransmission " ">" surround
      swap destination>> \ retransmit log-debug ]
    [ dispatch-retransmission ] 2bi ;

: maybe-retransmit ( id -- )
    retrieve-packet first2 dup max-retransmissions >=
    [
        drop "<retransmission aborted>" swap destination>>
        \ maybe-retransmit log-debug
    ] [
        retransmit
    ] if ;

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
