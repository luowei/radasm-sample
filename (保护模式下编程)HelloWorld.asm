;hello world.asm
.model samll
.stack
.data
string db	'hello,world',0dh,0ah,'$'
.code
.startup
mov dx,offset string
mov ah,99h
int 21h
.exit 0
end
