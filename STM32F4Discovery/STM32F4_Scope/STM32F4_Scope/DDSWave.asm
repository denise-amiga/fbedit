
.code

DDSGenWave proc uses ebx esi edi

	mov		ddsdata.DDS_VMin,4095
	mov		ddsdata.DDS_VMax,0
	movzx	eax,ddsdata.DDS_CommandStruct.DDS_WaveType
	.if !eax
		mov		esi,offset DDS_SineWave
		mov		edi,offset ddsdata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SineWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SineWave
		movsw
	.elseif eax==1
		mov		esi,offset DDS_TriangleWave
		mov		edi,offset ddsdata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_TriangleWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_TriangleWave
		movsw
	.elseif eax==2
		mov		esi,offset DDS_SquareWave
		mov		edi,offset ddsdata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SquareWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SquareWave
		movsw
	.elseif eax==3
		mov		esi,offset DDS_SawToothWave
		mov		edi,offset ddsdata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SawToothWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SawToothWave
		movsw
	.elseif eax==4
		mov		esi,offset DDS_RevSawToothWave
		mov		edi,offset ddsdata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_RevSawToothWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_RevSawToothWave
		movsw
	.endif
	xor		ebx,ebx
	mov		edi,offset ddsdata.DDS_WaveData
	.while ebx<4098
		movzx	eax,word ptr [edi+ebx*WORD]
		movzx	ecx,ddsdata.DDS_CommandStruct.Amplitude
		mul		ecx
		mov		ecx,4096
		div		ecx
		movzx	ecx,ddsdata.DDS_CommandStruct.Amplitude
		shr		ecx,1
		sub		ax,cx
		add		ax,2048
		movzx	ecx,ddsdata.DDS_CommandStruct.DCOffset
		add		ax,cx
		sub		ax,4096
		.if CARRY?
			xor		ax,ax
		.elseif ax>4095
			mov		ax,4095
		.endif
		mov		[edi+ebx*WORD],ax
		movzx	eax,ax
		.if eax<ddsdata.DDS_VMin
			mov		ddsdata.DDS_VMin,eax
		.endif
		.if eax>ddsdata.DDS_VMax
			mov		ddsdata.DDS_VMax,eax
		.endif
		inc		ebx
	.endw
	invoke InvalidateRect,ddsdata.hWndDDS,NULL,TRUE
	invoke UpdateWindow,ddsdata.hWndDDS
;	mov		eax,ddswavedata.SWEEP_StepSize
;	mov		ecx,ddswavedata.SWEEP_StepCount
;	shr		ecx,1
;	mul		ecx
;	mov		ebx,ddswavedata.DDS_PhaseFrq
;	sub		ebx,eax
;	mov		eax,ddswavedata.SWEEP_StepSize
;	mov		ecx,ddswavedata.SWEEP_StepCount
;	mul		ecx
;	mov		edx,ebx
;	add		edx,eax
;	mov		eax,ddswavedata.SWEEP_SubMode
;	.if eax==SWEEP_SubModeUp
;		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,FALSE
;		mov		ddswavedata.DDS_Sweep.SWEEP_Min,ebx
;		mov		ddswavedata.DDS_Sweep.SWEEP_Max,edx
;		mov		eax,ddswavedata.SWEEP_StepSize
;		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
;	.elseif eax==SWEEP_SubModeDown
;		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,FALSE
;		mov		ddswavedata.DDS_Sweep.SWEEP_Max,ebx
;		mov		ddswavedata.DDS_Sweep.SWEEP_Min,edx
;		mov		eax,ddswavedata.SWEEP_StepSize
;		neg		eax
;		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
;	.elseif eax==SWEEP_SubModeUpDown
;		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,TRUE
;		mov		ddswavedata.DDS_Sweep.SWEEP_Min,ebx
;		mov		ddswavedata.DDS_Sweep.SWEEP_Max,edx
;		mov		eax,ddswavedata.SWEEP_StepSize
;		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
;	.elseif eax==SWEEP_SubModePeak
;		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,FALSE
;		mov		ddswavedata.DDS_Sweep.SWEEP_Min,ebx
;		mov		ddswavedata.DDS_Sweep.SWEEP_Max,edx
;		mov		eax,ddswavedata.SWEEP_StepSize
;		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
;	.endif
	ret

DDSGenWave endp

