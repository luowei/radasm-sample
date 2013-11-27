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
    ;系统默认在内存0000:000到0000:03FE专门存放中断向量表
    ;第一步：把中断向量表中0号表项的内容进行修改，
    ;指向我们自己指定的中断处理程序的入口地址
    mov ax,0
    mov ds,ax
    ;中断向量表每个表项占四个字节，低字节放偏移地址，高字节放段地址
    mov word ptr ds:[0],0200h
    mov word ptr ds:[2],0
    
    ;第三步，把自己写的0号中断处理程序拷贝到中断向量表在0号表项
    ;所指向的内存地址中0000:0200
    ;设置程序的源地址，源地址由DS:SI组成，目的地址由ES:DI组成 
    mov ax,cs
    mov ds,ax
    mov si,offset int0	;程序所在地址，即源地址：ds:si
    mov ax,0
    mov es,ax			;设置目的地址
    mov di,200h
    mov cx,offset int0end-offset int0
    ;CLD指令设置数据拷贝方向是从低字节向高字节，si,di自动增量，STD相反
    cld
    rep movsb
    ;第四步，利用代码自动引发0号中断处理程序
    mov ax,100h
    mov bh,1
    div bh	;除数为1，产生除法溢出错误，中断！调用自己写的中断程序
    
    
    ;第二步：编写自己的中断处理程序，实现在屏幕中央显示字符串的功能
    int0:jmp short int0start	;这行代码占两个字节 
    	db "I am student !"
    int0start:mov ax,0b800h
    mov es,ax	;配置显存首地址
    ;要把"I am student !"一个拷贝到显存地址空间中
    mov ax,cs	;把代码段中的内容送到数据段当中去
    mov ds,ax	;0中断程序没区分代码段和数据段
    
    mov si,202h	;因jump short int0start占两字节
    mov di,12*160+36*2	
    ;一个屏幕最大是24行、80列，每行80个字，36是中央偏左一点 
    
    mov cx,14	;"I am student !" 点14个字节
    
	;---------字体属性----------
	;|  7   6 5 4   3   2 1 0  |
	;| B L  R G B   I   R G B  |
	;| 闪烁 背景色 高亮 前景色 |
	;---------------------------
  	mov ah,10100100b ;绿底红字
  s:mov al,byte ptr ds:[si]	;将第一个字符存到al中
  	mov es:[di],al	;拷贝字符
  	mov es:[di+1],ah ;拷贝字符属性
  	inc si		;源地址指针后移1个字符
  	add di,2	;显存地址加2字节
  	loop s
       
    MOV AH,4CH
    INT 21H
  int0end:nop  ;nop是空操作指令，占一个字节
  
CODES ENDS
    END START






