;1.
;===========================================================
;在保护模式下32位CPU仍然可以用20位地址来实现32位地址线寻址
;16位CPU: 16位段寄存器+16位偏移地址 (经地址加法器) -> 20位物理内存地址
;32位CPU: 32位地址的内存段信息存入在一张内存表中，只需将表的索引存入16寄存器当中即可
;保存表中索引的段寄存器称为：段选择子
;表中每个表示32位内存段信息称为：段描述符（保存了段的地址和段的长度）。	
;整张表称为：段描述符表
;段选择子16位，其中高13位用来表示描述符表中的索引，其低3位用表示段描述符中所指向的段描述符的属性
;


;启动程序在屏幕中央打印一行字符串
[BITS 16]
org 07c00h	;指明程序开始地址是07c00h,而不是原来 的00000
;int 汇编指令	int 10h
jmp main

gdt_table_start:	;告诉编译器段描述符开始
	;Intel规定描述符表的第一个描述符必须是空描述符
	gdt_null:
		dd 0h
		dd 0h	;Intel规定段描述符表的第一个表项必须为0
	gdt_data_addr	equ	$-gdt_table_start	;数据段的开始位置
	gdt_data：	;数据段描述符
		dw 07ffh ;段界限
		dw 0h	;段基地址18位
		db 10010010b	;段描述符的第六个字节属性（数据段）
		db 1100000b	;段描述符的第七个字节属性
		db 0	;段描述符的最后一个字节也就是段基地址
	
	gdt_video_addr equ $-gdt_table_start
	gdt_video:	;用来描述显存地址空间的段描述符
		dw	0FFH	;显存段界限就是1M
		dw	8000H
		db	0BH
		db	10010010b
		db	11000000b
		db	0
	
	gdt_code_addr	equ	$-gdt_table_start	;代码段的开始位置
	gdt_code:
		dw 07ff	;段界限
		dw 1h	;段基地址0~18位
		db 80h	;段基地址19~23位
		db 10011010b	;段描述符的第六个字节（代码段）
		db 11000000b	;段描述符的第七个字节
		db 0			;段基地址的第二部分
gdt_table_end:
		
		
;通过lgdt指令可以把GDTR描述表的大小和起始地址存入gdtr寄存器中
gdtr_addr:
	dw gdt_table_end-gdt_table_start-1	;段描述表长度
	dd gdt_table_start	;段描述表基地址
;lgdt [gdtr_addr]	;让CPU读取gdtr_addr所指向内存内容保存到gdtr寄存器当中
;A20地址线，切换到保护模式时，A20地址线必须开启。地址回绕作用，放弃32位CPU地址线的高12位。�
;端口的读写操作：
	;in	 accume port	;将端口的内容读到寄存器AL或AX当中，其中accume只能是AL或AX。
	;out port accume	;将accume中的内容写到端口中，这里accume可以是其它寄存器
	
;开启A20地址线
main:
	;修改数据段描述跟段基地址有关的字节，初始化数据段描述符的基地址
	xor eax,eax	;清空eax
	add eax,data_32	;将32位地址信息拷贝到eax中
	mov word [gdt_data+2],ax	;把ax中的内容拷贝到段描述符的第3、4两个字节当中，因是word类型的拷贝�
	shr eax,16	;右移16位
	mov byte [gdt_data+4],al	;将先前eax中的第5个字节移到段描述符当中
	mov byte [gdt_data+7],ah	;将先前eax中的第8个字节移到段描述符当中
	
	;修改代码段描述跟段基地址有关的字节，初始化数据段描述符的基地址
	xor eax,eax
	add eax,code_32
	mov word [gdt_code+2]
	shr eax,16
	mov byte [gdt_code+4],al
	mov byte [gdt_code+7],ah
	
	;在转放保护模式之前，必须废除原来的中断向量表，用cli指令可以废除实模式下的中断向量表
	cli
	lgdt [gdtr_addr]	;让CPU读取gdtr_addr所指向内存内容保存到gdtr寄存器当中

	enable_a20:
		in al,92h	;只要往0x92号端口中写入信息就可以开启A20地址线
		or al,00000010b	;00000010表示开启A20地址线的数据
		out 92h,al		;把设置好的数据写进0x92号端口当中
	