DDSHzToPhaseAdd proc frq:DWORD

	fild	frq
	fild	dds64
	fmulp	st(1),st
	fild	ddscycles
	fmulp	st(1),st
	fild	STM32Clock
	fdivp	st(1),st
	fistp	frq
	mov		eax,frq
	ret

DDSHzToPhaseAdd endp

DDSPhaseFrqToHz proc PhaseAdd:DWORD
	
	fild	STM32Clock
	fild	dds64
	fdivp	st(1),st
	fild	ddscycles
	fdivp	st(1),st
	fild	PhaseAdd
	fmulp	st(1),st
	fistp	PhaseAdd
	mov		eax,PhaseAdd
	ret

DDSPhaseFrqToHz endp

DDSWaveSetupProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		childdialogs.hWndDDSWaveSetup,eax
		mov		esi,offset szDDS_Waves
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBODDSWAVE,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		movzx	eax,ddsdata.DDS_CommandStruct.DDS_WaveType
		invoke SendDlgItemMessage,hWin,IDC_CBODDSWAVE,CB_SETCURSEL,eax,0
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_SETRANGE,FALSE,(DACMAX SHL 16)
		movzx	eax,ddsdata.DDS_CommandStruct.Amplitude
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSDCOFS,TBM_SETRANGE,FALSE,(((DACMAX+1)*2-1) SHL 16)
		movzx	eax,ddsdata.DDS_CommandStruct.DCOffset
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSDCOFS,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQH,TBM_SETRANGE,FALSE,(DDSMAX SHL 16)
		mov		eax,ddsdata.DDS_CommandStruct.DDS_PhaseFrq
		shr		eax,15
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQH,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQL,TBM_SETRANGE,FALSE,(DDSMAX SHL 16)
		mov		eax,ddsdata.DDS_CommandStruct.DDS_PhaseFrq
		and		eax,DDSMAX
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQL,TBM_SETPOS,TRUE,eax
		invoke DDSPhaseFrqToHz,ddsdata.DDS_CommandStruct.DDS_PhaseFrq
		invoke SetDlgItemInt,hWin,IDC_EDTDDSFREQUENCY,eax,FALSE
		invoke SendDlgItemMessage,hWin,IDC_EDTDDSFREQUENCY,EM_LIMITTEXT,7,0
		movzx	eax,ddsdata.DDS_CommandStruct.DDS_SubMode
		add		eax,IDC_RBNSWEEPOFF
		invoke CheckRadioButton,hWin,IDC_RBNSWEEPOFF,IDC_RBNSWEEPPEAK,eax
		invoke SendDlgItemMessage,hWin,IDC_EDTSWEEPSIZE,EM_LIMITTEXT,4,0
		invoke DDSPhaseFrqToHz,ddsdata.DDS_CommandStruct.SWEEP_Add
		invoke SetDlgItemInt,hWin,IDC_EDTSWEEPSIZE,eax,FALSE
		invoke SendDlgItemMessage,hWin,IDC_EDTSWEEPTIME,EM_LIMITTEXT,4,0
		movzx	eax,ddsdata.DDS_CommandStruct.SWEEP_StepTime
		inc		eax
		cdq
		mov		ecx,10
		div		ecx
		invoke SetDlgItemInt,hWin,IDC_EDTSWEEPTIME,eax,FALSE
		invoke SendDlgItemMessage,hWin,IDC_EDTSWEEPCOUNT,EM_LIMITTEXT,4,0
		movzx	eax,ddsdata.DDS_CommandStruct.SWEEP_StepCount
		dec		eax
		invoke SetDlgItemInt,hWin,IDC_EDTSWEEPCOUNT,eax,FALSE
		invoke GetDlgItem,hWin,IDC_BTNDDSSET
		invoke EnableWindow,eax,FALSE
		invoke GetDlgItem,hWin,IDC_BTNSWEEPSET
		invoke EnableWindow,eax,FALSE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDC_BTNDDSSET
				invoke GetDlgItemInt,hWin,IDC_EDTDDSFREQUENCY,NULL,FALSE
				.if eax
					.if eax>5255000
						invoke SetDlgItemInt,hWin,IDC_EDTDDSFREQUENCY,5255000,FALSE
						mov		eax,5255000
					.endif
					invoke DDSHzToPhaseAdd,eax
					mov		ddsdata.DDS_CommandStruct.DDS_PhaseFrq,eax
					dec		eax
					push	eax
					shr		eax,15
					invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQH,TBM_SETPOS,TRUE,eax
					pop		eax
					and		eax,DDSMAX
					invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQL,TBM_SETPOS,TRUE,eax
					invoke DDSGenWave
					inc		fDDS
					invoke GetDlgItem,hWin,IDC_BTNDDSSET
					invoke EnableWindow,eax,FALSE
				.endif
			.elseif eax==IDC_RBNSWEEPOFF
				mov		ddsdata.DDS_CommandStruct.DDS_SubMode,SWEEP_SubModeOff
				invoke DDSGenWave
				inc		fDDS
			.elseif eax==IDC_RBNSWEEPUP
				mov		ddsdata.DDS_CommandStruct.DDS_SubMode,SWEEP_SubModeUp
				invoke DDSGenWave
				inc		fDDS
			.elseif eax==IDC_RBNSWEEPDOWN
				mov		ddsdata.DDS_CommandStruct.DDS_SubMode,SWEEP_SubModeDown
				invoke DDSGenWave
				inc		fDDS
			.elseif eax==IDC_RBNSWEEPUPDOWN
				mov		ddsdata.DDS_CommandStruct.DDS_SubMode,SWEEP_SubModeUpDown
				invoke DDSGenWave
				inc		fDDS
			.elseif eax==IDC_BTNSWEEPSET
