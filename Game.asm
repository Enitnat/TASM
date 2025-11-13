;Game.asm
DATASEG
include "Strings.asm"

	DebugBool						db	0

	;Files:

	RandomFileName					db	'Assets/Random.txt', 0
	RandomFileHandle				dw	?

	ScoresFileName					db	'Assets/Scores.txt', 0
	ScoresFileHandle				dw	?

	ScoreTableFileName				db	'Assets/ScoreTab.bmp', 0
	ScoreTableFileHandle			dw	?

	AskSaveFileName					db	'Assets/AskSave.bmp', 0
	AskSaveFileHandle				dw	?

	MainMenuFileName				db	'Assets/MainMenu.bmp',0
	MainMenuFileHandle				dw	?

	InstructionsFileName			db	'Assets/Instruct.bmp',0
	InstructionsFileHandle			dw	?

	InvaderFileName					db	'Assets/Invader.bmp',0
	InvaderFileHandle				dw	?
	InvaderLength					equ	32
	InvaderHeight					equ	32


	ShooterFileName					db	'Assets/Shooter.bmp', 0
	ShooterFileHandle				dw	?
	ShooterLength					equ	16
	ShooterHeight					equ	16


	HeartFileName					db	'Assets/Heart.bmp', 0
	HeartFileHandle					dw	?
	HeartLength						equ	16
	HeartHeight						equ	16

;Enemies move & status info:
	TopInvadersMoveRightBool			db	?
	TopInvadersMovesToSideDone			db	?
	TopInvadersPrintStartLine			dw	?
	TopInvadersPrintStartRow			dw	?
	TopInvadersLeftAmount				db	?
	TopInvadersStatusArray				db	8 dup (?)

		TopInvadersLoopMoveCounter	  	db	?

	BottomInvadersMoveRightBool    db  ?
	BottomInvadersMovesToSideDone  db  ?
	BottomInvadersPrintStartLine   dw  ?
	BottomInvadersPrintStartRow    dw  ?
	BottomInvadersLeftAmount       db  ?
	BottomInvadersStatusArray      db  8 dup (?)

	BottomInvadersLoopMoveCounter  db  ?

	ShooterLineLocation				equ 90
	ShooterRowLocation				dw	?

	ShootingLength					equ	2
	ShootingHeight					equ	4

	PlayerShootingExists			db	?
	PlayerShootingLineLocation		dw	?
	PlayerShootingRowLocation		dw	?
	
	PlayerDirection             db  1

	InvadersShootingMaxAmount		db	?
	InvadersShootingCurrentAmount	db	?
	InvadersShootingLineLocations	dw	10 dup (?)
	InvadersShootingRowLocations	dw	10 dup (?)

	Score							db	?
	LivesRemaining					db	?
	Level							db	?

	DidNotDieInLevelBool			db	?


	HeartsPrintStartLine			equ	182
	HeartsPrintStartRow				equ	125

	StatsAreaBorderLine				equ	175

	FileReadBuffer					db	320 dup (?)

	;Colors:
	BlackColor						equ	0
	GreenColor						equ	30h
	RedColor						equ	40
	BlueColor						equ	54
	WhiteColor						equ	255

CODESEG
include "Invader.asm"
include "Procs.asm"

; -----------------------------------------------------------
; Prints the lower game area with score, lives, level, etc...
; Ben Raz
; -----------------------------------------------------------
proc PrintStatsArea
	; Print border:
	push 320
	push 2
	push StatsAreaBorderLine
	push 0
	push 100
	call PrintColor

	;Print labels:

	;Level label:
	xor bh, bh
	mov dh, 23
	mov dl, 1
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset LevelString
	int 21h


	;Score label:
	xor bh, bh
	mov dh, 23
	mov dl, 29
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset ScoreString
	int 21h

	ret
endp PrintStatsArea


;----------------------------------
; Updates the lives shown on screen
; Ben Raz
;----------------------------------
proc UpdateLives
	;Clear previous hearts:
	push 64
	push 14
	push HeartsPrintStartLine
	push HeartsPrintStartRow
	push BlackColor
	call PrintColor

	push offset HeartFileName
	push offset HeartFileHandle
	call OpenFile

	;Print amount of lifes remaining:
	xor ch, ch
	mov cl, [LivesRemaining]

	mov bx, HeartsPrintStartRow

