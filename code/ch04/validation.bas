10 I$ = "030640615" : S = 0
20 FOR J = 1 TO 9 : S = S + J * VAL(MID$(I$, J, 1)) : NEXT
30 C = MOD(S, 11) : C$ = MID$("0123456789X", C + 1, 1)
40 PRINT I$ + C$
