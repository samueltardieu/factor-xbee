USING: accessors byte-arrays elec344.xbee.api kernel strings tools.test ;

[ T{ modem-status f 2 } ]
[ B{ HEX: 8a HEX: 2 } frame>message ] unit-test

[ T{ rx f "ST" 48 0 "Foo" } ]
[ B{ HEX: 81 HEX: 53 HEX: 54 HEX: 30 HEX: 0 HEX: 46 HEX: 6f HEX: 6f }
  frame>message [ >string ] change-source [ >string ] change-data ] unit-test

[ T{ rx f "MYSENDER" 20 4 "Foo" } ]
[ B{ HEX: 80 HEX: 4d HEX: 59 HEX: 53 HEX: 45 HEX: 4e HEX: 44 HEX: 45 HEX: 52
     HEX: 14 HEX: 4 HEX: 46 HEX: 6f HEX: 6f }
  frame>message [ >string ] change-source [ >string ] change-data ] unit-test

[ B{ HEX: 7e HEX: 0 HEX: 8 HEX: 1
     HEX: 9 HEX: 53 HEX: 54 HEX: 0 HEX: 46 HEX: 6f HEX: 6f HEX: 2a } ]
[ "Foo" "ST" <tx-request> 9 >>id message>frame ] unit-test

[ B{ HEX: 7e HEX: 0 HEX: e HEX: 0 HEX: 0 HEX: 4d HEX: 59 HEX: 53
     HEX: 45 HEX: 4e HEX: 44 HEX: 45 HEX: 52 HEX: 0
     HEX: 46 HEX: 6f HEX: 6f HEX: 74 } ]
[ "Foo" "MYSENDER" <tx-request> message>frame ] unit-test

[ "Foo" "MYSENDE" <tx-request> message>frame ] [ bad-address? ] must-fail-with