@@printHeart:
	push bx
	push cx

	push [HeartFileHandle]
	push HeartLength
	push HeartHeight
	push HeartsPrintStartLine
	push bx
	push offset FileReadBuffer
	call PrintBMP

	pop cx
	pop bx
	add bx, 20
	loop @@printHeart

	push [HeartFileHandle]
	call CloseFile

	ret
endp UpdateLives


;----------------------------------
; Updates the score shown on screen
; Ben Raz
;----------------------------------
proc UpdateScoreStat
	xor bh, bh
	mov dh, 23
	mov dl, 36
	mov ah, 2
	int 10h

	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	ret
endp UpdateScoreStat


; ---------------------------------------
; Updates the level # and the score count
; Ben Raz
; ---------------------------------------
proc UpdateStats
	;Update level:
	xor bh, bh
	mov dh, 23
	mov dl, 8
	mov ah, 2
	int 10h

	mov ah, 2
	mov dl, [byte ptr Level]
	add dl, 30h
	int 21h

	;Update score:
	call UpdateScoreStat

	ret
endp UpdateStats


; ------------------------------------------------------------
; Moving invaders + player to initial location, removing shots
; Not getting back dead invaders
; Ben Raz
; ------------------------------------------------------------
proc MoveToStart
	; --- TOP BLOCK ---
    mov [byte ptr TopInvadersMoveRightBool], 1
    mov [byte ptr TopInvadersMovesToSideDone], 0
    mov [byte ptr TopInvadersLoopMoveCounter], 0
    mov [word ptr TopInvadersPrintStartLine], 3
    mov [word ptr TopInvadersPrintStartRow], 8

    ; --- BOTTOM BLOCK ---                    ; <<< NEW BLOCK
    mov [byte ptr BottomInvadersMoveRightBool], 0  ; 0 = move LEFT
    mov [byte ptr BottomInvadersMovesToSideDone], 0
    mov [byte ptr BottomInvadersLoopMoveCounter], 0
    mov [word ptr BottomInvadersPrintStartLine], 140   ; Start at line 100
    mov [word ptr BottomInvadersPrintStartRow], 280  
	
	mov [word ptr ShooterRowLocation], 152 
    mov [byte ptr PlayerShootingExists], 0

	mov [word ptr ShooterLineLocation], 90
    mov [byte ptr PlayerDirection], 1

	mov [byte ptr PlayerShootingExists], 0

	mov [byte ptr InvadersShootingCurrentAmount], 0


	cld
	push ds
	pop es

	;Zero invaders shots locations:
	xor ax, ax

	mov di, offset InvadersShootingLineLocations
	mov cx, 10
	rep stosw

	mov di, offset InvadersShootingRowLocations
	mov cx, 10
	rep stosw

	ret
endp MoveToStart

; ------------------------------------------------------------
; Resetting invaders locations, shootings, etc for a new level
; Ben Raz
; ------------------------------------------------------------
proc InitializeLevel
	mov [TopInvadersLeftAmount], 8         
    mov [BottomInvadersLeftAmount], 8

	cmp [byte ptr Level], 1
	jne @@checkLevelTwo

	mov [byte ptr InvadersShootingMaxAmount], 3
	jmp @@resetDidNotDieBool

@@checkLevelTwo:
	cmp [byte ptr Level], 2
	jne @@setLevelThree

	mov [byte ptr InvadersShootingMaxAmount], 5
	jmp @@resetDidNotDieBool

@@setLevelThree:
	mov [byte ptr InvadersShootingMaxAmount], 7

@@resetDidNotDieBool:
    mov [byte ptr DidNotDieInLevelBool], 1 ;true

    call MoveToStart


	cld
	push ds
	pop es

	;Set all TOP invaders as 'active':
    mov di, offset TopInvadersStatusArray
    mov cx, 8
    mov al, 1
    rep stosb

    mov di, offset BottomInvadersStatusArray
    mov cx, 8
    mov al, 1
    rep stosb

	ret
