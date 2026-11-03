10 C=1 : R=255 : G=128 : B=0          : REM ENTRY 1 = ORANGE
20 POKE $D100+C, ((R AND 15)<<4) OR (R>>4)
30 POKE $D200+C, ((G AND 15)<<4) OR (G>>4)
40 POKE $D300+C, ((B AND 15)<<4) OR (B>>4)
