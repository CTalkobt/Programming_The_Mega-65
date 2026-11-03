10 A$ = "MEGA65"
20 PRINT LEFT$(A$, 4); " "; MID$(A$, 3, 2); " "; RIGHT$(A$, 2)
30 MID$(A$, 4, 1) = "@" : PRINT A$ : REM MEG@65