endp InitializeLevel


; -----------------------------------------------
; Resetting every stat to its initial game value,
; and setting the first level
; Ben Raz
; -----------------------------------------------
proc InitializeGame
	mov [byte ptr Score], 0
	mov [byte ptr LivesRemaining], 3
	mov [byte ptr Level], 1


	call InitializeLevel

	ret
endp InitializeGame

; ------------------------------------------------
; Checking if player had died from invaders' shots
; TIGHTENED COLLISION BOX to match sprite dimensions (approx 16x16)
; ------------------------------------------------
proc CheckIfPlayerDied
    xor ch, ch
    mov cl, [InvadersShootingCurrentAmount]
    cmp cx, 0
    je @@returnZero

    xor si, si

@@checkShot:
    ;--- VERTICAL (LINE) CHECK ---
    
    ; 1. Check from above (Top boundary of the ship)
    mov ax, ShooterLineLocation
    ; WAS: sub ax, 3  <-- REMOVED PADDING
    cmp ax, [InvadersShootingLineLocations + si] ; Check if shot is BELOW the player's top edge
    ja @@checkNextShot

    ; 2. Check from below (Bottom boundary of the ship)
    ; WAS: add ax, 3  <-- REMOVED PADDING
    add ax, 16       ; Use actual height (ShooterHeight equ 16)
    cmp ax, [InvadersShootingLineLocations + si] ; Check if shot is ABOVE the player's bottom edge
    jb @@checkNextShot

    ;--- HORIZONTAL (ROW) CHECK ---
    
    ; 3. Check from left (Left boundary of the ship)
    mov ax, [ShooterRowLocation]
    ; WAS: dec ax   <-- REMOVED PADDING
    cmp ax, [InvadersShootingRowLocations + si] ; Check if shot is RIGHT of the player's left edge
    ja @@checkNextShot

    ; 4. Check from right (Right boundary of the ship)
    add ax, 16 ; Use actual length (ShooterLength equ 16)
    cmp ax, [InvadersShootingRowLocations + si] ; Check if shot is LEFT of the player's right edge
    jb @@checkNextShot

    ;Player killed: (Collision detected)
    mov ax, 1
    ret

@@checkNextShot:
    inc si
    loop @@checkShot

@@returnZero:
    ;Player not killed:
    xor ax, ax 
    ret
endp CheckIfPlayerDied



proc CheckIfTopReachedBottom
    mov cx, 8
    mov bx, bx

@@checkLineZero_T:
    cmp [TopInvadersStatusArray + bx], 0  ; <-- RENAMED
    jne @@lineZeroNotEmpty_T
    inc bx
    loop @@checkLineZero_T

    jmp @@invadersDidNotReachBottom_T

@@lineZeroNotEmpty_T:
    cmp [word ptr TopInvadersPrintStartLine], ShooterLineLocation - 5
    ja @@invadersReachedBottom_T

@@invadersDidNotReachBottom_T:
    xor ax, ax
    ret

@@invadersReachedBottom_T:
    mov ax, 1
    ret
endp CheckIfTopReachedBottom

; <<< NEW PROCEDURE >>>
proc CheckIfBottomReachedBottom
    mov cx, 8
    mov bx, bx

@@checkLineZero_B:
    cmp [BottomInvadersStatusArray + bx], 0  ; <-- USES BOTTOM VARS
    jne @@lineZeroNotEmpty_B
    inc bx
    loop @@checkLineZero_B

    jmp @@invadersDidNotReachBottom_B


@@lineZeroNotEmpty_B:
    cmp [word ptr BottomInvadersPrintStartLine], ShooterLineLocation + 35
    jb @@invadersReachedBottom_B

@@invadersDidNotReachBottom_B:
    xor ax, ax
    ret

@@invadersReachedBottom_B:
    mov ax, 1
    ret
endp CheckIfBottomReachedBottom