;转入保护模式,只要将CR0寄存器的第1位(PE位)置为1即可
;80386提供了4个32位的控制寄存器CR0~CR3，其中CR0中的某些位是用来标志是否要进入保护模式
;CR1寄存器保留没有被使用
;CR2和CR3用于分页机制
;CR0的PE位控制分段管理机制，PE=0,CPU运行于实模式；PE=1,CPU运行于保护模式
;CR0的PG位控制分段管理机,PG=0，禁止分页管理机制;PG=1，启用分页管理机制。
	mov eax,cr0
	or eax,1	;用于把CR0寄存器的第1置为1
	mov cr0,eax	;把CR0寄存器的第1置为1
;跳转到保护模式中
	jmp gdt_code_addr:0
	
;在保护模式下编程(在屏幕中央打印hello world)
[BITS 32]
	data_32:
		db	"hello world"
	code_32:
		MOV ax,gdt_data_addr
		mov ds,ax
		mov ax,gdt_video_addr
		mov gs,ax
		mov cx,11
		mov edi,(80*10+12)*2	;在屏幕中央显示
		mov bx,0
		mov ah,0ch
		s:mov al,[ds:bx]
		mov [gs:edi]
		mov [gs:edi+1],ah
		inc bx
		add edi,2
		loop s
		jmp $	;死循环
		times 510-($-$$)	db 0
		dw 0aa55h
	
	
	
	
;ok !  ^_^  
;1.启动虚拟机，用nasm boot.asm -o boot.bin 编译	
;2.把程序写到软盘镜像里去，用编译好的写入文件程序写入: ./write_image boot.bin boot.img
;3.将boot.img复制到自己在Bochs-2.4.6目录下建的文件夹下，并修改run.bat
;-----------------------------------------------
;其中write_image.c,可以在rad hat的vi编辑器这样写：�
#include<stdio.h>
#include<fcnt.h>
#include<sys/types.h>
#include<sys/stat.h>

int main(int argc,char *argv[])
{
	int fd_source;
	int fd_dest;
	int read_count=0;
	char buffer[512]={0};
	fd_source=open("boot.bin",O_RDONLY);
	IF(fd_source<0)
	{
		perror("open boot.bin error");
		return 0;
	}
	fd_dest=open("virtual_floppy.vfd",O_WRONLY);
	while ((read_count=read(fd_source,buffer,512))>0)
	{
	write(fd_dest,buffer,read_count);
	memset(buffer,0,512);
	}
	printf("wrinte image OK !");
	return 0;
}
;保存成write_image.c，然后编译：gcc write_image.c -o write_image
;用虚拟软盘制作工具，制作一个虚拟软盘（取名boot.img），最后再用它将引导程序写入boot.img
;  ^_^    ok!
;启动程序有问题的话，可以用bocsh虚拟机对操作系统进行调试。
;===================================================
;bocsh的调试功能bocshdbg
;	continue(c) 程序继续运行直到遇到断点为止
;	step(s)	音步跟踪
;	vbreak(vb)	在虚拟地址上设置一个断点
;	pbreak(b)	在物理地址上设置一个断点
;	lbreak(lb)	在线性地址上设置一个断点
;	disassemble	反汇编指令
;================================================================
;================================================================

;2.	一个在屏幕中央显示一行字符串的引导程(实模式下写)
;启动程序在屏幕中央打印一行字符串

org 07c00h	;指明程序开始地址是07c00h,而不是原来 的00000
;int 汇编指令	int 10h
	mov ax,cs
	mov es,ax
	mov bp,msgstr	;es:bp指向的内容就是我们要显示的字符串地址?
	
	mov cx,12	;字符串长度
	mov dh,12	;显示起始行号
	mov dl,36	;显示的列号
	mov bh,0	;显示的页数，在第0页显示
	mov al,1	;串结构
	mov bl,0c	;黑底红字
	
	msgstr: db "hello my os"
	int 10h		;BIOS中断
	times 510-($-$$) db 0 ;重复N次每次填充值为0
	;因为BIOS的第一个扇区是512字节，当最后两字节是55AA时，它就是引导程序?
	dw 55aaH
	jmp $	;为了不让程序结束，设置一个死循环，不断跳转到当前位置?
	
;在Linux操作系统下，用nasm 进行编译，命令：# nasm boot.asm -o boot.bin
;用 ndisasm boot.bin 可以进行反编译

