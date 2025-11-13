;Invader.asm
CODESEG

proc PrintTopInvaders
    push bp
    mov bp, sp
    sub sp, 4
    ;line: bp - 2 (Y position)
    ;row: bp - 4 (X position)

    push ax
    push bx
    push cx

    mov ax, [TopInvadersPrintStartLine] ; Correct: Load starting LINE (Y)
    mov [bp - 2], ax

    xor bx, bx ;current invader #

    mov cx, 1
@@printInvadersLine:
    push cx

    mov ax, [TopInvadersPrintStartRow] ; **FIXED: Must be START ROW (X)**
    mov [bp - 4], ax


    mov cx, 8
@@printInvader:
    push cx

    push bx

    cmp [byte ptr TopInvadersStatusArray + bx], 1 ; **FIXED: Must check STATUS ARRAY**
    jne @@skipInvader

    
    push [word ptr InvaderFileHandle]
    push InvaderLength
    push InvaderHeight
    push [word ptr bp - 2]
    push [word ptr bp - 4]
    push offset FileReadBuffer
    call PrintBMP

@@skipInvader:
    pop bx
    inc bx

    pop cx


    add [word ptr bp - 4], 36 ; set location for next invader (row/X-axis)

    loop @@printInvader

    add [word ptr bp - 2], 20 ; Set location for next line (line/Y-axis)

    pop cx
    loop @@printInvadersLine

    add sp, 4

    pop cx
    pop bx
    pop ax

    pop bp
    ret
endp PrintTopInvaders

proc PrintBottomInvaders
    push bp
    mov bp, sp
    sub sp, 4

    push ax
    push bx
    push cx

    mov ax, [BottomInvadersPrintStartLine]
    mov [bp - 2], ax

    xor bx, bx 

    mov cx, 1
@@printInvadersLine_B: 
    push cx

    ; --- FIX: CALCULATE LEFT EDGE ---
    ; StartRow is the Rightmost position. 
    ; We subtract 252 (36 * 7) to find the Leftmost position.
    mov ax, [BottomInvadersPrintStartRow] 
    sub ax, 252    
    mov [bp - 4], ax

    mov cx, 8
@@printInvader_B: 
    push cx
    push bx

    cmp [byte ptr BottomInvadersStatusArray + bx], 1 
    jne @@skipInvader_B 
    
    push [word ptr InvaderFileHandle]
    push InvaderLength
    push InvaderHeight
    push [word ptr bp - 2]
    push [word ptr bp - 4]
    push offset FileReadBuffer
    call PrintBMP

@@skipInvader_B: 
    pop bx
    inc bx
    pop cx

    ; --- FIX: MOVE RIGHT (Standard L->R) ---
    add [word ptr bp - 4], 36 

    loop @@printInvader_B 

    add [word ptr bp - 2], 20 
    pop cx
    loop @@printInvadersLine_B 

    add sp, 4
    pop cx
    pop bx
    pop ax
    pop bp
    ret
endp PrintBottomInvaders


proc ClearTopInvaders
    push bp
    mov bp, sp

    sub sp, 4

    push ax
    push bx
    push cx

    mov ax, [TopInvadersPrintStartLine]
    mov [bp - 2], ax

    xor bx, bx 

    mov cx, 1
@@printInvadersLine:
    push cx

    mov ax, [TopInvadersPrintStartRow] ;
    mov [bp - 4], ax


    mov cx, 8
@@printInvader:
    push cx

    push bx

    cmp [byte ptr TopInvadersStatusArray + bx], 1
    jne @@skipInvader

    
    push 30
    push 24
    mov ax, [bp - 2]
    sub ax, 4
    push ax
    mov ax, [bp - 4]
    sub ax, 4
    push ax
    push BlackColor
    call PrintColor

@@skipInvader:
    pop bx
    inc bx

    pop cx


    add [word ptr bp - 4], 36 

    loop @@printInvader

    add [word ptr bp - 2], 20 

    pop cx
    loop @@printInvadersLine

    add sp, 4

    pop cx
    pop bx
    pop ax

    pop bp
    ret
endp ClearTopInvaders


proc ClearBottomInvaders
    push bp
    mov bp, sp
    sub sp, 4

    push ax
    push bx
    push cx

    mov ax, [BottomInvadersPrintStartLine] 
    mov [bp - 2], ax

    xor bx, bx 

    mov cx, 1
