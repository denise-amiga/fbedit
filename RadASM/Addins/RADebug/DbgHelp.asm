
SOURCEFILE struct DWORD
	ModBase					QWORD ?
	FileName				DWORD ?
SOURCEFILE ends

SRCCODEINFO struct DWORD
	SizeOfStruct            DWORD ?
	Key                     PVOID ?
	ModBase                 QWORD ?
	Obj         			BYTE MAX_PATH+1 dup(?)
	FileName				BYTE MAX_PATH+1 dup(?)
	LineNumber              DWORD ?
	Address                 DWORD ?
SRCCODEINFO ends

SYMBOL_INFO struct QWORD
	SizeOfStruct			DWORD ?
	TypeIndex				DWORD ?
	Reserved				QWORD 2 dup(?)
	Index					DWORD ?
	nSize					DWORD ?
	ModBase					QWORD ?
	Flags					DWORD ?
	Value					QWORD ?
	Address					QWORD ?
	Register				DWORD ?
	Scope					DWORD ?
	Tag						DWORD ?
	NameLen					DWORD ?
	MaxNameLen				DWORD ?
	szName					BYTE ?
SYMBOL_INFO ends

.const

szSymInitialize					db 'SymInitialize',0
szSymLoadModule					db 'SymLoadModule',0
szSymGetModuleInfo				db 'SymGetModuleInfo',0
szSymEnumerateSymbols			db 'SymEnumerateSymbols',0
szSymEnumTypes					db 'SymEnumTypes',0
szSymEnumSourceFiles			db 'SymEnumSourceFiles',0
szSymEnumSourceLines			db 'SymEnumSourceLines',0
szSymFromAddr					db 'SymFromAddr',0
szSymUnloadModule				db 'SymUnloadModule',0
szSymCleanup					db 'SymCleanup',0
szSymSetContext					db 'SymSetContext',0
szSymEnumTypesByName			db 'SymEnumTypesByName',0

szVersionInfo					db '\StringFileInfo\040904B0\FileVersion',0
szVersion						db 'DbgHelp version %s',0
szSymOk							db 'Symbols OK',0
szSymbol						db 'Name: %s Adress: %X Size %u',0
szSourceFile					db 'FileName: %s',0
szSourceLine					db 'FileName: %s Adress: %X Line %u',0
szSymLoadModuleFailed			db 'SymLoadModule failed.',0
szSymInitializeFailed			db 'SymInitialize failed.',0
szFinal							db 'DbgHelp found %u source files containing %u lines and %u symbols,',0Dh,0
szDbgHelpFail					db 'Could not find DbgHelp.dll',0

.data?

dwModuleBase					DWORD ?
im								IMAGEHLP_MODULE <>
nErrors							DWORD ?

.code

GetDbgHelpVersion proc
	LOCAL	buffer[2048]:BYTE
	LOCAL	lpbuff:DWORD
	LOCAL	lpsize:DWORD

	invoke GetFileVersionInfo,addr DbgHelpDLL,NULL,sizeof buffer,addr buffer
	.if eax
		invoke VerQueryValue,addr buffer,addr szVersionInfo,addr lpbuff,addr lpsize
		.if eax
			mov		eax,lpbuff
			invoke wsprintf,addr buffer,addr szVersion,eax
			invoke PutString,addr buffer
		.endif
	.endif
	ret

GetDbgHelpVersion endp

FindWord proc uses esi,lpWord:DWORD

	mov		edx,lpData
	;Get pointer to word list
	mov		esi,[edx].ADDINDATA.lpWordList
	;Skip the words loaded from .api files
	add		esi,[edx].ADDINDATA.rpProjectWordList
	;Loop trough the word list
	.while [esi].PROPERTIES.nSize
		call	TestWord
		.if eax
			mov		eax,esi
			jmp		Ex			
		.endif
		;Move to next word
		mov		eax,[esi].PROPERTIES.nSize
		lea		esi,[esi+eax+sizeof PROPERTIES]
	.endw
	xor		eax,eax
  Ex:
	ret

TestWord:
	lea		ecx,[esi+sizeof PROPERTIES]
	mov		edx,lpWord
	.if [esi].PROPERTIES.nType=='p'
		invoke strcmp,ecx,edx
		.if !eax
			inc		eax
			retn
		.endif
		xor		eax,eax
	.else
		.while TRUE
			mov		al,[ecx]
			mov		ah,[edx]
			.if !ah
				.if al!='[' && al!=':'
					xor		eax,eax
				.endif
				retn
			.elseif al!=ah
				xor		eax,eax
				retn
			.endif
			inc		ecx
			inc		edx
		.endw
	.endif
	retn

