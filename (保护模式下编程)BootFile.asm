;Æô¶¯³ÌÐòÔÚÆÁÄ»ÖÐÑë´òÓ¡Ò»ÐÐ×Ö·û´®

org 07c00h	;Ö¸Ã÷³ÌÐò¿ªÊ¼µØÖ·ÊÇ07c00h,¶ø²»ÊÇÔ­À´ µÄ00000
;int »ã±àÖ¸Áî	int 10h
	mov ax,cs
	mov es,ax
	mov bp,msgstr	;es:bpÖ¸ÏòµÄÄÚÈÝ¾ÍÊÇÎÒÃÇÒªÏÔÊ¾µÄ×Ö·û´®µØÖ·®
	
	mov cx,12	;×Ö·û´®³¤¶È
	mov dh,12	;ÏÔÊ¾ÆðÊ¼ÐÐºÅ
	mov dl,36	;ÏÔÊ¾µÄÁÐºÅ
	mov bh,0	;ÏÔÊ¾µÄÒ³Êý£¬ÔÚµÚ0Ò³ÏÔÊ¾
	mov al,1	;´®½á¹¹
	mov bl,0c	;ºÚµ×ºì×Ö
	
	msgstr: db "hello my os"
	int 10h		;BIOSÖÐ¶Ï
	times 510-($-$$) db 0 ;ÖØ¸´N´ÎÃ¿´ÎÌî³äÖµÎª0
	;ÒòÎªBIOSµÄµÚÒ»¸öÉÈÇøÊÇ512×Ö½Ú£¬µ±×îºóÁ½×Ö½ÚÊÇ55AAÊ±£¬Ëü¾ÍÊÇÒýµ¼³ÌÐò¬
	dw 55aaH
	jmp $	;ÎªÁË²»ÈÃ³ÌÐò½áÊø£¬ÉèÖÃÒ»¸öËÀÑ­»·£¬²»¶ÏÌø×ªµ½µ±Ç°Î»ÖÃ£
	
;ÔÚLinux²Ù×÷ÏµÍ³ÏÂ£¬ÓÃnasm ½øÐÐ±àÒë£¬ÃüÁî£º# nasm boot.asm -o boot.bin
;ÓÃ ndisasm boot.bin ¿ÉÒÔ½øÐÐ·´±àÒë