@@printInvadersLine_CB:
    push cx

    ; --- FIX: CALCULATE LEFT EDGE ---
    mov ax, [BottomInvadersPrintStartRow] 
    sub ax, 252
    mov [bp - 4], ax

    mov cx, 8
@@printInvader_CB: 
    push cx
    push bx

    ; (Status check removed to fix "Don't Die" bug)
    
    push InvaderHeight ; 32
    push InvaderLength ; 32

    ; Handle Y-coordinate (Crash safety)
    mov ax, [bp - 2]
    cmp ax, 4
    jle @@Y_is_safe
    sub ax, 4
@@Y_is_safe:
    push ax

    ; Handle X-coordinate (Crash safety)
    mov ax, [bp - 4]
    cmp ax, 4
    jle @@X_is_safe
    sub ax, 4
@@X_is_safe:
    push ax
    
    push BlackColor
    call PrintColor

@@skipInvader_CB: 
    pop bx
    inc bx
    pop cx

    ; --- FIX: MOVE RIGHT (Standard L->R) ---
    add [word ptr bp - 4], 36 

    loop @@printInvader_CB 

    add [word ptr bp - 2], 20 
    pop cx
    loop @@printInvadersLine_CB 

    add sp, 4
    pop cx
    pop bx
    pop ax
    pop bp
    ret
endp ClearBottomInvaders



proc UpdateTopInvadersLocation
    cmp [byte ptr TopInvadersMovesToSideDone], 8    
    je @@reverseDirectionGoDown_T


    inc [byte ptr TopInvadersMovesToSideDone]     


    cmp [byte ptr TopInvadersMoveRightBool], 1   
    je @@moveRight_T 

    sub [word ptr TopInvadersPrintStartRow], 4    
    jmp @@procEnd_T 


@@moveRight_T: 
    add [word ptr TopInvadersPrintStartRow], 4    
    jmp @@procEnd_T 

@@reverseDirectionGoDown_T: 
    xor [byte ptr TopInvadersMoveRightBool], 1    
    mov [byte ptr TopInvadersMovesToSideDone], 0    
    add [word ptr TopInvadersPrintStartLine], 4    
    
@@procEnd_T: 
    ret
endp UpdateTopInvadersLocation


proc UpdateBottomInvadersLocation
    cmp [byte ptr BottomInvadersMovesToSideDone], 8   
    je @@reverseDirectionGoUp_B ; Renamed label for clarity

    inc [byte ptr BottomInvadersMovesToSideDone]   

    cmp [byte ptr BottomInvadersMoveRightBool], 1 
    je @@moveRight_B 

    sub [word ptr BottomInvadersPrintStartRow], 4   
    jmp @@procEnd_B 

@@moveRight_B: 
    add [word ptr BottomInvadersPrintStartRow], 4 
    jmp @@procEnd_B 

@@reverseDirectionGoUp_B: 
    xor [byte ptr BottomInvadersMoveRightBool], 1   
    mov [byte ptr BottomInvadersMovesToSideDone], 0   
    
    ; *** START OF FIX ***
    ; Add a safety check before moving up
    mov ax, [word ptr BottomInvadersPrintStartLine]
    cmp ax, 4       ; Check if Y is at 4 (or less)
    jle @@procEnd_B ; If it is, DON'T subtract. Just end.
    
    sub [word ptr BottomInvadersPrintStartLine], 4 ; Move up
    ; *** END OF FIX ***
    
@@procEnd_B: 
    ret
endp UpdateBottomInvadersLocation



proc CheckAndMoveTopInvaders
    cmp [byte ptr TopInvadersLoopMoveCounter], 3 
    jne @@skipPrint_T 


    call ClearTopInvaders
    call PrintTopInvaders
    call UpdateTopInvadersLocation
    mov [byte ptr TopInvadersLoopMoveCounter], 0 
    jmp @@procEnd_T 

@@skipPrint_T: 
    inc [byte ptr TopInvadersLoopMoveCounter] 

@@procEnd_T: 
    ret
endp CheckAndMoveTopInvaders


proc CheckAndMoveBottomInvaders
    cmp [byte ptr BottomInvadersLoopMoveCounter], 3 
    jne @@skipPrint_B 

    ;Move:
    call ClearBottomInvaders
    call UpdateBottomInvadersLocation
    call PrintBottomInvaders

    mov [byte ptr BottomInvadersLoopMoveCounter], 0 
    jmp @@procEnd_B 

@@skipPrint_B: 
    inc [byte ptr BottomInvadersLoopMoveCounter] 

@@procEnd_B: 
    ret
