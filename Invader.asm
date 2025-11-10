;Invader.asm
CODESEG

proc PrintTopInvaders
    push bp
    mov bp, sp
    sub sp, 4
    ;line: bp - 2 (Y position)
    ;row: bp - 4 (X position)

    mov ax, [TopInvadersPrintStartLine] ; Correct: Load starting LINE (Y)
    mov [bp - 2], ax

    xor bx, bx ;current invader #

    mov cx, 3
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

    pop bp
    ret
endp PrintTopInvaders

proc PrintBottomInvaders
    push bp
    mov bp, sp
    sub sp, 4

    mov ax, [BottomInvadersPrintStartLine]
    mov [bp - 2], ax

    xor bx, bx 

    mov cx, 3
@@printInvadersLine_B: 
    push cx

    mov ax, [BottomInvadersPrintStartRow] 
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


    sub [word ptr bp - 4], 36 

    loop @@printInvader_B 

    add [word ptr bp - 2], 20 
    pop cx
    loop @@printInvadersLine_B 

    add sp, 4

    pop bp
    ret
endp PrintBottomInvaders


proc ClearTopInvaders
    push bp
    mov bp, sp

    sub sp, 4

    mov ax, [TopInvadersPrintStartLine]
    mov [bp - 2], ax

    xor bx, bx 

    mov cx, 3
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

    pop bp
    ret
endp ClearTopInvaders


proc ClearBottomInvaders
    push bp
    mov bp, sp

    sub sp, 4


    mov ax, [BottomInvadersPrintStartLine] 
    mov [bp - 2], ax

    xor bx, bx 

    mov cx, 3
@@printInvadersLine_CB:
    push cx

    mov ax, [BottomInvadersPrintStartRow] 
    mov [bp - 4], ax


    mov cx, 8
@@printInvader_CB: 
    push cx

    push bx

    cmp [byte ptr BottomInvadersStatusArray + bx], 1 
    jne @@skipInvader_CB

    
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

@@skipInvader_CB: 
    pop bx
    inc bx

    pop cx


    add [word ptr bp - 4], 36 

    loop @@printInvader_CB 

    add [word ptr bp - 2], 20 

    pop cx
    loop @@printInvadersLine_CB 

    add sp, 4

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
    je @@reverseDirectionGoDown_B 


    inc [byte ptr BottomInvadersMovesToSideDone]   


    cmp [byte ptr BottomInvadersMoveRightBool], 1 
    je @@moveRight_B 


    sub [word ptr BottomInvadersPrintStartRow], 4  
    jmp @@procEnd_B 


@@moveRight_B: 
    add [word ptr BottomInvadersPrintStartRow], 4 
    jmp @@procEnd_B 

@@reverseDirectionGoDown_B: 
    xor [byte ptr BottomInvadersMoveRightBool], 1  
    mov [byte ptr BottomInvadersMovesToSideDone], 0  
    add [word ptr BottomInvadersPrintStartLine], 4 
    
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
    call PrintBottomInvaders
    call UpdateBottomInvadersLocation
    mov [byte ptr BottomInvadersLoopMoveCounter], 0 
    jmp @@procEnd_B 

@@skipPrint_B: 
    inc [byte ptr BottomInvadersLoopMoveCounter] 

@@procEnd_B: 
    ret
endp CheckAndMoveBottomInvaders


; -------------------------------------------------
; Choosing a random invader to shoot
; If not found after a few tries, no shot performed
; Updating shot location, adding it to shots arrays
; Ben Raz
; -------------------------------------------------
proc InvadersRandomShot
	push bp
	mov bp, sp

	;Check if max reached:
	mov al, [InvadersShootingCurrentAmount]
	cmp [InvadersShootingMaxAmount], al
	je @@procEnd

	;Shoot only after invaders movement:
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
	sub sp, 2 ;create local variable counting fails
	;address: bp - 2
	mov [word ptr bp - 2], 0

@@getRandomInvader:
	;Get a random invader
	push 24
	call Random
	mov si, ax

	;Check if invader 'alive':
	cmp [byte ptr TopInvadersStatusArray + si], 0
	jne @@setShootingLocation

	inc [word ptr bp - 2]

	cmp [word ptr bp - 2], 4
	jne @@getRandomInvader

	add sp, 2 ;clear local variable
	jmp @@procEnd


@@setShootingLocation:
	add sp, 2 ;clear local variable

	mov bl, 8
	div bl

	;al = lines, ah = rows
	push ax

	mov dx, [TopInvadersPrintStartLine]
	add dx, 15 ;set to buttom of first invader

	;set correct line:
	xor ah, ah
	mov bl, 20
	mul bl

	add dx, ax
	mov bl, [InvadersShootingCurrentAmount]
	xor bh, bh
	shl bx, 1
	mov [InvadersShootingLineLocations + bx], dx


	pop ax
	shr ax, 8 ;rows # in al
	mov bl, 35
	mul bl

	add ax, 10 ;set to middle of invader
	add ax, [TopInvadersPrintStartRow]

	mov bl, [InvadersShootingCurrentAmount]
	xor bh, bh
	shl bx, 1
	mov [InvadersShootingRowLocations + bx], ax

	inc [byte ptr InvadersShootingCurrentAmount]