; -----------------------------------------------------------
; Initiating the game, combining the game parts together
; Handles shooter + Invaders hits and deaths, movements, etc.
; Ben Raz
; -----------------------------------------------------------
proc PlayGame
	push offset InvaderFileName
	push offset InvaderFileHandle
	call OpenFile

	push offset ShooterFileName
	push offset ShooterFileHandle
	call OpenFile

	call InitializeGame

	call ClearScreen


@@firstLevelPrint:
	call PrintStatsArea
	call UpdateStats
	call UpdateLives

	call CheckAndMoveTopInvaders    
    call CheckAndMoveBottomInvaders 

	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP


	call PrintTopInvaders
    call PrintBottomInvaders


	;Print countdown to start:
	mov cx, 3
	mov dx, 33h
@@printCountdownNum:
	push cx
	push dx

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 19
	int 10h

	pop dx
	push dx
	mov ah, 2
	int 21h

	push 18
	call Delay

	pop dx
	dec dx
	pop cx
	loop @@printCountdownNum

	;clear number:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 19
	int 10h

	xor dl, dl
	mov ah, 2
	int 21h


@@readKey:
	mov ah, 1
	int 16h

	jz @@checkShotStatus

	;Clean buffer:
 	push ax
 	xor al, al
 	mov ah, 0ch
 	int 21h
 	pop ax
	
	;Check which key was pressed:
	cmp ah, 1 ;Esc
	je @@procEnd

	cmp ah, 39h ;Space
	je @@shootPressed

	cmp ah, 4Bh ;Left
	jne @@checkRight

	cmp [word ptr ShooterRowLocation], 21
	jb @@clearShot

	;Clear current shooter print:
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	sub [word ptr ShooterRowLocation], 10
	jmp @@printAgain

@@checkRight:
	cmp ah, 4Dh
	jne @@checkUp

	cmp [word ptr ShooterRowLocation], 290
	ja @@clearShot

	;Clear current shooter print:
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	add [word ptr ShooterRowLocation], 10
	jmp @@printAgain

@@checkUp: ; <--- NEW LABEL
    cmp ah, 48h  
    jne @@checkDown

    mov [byte ptr PlayerDirection], 1 
    jmp @@clearShot                   

@@checkDown: ; <--- NEW LABEL
    cmp ah, 50h 
    jne @@readKey

    mov [byte ptr PlayerDirection], 0 
    jmp @@clearShot                   

@@printAgain:
	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

@@checkShotStatus:
	;Check if shooting already exists in screen:
	cmp [byte ptr PlayerShootingExists], 0
	jne @@moveShooting

	jmp @@clearShot

@@shootPressed:
	;Check if shooting already exists in screen:
	cmp [byte ptr PlayerShootingExists], 0
	jne @@moveShooting

@@initiateShot:
	;Set initial shot location:
	mov ax, ShooterLineLocation
	sub ax, 6
	mov [word ptr PlayerShootingLineLocation], ax
	mov ax, [ShooterRowLocation]
	add ax, 7
	mov [word ptr PlayerShootingRowLocation], ax

	mov [byte ptr PlayerShootingExists], 1
	jmp @@printShooting

@@moveShooting:
	; Check if shot reached top or bottom boundary (10 or StatsAreaBorderLine)
    cmp [byte ptr PlayerDirection], 1 ; Check if direction is UP
    je @@checkBoundaryUp

    ; Direction is DOWN
    cmp [word ptr PlayerShootingLineLocation], StatsAreaBorderLine - 6 ; Check against stat bar (or slightly above)
    ja @@removeShot ; If below boundary, remove shot

    add [word ptr PlayerShootingLineLocation], 10 ; Move DOWN 10 pixels
    jmp @@printShooting

@@checkBoundaryUp:
    cmp [word ptr PlayerShootingLineLocation], 10 
    jb @@removeShot 

    sub [word ptr PlayerShootingLineLocation], 10 


@@printShooting:
	push ShootingLength
	push ShootingHeight
	push [word ptr PlayerShootingLineLocation]
	push [word ptr PlayerShootingRowLocation]
	push RedColor
	call PrintColor

	jmp @@clearShot

@@removeShot:
	mov [byte ptr PlayerShootingExists], 0
	mov [word ptr PlayerShootingLineLocation], 0
	mov [word ptr PlayerShootingRowLocation], 0

