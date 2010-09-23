USING: byte-arrays xbee xbee.api ;
IN: xbee.api.simple

: send ( data dst -- )
    <tx-request> send-message ;

: send-at ( data command -- )
    <at-command> send-message ;

: set-my ( my -- )
    "MY" send-at ;

: set-retries ( n -- )
    1byte-array "RR" send-at ;
