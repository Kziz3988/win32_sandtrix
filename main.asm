.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

.data
	WINDOW_W EQU 400
	WINDOW_H EQU 400
	FIELD_W EQU 160
	FIELD_H EQU 304
	LEFT_BAR_W EQU 32
	NEXT_INFO_WND_SIZE EQU 120
	TEXT_LINE_H EQU 20

	RIGHT_BAR_W EQU WINDOW_W - LEFT_BAR_W - FIELD_W
	RIGHT_BAR_X EQU LEFT_BAR_W + FIELD_W
	NEXT_INFO_WND_Y EQU (RIGHT_BAR_W - NEXT_INFO_WND_SIZE) / 2
	NEXT_INFO_WND_X EQU NEXT_INFO_WND_Y + RIGHT_BAR_X
	NEXT_INFO_TEXT_Y1 EQU NEXT_INFO_WND_Y + NEXT_INFO_WND_SIZE
	NEXT_INFO_TEXT_Y2 EQU NEXT_INFO_TEXT_Y1 + TEXT_LINE_H
	SCORE_TEXT_Y2 EQU NEXT_INFO_TEXT_Y2 + TEXT_LINE_H
	CLEARS_TEXT_Y2 EQU SCORE_TEXT_Y2 + TEXT_LINE_H
	RESTART_TEXT_Y2 EQU CLEARS_TEXT_Y2 + TEXT_LINE_H

	QUEUE_SIZE_MAX EQU FIELD_W * WINDOW_H

.data?
	hInstance dd ?
	hWinMain dd ?

	windowRealW dd ?
	windowRealH dd 0

	szBuffer db 50 dup(?)
	szTemp db 50 dup(?)
	szChar db 1 dup(?)
	stRect dd 4 dup(?)

	arrSands db FIELD_W * WINDOW_H dup(?) ;ɳ������
	arrQueueBFS dd QUEUE_SIZE_MAX dup(?) ;��������������У�����ѭ������
	arrSandsVisited db QUEUE_SIZE_MAX dup(?) ;ÿ��ɳ���ڹ����������ʱ�ķ������
	arrSandsToClear dd QUEUE_SIZE_MAX dup(?) ;��������ɳ��
	queueHead dd ? ;����ָ�루ƫ������
	queueTail dd ? ;��βָ�루ƫ������
	sandsToClearTotal dd ? ;��������ɳ��������������ɳ�������βָ�룩

	score dd ?
	clears dd ?
	brickX dd ?
	brickY dd ?
	brickDir dd ? ;ש�鷽��
	brickId dd ? ;��ǰש��ı��
	brickNextId dd ? ;��һ��ש��ı��
	brickColorId dd ?
	brickNextColorId dd ?

	bPlay db ? ;����Ƿ���Խ��в���
	scoreMult dd ? ;��������
	seed dd ? ;α�������ʼ����
	rand db ? ;α�����
	sandChangedMax dd ?;�������ƶ�����ɳ�ӵ�y����

.const
	szClassName db 'Sandtrix', 0
	szTitleMain db 'Sandtrix', 0
	szScoreText db 'SCORE: ', 0
	szClearsText db 'CLEARS: ', 0
	szNextInfoText db 'NEXT', 0
	szRestartText db 'RESTART', 0
	szGameOver db 'GAME OVER', 0
	szNumber db '0123456789', 0

	refreshInt dd 1 ;��Ļˢ�¼�������룩

	windowW dd WINDOW_W
	windowH dd WINDOW_H
	fieldW dd FIELD_W
	fieldH dd FIELD_H
	leftBarW dd LEFT_BAR_W
	nextInfoWndSize dd NEXT_INFO_WND_SIZE ;����һ��ש�顱���ڵı߳�
	textLineH dd TEXT_LINE_H ;�����и�

	rightBarW dd RIGHT_BAR_W
	rightBarX dd RIGHT_BAR_X
	nextInfoWndX dd NEXT_INFO_WND_X
	nextInfoWndY dd NEXT_INFO_WND_Y

	nextInfoTextY1 dd NEXT_INFO_TEXT_Y1
	nextInfoTextY2 dd NEXT_INFO_TEXT_Y2
	scoreTextY2 dd SCORE_TEXT_Y2
	clearsTextY2 dd CLEARS_TEXT_Y2
	restartTextY2 dd RESTART_TEXT_Y2

	blockSize dd 16 ;��������ı߳�
	;sandSize dd 1 ;����ɳ�ӵ�ֱ��

	colorBar dd 7F7F7Fh ;���������ɫ
	colorField dd 000000h ;��Ϸ�������ɫ
	colorText dd 0FFFFFFh

	arrBrickColor dd 0000FFh, 00FFFFh, 0FF0000h, 00FF00h, 800080h, 0FFFF00h
	colorRed dd 0000FFh
	;colorYellow dd 00FFFFh
	;colorBlue dd 0FF0000h
	;colorGreen dd 00FF00h
	;colorPurple dd 800080h
	;colorCyan dd 0FFFF00h

	scorePerClear dd 1 ;ÿ����һ�εĻ���������ÿ��ɳ�ӣ�
	scorePerBrick dd 64 ;ÿ����һ��ש��ķ���
	scoreBase dd 4 ;������������

	brickTotal db 7 ;һ��7��ש��
	colorTotal db 6 ;һ��6����ɫ
	;ÿ��ש���з����������꣬4��Ϊһ��
	arrBlockX dd 0, -1, 1, 2,   0,  0, 0, 0,   0, 1, -1, -2,   0, 0,  0,  0
			  dd 0, -1, -1, 1,   0,  0, -1, 0,   0, 1,  1, -1,   0, 0, 1,  0
			  dd 0, -1, 1, 1,   0,  0, 0, -1,   0, 1, -1, -1,   0, 0,  0,  1
			  dd 0, -1, 0, 1,   0,  0, -1, 0,   0, 1,  0, -1,   0, 0, 1,  0
			  dd 0, 0, -1, 1,   0, -1, -1, 0,   0,  0,  1, -1,   0, 1, 1,  0
			  dd 0, -1, 0, 1,   0,  0, -1, -1,   0, 1,  0, -1,   0, 0, 1,  1
			  dd 0, 0, 1, 1,   0, -1, 0, -1,   0,  0, -1, -1,   0, 1,  0,  1
	arrBlockY dd 0,  0, 0, 0,   0, -1, 1, 2,   0, 0,  0,  0,   0, 1, -1, -2
			  dd 0,  0,  1, 0,   0, -1, -1, 1,   0, 0, -1,  0,   0, 1, 1, -1
			  dd 0,  0, 0, 1,   0, -1, 1,  1,   0, 0,  0, -1,   0, 1, -1, -1
			  dd 0,  0, 1, 0,   0, -1,  0, 1,   0, 0, -1,  0,   0, 1, 0, -1
			  dd 0, 1,  1, 0,   0,  0, -1, 1,   0, -1, -1,  0,   0, 0, 1, -1
			  dd 0,  0, 1, 1,   0, -1,  0,  1,   0, 0, -1, -1,   0, 1, 0, -1
			  dd 0, 1, 0, 1,   0,  0, 1,  1,   0, -1,  0, -1,   0, 0, -1, -1
	;ש���ߵ���Է�Χ��2��Ϊһ��
	arrBrickW dd -1, 2,    0, 0,   -2, 1,    0, 0
			  dd -1, 1,   -1, 0,   -1, 1,    0, 1
			  dd -1, 1,   -1, 0,   -1, 1,    0, 1
			  dd -1, 1,   -1, 0,   -1, 1,    0, 1
			  dd -1, 1,   -1, 0,   -1, 1,    0, 1
			  dd -1, 1,   -1, 0,   -1, 1,    0, 1
			  dd 0, 1,   -1, 0,   -1, 0,    0, 1
	arrBrickH dd  0, 0,   -1, 2,    0, 0,   -2, 1
			  dd  0, 1,   -1, 1,   -1, 0,   -1, 1
			  dd  0, 1,   -1, 1,   -1, 0,   -1, 1
			  dd  0, 1,   -1, 1,   -1, 0,   -1, 1
			  dd  0, 1,   -1, 1,   -1, 0,   -1, 1
			  dd  0, 1,   -1, 1,   -1, 0,   -1, 1
			  dd 0, 1,    0, 1,   -1, 0,   -1, 0
	blockAbsMax dd 3
