10 POKE $1600, $60                    : REM RTS AT $1600
20 WPOKE $02F8, $1600                 : REM POINT THE USR VECTOR AT IT
30 PRINT USR(42)                      : REM SHOULD PRINT 42