FindWord endp

AddPredefinedTypes proc uses esi edi

	; Datatypes
	mov		esi,offset datatype
	.while [esi].DATATYPE.lpszType
		mov		eax,dbg.inxtype
		mov		edx,sizeof DEBUGTYPE
		mul		edx
		mov		edi,dbg.hMemType
		lea		edi,[edi+eax]
		invoke strcpy,addr [edi].DEBUGTYPE.szName,[esi].DATATYPE.lpszType
		movzx	eax,[esi].DATATYPE.nSize
		mov		[edi].DEBUGTYPE.nSize,eax
		inc		dbg.inxtype
		lea		esi,[esi+sizeof DATATYPE]
	.endw
	ret

AddPredefinedTypes endp

AddConstants proc uses esi edi
	LOCAL	lpszName:DWORD
	LOCAL	buffer[256]:BYTE

	; Constants from RadASM, case sensitive
	mov		edx,lpData
	;Get pointer to word list
	mov		esi,[edx].ADDINDATA.lpWordList
	; Loop trough the word list
	.while [esi].PROPERTIES.nSize
		.if [esi].PROPERTIES.nType=='c' || [esi].PROPERTIES.nType=='R'
			; Found
			push	esi
			lea		edi,[esi+sizeof PROPERTIES]
			mov		lpszName,edi
			invoke strlen,edi
			lea		edi,[edi+eax+1]
			mov		eax,[edi]
			and		eax,0FF5F5F5Fh
			.if eax==' UQE'
				lea		edi,[edi+4]
			.endif
			invoke strcpy,addr buffer,edi
			lea		esi,buffer
			mov		nError,0
			invoke CalculateIt,0
			.if !nError
				push	eax
				mov		eax,dbg.inxtype
				mov		edx,sizeof DEBUGTYPE
				mul		edx
				mov		edi,dbg.hMemType
				lea		edi,[edi+eax]
				invoke strcpy,addr [edi].DEBUGTYPE.szName,lpszName
				pop		eax
				mov		[edi].DEBUGTYPE.nSize,eax
				inc		dbg.inxtype
;			.else
;				invoke wsprintf,addr outbuffer,addr szErrConstant,addr buffer
;				invoke PutString,addr outbuffer
			.endif
			pop		esi
		.endif
		;Move to next word
		mov		eax,[esi].PROPERTIES.nSize
		lea		esi,[esi+eax+sizeof PROPERTIES]
	.endw
  Ex:
	ret

AddConstants endp

