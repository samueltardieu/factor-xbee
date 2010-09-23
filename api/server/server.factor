USING: accessors combinators.short-circuit concurrency.mailboxes
       xbee.api fry kernel math namespaces threads ;
IN: xbee.api.server

SYMBOL: receiver-mailbox*

: receiver-mailbox ( -- mailbox )
    receiver-mailbox* get ;

<PRIVATE

SYMBOL: id

: next-id ( -- id )
    id get dup 255 = [ drop 1 ] [ 1 + ] if [ id set ] keep ;

SYMBOL: sender-mailbox*

: sender ( -- )
    [ sender-mailbox* get mailbox-get send-message t ] loop ;

: receiver ( -- )
    [ receive-message receiver-mailbox mailbox-put t ] loop ;

: receive-one ( pred -- message )
    [ receiver-mailbox ] dip mailbox-get? ; inline

PRIVATE>

: receive ( -- message )
    receiver-mailbox mailbox-get ;

: receive-rx ( -- message )
    [ rx? ] receive-one ;

: receive-id ( id -- message )
    '[ dup { [ tx-status? ] [ at-response? ] [ remote-at-response? ] } 1||
       [ id>> _ = ] [ drop f ] if ] receive-one ;

: send ( message -- )
    sender-mailbox* get mailbox-put ;

: send-id ( message -- id )
    next-id [ >>id send ] keep ;

: send-synchronous ( message -- message' )
    send-id receive-id ;

: start-server ( -- )
    0 id set
    <mailbox> sender-mailbox* set-global
    <mailbox> receiver-mailbox* set-global
    [ receiver ] "XBee receiver" spawn drop
    [ sender ] "XBee sender" spawn drop ;
