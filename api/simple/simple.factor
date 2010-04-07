USING: byte-arrays elec344.xbee elec344.xbee.api ;
IN: elec344.xbee.api.simple

: send ( data dst -- )
    <tx-request> send-message ;

: send-at ( data command -- )
    <at-command> send-message ;

: set-my ( my -- )
    "MY" send-at ;

: set-retries ( n -- )
    1byte-array "RR" send-at ;