AddVar proc uses ebx esi edi,lpName:DWORD,nSize:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	lpArray:DWORD
	LOCAL	lpType:DWORD
	LOCAL	fErrArray:DWORD
	LOCAL	fErrType:DWORD

	mov		lpArray,0
	mov		lpType,0
	mov		fErrArray,0
	mov		fErrType,0
	mov		esi,lpName
	lea		edi,buffer
	.while TRUE
		mov		al,[esi]
		.if al=='['
			mov		byte ptr [edi],0
			inc		edi
			mov		lpArray,edi
			mov		[edi],al
			inc		edi
		.elseif al==':'
			mov		byte ptr [edi],0
			inc		edi
			mov		lpType,edi
			mov		[edi],al
			inc		edi
		.elseif al
			mov		[edi],al
			inc		edi
		.else
			xor		eax,eax
			mov		[edi],ax
			.break
		.endif
		inc		esi
	.endw
	mov		edi,dbg.lpvar
	; Add name
	invoke strcpy,addr [edi+sizeof DEBUGVAR],addr buffer
	invoke strlen,addr buffer
	lea		ebx,[eax+1]
	.if lpArray
		invoke strcpy,addr [edi+ebx+sizeof DEBUGVAR],lpArray
		invoke strlen,lpArray
		lea		ebx,[ebx+eax]
		add		eax,lpArray
		mov		byte ptr [eax-1],0
	.endif
	.if lpType
		mov		eax,lpType
		inc		eax
		invoke GetPredefinedDatatype,eax
		.if eax
			push	eax
			invoke strcpy,addr [edi+ebx+sizeof DEBUGVAR],addr szColon
			pop		eax
			invoke strcat,addr [edi+ebx+sizeof DEBUGVAR],eax
		.else
			invoke strcpy,addr [edi+ebx+sizeof DEBUGVAR],lpType
		.endif
		invoke strlen,addr [edi+ebx+sizeof DEBUGVAR]
		lea		ebx,[ebx+eax]
	.endif
	inc		ebx
	mov		eax,lpArray
	.if eax
		push	ebx
		lea		ebx,[eax+1]
		invoke IsDec,ebx
		.if eax
			invoke DecToBin,ebx
		.else
			invoke IsHex,ebx
			.if eax
				invoke HexToBin,ebx
			.else
				xor		ecx,ecx
				.while byte ptr [ebx+ecx]
					.if byte ptr [ebx+ecx]==']'
						mov		byte ptr [ebx+ecx],0
						.break
					.endif
					inc		ecx
				.endw
				invoke FindTypeSize,ebx
				.if !edx
					mov		fErrArray,TRUE
				.endif
			.endif
		.endif
		pop		ebx
	.else
		mov		eax,1
	.endif
	mov		[edi].DEBUGVAR.nArray,eax
	.if nSize
		mov		eax,nSize
		mov		[edi].DEBUGVAR.nSize,eax
	.elseif lpType
		mov		eax,lpType
		lea		eax,[eax+1]
		invoke FindTypeSize,eax
		.if !edx
			mov		fErrType,TRUE
		.else
			mov		[edi].DEBUGVAR.nSize,eax
		.endif
	.endif
	.if fErrArray
		invoke strlen,addr [edi+sizeof DEBUGVAR]
		invoke strcat,addr buffer,addr [edi+eax+1+sizeof DEBUGVAR]
		invoke wsprintf,addr outbuffer,addr szErrArray,addr buffer
		invoke PutString,addr outbuffer
		inc		dbg.nErrors
	.elseif fErrType
		invoke strlen,addr [edi+sizeof DEBUGVAR]
		invoke strcat,addr buffer,addr [edi+eax+1+sizeof DEBUGVAR]
		invoke wsprintf,addr outbuffer,addr szErrType,addr buffer
		invoke PutString,addr outbuffer
		inc		dbg.nErrors
	.endif
	lea		eax,[edi+ebx+sizeof DEBUGVAR]
	mov		dbg.lpvar,eax
	ret

AddVar endp

AddVarList proc uses ebx esi edi,lpList:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	nOfs:DWORD

	mov		nOfs,0
	mov		esi,lpList
	.while byte ptr [esi]
		mov		ebx,dbg.lpvar
		lea		edi,buffer
		.while TRUE
			mov		al,[esi]
			.if !al
				mov		[edi],al
				invoke AddVar,addr buffer,0
				.break
			.elseif al==','
				mov		byte ptr [edi],0
				invoke AddVar,addr buffer,0
				inc		esi
				.break
			.else
				mov		[edi],al
				inc		esi
				inc		edi
			.endif
		.endw
		mov		eax,[ebx].DEBUGVAR.nSize
		mov		ecx,nOfs
		mov		edx,[ebx].DEBUGVAR.nArray
		.if  !(eax & 3) && (ecx & 3)
			; DWord align
			shr		ecx,2
			inc		ecx
			shl		ecx,2
		.elseif !(eax & 1) && (ecx & 1)
			; Word align
			shr		ecx,1
			inc		ecx
			shl		ecx,1
		.endif
		mul		edx
		add		eax,ecx
		mov		nOfs,eax
		mov		[ebx].DEBUGVAR.nOfs,eax
	.endw
	mov		eax,dbg.lpvar
	lea		eax,[eax+sizeof DEBUGVAR+2]
	mov		dbg.lpvar,eax
	ret

AddVarList endp

EnumTypesCallback proc uses ebx esi edi,pSymInfo:DWORD,SymbolSize:DWORD,UserContext:DWORD

	mov		esi,pSymInfo
	.if fOptions & 1
		invoke wsprintf,addr outbuffer,addr szType,addr [esi].SYMBOL_INFO.szName,[esi].SYMBOL_INFO.nSize
		invoke PutString,addr outbuffer
	.endif
	mov		eax,dbg.inxtype
	mov		edx,sizeof DEBUGTYPE
	mul		edx
	mov		edi,dbg.hMemType
	lea		edi,[edi+eax]
	invoke strcpyn,addr [edi].DEBUGTYPE.szName,addr [esi].SYMBOL_INFO.szName,sizeof DEBUGTYPE.szName
	mov		eax,[esi].SYMBOL_INFO.nSize
	mov		[edi].DEBUGTYPE.nSize,eax
	inc		dbg.inxtype
	mov		eax,TRUE
	ret

