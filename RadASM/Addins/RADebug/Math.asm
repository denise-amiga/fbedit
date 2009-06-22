
.const

szSHL							db 'SHL',0
szSHR							db 'SHL',0
szAND							db 'AND',0
szOR							db 'OR',0
szXOR							db 'XOR',0
szNOT							db 'NOT',0

.data?

fError							DWORD ?

.code


FUNCSHL							equ 1
FUNCSHR							equ 2
FUNCAND							equ 3
FUNCOR							equ 4
FUNCXOR							equ 5

.const

szFUNC							db 'SHL',0,
								   'SHR',0,
								   'AND',0,
								   'OR',0,
								   'XOR',0,0

szSyntaxError					db 'Syntax error: %s',0
szVariableNotFound				db 'Variable not found: %s',0

.code

GetFunc proc uses ebx esi edi
	LOCAL	buffer[256]:BYTE
	LOCAL	nFunc:DWORD
	LOCAL	nLen:DWORD

	mov		al,[esi]
	.if al<'A'
		jmp		Ex
	.endif
	lea		edi,buffer
	xor		ecx,ecx
	mov		nFunc,ecx
	.while TRUE
		mov		al,[esi+ecx]
		.if (al>='A' && al<='Z') || (al>='a' && al<='z')
			mov		[edi+ecx],al
		.else
			xor		eax,eax
			.break
		.endif
		inc		ecx
	.endw
	mov		[edi+ecx],al
	mov		ebx,offset szFUNC
	lea		edi,buffer
	.while byte ptr [ebx]
		inc		nFunc
		push	ecx
		invoke lstrcmpi,ebx,edi
		pop		ecx
		.if !eax
			mov		eax,nFunc
			jmp		Ex
		.endif
		push	ecx
		invoke lstrlen,ebx
		pop		ecx
		lea		ebx,[ebx+eax+1]
	.endw
	mov		al,[esi]
  Ex:
	ret

GetFunc endp

; esi is a pointer to the value
GetValue proc uses ebx edi
	LOCAL	buffer[256]:BYTE
	LOCAL	nLen:DWORD

	push	esi
	mov		nLen,0
	lea		edi,buffer
	.while TRUE
		mov		al,[esi]
		.if (al>='0' && al<='9') || (al>='A' && al<='Z') || (al>='a' && al<='z')
			mov		[edi],al
			inc		edi
			inc		esi
			inc		nLen
		.else
			.break
		.endif
	.endw
	mov		byte ptr [edi],0
	lea		edi,buffer
	mov		al,[edi]
	.if al>='0' && al<='9'
		; Hex or Decimal
		invoke IsDec,edi
		.if eax
			invoke DecToBin,edi
			jmp		Ex
		.else
			invoke IsHex,edi
			.if eax
				invoke HexToBin,edi
				jmp		Ex
			.endif
		.endif
		mov		nError,1
		invoke strcpy,addr szError,addr buffer
		xor		eax,eax
		jmp		Ex
	.else
		; Variable
		.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
			inc		esi
			inc		nLen
		.endw
		.if byte ptr [esi]=='('
			lea		edi,buffer
			invoke lstrlen,edi
			lea		edi,[edi+eax]
			xor		ecx,ecx
			.while byte ptr [esi]
				mov		al,[esi]
				.if al!=VK_SPACE && al!=VK_TAB
					mov		[edi],al
					inc		edi
				.endif
				inc		esi
				inc		nLen
				.if al=='('
					inc		ecx
				.elseif al==')'
					dec		ecx
					.break .if ZERO?
				.endif
			.endw
			mov		byte ptr [edi],0
		.endif
		push	mFunc
		invoke GetVarVal,addr buffer,dbg.prevline,FALSE
		pop		mFunc
		.if eax
			.if !mFunc
				mov		mFunc,eax
			.endif
			mov		eax,var.Value
			jmp		Ex
		.else
			mov		nError,2
			invoke strcpy,addr szError,addr buffer
			xor		eax,eax
			jmp		Ex
		.endif
	.endif
  Ex:
	pop		esi
	add		esi,nLen
	ret

GetValue endp

; esi is a pointer to the math
CalculateIt proc uses ebx edi,PrevFunc:DWORD

  Nxt:
  	.if nError
  		ret
  	.endif
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	push	eax
	invoke GetFunc
	mov		edx,ecx
	movzx	ecx,al
	pop		eax
	mov		ebx,PrevFunc
	.if !ecx
		ret
	.elseif ecx==FUNCSHL
		mov		mFunc,'H'
		lea		esi,[esi+edx]
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		shl		eax,cl
	.elseif ecx==FUNCSHR
		mov		mFunc,'H'
		lea		esi,[esi+edx]
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		shr		eax,cl
	.elseif ecx==FUNCAND
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx=='+' || ebx=='-' || ebx==FUNCSHL || ebx==FUNCSHR
			ret
		.endif
		lea		esi,[esi+edx]
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		and		eax,ecx
	.elseif ecx==FUNCOR
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx=='+' || ebx=='-' || ebx==FUNCSHL || ebx==FUNCSHR || ebx==FUNCAND
			ret
		.endif
		lea		esi,[esi+edx]
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		or		eax,ecx
	.elseif ecx==FUNCXOR
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx=='+' || ebx=='-' || ebx==FUNCSHL || ebx==FUNCSHR || ebx==FUNCAND || ebx==FUNCOR
			ret
		.endif
		lea		esi,[esi+edx]
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		xor		eax,ecx
	.elseif ecx=='('
		mov		mFunc,'H'
		inc		esi
		invoke CalculateIt,ecx
	.elseif ecx==')'
		mov		mFunc,'H'
		inc		esi
		ret
	.elseif ecx=='+'
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx==FUNCSHL || ebx==FUNCSHR
			ret
		.endif
		inc		esi
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		add		eax,ecx
	.elseif ecx=='-'
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx==FUNCSHL || ebx==FUNCSHR
			ret
		.endif
		inc		esi
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xchg	eax,ecx
		sub		eax,ecx
	.elseif ecx=='*'
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx==FUNCSHL || ebx==FUNCSHR
			ret
		.endif
		inc		esi
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		mul		ecx
	.elseif ecx=='/'
		mov		mFunc,'H'
		.if ebx=='*' || ebx=='/' || ebx==FUNCSHL || ebx==FUNCSHR
			ret
		.endif
		inc		esi
		push	eax
		invoke CalculateIt,ecx
		pop		ecx
		xor		edx,edx
		xchg	eax,ecx
		div		ecx
	.else
		push	esi
		invoke GetValue
		pop		edx
		.if esi==edx
			mov		nError,1
			ret
		.endif
	.endif
	jmp		Nxt

CalculateIt endp

DoMath proc uses ebx esi edi,lpMath:DWORD

	mov		nError,0
	mov		mFunc,0
	mov		esi,lpMath
	xor		eax,eax
	invoke CalculateIt,0
	.if !nError
		mov		var.Value,eax
		.if mFunc=='H'
			invoke wsprintf,offset outbuffer,addr szValue,var.Value,var.Value
		.else
			invoke FormatOutput,addr outbuffer
		.endif
		mov		eax,TRUE
		jmp		Ex
	.elseif nError==1
		invoke wsprintf,offset outbuffer,addr szSyntaxError,addr szError
	.elseif nError==2
		invoke wsprintf,offset outbuffer,addr szVariableNotFound,addr szError
	.endif
	xor		eax,eax
  Ex:
	ret

DoMath endp