@@clearShot:
	push 2
	call Delay

	push ShootingLength
	push ShootingHeight
	push [word ptr PlayerShootingLineLocation]
	push [word ptr PlayerShootingRowLocation]
	push BlackColor
	call PrintColor

	mov al, [TopInvadersLeftAmount]      
	add al, [BottomInvadersLeftAmount]    
	cmp al, 0                       
	je @@setNewLevel

    call CheckAndKillTopInvader              
    call CheckAndKillBottomInvader        

@@moveInvaders:
	call ClearInvadersShots

    call CheckAndMoveTopInvaders
    call CheckAndMoveBottomInvaders
    call CheckIfTopReachedBottom
	cmp ax, 1
	je @@playerDied

    call CheckIfBottomReachedBottom
	cmp ax, 1
	je @@playerDied

	call UpdateInvadersShots
	call InvadersRandomShot
	call printInvadersShots


	call CheckIfPlayerDied
	cmp ax, 0
	je @@readKey

@@playerDied:
	;Player died:
	push 18
	call Delay

	;decrease amount of lives left, check if 0 left:
	dec [byte ptr LivesRemaining]
	cmp [byte ptr LivesRemaining], 0
	je @@printDied

	;Clear screan without stats area:
	push 320
	push StatsAreaBorderLine
	push 0 ;line
	push 0 ;row
	push BlackColor
	call PrintColor

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 8
	int 10h

	;tell user he was hit, -5 score...
	mov ah, 9
	mov dx, offset HitString
	int 21h

; Nice blink animation for death:
	mov cx, 3
@@blinkShooter:
	push cx

	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	push 6
	call Delay

	push [word ptr ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

	push 6
	call Delay

	pop cx
	loop @@blinkShooter

	;sub 5 score if possible, if he doesn't have 5 yet, just reset to 0:
	cmp [byte ptr Score], 5
	jb @@resetScoreAfterDeath

	sub [byte ptr Score], 5
	jmp @@resetBeforeContinueAfterDeath


@@resetScoreAfterDeath:
	mov [byte ptr Score], 0

@@resetBeforeContinueAfterDeath:
	call MoveToStart

	mov [byte ptr DidNotDieInLevelBool], 0 ;false


	push 24
	call Delay

	call ClearScreen

	
	jmp @@firstLevelPrint


	jmp @@readKey

@@printDied:
	call ClearScreen
; Print a message when game is over:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 15
	int 10h

	mov ah, 9
	mov dx, offset GameOverString
	int 21h

	;print actual score #:
	mov ah, 2
	xor bh, bh
	mov dh, 13
	mov dl, 10
	int 10h

	mov ah, 9
	mov dx, offset YouEarnedXString
	int 21h
	
	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	mov ah, 9
	mov dx, offset ScoreWordString
	int 21h
	
	push 54
	call Delay

	jmp @@procEnd


@@setNewLevel:
	cmp [byte ptr DidNotDieInLevelBool], 1
	jne @@SkipPerfectLevelBonus

	add [byte ptr Score], 5 ;special bonus for perfect level (no death in level)

	;print bonus message:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 8
	int 10h

	mov ah, 9
	mov dx, offset PerfectLevelString
	int 21h

	push 24
	call Delay

	call ClearScreen


@@SkipPerfectLevelBonus:

	cmp [byte ptr Level], 3
	je @@printWin


	inc [byte ptr Level]
	call InitializeLevel

	call ClearScreen
	jmp @@firstLevelPrint

@@printWin:
; Print win message to user (finished 3 levels):
	mov ah, 9
	mov dx, offset WinString
	int 21h

	;print actual score #:
	mov ah, 2
	xor bh, bh
	mov dh, 13
	mov dl, 15
	int 10h

	mov ah, 9
	mov dx, offset YouEarnedXString
	int 21h

	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	mov ah, 9
	mov dx, offset ScoreWordString
	int 21h


@@procEnd:
	push [ShooterFileHandle]
	call CloseFile

	push [InvaderFileHandle]
	call CloseFile

	ret
endp PlayGame