10 B = $FFDE800
20 IF (PEEK($D6E0) AND 128) = 0 THEN 20                    : REM WAIT FOR TXIDLE
30 FOR I = 0 TO 5 : POKE B + I, $FF : NEXT                 : REM TO: EVERYONE
40 FOR I = 0 TO 5 : POKE B + 6 + I, PEEK($D6E9 + I) : NEXT : REM FROM: THIS MEGA65
50 POKE B + 12, $88 : POKE B + 13, $B5                     : REM FRAME TYPE
60 FOR I = 14 TO 59 : POKE B + I, 0 : NEXT                 : REM 46 BYTES OF DATA
70 POKE $D6E2, 60 : POKE $D6E3, 0                          : REM LENGTH
80 POKE $D6E4, 1                                           : REM SEND
