USING: accessors byte-arrays elec344.xbee.api.messages kernel strings tools.test ;

[ T{ modem-status f 2 } ]
[ B{ HEX: 8a HEX: 2 } frame>message ] unit-test

[ T{ rx f "ST" 48 0 "Foo" } ]
[ B{ HEX: 81 HEX: 53 HEX: 54 HEX: 30 HEX: 0 HEX: 46 HEX: 6f HEX: 6f }
  frame>message [ >string ] change-source [ >string ] change-data ] unit-test

[ T{ rx f "MYSENDER" 20 4 "Foo" } ]
[ B{ HEX: 80 HEX: 4d HEX: 59 HEX: 53 HEX: 45 HEX: 4e HEX: 44 HEX: 45 HEX: 52
     HEX: 14 HEX: 4 HEX: 46 HEX: 6f HEX: 6f }
  frame>message [ >string ] change-source [ >string ] change-data ] unit-test
