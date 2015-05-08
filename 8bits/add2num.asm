; 输出两个空字符，使得打印机切换到左轮
W1:
    JNPB W1
    MOV A,#AH
    STA 8002H
W2:
    JNPB W2
    STA 8002H
; 读入R2
L2:
    JNKB L2
    LDA 8001H
    MOV R2,A
; 读入R1
L1:
    JNKB L1
    LDA 8001H
    MOV R1,A
; 输出R1
WL1:
    JNPB WL1
    STA 8002H
; 输出R2并换行
WL2:
    JNPB WL2
    MOV A,R2
    MOV R0,#10H
    ADD A,R0
    STA 8002H
; 输出加号并换行
WADD:
    JNPB WADD
    MOV A,#10H
    STA 8002H
; 输出两个空字符，使得打印机切换到左轮
WADD1:
    JNPB WADD1
    MOV A,#AH
    STA 8002H
WADD2:
    JNPB WADD2
    STA 8002H
; 读入R4
L4:
    JNKB L4
    LDA 8001H
    MOV R4,A
; 读入R3
L3:
    JNKB L3
    LDA 8001H
    MOV R3,A
; 输出R3
W3:
    JNPB W3
    STA 8002H
; 输出R4并换行
W4:
    JNPB W4
    MOV A,R4
    MOV R0,#10H
    ADD A,R0
    STA 8002H
; 输出等号并换行
WEQ:
    JNPB WEQ
    MOV A,#19H
    STA 8002H
; 输出两个空字符，使得打印机切换到左轮
WEQ1:
    JNPB WEQ1
    MOV A,#AH
    STA 8002H
WEQ2:
    JNPB WEQ2
    STA 8002H
; R6 = R2 + R4
    MOV A,R4
    ADD A,R2
    MOV R6,A
; R5 = R1 + R3
    MOV A,R1
    ADD A,R3
    MOV R5,A
; 若 R5 - 10 >= 0 则向R6进位
    MOV R0, #AH
    SUB A,R0
    JC Z1
 
    MOV R5,A
    MOV R0,#1H
    MOV A,R6
    ADD A,R0
    MOV R6,A
; 若 R6 - 10 >= 0 则向R7进位
Z1:
    MOV R0,#AH
    MOV A,R6
    SUB A,R0
    JC Z2
 
    MOV R6,A
    MOV R7,#1H
Z2:
; 输出R5
W5:
    JNPB W5
    MOV A,R5
    STA 8003H
; 输出R6
W6:
    JNPB W6
    MOV A,R6
    STA 8003H
; 输出R7并换行
W7:
    JNPB W7
    MOV A,R7
    MOV R0,#10H
    ADD A,R0
    STA 8003H
 
LOOP:
    JMP LOOP
