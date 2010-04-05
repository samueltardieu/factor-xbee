USING: byte-arrays calendar elec344.xbee elec344.xbee.api threads ;
IN: elec344.xbee.api.simple

: send ( data dst -- )
    <tx-request> send-message ;

: send-at ( data command -- )
    <at-command> send-message ;

: set-my ( my -- )
    "MY" send-at ;

: set-retries ( n -- )
    1byte-array "RR" send-at ;

: enter-api-mode ( -- )
    "" "FR" send-at
    2 seconds sleep
    enter-command-mode
    "ATAP1\r\n" send-raw
    1 seconds sleep
    leave-command-mode ;
