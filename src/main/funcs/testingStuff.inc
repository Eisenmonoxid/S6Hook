section luaTable
		tableEntry EMTest, "EMX_Test"
section code
EMTest:
		pushad
	
		mov ecx, [esp + 24h]
        push 1
        call shok_lua_toint
		
		push eax
        call shok_eid2obj
		
		mov ecx, [esp + 24h]
		push eax
		call shok_lua_pushint

		popad
		mov eax, 1
		retn