.code
	Random proc range: byte ;ʹ������ͬ�෨����α�����: x_{n+1} = (a * x_n + b) mod m
		mov eax, seed
		mov ecx, 630360016 ;a
		mul ecx
		mov ecx, 7 ;b
		add eax, ecx
		mov ecx, 2147483647 ;m
		div ecx
		mov seed, edx
		xor ax, ax
		mov al, dl
		mov bl, range
		div bl
		mov rand, ah
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx
		ret
	Random endp

	GenerateNextBrick proc ;���������һ��ש��
		;���������һ��ש�������
		invoke Random, brickTotal
		xor eax, eax
		mov al, rand
		mov brickNextId, eax
		;���������һ��ש�����ɫ
		invoke Random, colorTotal
		xor eax, eax
		mov al, rand
		mov brickNextColorId, eax
		ret
	GenerateNextBrick endp
		
	NewBrick proc ;������ש��
		mov eax, brickNextId
		mov brickId, eax
		mov eax, brickNextColorId
		mov brickColorId, eax
		invoke GenerateNextBrick

		mov eax, fieldW
		xor edx, edx
		mov ebx, 2
		div ebx
		mov brickX, eax
		mov eax, blockSize
		mov ebx, blockAbsMax
		mul ebx
		mov brickY, eax
		mov brickDir, 0
		ret
	NewBrick endp

	DrawRectangle proc uses eax hdc: HDC, hbr: HBRUSH, x1: dword, y1: dword, x2: dword, y2: dword
		;����һ�����Σ��ڽ��յ�WM_PAINTʱʹ��
		mov eax, x1
		mov dword ptr [stRect], eax
		mov eax, y1
		mov dword ptr [stRect+4], eax
		mov eax, x2
		mov dword ptr [stRect+8], eax
		mov eax, y2
		mov dword ptr [stRect+12], eax
		invoke FillRect, hdc, addr stRect, hbr
		ret

	DrawRectangle endp

	Init proc ;��Ϸ��ʼ��
		.if seed == -1
			;���ڴ��ַ��Ϊ��������ӵĳ�ֵ
			lea ax, seed
			mov seed, eax
		.endif
		;lea ax, seed
		;mov seed, eax
		;���ɵ�һ��ש��
		invoke GenerateNextBrick
		invoke NewBrick
		;���ɳ��
		mov eax, offset arrSands
		mov ebx, FIELD_W * WINDOW_H
		mov ecx, -1
		mov edx, 0
		clear_sand:
			mov [eax+edx], ecx
			inc edx
			dec ebx
			cmp ebx, 0
			jnz clear_sand
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov score, 0
		mov clears, 0
		mov bPlay, 1
		mov scoreMult, 1
		mov sandChangedMax, WINDOW_H
		ret
	Init endp

	DwordToString proc num: dword ;˫��������ת�ַ������������szBuffer��
		mov eax, num
		mov ecx, 10
		mov szBuffer, NULL
		mov edi, esp
		convert:
			xor edx, edx
			div ecx
			cmp eax, 0
			je invert
			
			movzx bx, [szNumber+edx]
			push bx
			jmp convert

		invert:
			movzx bx, [szNumber+edx]
			push bx
			concat:
				pop bx
				mov szChar, bl
				mov byte ptr [szChar+1], 0
				invoke lstrcatA, addr szBuffer, addr szChar
				cmp edi, esp
				je finish
				jmp concat

		finish:
			xor eax, eax
			xor ebx, ebx
			xor ecx, ecx
			xor edx, edx
			xor edi, edi
			ret
	DwordToString endp

	BFSInQueue proc uses eax ebx ecx, num: dword ;���������������Ӳ���
		mov ebx, num
		mov eax, queueTail
		mov [arrSandsVisited+ebx], 1 ;����βԪ����Ϊ�ѷ���
		mov ecx, 4
		mul ecx
		mov [arrQueueBFS+eax], ebx

		inc queueTail
		.if queueTail == QUEUE_SIZE_MAX
			mov queueTail, 0 ;��βָ�뷵��������ʼλ��
		.endif
		ret
	BFSInQueue endp
	
	_ProcWinMain proc uses ebx edi esi hWnd, uMsg, wParam, lParam ;������ѭ��
		local @stPs: PAINTSTRUCT
		local @stRect: RECT
		local @stRectScore: RECT
		local @stRectClears: RECT
		local @stRectNextInfo: RECT
		local @stRectRestart: RECT
		local @stRectGameOver: RECT
		local @stRectField: RECT
		local @stPos: POINT

		local @hdcPs
		local @hBrush

		local @rightBarW
		local @rightBarX

		local @szScore
		local @szClears

		local @blockAbsX: dword
		local @blockAbsY: dword
		local @blockNextX: dword
		local @blockNextY: dword
		local @brickX1
		local @brickX2

		local @loopVar
		local @loopVar2
		local @loopVar3
		local @flag: byte

		local @currentColorX ;��ǰ������ɫ����ʼ��
		local @currentColorY ;��ǰ������ɫ����ʼ��
		local @currentColorId: byte ;��ǰ������ɫ
		local @currentColorW ;��ǰ������ɫ���
		.if uMsg == WM_PAINT ;���ƴ���
			invoke BeginPaint, hWnd, addr @stPs
			mov @hdcPs, eax

			.if windowRealH == 0
				invoke GetClientRect, hWnd, addr @stRect ;��ȡ���ڴ�С
				mov eax, @stRect.bottom
				sub eax, @stRect.top
				mov windowRealH, eax
			.endif

			;��ʼ������
			mov al, bPlay
			cmp al, 0
			jz draw_brick_start ;����ǰɳ�������ƶ����򲻸�����Ϸ����

			.if bPlay == -1 ;ɳ�ӿ�ʼ�ƶ�
				mov bPlay, 0
			.endif
			;����������
			invoke CreateSolidBrush, colorBar
			mov ebx, eax
			invoke SelectObject, @hdcPs, ebx
			invoke DrawRectangle, @hdcPs, ebx, 0, 0, leftBarW, windowH
			;�����Ҳ����
			invoke DrawRectangle, @hdcPs, ebx, rightBarX, 0, RIGHT_BAR_X + RIGHT_BAR_W, windowH
			invoke DeleteObject, ebx
			;���ơ���һ��ש�顱����
			invoke CreateSolidBrush, colorField
			mov ebx, eax
			invoke SelectObject, @hdcPs, eax
			invoke DrawRectangle, @hdcPs, ebx, nextInfoWndX, nextInfoWndY, NEXT_INFO_WND_X + NEXT_INFO_WND_SIZE, NEXT_INFO_WND_Y + NEXT_INFO_WND_SIZE
			invoke DeleteObject, ebx
			;ˢ����Ϸ��
			invoke CreateSolidBrush, colorField
			mov ebx, eax
			invoke SelectObject, @hdcPs, eax
			invoke DrawRectangle, @hdcPs, ebx, leftBarW, 0, RIGHT_BAR_X, windowH
			invoke DeleteObject, ebx
			
			;���ƽ���
			invoke CreateSolidBrush, colorBar
			mov ebx, eax
			invoke SelectObject, @hdcPs, eax
			invoke DrawRectangle, @hdcPs, ebx, leftBarW, WINDOW_H - FIELD_H, RIGHT_BAR_X, WINDOW_H - FIELD_H + 1
			invoke DeleteObject, ebx

			invoke SetBkColor, @hdcPs, colorBar
			invoke SetTextColor, @hdcPs, colorText
			;����һ��ש�顱����
			mov eax, rightBarX
			mov dword ptr [@stRectNextInfo], eax
			mov eax, nextInfoTextY1
			mov dword ptr [@stRectNextInfo+4], eax
			mov eax, windowW
			mov dword ptr [@stRectNextInfo+8], eax
			mov eax, nextInfoTextY2
			mov dword ptr [@stRectNextInfo+12], eax
			invoke DrawText, @hdcPs, addr szNextInfoText, -1, addr @stRectNextInfo, DT_CENTER or DT_SINGLELINE or DT_VCENTER

			;�����¿�ʼ����ť
			mov eax, rightBarX
			mov dword ptr [@stRectRestart], eax
			mov eax, clearsTextY2
			mov dword ptr [@stRectRestart+4], eax
			mov eax, windowW
			mov dword ptr [@stRectRestart+8], eax
			mov eax, restartTextY2
			mov dword ptr [@stRectRestart+12], eax
			invoke DrawText, @hdcPs, addr szRestartText, -1, addr @stRectRestart, DT_CENTER or DT_SINGLELINE or DT_VCENTER

			;����
			mov eax, nextInfoWndX
			mov dword ptr [@stRectScore], eax
			mov eax, nextInfoTextY2
			mov dword ptr [@stRectScore+4], eax
			mov eax, windowW
			mov dword ptr [@stRectScore+8], eax
			mov eax, scoreTextY2
			mov dword ptr [@stRectScore+12], eax
			mov @szScore, NULL
			invoke DwordToString, score
			invoke lstrcatA, addr @szScore, addr szScoreText
			invoke lstrcatA, addr @szScore, addr szBuffer
			invoke DrawText, @hdcPs, addr @szScore, -1, addr @stRectScore, DT_LEFT or DT_SINGLELINE or DT_VCENTER

			;��������
			mov eax, nextInfoWndX
			mov dword ptr [@stRectClears], eax
			mov eax, scoreTextY2
			mov dword ptr [@stRectClears+4], eax
			mov eax, windowW
			mov dword ptr [@stRectClears+8], eax
			mov eax, clearsTextY2
			mov dword ptr [@stRectClears+12], eax
			mov @szClears, NULL
			invoke DwordToString, clears
			invoke lstrcatA, addr @szClears, addr szClearsText
			invoke lstrcatA, addr @szClears, addr szBuffer
			invoke DrawText, @hdcPs, addr @szClears, -1, addr @stRectClears, DT_LEFT or DT_SINGLELINE or DT_VCENTER

			draw_brick_start:
			cmp bPlay, 0
			jz draw_brick_finished

			;��ȡ������ɫ
			mov eax, brickColorId
			shl eax, 2
			mov edx, [arrBrickColor+eax]
			invoke CreateSolidBrush, edx
			mov @hBrush, eax
			invoke SelectObject, @hdcPs, eax

			;����ש��
			mov @loopVar, 0 ;ʹ��ecx��loop����ĳЩ����������ͻ������ÿ������Ч����һ�»���ѭ��
			draw_brick:
				;ÿ����������꣺x = arrBlockX[(brickId * 4 + brickDir) * 4 + blockId] * blockSize + brickX, y = arrBlockY[(brickId * 4 + brickDir) * 4 + blockId] * blockSize + brickY
				;ԭ���ƻ�ʹ����ת������м��㣬������32λ���������˷�ʮ�ַ�������˲��ý�ȫ�������Ӧ����ֱ���г��ķ�ʽ��
				mov eax, brickId
				shl eax, 2
				add eax, brickDir
				shl eax, 2
				add eax, @loopVar
				shl eax, 2
				mov eax, [arrBlockX+eax]
				mul blockSize
				add eax, brickX
				mov @blockAbsX, eax

				mov eax, brickId
				shl eax, 2
				add eax, brickDir
				shl eax, 2
				add eax, @loopVar
				shl eax, 2
				mov eax, [arrBlockY+eax]
				mul blockSize
				add eax, brickY
				mov @blockAbsY, eax

				add eax, blockSize
				mov ebx, @blockAbsX
				add ebx, blockSize
				invoke DrawRectangle, @hdcPs, @hBrush, @blockAbsX, @blockAbsY, ebx, eax
				
				inc @loopVar
				cmp @loopVar, 4 ;����4������
				jne draw_brick
			
			draw_brick_finished:
				invoke DeleteObject, @hBrush
				mov @loopVar, 0
				mov eax, brickNextColorId
				shl eax, 2
				mov edx, [arrBrickColor+eax]
				invoke CreateSolidBrush, edx
				mov @hBrush, eax

			;������һ��ש��
			draw_next_brick:
				mov eax, brickNextId
				shl eax, 4
				add eax, @loopVar
				shl eax, 2
				mov eax, [arrBlockX+eax]
				mul blockSize
				add eax, nextInfoWndX
				mov @blockAbsX, eax
				xor edx, edx
				mov eax, nextInfoWndSize
				sub eax, blockSize
				mov ebx, 2
				div ebx
				mov ebx, @blockAbsX
				add ebx, eax
				mov @blockAbsX, ebx

				mov eax, brickNextId
				shl eax, 4
				add eax, @loopVar
				shl eax, 2
				mov eax, [arrBlockY+eax]
				mul blockSize
				add eax, nextInfoWndY
				mov @blockAbsY, eax
				xor edx, edx
				mov eax, nextInfoWndSize
				mov ebx, 2
				div ebx
				mov ebx, @blockAbsY
				add ebx, eax
				sub ebx, blockSize
				mov @blockAbsY, ebx

				add ebx, blockSize
				mov eax, @blockAbsX
				add eax, blockSize
				invoke DrawRectangle, @hdcPs, @hBrush, @blockAbsX, @blockAbsY, eax, ebx
				
				inc @loopVar
				cmp @loopVar, 4
				jne draw_next_brick
				invoke DeleteObject, @hBrush

			;����ɳ��
				mov @loopVar, -1
				mov al, [arrSands]
				mov @currentColorId, al
				mov eax, leftBarW
				mov @currentColorX, eax
				mov @currentColorY, 0
				mov @currentColorW, 0
			draw_sands:
				inc @loopVar
				mov ebx, @loopVar
				mov eax, sandChangedMax
				inc eax
				mov ecx, fieldW
				mul ecx
				cmp ebx, eax
				je draw_sands_finished

				mov eax, @loopVar
				xor edx, edx
				mov ebx, fieldW
				div ebx
				add edx, leftBarW
				mov @blockAbsX, edx ;��ǰ����x����
				mov @blockAbsY, eax ;��ǰ����y����
				cmp edx, leftBarW
				jnz in_middle
				cmp bPlay, 1
				je in_middle ;��ǰɳ��ֹͣ�˶������谴�и���
				;λ��һ�е���ʼλ�ã�����ǰ������ɫ
				mov edx, 000000h
				invoke CreateSolidBrush, edx
				mov ebx, eax
				mov eax, @blockAbsY
				inc eax
				invoke DrawRectangle, @hdcPs, ebx, leftBarW, @blockAbsY, LEFT_BAR_W + FIELD_W, eax
				invoke DeleteObject, ebx
				invoke CreateSolidBrush, colorBar
				mov ebx, eax
				invoke SelectObject, @hdcPs, eax
				invoke DrawRectangle, @hdcPs, ebx, leftBarW, WINDOW_H - FIELD_H, RIGHT_BAR_X, WINDOW_H - FIELD_H + 1
				invoke DeleteObject, ebx

				in_middle:
					cmp eax, @currentColorY
					jne color_breaks ;��ǰ�е�ĩβ

				xor ebx, ebx
				mov eax, @loopVar
				mov bl, [arrSands+eax]
				cmp bl, @currentColorId
				jne color_breaks ;��������ɫ

				inc @currentColorW ;��ǰ��ɫ��������
				jmp draw_sands

				color_breaks:
					cmp @currentColorId, -1
					je update_color ;��ǰλ��û��ɳ�ӣ��������
					movzx eax, @currentColorId
					shl eax, 2
					mov edx, [arrBrickColor+eax]
					invoke CreateSolidBrush, edx
					mov ebx, eax
					mov eax, @currentColorX
					add eax, @currentColorW
					mov ecx, @currentColorY
					inc ecx
					inc ecx
					invoke DrawRectangle, @hdcPs, ebx, @currentColorX, @currentColorY, eax, ecx
					invoke DeleteObject, ebx
				update_color:
					mov bl, [arrSands+eax]
					mov @currentColorId, bl
					mov ebx, @blockAbsX
					mov @currentColorX, ebx
					mov ebx, @blockAbsY
					mov @currentColorY, ebx
					mov @currentColorW, 1
					jmp draw_sands

			draw_sands_finished:
				.if bPlay == 2
					;����Ϸ����������
					invoke SetBkColor, @hdcPs, colorField
					invoke SetTextColor, @hdcPs, colorRed
					mov eax, leftBarW
					mov dword ptr [@stRectGameOver], eax
					mov eax, 0
					mov dword ptr [@stRectGameOver+4], eax
					mov eax, RIGHT_BAR_X
					mov dword ptr [@stRectGameOver+8], eax
					mov eax, WINDOW_H - FIELD_H
					mov dword ptr [@stRectGameOver+12], eax
					invoke DrawText, @hdcPs, addr szGameOver, -1, addr @stRectGameOver, DT_CENTER or DT_SINGLELINE or DT_VCENTER
				.endif

				invoke EndPaint, hWnd, addr @stPs
				invoke DeleteObject, @hdcPs
				mov @flag, 0
				mov sandChangedMax, 0
				.if bPlay == 0
					;ɳ����������һ��
					mov eax, windowRealH
					mul fieldW
					mov @loopVar, eax
					sand_gravity:
						dec @loopVar
						mov eax, @loopVar
						mov bl, [arrSands+eax]
						cmp bl, -1
						je sand_affected ;��ǰλ��û��ɳ�ӣ��������
						mov eax, @loopVar
						add eax, fieldW ;��ǰɳ�����·�
						mov ecx, eax
						xor edx, edx
						mov ebx, fieldW
						div ebx
						cmp eax, windowRealH
						jae sand_affected ;�Ѵ�����ײ�

						mov al, [arrSands+ecx]
						cmp al, -1
						jne compare_left ;���·���ɳ��

						mov ecx, @loopVar
						mov bl, [arrSands+ecx]
						mov [arrSands+ecx], -1
						add ecx, fieldW
						mov [arrSands+ecx], bl
						mov @flag, 1 ;��ɳ��λ�ñ仯����������
						mov eax, @loopVar
						xor edx, edx
						mov ebx, fieldW
						div ebx
						cmp eax, sandChangedMax
						ja sand_changed_max_update
						jmp sand_affected

						compare_left:
							xor edx, edx
							mov eax, @loopVar
							mov ebx, fieldW
							div ebx
							cmp edx, 0
							jz compare_right ;��ǰλ����Ϸ�������

							mov eax, @loopVar
							add eax, fieldW
							dec eax ;��ǰɳ�����·�
							mov bl, [arrSands+eax]
							cmp bl ,-1
							jne compare_right ;���·���ɳ��

							mov ecx, @loopVar
							mov bl, [arrSands+ecx]
							mov [arrSands+ecx], -1
							add ecx, fieldW
							dec ecx
							mov [arrSands+ecx], bl
							mov @flag, 1 ;��ɳ��λ�ñ仯����������
							mov eax, @loopVar
							xor edx, edx
							mov ebx, fieldW
							div ebx
							cmp eax, sandChangedMax
							ja sand_changed_max_update
							jmp sand_affected

						compare_right:
							xor edx, edx
							mov eax, @loopVar
							mov ebx, fieldW
							div ebx
							inc edx
							cmp edx, fieldW
							jae sand_affected ;��ǰλ����Ϸ�����ұ�

							mov eax, @loopVar
							add eax, fieldW
							inc eax ;��ǰɳ�����·�
							mov bl, [arrSands+eax]
							cmp bl ,-1
							jne sand_affected ;���·���ɳ��

							mov ecx, @loopVar
							mov bl, [arrSands+ecx]
							mov [arrSands+ecx], -1
							add ecx, fieldW
							inc ecx
							mov [arrSands+ecx], bl
							mov @flag, 1 ;��ɳ��λ�ñ仯����������
							mov eax, @loopVar
							xor edx, edx
							mov ebx, fieldW
							div ebx
							cmp eax, sandChangedMax
							jbe sand_affected
						sand_changed_max_update:
							mov sandChangedMax, eax
						sand_affected:
							cmp @loopVar, 1
							jnz sand_gravity

						inc sandChangedMax
					.if @flag == 0 ;û��ɳ�ӿ����ƶ�����ʼ��������
						mov bPlay, 1
						mov eax, windowRealH
						mov sandChangedMax, eax

						;��ʼ�������������
						mov @loopVar, 0
						mov queueHead, 0
						mov queueTail, 0
						mov sandsToClearTotal, 0
						init_bfs:
							mov eax, @loopVar
							mov bl, [arrSands+eax]
							.if bl == -1
								;����û��ɳ�ӵ�λ����Ϊ�ѷ��ʣ��൱���ϰ�
								mov [arrSandsVisited+eax], 1
							.else
								mov [arrSandsVisited+eax], 0
							.endif
							shl eax, 2
							mov [arrQueueBFS+eax], 0
							mov [arrSandsToClear+eax], 0
							inc @loopVar
							cmp @loopVar, QUEUE_SIZE_MAX
							jne init_bfs

							mov eax, fieldW
							mov ebx, windowRealH
							mul ebx
							mov @loopVar, eax ;�������ϲ���
							mov @currentColorId, -1
							mov @brickX1, 0 ;��ɫ��ͨ�����Ƿ���������Ե
							mov @brickX2, 0 ;��ɫ��ͨ�����Ƿ������Ҳ��Ե
							mov @szScore, 0

						start_bfs:
							dec @loopVar
							cmp @loopVar, 0
							je bfs_finished
						
						check_queue:
							mov eax, queueHead
							cmp eax, queueTail
							je check_result ;����Ϊ�գ����β��ҽ���
							jmp search_bottom ;���зǿգ���������

						check_result:
							mov eax, @brickX1
							and eax, @brickX2
							cmp eax, 1
							jne search_next ;���β���δ�ҵ�����Ҫ������򣬲�����һ��δ�����ʵ�λ��
							
							mov @loopVar2, 0 ;������ɳ�ӵĵ�ַƫ����
							mov @szScore, 0 ;������ɳ����

						clear_sands: ;����������ͨ��ɳ��
							mov eax, @loopVar2
							cmp eax, sandsToClearTotal
							je bfs_finished

							mov ecx, [arrSandsToClear+eax]
							mov [arrSands+ecx], -1
							inc @szScore
							add @loopVar2, 4
							jmp clear_sands

						search_bottom:
							;����Ԫ������δ�����ʵ�����λ�����
							mov eax, queueHead
							shl eax, 2
							mov ecx, [arrQueueBFS+eax]
							mov @loopVar3, ecx ;����λ��
							mov eax, ecx
							xor edx, edx
							mov ebx, fieldW
							div ebx
							mov @blockAbsX, edx ;����λ��x����
							mov @blockAbsY, eax ;����λ��y����

							mov eax, windowRealH
							dec eax
							cmp eax, @blockAbsY
							jbe search_right ;�������·�
							mov ecx, @loopVar3
							add ecx, fieldW ;����λ���·�����λ��
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne search_right ;�����������λ����ɫ��ͬ������λ��
							cmp [arrSandsVisited+ecx], 1
							je search_right ;��λ���ѱ�����
							invoke BFSInQueue, ecx

						search_right:
							mov eax, fieldW
							dec eax
							cmp eax, @blockAbsX
							jbe search_top ;�������Ҳ�
							mov ecx, @loopVar3
							inc ecx ;����λ���Ҳ�����λ��
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne search_top ;�����������λ����ɫ��ͬ������λ��
							cmp [arrSandsVisited+ecx], 1
							je search_top ;��λ���ѱ�����
							invoke BFSInQueue, ecx

						search_top:
							cmp @blockAbsY, 0
							jz search_left ;�������Ϸ�
							mov ecx, @loopVar3
							sub ecx, fieldW ;����λ���Ϸ�����λ��
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne search_left ;�����������λ����ɫ��ͬ������λ��
							cmp [arrSandsVisited+ecx], 1
							je search_left ;��λ���ѱ�����
							invoke BFSInQueue, ecx

						search_left:
							cmp @blockAbsX, 0
							jz visit_head ;���������
							mov ecx, @loopVar3
							dec ecx ;����λ���������λ��
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne visit_head ;�����������λ����ɫ��ͬ������λ��
							cmp [arrSandsVisited+ecx], 1
							je visit_head ;��λ���ѱ�����
							invoke BFSInQueue, ecx
						
						visit_head:
							;����Ԫ�س���
							mov eax, queueHead
							shl eax, 2
							mov ecx, [arrQueueBFS+eax]
							mov eax, ecx
							xor edx, edx
							mov ebx, fieldW
							div ebx
							.if edx == 0
								mov @brickX1, 1 ;���������
							.elseif edx == FIELD_W - 1
								mov @brickX2, 1 ;�������Ҳ�
							.endif
							mov eax, sandsToClearTotal
							mov [arrSandsToClear+eax], ecx
							add eax, 4
							mov sandsToClearTotal, eax

							inc queueHead
							.if queueHead == QUEUE_SIZE_MAX
								mov queueHead, 0 ;����ָ�뷵��������ʼλ��
							.endif

							jmp check_queue

						search_next:
							mov @brickX1, 0
							mov @brickX2, 0
							mov sandsToClearTotal, 0 ;��մ�������ɳ��
							mov eax, @loopVar
							cmp [arrSandsVisited+eax], 1
							je start_bfs ;��ǰλ���ѱ����ʣ�����

							invoke BFSInQueue, @loopVar
							mov eax, @loopVar
							mov bl, [arrSands+eax]
							mov @currentColorId, bl
							jmp start_bfs

						bfs_finished:
							mov eax, @brickX1
							and eax, @brickX2
							.if eax == 0
								;û���κ�ɳ�ӱ��������÷ֱ��ʳ�ʼ��
								mov scoreMult, 1
							.else
								mov eax, @szScore
								mul scoreMult
								mul scoreBase
								add score, eax
								inc clears
								.if scoreMult == 128 ;���128��
								.else
									shl scoreMult, 1 ;�÷ֱ��ʷ���
								.endif
								mov bPlay, -1 ;ɳ�����¿�ʼ����
							.endif
							
						.if bPlay == 1
							;���ɳ���Ƿ񳬹�����
							mov @loopVar, FIELD_W * (WINDOW_H - FIELD_H)
							mov @flag, 0
							check_limit:
								dec @loopVar
								mov eax, @loopVar
								mov bl, [arrSands+eax]
								.if bl == -1
								.else
									mov @flag, 1
								.endif

								cmp @loopVar, FIELD_W * (WINDOW_H - FIELD_H - 1)
								jae check_limit

							.if @flag == 1
								;ɳ�ӳ������ޣ�������Ϸ
								mov bPlay, 2
							.endif

						.endif
						invoke InvalidateRect, hWnd, NULL, FALSE
						ret
					.endif

					invoke Sleep, refreshInt
					mov eax, leftBarW
					mov dword ptr [stRect], eax
					mov dword ptr [stRect+4], 0
					mov eax, LEFT_BAR_W + FIELD_W + 1
					mov dword ptr [stRect+8], eax
					mov eax, sandChangedMax
					inc eax
					mov dword ptr [stRect+12], eax
					invoke InvalidateRect, hWnd, addr stRect, FALSE ;��������Ϸ����
				.endif

		.elseif uMsg == WM_CLOSE ;�رմ���
			invoke DestroyWindow, hWinMain
			invoke PostQuitMessage, NULL

		.elseif uMsg == WM_LBUTTONUP ;�����
			invoke GetCursorPos, addr @stPos
			invoke ScreenToClient, hWnd, addr @stPos
			.if @stPos.x >= RIGHT_BAR_X
				.if @stPos.y >= CLEARS_TEXT_Y2
					.if @stPos.y <= RESTART_TEXT_Y2
						invoke Init
						invoke InvalidateRect, hWnd, NULL, FALSE
					.endif
				.endif
			.endif

		.elseif uMsg == WM_KEYUP ;��������
			.if bPlay == 1 ;�������
				;��Ϸ�����x���귶Χ��leftBarW��rightBarX֮��
				mov eax, leftBarW
				add eax, fieldW
				mov @rightBarX, eax
				.if wParam == VK_LEFT ;�����������
					mov eax, brickX
					sub eax, blockSize
					mov brickX, eax
					jmp wall_jump
				.elseif wParam == VK_RIGHT ;�ҷ����������
					mov eax, brickX
					add eax, blockSize
					mov brickX, eax
					jmp wall_jump
				.elseif wParam == 41h ;A������ʱ����ת
					mov eax, brickDir
					dec eax
					.if eax == -1
						mov brickDir, 3
					.else
						mov brickDir, eax
					.endif
					jmp wall_jump
				.elseif wParam == 44h ;D����˳ʱ����ת
					mov eax, brickDir
					inc eax
					.if eax == 4
						mov brickDir, 0
					.else
						mov brickDir, eax
					.endif
					wall_jump: ;��������Ϸ�����ש���ƻ���Ϸ������
						;ש�����x���꣺x1 = arrBrickW[brickId * 8 + brickDir * 2] * blockSize + brickX
						;ש���ұ�x���꣺x2 = (arrBrickW[brickId * 8 + brickDir * 2 + 1] + 1) * blockSize + brickX
						mov eax, brickId
						shl eax, 3
						mov ecx, eax
						mov eax, brickDir
						shl eax, 1
						add eax, ecx
						shl eax, 2
						mov ebx, [arrBrickW+eax]
						mov @brickX1, ebx
						add eax, 4
						mov ebx, [arrBrickW+eax]
						inc ebx
						mov @brickX2, ebx
						mov eax, @brickX1
						mul blockSize
						mov ebx, eax
						add ebx, brickX
						mov @brickX1, ebx ;ש�����x����
						mov eax, @brickX2
						mul blockSize
						mov ebx, eax
						add ebx, brickX
						mov @brickX2, ebx ;ש���ұ�x����

						left_cmp:
							mov ebx, @brickX1
							cmp ebx, leftBarW
							jae right_cmp
							mov eax, leftBarW
							sub eax, @brickX1
							mov ebx, brickX
							add ebx, eax
							mov brickX, ebx

						right_cmp:
							mov ebx, @brickX2
							cmp ebx, @rightBarX
							jbe finish_cmp
							mov eax, @brickX2
							sub eax, @rightBarX
							mov ebx, brickX
							sub ebx, eax
							mov brickX, ebx

						finish_cmp:
				.elseif wParam == VK_SPACE ;�ո��������
					mov eax, scoreBase
					mov ebx, scorePerBrick
					mul ebx
					add score, eax
					mov @loopVar, 0
					sandify:
						mov eax, brickId
						shl eax, 2
						add eax, brickDir
						shl eax, 2
						add eax, @loopVar
						shl eax, 2
						mov eax, [arrBlockX+eax]
						mul blockSize
						add eax, brickX
						mov @blockAbsX, eax

						mov eax, brickId
						shl eax, 2
						add eax, brickDir
						shl eax, 2
						add eax, @loopVar
						shl eax, 2
						mov eax, [arrBlockY+eax]
						mul blockSize
						add eax, brickY
						mov @blockAbsY, eax

						mov @loopVar2, 0
						sandify_x:
							mov @loopVar3, 0
							sandify_y:
								mov ebx, @blockAbsX
								sub ebx, leftBarW ;����������ת��Ϊ�������
								add ebx, @loopVar2
								mov eax, @blockAbsY
								add eax, @loopVar3
								mul fieldW
								add eax, ebx
								mov ebx, brickColorId
								mov [arrSands+eax], bl
								inc @loopVar3
								mov eax, blockSize
								cmp @loopVar3, eax
								jne sandify_y
							inc @loopVar2
							mov eax, blockSize
							cmp @loopVar2, eax
							jne sandify_x
						inc @loopVar
						cmp @loopVar, 4 ;����4������
						jne sandify
						invoke NewBrick
						mov bPlay, -1 ;ɳ�ӿ�ʼ���䣬��ֹ��Ҳ���ֱ��ɳ���˶�ֹͣ
				.endif
				mov eax, leftBarW
				mov dword ptr [stRect], eax
				mov dword ptr [stRect+4], 0
				mov eax, LEFT_BAR_W + FIELD_W + 1
				mov dword ptr [stRect+8], eax
				mov eax, WINDOW_H - FIELD_H + 1
				mov dword ptr [stRect+12], eax
				invoke InvalidateRect, hWnd, addr stRect, FALSE ;�����·�������
			.endif

		.else ;Ĭ�����
			invoke DefWindowProc, hWnd, uMsg, wParam, lParam
			ret
		.endif
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx
		xor edi, edi
		ret
	_ProcWinMain endp

	_WinMain proc ;����Windows����
		local @stWndClass: WNDCLASSEX
		local @stMsg: MSG
		local @stRect: RECT
		local @paddingW ;���ڱ߿�Ŀ��
		
		invoke GetSystemMetrics, SM_CYCAPTION
		mov ebx, eax
		invoke GetSystemMetrics, SM_CYSIZEFRAME
		sub ebx, eax
		invoke GetSystemMetrics, SM_CXPADDEDBORDER
		sub ebx, eax
		mov @paddingW, ebx
		mov eax, windowW
		add eax, @paddingW
		mov windowRealW, eax

		;��ȡ���ھ��
		invoke GetModuleHandle, NULL
		mov hInstance, eax
		invoke RtlZeroMemory, addr @stWndClass, sizeof @stWndClass
		push hInstance
		pop @stWndClass.hInstance

		;��ȡ���
		invoke LoadCursor, 0, IDC_ARROW
		mov @stWndClass.hCursor, eax

		;���ô�����ʽ
		mov @stWndClass.style, CS_HREDRAW or CS_VREDRAW
		mov @stWndClass.hbrBackground, COLOR_WINDOW + 1
		mov @stWndClass.hIcon, NULL

		mov @stWndClass.cbSize, sizeof WNDCLASSEX
		mov @stWndClass.lpszClassName, offset szClassName
		mov @stWndClass.lpfnWndProc, offset _ProcWinMain
		invoke RegisterClassEx, addr @stWndClass
		invoke CreateWindowEx, WS_EX_CLIENTEDGE, offset szClassName, offset szTitleMain, WS_OVERLAPPEDWINDOW and not WS_THICKFRAME and not WS_MAXIMIZEBOX, 200, 200, windowRealW, windowH, NULL, NULL, hInstance, NULL
		mov hWinMain, eax
		invoke ShowWindow, hWinMain, SW_SHOWNORMAL
		invoke UpdateWindow, hWinMain

		xor eax, eax
		xor ebx, ebx

		;��Ϣѭ��
		.while TRUE
			invoke GetMessage, addr @stMsg, NULL, 0, 0
			.break .if eax == 0 ;�˳�����
			invoke TranslateMessage, addr @stMsg
			invoke DispatchMessage, addr @stMsg
		.endw
		ret

	_WinMain endp

	main proc
		mov seed, -1
		invoke Init
		call _WinMain
		invoke ExitProcess, 0
	main endp

end main
