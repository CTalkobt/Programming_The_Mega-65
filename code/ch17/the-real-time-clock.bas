10 RT = $FFD7110
20 S = PEEK(RT) : M = PEEK(RT + 1) : H = PEEK(RT + 2) AND $7F
30 PRINT RIGHT$(HEX$(H), 2); ":"; RIGHT$(HEX$(M), 2); ":"; RIGHT$(HEX$(S), 2)
