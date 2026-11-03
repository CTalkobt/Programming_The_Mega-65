10 A$ = "PROGRAMMING THE MEGA65"
20 R$ = "" : FOR I = LEN(A$) TO 1 STEP -1 : R$ = R$ + MID$(A$, I, 1) : NEXT : PRINT R$
30 W = 0 : P = 1
40 DO : P = INSTR(A$, " ", P) : IF P = 0 THEN EXIT
50 W = W + 1 : P = P + 1 : LOOP
60 PRINT W + 1; "WORDS"
70 MID$(A$, 13, 3) = "OUR" : PRINT A$
80 PRINT INSTR(A$, "MEGA")