EnumTypesCallback endp

EnumerateSymbolsCallback proc uses ebx edi,SymbolName:DWORD,SymbolAddress:DWORD,SymbolSize:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	Displacement:QWORD

	.if SymbolSize
		.if fOptions & 1
			invoke wsprintf,addr buffer,addr szSymbol,SymbolName,SymbolAddress,SymbolSize
			invoke PutString,addr buffer
		.endif
		mov		eax,dbg.inxsymbol
		mov		edx,sizeof DEBUGSYMBOL
		mul		edx
		mov		edi,dbg.hMemSymbol
		lea		edi,[edi+eax]
		mov		eax,SymbolAddress
		mov		[edi].DEBUGSYMBOL.Address,eax
		mov		eax,SymbolSize
		mov		[edi].DEBUGSYMBOL.nSize,eax
		invoke strcpyn,addr [edi].DEBUGSYMBOL.szName,SymbolName,sizeof DEBUGSYMBOL.szName
		invoke FindWord,SymbolName
		.if eax
			mov		esi,eax
			movzx	edx,[esi].PROPERTIES.nType
			mov		[edi].DEBUGSYMBOL.nType,dx
			.if edx=='p'
				; Proc
				mov		eax,dbg.lpvar
				mov		[edi].DEBUGSYMBOL.lpType,eax
				; Point to parameters
				invoke strlen,addr [esi+sizeof PROPERTIES]
				lea		esi,[esi+eax+1+sizeof PROPERTIES]
				invoke AddVarList,esi
				; Point to locals
				invoke strlen,esi
				lea		esi,[esi+eax+1]
				invoke AddVarList,esi
			.elseif edx=='d'
				; Variable
				mov		eax,dbg.lpvar
				mov		[edi].DEBUGSYMBOL.lpType,eax
				invoke AddVar,addr [esi+sizeof PROPERTIES],[edi].DEBUGSYMBOL.nSize
			.endif
		.endif
		inc		dbg.inxsymbol
	.endif
	mov		eax,TRUE
	ret

EnumerateSymbolsCallback endp

EnumSourceFilesCallback proc uses ebx edi,pSourceFile:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	mov		ebx,pSourceFile
	.if fOptions & 1
		invoke wsprintf,addr buffer,addr szSourceFile,[ebx].SOURCEFILE.FileName
		invoke PutString,addr buffer
	.endif
	mov		eax,dbg.inxsource
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	mov		edi,dbg.hMemSource
	lea		edi,[edi+eax]
	mov		eax,dbg.inxsource
	mov		[edi].DEBUGSOURCE.FileID,ax
	invoke strcpy,addr [edi].DEBUGSOURCE.FileName,[ebx].SOURCEFILE.FileName
	inc		dbg.inxsource
	mov		eax,TRUE
	ret

EnumSourceFilesCallback endp

EnumLinesCallback proc uses ebx esi edi,pLineInfo:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	mov		ebx,pLineInfo
	.if fOptions & 1
		invoke wsprintf,addr buffer,addr szSourceLine,addr [ebx].SRCCODEINFO.FileName,[ebx].SRCCODEINFO.Address,[ebx].SRCCODEINFO.LineNumber
		invoke PutString,addr buffer
	.endif
	; Find source file
	xor		ecx,ecx
	.while ecx<dbg.inxsource
		push	ecx
		mov		eax,ecx
		mov		edx,sizeof DEBUGSOURCE
		mul		edx
		mov		esi,dbg.hMemSource
		lea		esi,[esi+eax]
		invoke strcmpi,addr [esi].DEBUGSOURCE.FileName,addr [ebx].SRCCODEINFO.FileName
		.if !eax
			mov		eax,dbg.inxline
			mov		edx,sizeof DEBUGLINE
			mul		edx
			mov		edi,dbg.hMemLine
			lea		edi,[edi+eax]
			mov		ax,[esi].DEBUGSOURCE.FileID
			mov		[edi].DEBUGLINE.FileID,ax
			mov		eax,[ebx].SRCCODEINFO.LineNumber
			mov		[edi].DEBUGLINE.LineNumber,eax
			mov		eax,[ebx].SRCCODEINFO.Address
			mov		[edi].DEBUGLINE.Address,eax
			inc		dbg.inxline
			pop		ecx
			.break
		.endif
		pop		ecx
		inc		ecx
	.endw
	mov		eax,TRUE
	ret