@@procEnd:
	pop bp
	ret
endp InvadersRandomShot


; -------------------------------------------------------
; Moving invaders' shots down, checking if reached bottom
; If reached bottom, shot is removed
; Ben Raz
; -------------------------------------------------------
proc UpdateInvadersShots

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
	ret
endp UpdateInvadersShots


; --------------------------------------------------------------------
; Reading invaders' shots status, and printing them by saved locations
; Ben Raz
; --------------------------------------------------------------------
proc PrintInvadersShots
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
	ret
endp PrintInvadersShots


; --------------------------------------------------
; Replacing printed invaders' shots with black color
; (before printing at updated locations)
; Ben Raz
; --------------------------------------------------
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


; ------------------------------------------------
; Checks if an invader was hi by player's shot
; If true, invader is marked as 'dead' and removed
; Ben Raz
; ------------------------------------------------
proc CheckAndKillTopInvader
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
    ret
endp CheckAndKillTopInvader

proc CheckAndKillBottomInvader
    ;Check if invader killed:
    ;Check above:
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    dec dx
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_B ; Renamed label

    ;Check below:
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    add dx, 4
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_B ; Renamed label

    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    sub dx, 3
    mov cx, [PlayerShootingRowLocation]
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_B ; Renamed label

    ;Check from left
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    mov cx, [PlayerShootingRowLocation]
    dec cx
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_B ; Renamed label

    ;Check from right
    mov ah, 0Dh
    mov dx, [PlayerShootingLineLocation]
    mov cx, [PlayerShootingRowLocation]
    add cx, 2
    mov bh, 0
    int 10h

    cmp al, GreenColor
    je @@killInvader_B ; Renamed label

    jmp @@procEnd_B ; Renamed label


@@killInvader_B: ; Renamed label
    ;set cursor to top left
    xor bh, bh
    xor dx, dx
    mov ah, 2
    int 10h

    mov ax, [PlayerShootingLineLocation]
    sub ax, [BottomInvadersPrintStartLine] ; <-- USES BOTTOM VARS

    cmp ax, 22
    jb @@killedInLine0_B ; Renamed label

    cmp ax, 0FFE0h
    ja @@killedInLine0_B ; Renamed label

    cmp ax, 42
    jb @@killedInLine1_B ; Renamed label

    push 2
    jmp @@checkKilledRow_B ; Renamed label

@@killedInLine0_B: ; Renamed label
    push 0
    jmp @@checkKilledRow_B ; Renamed label

@@killedInLine1_B: ; Renamed label
    push 1

@@checkKilledRow_B: ; Renamed label
    cmp [byte ptr DebugBool], 1
    jne @@skipLineDebugPrint_B ; Renamed label

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

@@skipLineDebugPrint_B: ; Renamed label
    mov ax, [PlayerShootingRowLocation]
    sub ax, [BottomInvadersPrintStartRow] ; <-- USES BOTTOM VARS
    add ax, 2

    ;In some rare cases startRow is bigger than shootingRow, check:
    cmp ax, 0FFE0h
    jb @@setForRowFind_B ; Renamed label

    xor cx, cx
    jmp @@rowFound_B ; Renamed label

@@setForRowFind_B: ; Renamed label
    xor cx, cx ;row counter
    mov dx, 28
@@checkRow_B: ; Renamed label
    cmp ax, dx
    jb @@rowFound_B ; Renamed label

    add dx, 36
    inc cx
    jmp @@checkRow_B ; Renamed label

@@rowFound_B: ; Renamed label
    cmp [byte ptr DebugBool], 1
    jne @@skipRowDebugPrint_B ; Renamed label

    mov ah, 2
    mov dl, 'R'
    int 21h

    mov dx, cx
    add dl, 30h
    int 21h

@@skipRowDebugPrint_B: ; Renamed label
    pop bx
    ;bx holding line, cx holding row

    shl bx, 3 ;multiply by 8
    add bx, cx

    push bx

    mov [byte ptr BottomInvadersStatusArray + bx], 0 ; <-- USES BOTTOM VARS
    dec [byte ptr BottomInvadersLeftAmount]        ; <-- USES BOTTOM VARS

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
    add dx, [BottomInvadersPrintStartLine] ; <-- USES BOTTOM VARS
    sub dx, 4

    pop ax
    shr ax, 8
    mov bl, 36
    mul bl
    add ax, [BottomInvadersPrintStartRow] ; <-- USES BOTTOM VARS
    sub ax, 4

    push 36
    push 24
    push dx
    push ax
    push BlackColor
    call PrintColor

@@procEnd_B: ; Renamed label
    ret
endp CheckAndKillBottomInvader