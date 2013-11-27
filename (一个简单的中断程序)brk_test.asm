DATAS SEGMENT
    ;此处输入数据段代码  
DATAS ENDS

STACKS SEGMENT
    ;此处输入堆栈段代码
STACKS ENDS

CODES SEGMENT
    ASSUME CS:CODES,DS:DATAS,SS:STACKS
START:
    MOV AX,DATAS
    MOV DS,AX
    ;除0中断
    mov ax,1000h  	;ax当作被除数
    mov bh,1		;bx除数
    div bh			;因AX是16位，bh为1，结果仍是16位，产生除法溢出错误
    ;除数为8位时，被除数存储在AX，结果：AL存储除法的商，AH存储除法的余数
    ;除数为16位时，被除数存储在DX+AX中，结果：AX存储商，DX存储余数
    
    MOV AH,4CH
    INT 21H
CODES ENDS
    END START