EnumLinesCallback endp

DbgHelp proc uses ebx,hProcess:DWORD,lpFileName:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke LoadLibrary,addr DbgHelpDLL
	.if eax
		mov		hDbgHelpDLL,eax
		invoke GetDbgHelpVersion
		; Allocate memory for DEBUGTYPE, max 16K types
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024*sizeof DEBUGTYPE
		mov		dbg.hMemType,eax
		; Allocate memory for DEBUGSYMBOL, max 16K symbols
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024*sizeof DEBUGSYMBOL
		mov		dbg.hMemSymbol,eax
		; Allocate memory for DEBUGSOURCE, max 512 sources
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,512*sizeof DEBUGSOURCE
		mov		dbg.hMemSource,eax
		; Allocate memory for DEBUGLINE, max 128K lines
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,128*1024*sizeof DEBUGLINE
		mov		dbg.hMemLine,eax
		; Allocate memory for var definitions
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		dbg.hMemVar,eax
		mov		dbg.lpvar,eax
		; Zero the indexes
		mov		dbg.inxtype,0
		mov		dbg.inxsymbol,0
		mov		dbg.inxsource,0
		mov		dbg.inxline,0
		invoke GetProcAddress,hDbgHelpDLL,addr szSymInitialize
		.if eax
			mov		ebx,eax
			push	FALSE
			push	NULL
			push	hProcess
			call	ebx
		.endif
		.if eax
			invoke GetProcAddress,hDbgHelpDLL,addr szSymLoadModule
			.if eax
				mov		ebx,eax
				push	0
				push	0
				push	0
				push	lpFileName
				push	0
				push	hProcess
				call	ebx
			.endif
			.if eax
				mov		dwModuleBase,eax
				mov		im.SizeOfStruct,sizeof IMAGEHLP_MODULE
				mov		im.SymType1,SymNone
				invoke GetProcAddress,hDbgHelpDLL,addr szSymGetModuleInfo
				.if eax
					mov		ebx,eax
					lea		eax,im
					push	eax
					push	dwModuleBase
					push	hProcess
					call	ebx
				.endif
				.if im.SymType1==SymPdb
					invoke AddPredefinedTypes
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumTypes
					.if eax
						mov		ebx,eax
						push	0
						push	offset EnumTypesCallback
						push	0
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
					invoke AddConstants
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumerateSymbols
					.if eax
						mov		ebx,eax
						.if fOptions & 1
							invoke PutString,addr szSymOk
						.endif
						push	0
						push	offset EnumerateSymbolsCallback
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumSourceFiles
					.if eax
						mov		ebx,eax
						.if fOptions & 1
							invoke PutString,addr szSymEnumSourceFiles
						.endif
						push	0
						push	offset EnumSourceFilesCallback
						push	0
						push	0
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumSourceLines
					.if eax
						mov		ebx,eax
						.if fOptions & 1
							invoke PutString,addr szSymEnumSourceLines
						.endif
						push	0
						push	offset EnumLinesCallback
						push	0
						push	0
						push	0
						push	0
						push	0
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
				.endif
				invoke GetProcAddress,hDbgHelpDLL,addr szSymUnloadModule
				.if eax
					mov		ebx,eax
					push	dwModuleBase
					push	hProcess
					call	ebx
				.endif
				invoke GetProcAddress,hDbgHelpDLL,addr szSymCleanup
				.if eax
					mov		ebx,eax
					push	hProcess
					call	ebx
				.endif
			.else
				invoke PutString,addr szSymLoadModuleFailed
			.endif
		.else
			invoke PutString,addr szSymInitializeFailed
		.endif
		invoke FreeLibrary,hDbgHelpDLL
		mov		hDbgHelpDLL,0
	.else
		invoke PutString,addr szDbgHelpFail
	.endif
	ret

DbgHelp endp
