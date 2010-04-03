USING: byte-arrays kernel math make sequences ;
IN: elec344.xbee.api

: ,2 ( word -- )
    256 /mod [ , ] bi@ ;

: checksum ( data -- c )
    sum 255 bitand 255 bitxor ;

: make-frame ( data -- frame )
    [ HEX: 7e , [ length ,2 ] [ % ] [ checksum , ] tri ] B{ } make ;
