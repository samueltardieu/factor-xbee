USING: arrays assocs concurrency.messaging elec344.xbee kernel namespaces
       sequences strings threads ;
IN: elec344.xbee.dispatcher

SYMBOL: sender-thread
SYMBOL: recipients

: sender ( -- ? )
    receive first2 send-16 t ;

: dispatch-16 ( data dst -- )
    2array sender-thread get send ;

: recipient ( pkt -- id )
    3 head 1 tail >string ;

: content ( pkt -- content )
    5 tail ;

: receiver ( -- ? )
    [ receive-api dup first HEX: 81 = ] [ drop ] until
    dup recipient recipients get at
    [ [ content ] [ send ] bi* ] [ drop ] if* t ;

: register-recipient ( thread-id recipient -- )
    recipients get set-at ;

: unregister-recipient ( recipient -- )
    recipients get delete-at ;

: start-dispatcher ( -- )
    H{ } clone recipients set
    [ sender ] "XBee sender" spawn-server sender-thread set
    [ receiver ] "XBee receiver" spawn-server drop ;