;				invoke GetDlgItemInt,hWin,IDC_EDTSWEEPSIZE,NULL,FALSE
;				invoke DDSHzToPhaseAdd,eax
;				mov		ddswavedata.SWEEP_StepSize,eax
;				invoke GetDlgItemInt,hWin,IDC_EDTSWEEPTIME,NULL,FALSE
;				.if eax>6500
;					invoke SetDlgItemInt,hWin,IDC_EDTSWEEPTIME,6500,FALSE
;					mov		eax,6500
;				.endif
;				mov		ecx,10
;				mul		ecx
;				dec		eax
;				mov		ddswavedata.SWEEP_StepTime,eax
;				invoke GetDlgItemInt,hWin,IDC_EDTSWEEPCOUNT,NULL,FALSE
;				.if eax>1535
;					invoke SetDlgItemInt,hWin,IDC_EDTSWEEPCOUNT,1536,FALSE
;					mov		eax,1535
;				.endif
;				inc		eax
;				mov		ddswavedata.SWEEP_StepCount,eax
;				invoke DDSGenWave
;				inc		fCommand
;				invoke GetDlgItem,hWin,IDC_BTNSWEEPSET
;				invoke EnableWindow,eax,FALSE
;				invoke InvalidateRect,childdialogs.hWndDDSPeak,NULL,TRUE
			.endif
		.elseif edx==EN_CHANGE
			.if eax==IDC_EDTDDSFREQUENCY
				invoke GetDlgItem,hWin,IDC_BTNDDSSET
				invoke EnableWindow,eax,TRUE
			.else
				invoke GetDlgItem,hWin,IDC_BTNSWEEPSET
				invoke EnableWindow,eax,TRUE
			.endif
		.elseif edx==CBN_SELCHANGE
			invoke SendDlgItemMessage,hWin,IDC_CBODDSWAVE,CB_GETCURSEL,0,0
			mov		ddsdata.DDS_CommandStruct.DDS_WaveType,al
			invoke DDSGenWave
			inc		fDDS
		.endif
	.elseif eax==WM_HSCROLL
		invoke GetDlgCtrlID,lParam
		.if eax==IDC_TRBDDSAMP
			invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_GETPOS,0,0
			mov		ddsdata.DDS_CommandStruct.Amplitude,ax
			invoke DDSGenWave
			inc		fDDS
		.elseif eax==IDC_TRBDDSDCOFS
			invoke SendDlgItemMessage,hWin,IDC_TRBDDSDCOFS,TBM_GETPOS,0,0
			mov		ddsdata.DDS_CommandStruct.DCOffset,ax
			invoke DDSGenWave
			inc		fDDS
		.elseif eax==IDC_TRBDDSFRQH || eax==IDC_TRBDDSFRQL
			invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQH,TBM_GETPOS,0,0
			mov		edx,ddsdata.DDS_CommandStruct.DDS_PhaseFrq
			and		edx,DDSMAX
			shl		eax,15
			or		eax,edx
			mov		ddsdata.DDS_CommandStruct.DDS_PhaseFrq,eax
			invoke SendDlgItemMessage,hWin,IDC_TRBDDSFRQL,TBM_GETPOS,0,0
			mov		edx,ddsdata.DDS_CommandStruct.DDS_PhaseFrq
			and		edx,0FFFF8000h
			or		eax,edx
			inc		eax
			mov		ddsdata.DDS_CommandStruct.DDS_PhaseFrq,eax
			invoke DDSGenWave
			inc		fDDS
		.endif
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
		mov		childdialogs.hWndDDSWaveSetup,0
		invoke SetFocus,hWnd
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DDSWaveSetupProc endp

DDSWaveProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	mDC:HDC
	LOCAL	pt:POINT

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		;Draw horizontal lines
		sub		rect.bottom,TEXTHIGHT
		invoke CreatePen,PS_SOLID,1,0303030h
		invoke SelectObject,mDC,eax
		push	eax
		mov		eax,rect.bottom
		mov		ecx,6
		xor		edx,edx
		div		ecx
		mov		edx,eax
		mov		edi,eax
		xor		ecx,ecx
		.while ecx<5
			push	ecx
			push	edx
			invoke MoveToEx,mDC,0,edi,NULL
			invoke LineTo,mDC,rect.right,edi
			pop		edx
			add		edi,edx
			pop		ecx
			inc		ecx
		.endw
		invoke MoveToEx,mDC,0,rect.bottom,NULL
		invoke LineTo,mDC,rect.right,rect.bottom
		;Draw vertical lines
		mov		eax,rect.right
		mov		ecx,10
		xor		edx,edx
		div		ecx
		mov		edx,eax
		mov		edi,eax
		xor		ecx,ecx
		.while ecx<9
			push	ecx
			push	edx
			invoke MoveToEx,mDC,edi,0,NULL
			invoke LineTo,mDC,edi,rect.bottom
			pop		edx
			add		edi,edx
			pop		ecx
			inc		ecx
		.endw
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		;Draw curve
		invoke CreatePen,PS_SOLID,2,008000h
		invoke SelectObject,mDC,eax
		push	eax
		mov		esi,offset ddsdata.DDS_WaveData
		xor		edi,edi
		call	GetPoint
		invoke MoveToEx,mDC,pt.x,pt.y,NULL
		.while edi<4097*WORD
			call	GetPoint
			invoke LineTo,mDC,pt.x,pt.y
			inc		edi
			inc		edi
		.endw
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		add		rect.bottom,TEXTHIGHT
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	ret

GetPoint:
	;Get X position
	mov		eax,edi
	mov		ecx,rect.right
	mul		ecx
	mov		ecx,4097*2
	div		ecx
	mov		pt.x,eax
	;Get y position
	movzx	eax,word ptr [esi+edi]
	sub		eax,DACMAX
	neg		eax
	mov		ecx,rect.bottom
	sub		ecx,2
	.if SIGN?
		xor		ecx,ecx
	.endif
	mul		ecx
	mov		ecx,DACMAX
	div		ecx
	mov		pt.y,eax
	retn

DDSWaveProc endp

DDSWaveChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		ddsdata.hWndDialog,eax
		invoke GetDlgItem,hWin,IDC_UDCDDSWAVE
		mov		ddsdata.hWndDDS,eax
		mov		ddsdata.DDS_CommandStruct.DDS_WaveType,DDS_ModeSinWave
		mov		ddsdata.DDS_CommandStruct.DDS_SubMode,SWEEP_SubModeOff
		mov		ddsdata.DDS_CommandStruct.DDS_PhaseFrq,100000
		mov		ddsdata.DDS_CommandStruct.Amplitude,DACMAX
		mov		ddsdata.DDS_CommandStruct.DCOffset,DACMAX
		mov		ddsdata.DDS_CommandStruct.SWEEP_Add,1000
		mov		ddsdata.DDS_CommandStruct.SWEEP_StepTime,100
		mov		ddsdata.DDS_CommandStruct.SWEEP_StepCount,10
		invoke DDSGenWave
	.elseif	eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		sub		rect.right,135
		sub		rect.bottom,2
		invoke MoveWindow,ddsdata.hWndDDS,0,0,rect.right,rect.bottom,TRUE
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DDSWaveChildProc endp
