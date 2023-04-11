%include 'globals.inc'

bits 32
section text
org 0							 ; NO FIXED BASE; USE POSITION INDEPENDENT CODE

stage2:
		add esp, 16				; restore stack so that 
								; retn 4 takes us back to the
								; caller of the faked eObj->Destroy() call
								
		
		pop ecx					; restore entity obj this ptr 
								; saved by stage1 asciiPre
								
		mov dword [ecx], 92621Ch; restore vtbl ptr
		mov edx, [ecx]
		push 0					
		call [edx+1Ch]			; call original eObj->Destroy(0)
		
		mov ebx, [esp+8]		; luaState
		
		push eax				; dummy create space on stack for temp value
		mov ebp, esp			; ptr to tempValue
		
		cmp byte [hookAllocdFlag], 0
		jnz .copyPayload
		
		mfence
		clflush [hookBase]
		
		push 4h					; R/W
		push 2000h				; reserve 
		push hookAllocSize
		push hookBase
		call [virtualAlloc]
		
		push 4h					; R/W
		push 1000h				; commit
		push hookAllocSize
		push hookBase
		call [virtualAlloc]
		test eax, eax
		jz .abort
		
		mfence
		clflush [hookBase]
								; get write permissions for .text
		push ebp				; ptr to temp val
		push 40h				; new access: R/W/X
		push 4F5000h			; length
		push 401000h			; start of segment (.text, .rdata, etc...)
		call findVirtualProtect	
		call eax				; call VirtualProtect(...)
		test eax, eax
		jz .abort
				
		mov byte [hookAllocdFlag], 1
		
.copyPayload:	
		
		push ebp				; &tempValue = size of string
		push 3					; lua arg3 = main S6Hook payload
		push ebx
		call [lua_tolstring]
		add esp, 0Ch
		
		mfence
		clflush [hookBase]
		
		mov esi, eax			; copy source = lua string
		mov edi, hookBase		; copy destination
		mov ecx, [ebp]			; S6Hook size
		rep movsb				; repeate byte move ecx times
		
		mov eax, hookBase
		call eax				; run payload
		
.abort:
		pop eax					; remove tempValue
		retn 4
		
findVirtualProtect:
		push 0
		push 'el32'
		push 'kern'
		push esp
		call [loadLibraryA]		; eax = LoadLibraryA("kernel32")
		
		push 7463h		; 'ct\0\0'
		push 'rote'
		push 'ualP'
		push 'Virt'
		push esp
		push eax
		call [getProcAddress]	; eax = GetProcAddress(eax, "VirtualProtect")
		add esp, 28
		
		retn
		