endp CheckAndMoveBottomInvaders


proc InvadersRandomShot
    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx
    push si

    ;Check if max reached:
    mov al, [InvadersShootingCurrentAmount]
    cmp [InvadersShootingMaxAmount], al
    je @@procEnd

    ;Shoot only after invaders movement:
    ; --- FIX: Use TopInvaders... variable ---
    cmp [byte ptr TopInvadersLoopMoveCounter], 3
    jne @@procEnd


    mov al, [InvadersShootingMaxAmount]
    sub al, 2
    cmp al, [InvadersShootingCurrentAmount]
    ja @@shootRandomly

    ;Shoot or not, randomly:
    ;Chance of 3/4 to shoot
    push 4
    call Random
    cmp ax, 0
    je @@procEnd

@@shootRandomly:
    ; --- This stack frame setup is from the OG code and is SAFE ---
    sub sp, 2 ;create local variable counting fails
    mov [word ptr bp - 2], 0

@@getRandomInvader:
    ;Get a random invader
    ; --- FIX: Change 24 (3 rows) to 8 (1 row) ---
    push 8
    call Random
    mov si, ax

    ;Check if invader 'alive':
    ; --- FIX: Use TopInvaders... variable ---
    cmp [byte ptr TopInvadersStatusArray + si], 0
    jne @@setShootingLocation

    inc [word ptr bp - 2]

    cmp [word ptr bp - 2], 4
    jne @@getRandomInvader

    add sp, 2 ;clear local variable
    jmp @@procEnd


@@setShootingLocation:
    add sp, 2 ;clear local variable

    ; --- LOGIC FOR 1 ROW ---
    ; (The OG logic is fine, AX is 0-7, so DIV BL gives AL=0, AH=0-7)
    mov bl, 8
    div bl

    ;al = lines (0), ah = rows (0-7)
    push ax

    ; --- FIX: Use TopInvaders... variable ---
    mov dx, [TopInvadersPrintStartLine]
    add dx, 15 ;set to buttom of first invader

    ;set correct line:
    xor ah, ah
    mov bl, 20
    mul bl    ; (AL is 0, so AX becomes 0, this is correct)

    add dx, ax
    mov bl, [InvadersShootingCurrentAmount]
    xor bh, bh
    shl bx, 1
    mov [word ptr InvadersShootingLineLocations + bx], dx ; Add 'word ptr'

    pop ax
    shr ax, 8 ;rows # in al (0-7)
    mov bl, 35
    mul bl

    add ax, 10 ;set to middle of invader
    ; --- FIX: Use TopInvaders... variable ---
    add ax, [TopInvadersPrintStartRow]

    mov bl, [InvadersShootingCurrentAmount]
    xor bh, bh
    shl bx, 1
    mov [word ptr InvadersShootingRowLocations + bx], ax ; Add 'word ptr'

    inc [byte ptr InvadersShootingCurrentAmount]

@@procEnd:
    ; --- RESTORE ALL REGISTERS (reverse order) ---
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ; -------------------------------------------

    pop bp
    ret
endp InvadersRandomShot


; -------------------------------------------------------
; Moving invaders' shots down, checking if reached bottom
; If reached bottom, shot is removed
; Ben Raz
; -------------------------------------------------------
proc UpdateInvadersShots

    push ax
    push cx
    push si
    push di
    push es

	cmp [byte ptr InvadersShootingCurrentAmount], 0
	je @@procEnd

	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]

	xor di, di

@@moveShooting:
	add [word ptr InvadersShootingLineLocations + di], 10

	add di, 2
	loop @@moveShooting

	;Check if oldest shot reached the bottom:
	cmp [word ptr InvadersShootingLineLocations], StatsAreaBorderLine - 12
	jb @@procEnd

	;Remove shot:
	mov [word ptr InvadersShootingLineLocations], 0

	mov [word ptr InvadersShootingRowLocations], 0

	;If it's the only shot, no need to move others in array:
	cmp [byte ptr InvadersShootingCurrentAmount], 1
	je @@decShootingsAmount

	cld

	mov ax, ds
	mov es, ax

	mov si, offset InvadersShootingLineLocations
	mov di, si
	add si, 2

	mov cx, 9
	rep movsw


	mov si, offset InvadersShootingRowLocations
	mov di, si
	add si, 2

	mov cx, 9
	rep movsw

@@decShootingsAmount:
	dec [byte ptr InvadersShootingCurrentAmount]


@@procEnd:
    pop es
    pop di
    pop si
    pop cx
    pop ax
	ret
