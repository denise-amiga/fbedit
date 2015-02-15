
; STM32 value line Discovery Digital Oscilloscope demo project.
; -------------------------------------------------------------------------------
;
; IMPORTANT NOTICE!
; -----------------
; The use of the evaluation board is restricted:
; "This device is not, and may not be, offered for sale or lease, or sold or
; leased or otherwise distributed".
;
; For more info see this license agreement:
; http://www.st.com/internet/com/LEGAL_RESOURCES/LEGAL_AGREEMENT/
; LICENSE_AGREEMENT/EvaluationProductLicenseAgreement.pdf

.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Filter.inc
include DDSWave.asm

.code

;//Simple "bandpass resonator" (notch) filter I generated with FIVIEW,
;// used to demostrate that the ADC to DAC path is working.
;
;// Center frequency is 880Hz, Q=50
;// FIVIEW generates code with doubles, I converted it to floats as
;// the STM32F4 had hardware FP for floats, but not doubles
;
;///////////////////////////////////////////////////////////////////////
;
;// Generated by Fiview 0.9.10 <http://uazu.net/fiview/>.  
;// All generated example code below is in the public domain.
;// Filter 1
;// File: -i #1
;// Guessed type: band-pass
;//
;// Frequency-response:
;//   Peak gain: 796.775
;//   Guessed 100% gain: 796.775
;//   Regions between half-power points (70.71% response or -3.01dB):
;//     871.245Hz -> 888.845Hz  (width 17.6Hz, midpoint 880.045Hz)
;//   Regions between quarter-power points (50% response or -6.02dB):
;//     864.89Hz -> 895.372Hz  (width 30.482Hz, midpoint 880.131Hz)
;//
;// Filter descriptions:
;//   BpRe/50/880 == Bandpass resonator, Q=50 (0 means Inf), frequency 880
;//
;// Example code (optimised for cleaner compilation to efficient machine code)
;float filter(register float val)
;{
;   static float buf[2];
;   register float tmp, fir, iir;
;   tmp= buf[0]; memmove(buf, buf+1, 1*sizeof(float));
;
;   iir= val * 0.001255059246835381 * 0.75;   
;   iir -= 0.9974898815063291*tmp; fir= -tmp;
;   iir -= -1.981739077169366*buf[0];
;
;   fir += iir;
;   buf[1]= iir; val= fir;
;   return val;
;}

Filter1 proc uses ebx esi edi,val:REAL4
	LOCAL	tmp:REAL4
	LOCAL	fir:REAL4
	LOCAL	iir:REAL4

	;tmp = buf[0]
	fld		buf[0]
	fst		tmp
	;fir = -tmp
	fchs
	fstp	fir
	;memmove(buf, buf+1, 1*sizeof(float))
	fld		buf[4]
	fstp	buf[0]
	;iir = val * 0.001255059246835381 * 0.75
	fld		val
	fmul	iir1a
	fmul	iir2a
	fstp	iir
	;iir -= 0.9974898815063291*tmp; fir= -tmp
	fld		iir
	fld		tmp
	fmul	iir3a
	fsubp	st(1),st
	fstp	iir
	;iir -= -1.981739077169366*buf[0]
	fld		iir
	fld		buf[0]
	fmul	iir4a
	fsubp	st(1),st
	fstp	iir
	;fir += iir
	fld		fir
	fadd	iir
	fstp	fir
	;buf[1]= iir
	fld		iir
	fstp	buf[4]
	;val = fir
	fld		fir
	fistp	val
	;return val
	mov		eax,val
	ret

Filter1 endp

;fiview 800000 -i BpRe/100/200000
;// Example code (functionally the same as the above code, but 
;//  optimised for cleaner compilation to efficient machine code)
;double
;process(register double val) {
;   static double buf[2];
;   register double tmp, fir, iir;
;   tmp= buf[0]; memmove(buf, buf+1, 1*sizeof(double));
;   // use 0.007792618324143074 below for unity gain at 100% level
;   iir= val * 0.007792618324143074;
;   iir -= 0.9844147633517139*tmp; fir= -tmp;
;   iir -= -1.2150259892613e-016*buf[0];
;   fir += iir;
;   buf[1]= iir; val= fir;
;   return val;
;}
;
Filter2 proc uses ebx esi edi,val:REAL4
	LOCAL	tmp:REAL4
	LOCAL	fir:REAL4
	LOCAL	iir:REAL4

	;tmp = buf[0]
	fld		buf[0]
	fst		tmp
	;fir = -tmp
	fchs
	fstp	fir
	;memmove(buf, buf+1, 1*sizeof(float))
	fld		buf[4]
	fstp	buf[0]
	;iir = val * 0.007792618324143074 * 1.0
	fld		val
	fmul	iir1b
	fmul	iir2b
	fstp	iir
	;iir -= 0.9844147633517139*tmp
	fld		iir
	fld		tmp
	fmul	iir3b
	fsubp	st(1),st
	fstp	iir
	;iir -= -1.2150259892613e-016*buf[0]
	fld		iir
	fld		buf[0]
	fmul	iir4b
	fsubp	st(1),st
	fstp	iir
	;fir += iir
	fld		fir
	fadd	iir
	fstp	fir
	;buf[1]= iir
	fld		iir
	fstp	buf[4]
	;val = fir
	fld		fir
	fistp	val
	;return val
	mov		eax,val
	ret

