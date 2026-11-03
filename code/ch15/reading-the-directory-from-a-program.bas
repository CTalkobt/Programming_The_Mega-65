10 DIM N$(143), T$(143), B(143) : C = -1
20 OPEN 1, 8, 0, "$"
30 GET#1, A$, A$                    : REM SKIP THE LOAD ADDRESS
40 DO
50 GET#1, A$, A$ : IF ST THEN EXIT   : REM LINK; END OF DIRECTORY
60 GET#1, L$, H$ : BL = ASC(L$) + 256 * ASC(H$)
70 L$ = ""
80 DO
90 GET#1, A$ : IF ASC(A$) THEN L$ = L$ + A$
100 LOOP WHILE ASC(A$)
110 Q = INSTR(L$, CHR$(34)) : IF Q = 0 THEN FR = BL : EXIT
120 R = INSTR(L$, CHR$(34), Q + 1)
130 C = C + 1 : N$(C) = MID$(L$, Q + 1, R - Q - 1) : B(C) = BL
140 F$ = MID$(L$, R + 1)
150 DO WHILE LEFT$(F$, 1) = " " : F$ = MID$(F$, 2) : LOOP
160 T$(C) = F$
170 LOOP
180 CLOSE 1
190 PRINT "DISK: "; N$(0); "  ID: "; T$(0)
200 FOR I = 1 TO C : PRINT N$(I), LEFT$(T$(I), 3), B(I) : NEXT
210 PRINT C; "FILES,"; FR; "BLOCKS FREE"
