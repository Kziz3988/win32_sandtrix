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

	arrSands db FIELD_W * WINDOW_H dup(?) ;沙子数据
	arrQueueBFS dd QUEUE_SIZE_MAX dup(?) ;广度优先搜索队列，采用循环队列
	arrSandsVisited db QUEUE_SIZE_MAX dup(?) ;每个沙子在广度优先搜索时的访问情况
	arrSandsToClear dd QUEUE_SIZE_MAX dup(?) ;待消除的沙子
	queueHead dd ? ;队首指针（偏移量）
	queueTail dd ? ;队尾指针（偏移量）
	sandsToClearTotal dd ? ;待消除的沙子数（即待消除沙子数组的尾指针）

	score dd ?
	clears dd ?
	brickX dd ?
	brickY dd ?
	brickDir dd ? ;砖块方向
	brickId dd ? ;当前砖块的编号
	brickNextId dd ? ;下一个砖块的编号
	brickColorId dd ?
	brickNextColorId dd ?

	bPlay db ? ;玩家是否可以进行操作
	scoreMult dd ? ;连消倍率
	seed dd ? ;伪随机数初始种子
	rand db ? ;伪随机数
	sandChangedMax dd ?;最下面移动过的沙子的y坐标

.const
	szClassName db 'Sandtrix', 0
	szTitleMain db 'Sandtrix', 0
	szScoreText db 'SCORE: ', 0
	szClearsText db 'CLEARS: ', 0
	szNextInfoText db 'NEXT', 0
	szRestartText db 'RESTART', 0
	szGameOver db 'GAME OVER', 0
	szNumber db '0123456789', 0

	refreshInt dd 1 ;屏幕刷新间隔（毫秒）

	windowW dd WINDOW_W
	windowH dd WINDOW_H
	fieldW dd FIELD_W
	fieldH dd FIELD_H
	leftBarW dd LEFT_BAR_W
	nextInfoWndSize dd NEXT_INFO_WND_SIZE ;“下一个砖块”窗口的边长
	textLineH dd TEXT_LINE_H ;文字行高

	rightBarW dd RIGHT_BAR_W
	rightBarX dd RIGHT_BAR_X
	nextInfoWndX dd NEXT_INFO_WND_X
	nextInfoWndY dd NEXT_INFO_WND_Y

	nextInfoTextY1 dd NEXT_INFO_TEXT_Y1
	nextInfoTextY2 dd NEXT_INFO_TEXT_Y2
	scoreTextY2 dd SCORE_TEXT_Y2
	clearsTextY2 dd CLEARS_TEXT_Y2
	restartTextY2 dd RESTART_TEXT_Y2

	blockSize dd 16 ;单个方块的边长
	;sandSize dd 1 ;单个沙子的直径

	colorBar dd 7F7F7Fh ;侧边栏的颜色
	colorField dd 000000h ;游戏区域的颜色
	colorText dd 0FFFFFFh

	arrBrickColor dd 0000FFh, 00FFFFh, 0FF0000h, 00FF00h, 800080h, 0FFFF00h
	colorRed dd 0000FFh
	;colorYellow dd 00FFFFh
	;colorBlue dd 0FF0000h
	;colorGreen dd 00FF00h
	;colorPurple dd 800080h
	;colorCyan dd 0FFFF00h

	scorePerClear dd 1 ;每消除一次的基础分数（每粒沙子）
	scorePerBrick dd 64 ;每放下一个砖块的分数
	scoreBase dd 4 ;基础分数倍率

	brickTotal db 7 ;一共7种砖块
	colorTotal db 6 ;一共6种颜色
	;每个砖块中方块的相对坐标，4项为一组
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
	;砖块宽高的相对范围，2项为一组
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
	Random proc range: byte ;使用线性同余法生成伪随机数: x_{n+1} = (a * x_n + b) mod m
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

	GenerateNextBrick proc ;随机生成下一个砖块
		;随机生成下一个砖块的种类
		invoke Random, brickTotal
		xor eax, eax
		mov al, rand
		mov brickNextId, eax
		;随机生成下一个砖块的颜色
		invoke Random, colorTotal
		xor eax, eax
		mov al, rand
		mov brickNextColorId, eax
		ret
	GenerateNextBrick endp
		
	NewBrick proc ;生成新砖块
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
		;绘制一个矩形，在接收到WM_PAINT时使用
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

	Init proc ;游戏初始化
		.if seed == -1
			;将内存地址作为随机数种子的初值
			lea ax, seed
			mov seed, eax
		.endif
		;lea ax, seed
		;mov seed, eax
		;生成第一个砖块
		invoke GenerateNextBrick
		invoke NewBrick
		;清除沙子
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

	DwordToString proc num: dword ;双字型数字转字符串，结果存在szBuffer中
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

	BFSInQueue proc uses eax ebx ecx, num: dword ;广度优先搜索的入队操作
		mov ebx, num
		mov eax, queueTail
		mov [arrSandsVisited+ebx], 1 ;将队尾元素设为已访问
		mov ecx, 4
		mul ecx
		mov [arrQueueBFS+eax], ebx

		inc queueTail
		.if queueTail == QUEUE_SIZE_MAX
			mov queueTail, 0 ;队尾指针返回数组起始位置
		.endif
		ret
	BFSInQueue endp
	
	_ProcWinMain proc uses ebx edi esi hWnd, uMsg, wParam, lParam ;窗口主循环
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

		local @currentColorX ;当前连续颜色的起始列
		local @currentColorY ;当前连续颜色的起始行
		local @currentColorId: byte ;当前连续颜色
		local @currentColorW ;当前连续颜色宽度
		.if uMsg == WM_PAINT ;绘制窗口
			invoke BeginPaint, hWnd, addr @stPs
			mov @hdcPs, eax

			.if windowRealH == 0
				invoke GetClientRect, hWnd, addr @stRect ;获取窗口大小
				mov eax, @stRect.bottom
				sub eax, @stRect.top
				mov windowRealH, eax
			.endif

			;初始化界面
			mov al, bPlay
			cmp al, 0
			jz draw_brick_start ;若当前沙子正在移动，则不更新游戏界面

			.if bPlay == -1 ;沙子开始移动
				mov bPlay, 0
			.endif
			;绘制左侧边栏
			invoke CreateSolidBrush, colorBar
			mov ebx, eax
			invoke SelectObject, @hdcPs, ebx
			invoke DrawRectangle, @hdcPs, ebx, 0, 0, leftBarW, windowH
			;绘制右侧边栏
			invoke DrawRectangle, @hdcPs, ebx, rightBarX, 0, RIGHT_BAR_X + RIGHT_BAR_W, windowH
			invoke DeleteObject, ebx
			;绘制“下一个砖块”窗口
			invoke CreateSolidBrush, colorField
			mov ebx, eax
			invoke SelectObject, @hdcPs, eax
			invoke DrawRectangle, @hdcPs, ebx, nextInfoWndX, nextInfoWndY, NEXT_INFO_WND_X + NEXT_INFO_WND_SIZE, NEXT_INFO_WND_Y + NEXT_INFO_WND_SIZE
			invoke DeleteObject, ebx
			;刷新游戏区
			invoke CreateSolidBrush, colorField
			mov ebx, eax
			invoke SelectObject, @hdcPs, eax
			invoke DrawRectangle, @hdcPs, ebx, leftBarW, 0, RIGHT_BAR_X, windowH
			invoke DeleteObject, ebx
			
			;绘制界限
			invoke CreateSolidBrush, colorBar
			mov ebx, eax
			invoke SelectObject, @hdcPs, eax
			invoke DrawRectangle, @hdcPs, ebx, leftBarW, WINDOW_H - FIELD_H, RIGHT_BAR_X, WINDOW_H - FIELD_H + 1
			invoke DeleteObject, ebx

			invoke SetBkColor, @hdcPs, colorBar
			invoke SetTextColor, @hdcPs, colorText
			;“下一个砖块”文字
			mov eax, rightBarX
			mov dword ptr [@stRectNextInfo], eax
			mov eax, nextInfoTextY1
			mov dword ptr [@stRectNextInfo+4], eax
			mov eax, windowW
			mov dword ptr [@stRectNextInfo+8], eax
			mov eax, nextInfoTextY2
			mov dword ptr [@stRectNextInfo+12], eax
			invoke DrawText, @hdcPs, addr szNextInfoText, -1, addr @stRectNextInfo, DT_CENTER or DT_SINGLELINE or DT_VCENTER

			;“重新开始”按钮
			mov eax, rightBarX
			mov dword ptr [@stRectRestart], eax
			mov eax, clearsTextY2
			mov dword ptr [@stRectRestart+4], eax
			mov eax, windowW
			mov dword ptr [@stRectRestart+8], eax
			mov eax, restartTextY2
			mov dword ptr [@stRectRestart+12], eax
			invoke DrawText, @hdcPs, addr szRestartText, -1, addr @stRectRestart, DT_CENTER or DT_SINGLELINE or DT_VCENTER

			;分数
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

			;消除次数
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

			;获取方块颜色
			mov eax, brickColorId
			shl eax, 2
			mov edx, [arrBrickColor+eax]
			invoke CreateSolidBrush, edx
			mov @hBrush, eax
			invoke SelectObject, @hdcPs, eax

			;绘制砖块
			mov @loopVar, 0 ;使用ecx和loop会与某些函数产生冲突，导致每次运行效果不一致或死循环
			draw_brick:
				;每个方块的坐标：x = arrBlockX[(brickId * 4 + brickDir) * 4 + blockId] * blockSize + brickX, y = arrBlockY[(brickId * 4 + brickDir) * 4 + blockId] * blockSize + brickY
				;原本计划使用旋转矩阵进行计算，但处理32位带符号数乘法十分繁琐，因此采用将全部方向对应坐标直接列出的方式。
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
				cmp @loopVar, 4 ;绘制4个方块
				jne draw_brick
			
			draw_brick_finished:
				invoke DeleteObject, @hBrush
				mov @loopVar, 0
				mov eax, brickNextColorId
				shl eax, 2
				mov edx, [arrBrickColor+eax]
				invoke CreateSolidBrush, edx
				mov @hBrush, eax

			;绘制下一个砖块
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

			;绘制沙子
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
				mov @blockAbsX, edx ;当前像素x坐标
				mov @blockAbsY, eax ;当前像素y坐标
				cmp edx, leftBarW
				jnz in_middle
				cmp bPlay, 1
				je in_middle ;当前沙子停止运动，无需按行更新
				;位于一行的起始位置，将当前行填充黑色
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
					jne color_breaks ;当前行的末尾

				xor ebx, ebx
				mov eax, @loopVar
				mov bl, [arrSands+eax]
				cmp bl, @currentColorId
				jne color_breaks ;遇到新颜色

				inc @currentColorW ;当前颜色继续延伸
				jmp draw_sands

				color_breaks:
					cmp @currentColorId, -1
					je update_color ;当前位置没有沙子，无需绘制
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
					;“游戏结束”文字
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
					;沙子整体下落一步
					mov eax, windowRealH
					mul fieldW
					mov @loopVar, eax
					sand_gravity:
						dec @loopVar
						mov eax, @loopVar
						mov bl, [arrSands+eax]
						cmp bl, -1
						je sand_affected ;当前位置没有沙子，无需操作
						mov eax, @loopVar
						add eax, fieldW ;当前沙子正下方
						mov ecx, eax
						xor edx, edx
						mov ebx, fieldW
						div ebx
						cmp eax, windowRealH
						jae sand_affected ;已处于最底部

						mov al, [arrSands+ecx]
						cmp al, -1
						jne compare_left ;正下方有沙子

						mov ecx, @loopVar
						mov bl, [arrSands+ecx]
						mov [arrSands+ecx], -1
						add ecx, fieldW
						mov [arrSands+ecx], bl
						mov @flag, 1 ;有沙子位置变化，继续下落
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
							jz compare_right ;当前位于游戏区最左边

							mov eax, @loopVar
							add eax, fieldW
							dec eax ;当前沙子左下方
							mov bl, [arrSands+eax]
							cmp bl ,-1
							jne compare_right ;左下方有沙子

							mov ecx, @loopVar
							mov bl, [arrSands+ecx]
							mov [arrSands+ecx], -1
							add ecx, fieldW
							dec ecx
							mov [arrSands+ecx], bl
							mov @flag, 1 ;有沙子位置变化，继续下落
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
							jae sand_affected ;当前位于游戏区最右边

							mov eax, @loopVar
							add eax, fieldW
							inc eax ;当前沙子右下方
							mov bl, [arrSands+eax]
							cmp bl ,-1
							jne sand_affected ;右下方有沙子

							mov ecx, @loopVar
							mov bl, [arrSands+ecx]
							mov [arrSands+ecx], -1
							add ecx, fieldW
							inc ecx
							mov [arrSands+ecx], bl
							mov @flag, 1 ;有沙子位置变化，继续下落
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
					.if @flag == 0 ;没有沙子可以移动，开始尝试消除
						mov bPlay, 1
						mov eax, windowRealH
						mov sandChangedMax, eax

						;初始化广度优先搜索
						mov @loopVar, 0
						mov queueHead, 0
						mov queueTail, 0
						mov sandsToClearTotal, 0
						init_bfs:
							mov eax, @loopVar
							mov bl, [arrSands+eax]
							.if bl == -1
								;所有没有沙子的位置设为已访问，相当于障碍
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
							mov @loopVar, eax ;从下往上查找
							mov @currentColorId, -1
							mov @brickX1, 0 ;单色连通区域是否碰到左侧边缘
							mov @brickX2, 0 ;单色连通区域是否碰到右侧边缘
							mov @szScore, 0

						start_bfs:
							dec @loopVar
							cmp @loopVar, 0
							je bfs_finished
						
						check_queue:
							mov eax, queueHead
							cmp eax, queueTail
							je check_result ;队列为空，本次查找结束
							jmp search_bottom ;队列非空，继续查找

						check_result:
							mov eax, @brickX1
							and eax, @brickX2
							cmp eax, 1
							jne search_next ;本次查找未找到符合要求的区域，查找下一个未被访问的位置
							
							mov @loopVar2, 0 ;待消除沙子的地址偏移量
							mov @szScore, 0 ;消除的沙子数

						clear_sands: ;消除所有连通的沙子
							mov eax, @loopVar2
							cmp eax, sandsToClearTotal
							je bfs_finished

							mov ecx, [arrSandsToClear+eax]
							mov [arrSands+ecx], -1
							inc @szScore
							add @loopVar2, 4
							jmp clear_sands

						search_bottom:
							;队首元素所有未被访问的相邻位置入队
							mov eax, queueHead
							shl eax, 2
							mov ecx, [arrQueueBFS+eax]
							mov @loopVar3, ecx ;队首位置
							mov eax, ecx
							xor edx, edx
							mov ebx, fieldW
							div ebx
							mov @blockAbsX, edx ;队首位置x坐标
							mov @blockAbsY, eax ;队首位置y坐标

							mov eax, windowRealH
							dec eax
							cmp eax, @blockAbsY
							jbe search_right ;处于最下方
							mov ecx, @loopVar3
							add ecx, fieldW ;队首位置下方相邻位置
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne search_right ;仅搜索与队首位置颜色相同的相邻位置
							cmp [arrSandsVisited+ecx], 1
							je search_right ;该位置已被访问
							invoke BFSInQueue, ecx

						search_right:
							mov eax, fieldW
							dec eax
							cmp eax, @blockAbsX
							jbe search_top ;处于最右侧
							mov ecx, @loopVar3
							inc ecx ;队首位置右侧相邻位置
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne search_top ;仅搜索与队首位置颜色相同的相邻位置
							cmp [arrSandsVisited+ecx], 1
							je search_top ;该位置已被访问
							invoke BFSInQueue, ecx

						search_top:
							cmp @blockAbsY, 0
							jz search_left ;处于最上方
							mov ecx, @loopVar3
							sub ecx, fieldW ;队首位置上方相邻位置
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne search_left ;仅搜索与队首位置颜色相同的相邻位置
							cmp [arrSandsVisited+ecx], 1
							je search_left ;该位置已被访问
							invoke BFSInQueue, ecx

						search_left:
							cmp @blockAbsX, 0
							jz visit_head ;处于最左侧
							mov ecx, @loopVar3
							dec ecx ;队首位置左侧相邻位置
							mov al, [arrSands+ecx]
							cmp al, @currentColorId
							jne visit_head ;仅搜索与队首位置颜色相同的相邻位置
							cmp [arrSandsVisited+ecx], 1
							je visit_head ;该位置已被访问
							invoke BFSInQueue, ecx
						
						visit_head:
							;队首元素出队
							mov eax, queueHead
							shl eax, 2
							mov ecx, [arrQueueBFS+eax]
							mov eax, ecx
							xor edx, edx
							mov ebx, fieldW
							div ebx
							.if edx == 0
								mov @brickX1, 1 ;碰到最左侧
							.elseif edx == FIELD_W - 1
								mov @brickX2, 1 ;碰到最右侧
							.endif
							mov eax, sandsToClearTotal
							mov [arrSandsToClear+eax], ecx
							add eax, 4
							mov sandsToClearTotal, eax

							inc queueHead
							.if queueHead == QUEUE_SIZE_MAX
								mov queueHead, 0 ;队首指针返回数组起始位置
							.endif

							jmp check_queue

						search_next:
							mov @brickX1, 0
							mov @brickX2, 0
							mov sandsToClearTotal, 0 ;清空待消除的沙子
							mov eax, @loopVar
							cmp [arrSandsVisited+eax], 1
							je start_bfs ;当前位置已被访问，跳过

							invoke BFSInQueue, @loopVar
							mov eax, @loopVar
							mov bl, [arrSands+eax]
							mov @currentColorId, bl
							jmp start_bfs

						bfs_finished:
							mov eax, @brickX1
							and eax, @brickX2
							.if eax == 0
								;没有任何沙子被消除，得分倍率初始化
								mov scoreMult, 1
							.else
								mov eax, @szScore
								mul scoreMult
								mul scoreBase
								add score, eax
								inc clears
								.if scoreMult == 128 ;最高128倍
								.else
									shl scoreMult, 1 ;得分倍率翻倍
								.endif
								mov bPlay, -1 ;沙子重新开始下落
							.endif
							
						.if bPlay == 1
							;检测沙子是否超过界限
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
								;沙子超过界限，结束游戏
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
					invoke InvalidateRect, hWnd, addr stRect, FALSE ;仅更新游戏区域
				.endif

		.elseif uMsg == WM_CLOSE ;关闭窗口
			invoke DestroyWindow, hWinMain
			invoke PostQuitMessage, NULL

		.elseif uMsg == WM_LBUTTONUP ;鼠标点击
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

		.elseif uMsg == WM_KEYUP ;按键操作
			.if bPlay == 1 ;允许操作
				;游戏区域的x坐标范围在leftBarW至rightBarX之间
				mov eax, leftBarW
				add eax, fieldW
				mov @rightBarX, eax
				.if wParam == VK_LEFT ;左方向键：左移
					mov eax, brickX
					sub eax, blockSize
					mov brickX, eax
					jmp wall_jump
				.elseif wParam == VK_RIGHT ;右方向键：右移
					mov eax, brickX
					add eax, blockSize
					mov brickX, eax
					jmp wall_jump
				.elseif wParam == 41h ;A键：逆时针旋转
					mov eax, brickDir
					dec eax
					.if eax == -1
						mov brickDir, 3
					.else
						mov brickDir, eax
					.endif
					jmp wall_jump
				.elseif wParam == 44h ;D键：顺时针旋转
					mov eax, brickDir
					inc eax
					.if eax == 4
						mov brickDir, 0
					.else
						mov brickDir, eax
					.endif
					wall_jump: ;将超出游戏区域的砖块移回游戏区域内
						;砖块左边x坐标：x1 = arrBrickW[brickId * 8 + brickDir * 2] * blockSize + brickX
						;砖块右边x坐标：x2 = (arrBrickW[brickId * 8 + brickDir * 2 + 1] + 1) * blockSize + brickX
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
						mov @brickX1, ebx ;砖块左边x坐标
						mov eax, @brickX2
						mul blockSize
						mov ebx, eax
						add ebx, brickX
						mov @brickX2, ebx ;砖块右边x坐标

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
				.elseif wParam == VK_SPACE ;空格键：放置
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
								sub ebx, leftBarW ;将绝对坐标转化为相对坐标
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
						cmp @loopVar, 4 ;绘制4个方块
						jne sandify
						invoke NewBrick
						mov bPlay, -1 ;沙子开始下落，禁止玩家操作直到沙子运动停止
				.endif
				mov eax, leftBarW
				mov dword ptr [stRect], eax
				mov dword ptr [stRect+4], 0
				mov eax, LEFT_BAR_W + FIELD_W + 1
				mov dword ptr [stRect+8], eax
				mov eax, WINDOW_H - FIELD_H + 1
				mov dword ptr [stRect+12], eax
				invoke InvalidateRect, hWnd, addr stRect, FALSE ;仅更新放置区域
			.endif

		.else ;默认情况
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

	_WinMain proc ;创建Windows窗口
		local @stWndClass: WNDCLASSEX
		local @stMsg: MSG
		local @stRect: RECT
		local @paddingW ;窗口边框的宽度
		
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

		;获取窗口句柄
		invoke GetModuleHandle, NULL
		mov hInstance, eax
		invoke RtlZeroMemory, addr @stWndClass, sizeof @stWndClass
		push hInstance
		pop @stWndClass.hInstance

		;获取光标
		invoke LoadCursor, 0, IDC_ARROW
		mov @stWndClass.hCursor, eax

		;设置窗口样式
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

		;消息循环
		.while TRUE
			invoke GetMessage, addr @stMsg, NULL, 0, 0
			.break .if eax == 0 ;退出窗口
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