endp UpdateInvadersShots


; --------------------------------------------------------------------
; Reading invaders' shots status, and printing them by saved locations
; Ben Raz
; --------------------------------------------------------------------
proc PrintInvadersShots
    push ax
    push cx
    push si

	cmp [byte ptr InvadersShootingCurrentAmount], 0
	je @@procEnd

	xor si, si

	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]

@@printShooting:
	push cx
	push si

	push ShootingLength
	push ShootingHeight
	push [word ptr InvadersShootingLineLocations + si]
	push [word ptr InvadersShootingRowLocations + si]
	push BlueColor
	call PrintColor

	pop si
	add si, 2

	pop cx
	loop @@printShooting


@@procEnd:
    pop si
    pop cx
    pop ax
	ret
endp PrintInvadersShots


proc ClearInvadersShots

	xor si, si
	
	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]

	cmp cx, 0
	jne @@clearShot

	ret

@@clearShot:
	push cx
	push si

	push ShootingLength
	push ShootingHeight
	push [InvadersShootingLineLocations + si]
	push [InvadersShootingRowLocations + si]
	push BlackColor
	call PrintColor

	pop si
	add si, 2
	pop cx
	loop @@clearShot
	
	ret
endp ClearInvadersShots


proc CheckAndKillTopInvader

    push ax
    push bx
    push cx
    push dx
    ;Check if invader killed:
    ;Check above:
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    dec dx
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_T ; Renamed label

    ;Check below:
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    add dx, 4
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_T ; Renamed label

    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    sub dx, 3
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_T ; Renamed label

    ;Check from left
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    mov cx, [PlayerShootingRowLocation]
    dec cx
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_T ; Renamed label

    ;Check from right
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    mov cx, [PlayerShootingRowLocation]
    add cx, 2
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_T ; Renamed label

    jmp @@procEnd_T ; Renamed label


@@killInvader_T: ; Renamed label
    ;set cursor to top left
    xor bh, bh
    xor dx, dx
    mov ah, 2
    int 10h

    mov ax, [PlayerShootingLineLocation]
    sub ax, [TopInvadersPrintStartLine] ; <-- RENAMED

    cmp ax, 22
    jb @@killedInLine0_T ; Renamed label

    cmp ax, 0FFE0h
    ja @@killedInLine0_T ; Renamed label

    cmp ax, 42
    jb @@killedInLine1_T ; Renamed label

    push 2
    jmp @@checkKilledRow_T ; Renamed label

@@killedInLine0_T: ; Renamed label
    push 0
    jmp @@checkKilledRow_T ; Renamed label

@@killedInLine1_T: ; Renamed label
    push 1

@@checkKilledRow_T: ; Renamed label
    cmp [byte ptr DebugBool], 1
    jne @@skipLineDebugPrint_T ; Renamed label

; Print hit debug info (if used debug flag):
    mov ah, 2
    xor bh, bh
    xor dx, dx
    int 10h

    mov dl, 'L'
    int 21h

    pop dx
    push dx
    add dl, 30h
    mov ah, 2
    int 21h

@@skipLineDebugPrint_T: ; Renamed label
    mov ax, [PlayerShootingRowLocation]
    sub ax, [TopInvadersPrintStartRow] ; <-- RENAMED
    add ax, 2

    ;In some rare cases startRow is bigger than shootingRow, check:
    cmp ax, 0FFE0h
    jb @@setForRowFind_T ; Renamed label

    xor cx, cx
    jmp @@rowFound_T ; Renamed label

@@setForRowFind_T: ; Renamed label
    xor cx, cx ;row counter
    mov dx, 28
@@checkRow_T: ; Renamed label
    cmp ax, dx
    jb @@rowFound_T ; Renamed label

    add dx, 36
    inc cx
    jmp @@checkRow_T ; Renamed label

@@rowFound_T: ; Renamed label
    cmp [byte ptr DebugBool], 1
    jne @@skipRowDebugPrint_T ; Renamed label

    mov ah, 2
    mov dl, 'R'
    int 21h

    mov dx, cx
    add dl, 30h
    int 21h

