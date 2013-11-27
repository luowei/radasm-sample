data segment
	msg db "hello world"
data ends

code segment
	assume cs:code,ds:data
main proc near
	start:	;获取代码段的偏移地址
	mov ax,data ;将数据段存到ds当中
	mov ds,ax

	mov bx,0b800h	;将显存地址空间的起始地址，拷贝到附加段中
	mov es,bx

	mov cx,11d
	mov si,0
	mov bx,0
	;---------字体属性----------
	;|  7   6 5 4   3   2 1 0  |
	;| B L  R G B   I   R G B  |
	;| 闪烁 背景色 高亮 前景色 |
	;--------------------------
	mov ah,10100100b ;绿底红字
	s:mov al,ds:[si] ;拷贝字符
	mov es:[bx],al
	mov es:[bx+1],ah ;拷贝字符属性
	inc si
	add bx,2
	loop s

	mov ax,4c00h
	int 21h
	ret
main endp
code ends
	end start