Filter2 endp

;fiview 800000 -i BpBe8/190000-210000
;// Example code (functionally the same as the above code, but 
;//  optimised for cleaner compilation to efficient machine code)
;double
;process(register double val) {
;   static double buf[2];
;   register double tmp, fir, iir;
;   tmp= buf[0]; memmove(buf, buf+1, 1*sizeof(double));
;   // use 0.07295965726826664 below for unity gain at 100% level
;   iir= val * 0.07295965726827532;
;   iir -= 0.8540806854634667*tmp; fir= -tmp;
;   iir -= -1.013642496376809e-016*buf[0];
;   fir += iir;
;   buf[1]= iir; val= fir;
;   return val;
;}
;
Filter3 proc uses ebx esi edi,val:REAL4
	LOCAL	tmp:REAL4
	LOCAL	fir:REAL4
	LOCAL	iir:REAL4
	LOCAL	imm:REAL4

	;tmp = buf[0]
	fld		buf[0]
	fstp	tmp
	;memmove(buf, buf+1, 15*sizeof(double))
	invoke RtlMoveMemory,addr buf[0],addr buf[4],sizeof REAL4
	;iir= val * 0.07295965726827532
	fld		val
	fmul	iir1c
	fstp	iir
	;iir -= 0.8540806854634667 * tmp
	fld		iir
	fld		tmp
	fmul	iir2c
	fsubp	st(1),st
	fstp	iir
	;fir = -tmp
	fld		tmp
	fchs
	fstp	fir
	;iir -= -1.013642496376809e-016 * buf[0]
	fld		iir
	fld		buf[0]
	fmul	iir3c
	fsubp	st(1),st
	fstp	iir
	;fir += iir
	fld		fir
	fadd	iir
	fstp	fir
	;buf[1] = iir;
	fld		iir
	fstp	buf[4]
	;val = fir
	fld		fir
	fistp	val
	mov		eax,val
	ret

Filter3 endp

MainDlgProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	tid:DWORD
	LOCAL	tci:TC_ITEM
	LOCAL	val:REAL4
	LOCAL	ival:DWORD

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke GetDlgItem,hWin,IDC_MAINTAB
		mov		childdialogs.hWndMainTab,eax
		mov		tci.imask,TCIF_TEXT
		mov		tci.lpReserved1,0
		mov		tci.lpReserved2,0
		mov		tci.iImage,-1
		mov		tci.lParam,0
		mov		tci.pszText,offset szTabTitleDDS
		invoke SendMessage,childdialogs.hWndMainTab,TCM_INSERTITEM,0,addr tci
		invoke CreateFontIndirect,addr Tahoma
		mov		hFont,eax
		;Create DDS Wave child dialog
		invoke CreateDialogParam,hInstance,IDD_DDSWAVE,childdialogs.hWndMainTab,addr DDSWaveChildProc,0
		mov		childdialogs.hWndDDSWaveDialog,eax
		xor		ebx,ebx
		.while ebx<4096
			mov		eax,ebx
			and		eax,0003h
			movzx	eax,TestWave[eax*WORD]
			mov		ival,eax
			fild	ival
			fstp	val
			invoke Filter3,val
;			PrintDec eax
			add		eax,2048
			mov		wave[ebx*WORD],ax
			inc		ebx
		.endw
		
	.elseif	eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,childdialogs.hWndMainTab,0,0,rect.right,rect.bottom,TRUE
		add		rect.left,5
		sub		rect.right,10
		add		rect.top,25
		sub		rect.bottom,30
		invoke MoveWindow,childdialogs.hWndDDSWaveDialog,rect.left,rect.top,rect.right,rect.bottom,TRUE
	.elseif	eax==WM_CLOSE
		invoke DeleteObject,hFont
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

MainDlgProc endp

start:
	
	invoke	GetModuleHandle,NULL
	mov		hInstance,eax
	invoke	InitCommonControls
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.cbClsExtra,0
	mov		wc.cbWndExtra,0
	mov		eax,hInstance
	mov		wc.hInstance,eax
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	mov		wc.hbrBackground,NULL
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpfnWndProc,offset DDSWaveProc
	mov		wc.lpszClassName,offset szDDSWAVECLASS
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset DDSPeakProc
	mov		wc.lpszClassName,offset szDDSPEAKCLASS
	invoke RegisterClassEx,addr wc
	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr MainDlgProc,NULL
	invoke	ExitProcess,0

end start