@@skipRowDebugPrint_T: ; Renamed label
    pop bx
    ;bx holding line, cx holding row

    shl bx, 3 ;multiply by 8
    add bx, cx

    push bx

    mov [byte ptr TopInvadersStatusArray + bx], 0 ; <-- RENAMED
    dec [byte ptr TopInvadersLeftAmount]        ; <-- RENAMED

    mov [byte ptr PlayerShootingExists], 0
    mov [word ptr PlayerShootingLineLocation], 0
    mov [word ptr PlayerShootingRowLocation], 0

    ;Increase and update score:
    inc [byte ptr Score]
    call UpdateScoreStat

    pop ax
    ;clear killed invader print
    mov bl, 8
    div bl
    push ax
    xor ah, ah
    mov bl, 20
    mul bl

    mov dx, ax
    add dx, [TopInvadersPrintStartLine] ; <-- RENAMED
    sub dx, 4

    pop ax
    shr ax, 8
    mov bl, 36
    mul bl
    add ax, [TopInvadersPrintStartRow] ; <-- RENAMED
    sub ax, 4

    push 36
    push 24
    push dx
    push ax
    push BlackColor
    call PrintColor

@@procEnd_T: ; Renamed label
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp CheckAndKillTopInvader

proc CheckAndKillBottomInvader
    push ax
    push bx
    push cx
    push dx

    ; --- 1. CHECK FOR HIT (UNCHANGED) ---
    ;Check above:
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    dec dx
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h
    cmp al, GreenColor
    je @@killInvader_B 

    ;Check below:
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    add dx, 4
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h
    cmp al, GreenColor
    je @@killInvader_B 

    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    sub dx, 3
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h
    cmp al, GreenColor
    je @@killInvader_B 

    ;Check from left
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    mov cx, [PlayerShootingRowLocation]
    dec cx
    mov bh, 0
    int 10h
    cmp al, GreenColor
    je @@killInvader_B 

    ;Check from right
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    mov cx, [PlayerShootingRowLocation]
    add cx, 2
    mov bh, 0
    int 10h
    cmp al, GreenColor
    je @@killInvader_B 

    jmp @@procEnd_B 


@@killInvader_B: 
    ; Hide the hit pixel
    xor bh, bh
    xor dx, dx
    mov ah, 2
    int 10h

    ; --- 2. FIND WHICH INVADER WAS HIT ---
    
    ; Start scanning at the LEFT edge (StartRow - 252)
    mov dx, [BottomInvadersPrintStartRow]
    sub dx, 252   
    
    xor cx, cx    ; Index 0 (Leftmost)
    mov ax, [PlayerShootingRowLocation] ; Bullet X

@@scanLoop_B:
    ; Check if Bullet is inside current invader [dx ... dx+32]
    
    cmp ax, dx          
    jb @@nextInvader_B  
    
    push dx
    add dx, 32          
    cmp ax, dx
    pop dx
    ja @@nextInvader_B  

    ; IF WE ARE HERE, IT'S A MATCH!
    jmp @@invaderFound_B

@@nextInvader_B:
    add dx, 36     ; Move X to the RIGHT
    inc cx         ; Next Index (0 -> 1 -> 2...)
    
    cmp cx, 8
    jb @@scanLoop_B 

    jmp @@procEnd_B

@@invaderFound_B:

    ; --- 3. KILL THE INVADER ---
    
    mov bx, cx
    push bx ; Save index

    mov [byte ptr BottomInvadersStatusArray + bx], 0 
    dec [byte ptr BottomInvadersLeftAmount]        

    mov [byte ptr PlayerShootingExists], 0
    mov [word ptr PlayerShootingLineLocation], 0
    mov [word ptr PlayerShootingRowLocation], 0

    inc [byte ptr Score]
    call UpdateScoreStat

    ; --- 4. CLEAR THE SPECIFIC INVADER ---
    pop ax ; Restore Index
    
    ; Calculate the X position using Left-to-Right math
    ; X = (StartRow - 252) + (Index * 36)
    
    push ax
    mov bl, 36
    mul bl      ; AX = Index * 36
    
    mov bx, [BottomInvadersPrintStartRow]
    sub bx, 252 ; BX = Left Start
    add ax, bx  ; AX = Correct X coordinate
    
    ; Standard Clear Logic
    mov dx, [BottomInvadersPrintStartLine]
    sub dx, 4
    push dx ; Y
    
    sub ax, 4
    push ax ; X

    push 36 ; Width
    push 24 ; Height
    
    ; Fix Stack Order for PrintColor (Width, Height, Y, X, Color)
    pop bx ; Height
    pop si ; Width
    pop ax ; X
    pop dx ; Y
    
    push si ; 36
    push bx ; 24
    push dx ; Y
    push ax ; X
    push BlackColor
    call PrintColor

@@procEnd_B: 
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp CheckAndKillBottomInvader