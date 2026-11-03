10 PW$ = "" : DO
20 GET A$ : PW$ = PW$ + A$
30 LOOP UNTIL LEN(PW$) > 7 OR A$ = CHR$(13)
