.MODEL SMALL
.STACK 100H

.DATA
    users db 50 dup ('$')         ; Array to store usernames (max 5 users, 10 characters each)
    passwords db 50 dup ('$')     ; Array to store passwords (max 5 users, 10 characters each)
    user_count db 0               ; Counter for the number of registered users
    input_buffer db 20, ?, 20 dup('$')  ; First byte is buffer size, second is actual input length
    current_user db 0             ; Store index of current user being checked
    
    ; Main menu messages
    msg_menu db 13,10,'1. Signup', 0Dh, 0Ah, '2. Login', 0Dh, 0Ah, 'Enter your choice: $'
    msg_signup_success db 13,10,'Signup Successful! Please login to continue.', 0Dh, 0Ah, '$'
    msg_login_success db 13,10,'Login Successful!', 0Dh, 0Ah, '$'
    msg_login_fail db 13,10,'Login Failed!', 0Dh, 0Ah, '$'
    msg_user_limit db 13,10,'User limit reached!', 0Dh, 0Ah, '$'
    msg_enter_username db 13,10,'Enter Username: $'
    msg_enter_password db 13,10,'Enter Password: $'
    msg_press_any_key db 13,10,'Press any key to continue...', 0Dh, 0Ah, '$'
    
    ; Banking menu messages
    msg_banking_menu db 13,10,'===== Banking Menu =====', 0Dh, 0Ah
        db '1. Display Balance & Transactions', 0Dh, 0Ah
        db '2. Cash Deposit', 0Dh, 0Ah
        db '3. Cash Withdrawal', 0Dh, 0Ah
        db '4. Print Receipt', 0Dh, 0Ah
        db '5. Foreign Exchange Calculator', 0Dh, 0Ah
        db '6. Logout', 0Dh, 0Ah
        db 'Enter your choice: $'

    ; Foreign Exchange Calculator Messages and Variables
    msg_forex_menu db 13,10,'===== Foreign Exchange Calculator =====', 0Dh, 0Ah
        db '1. USD to BDT', 0Dh, 0Ah
        db '2. BDT to USD', 0Dh, 0Ah
        db '3. Back to Banking Menu', 0Dh, 0Ah
        db 'Enter your choice: $'
    msg_enter_amount db 13,10,'Enter amount (max 5 digits): $'
    msg_result db 13,10,'Result: $'
    msg_overflow db 13,10,'Error: Amount too large!$', 0Dh, 0Ah, '$'
    msg_divide_error db 13,10,'Division Error! Please try a smaller amount.$'
    old_int0_offset dw ?
    old_int0_segment dw ?
    
    ; Forex variables - simplified
    amount_buffer db 6, ?, 6 dup('$')
    conversion_choice db 0    ; Add this to store choice
    temp dw 0
    temp2 dw 0
    ten dw 10
    exchange_rate dw 110     ; 1 USD = 110 BDT 
    
    ;Omer
    msg_balance_label db "Balance: $", 0
    msg_deposit_prompt db "Enter amount to deposit: $", 0
    msg_press_key db 0Dh, 0Ah, "Press any key to return to menu...$", 0 
    msg_withdraw db "Enter amount you want to withdraw: $"
    deposit_input db 6, ?, 5 dup(0)  ; Buffer for deposit input (max 5 digits)
    balance db "0000$", 0 
    ;new
    b dw 5 dup(00000) 
    nowbalance dw ? 
    deposited dw ? 
    transaction_count dw 0
    withdraw dw ?  
    tr_success db "Your Transaction Was successful. $" 
    tr_fail db "Your Tansaction Was Unsuccessful.$" 
    msg_recipt db "Please Collect Your Banking Recipt$" 
    
    MAX_TRANSACTIONS equ 50
    transaction_amounts dw MAX_TRANSACTIONS dup(0)
    transaction_types db MAX_TRANSACTIONS dup('$') 

    msg_deposit db 'Deposit$'
    msg_withdrawal db 'Withdrawal$'
    msg_receipt_header db 13,10,'===== Transaction Receipt =====',13,10,'$'
    msg_receipt_line db 'Type: $'
    msg_receipt_amount db ' Amount: $'
    msg_no_transactions db 'No transactions to display.$'     


.CODE
MAIN PROC
    ; Save old INT 0 vector
    mov ax, 0
    mov es, ax
    mov ax, es:[0]    ; Get old INT 0 offset
    mov old_int0_offset, ax
    mov ax, es:[2]    ; Get old INT 0 segment
    mov old_int0_segment, ax
    
    ; Set new INT 0 vector
    cli               ; Disable interrupts
    mov word ptr es:[0], offset divide_error_handler
    mov ax, cs
    mov word ptr es:[2], ax
    sti               ; Enable interrupts

    ; Initialize DS
    MOV AX, @DATA
    MOV DS, AX

main_menu:
    ; Display menu
    lea dx, msg_menu
    mov ah, 09h
    int 21h

    ; Get user choice
    mov ah, 01h
    int 21h
    sub al, '0'      ; Convert ASCII to number
    cmp al, 1
    je signup
    cmp al, 2
    je login
    jmp main_menu    ; Invalid choice, return to menu

signup:
    ; Check if user limit reached
    mov al, user_count
    cmp al, 5        ; Maximum 5 users
    jae user_limit_reached

    ; Prompt for username
    lea dx, msg_enter_username
    mov ah, 09h
    int 21h
    call get_input   ; Read username input
    
    ; Store username in array
    mov si, offset users
    xor ax, ax
    mov al, user_count
    mov cx, 10
    mul cx
    add si, ax
    call store_input ; Store the username

    ; Prompt for password
    lea dx, msg_enter_password
    mov ah, 09h
    int 21h
    call get_input   ; Read password input
    
    ; Store password in array
    mov si, offset passwords
    xor ax, ax
    mov al, user_count
    mov cx, 10
    mul cx
    add si, ax
    call store_input ; Store the password

    ; Increment user count
    inc user_count

    ; Display success message
    lea dx, msg_signup_success
    mov ah, 09h
    int 21h

    ; Wait for key press
    lea dx, msg_press_any_key
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h

    jmp login        ; Go directly to login after signup

login:
    ; Initialize current_user counter
    mov current_user, 0
    
    ; Prompt for username
    lea dx, msg_enter_username
    mov ah, 09h
    int 21h
    call get_input   ; Read username input

    ; Start checking with first user
    mov current_user, 0

check_next_user:
    ; Check if we've checked all users
    mov al, current_user
    cmp al, user_count
    jae login_fail    ; If we've checked all users and found no match, fail

    ; Calculate offset for current user
    mov si, offset users
    xor ax, ax
    mov al, current_user
    mov cx, 10
    mul cx
    add si, ax

    ; Compare username
    call compare_strings
    cmp ax, 1        ; Check if strings match
    je username_found

    ; Username didn't match, try next user
    inc current_user
    jmp check_next_user

username_found:
    ; Username matched, now check password
    lea dx, msg_enter_password
    mov ah, 09h
    int 21h
    call get_input   ; Read password input

    ; Calculate offset for current user's password
    mov si, offset passwords
    xor ax, ax
    mov al, current_user
    mov cx, 10
    mul cx
    add si, ax

    ; Compare password
    call compare_strings
    cmp ax, 1        ; Check if strings match
    jne login_fail   ; If password doesn't match, fail

    ; Both username and password matched
    lea dx, msg_login_success
    mov ah, 09h
    int 21h

    ; Wait for key press
    lea dx, msg_press_any_key
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h

    jmp banking_menu  ; Jump to banking menu after successful login

banking_menu:
    ; Clear screen (optional)
    mov ax, 0003h
    int 10h 
    mov bx,0

    ; Display banking menu
    lea dx, msg_banking_menu
    mov ah, 09h
    int 21h

    ; Get user choice
    mov ah, 01h
    int 21h
    sub al, '0'      ; Convert ASCII to number

    cmp al, 1
    je DisplayBalance        ;update later
    cmp al, 2
    je deposit             
    
    cmp al, 3 
    je Cashwithdraw
    cmp al, 4
    je recipt
    cmp al, 5
    je forex_calculator  ; Jump to forex calculator
    cmp al, 6
    je main_menu     ; Logout - return to main menu
    
    jmp banking_menu ; Invalid choice, stay in banking menu


DisplayBalance:
    call NEXT_LINE
    lea dx, msg_balance_label
    mov ah, 9
    int 21h

    mov ax, [b] 
               
    call display_number    

    lea dx, msg_press_key
    mov ah, 9
    int 21h

    mov ah, 1
    int 21h
    jmp banking_menu



deposit:
    call NEXT_LINE
    
    lea dx, msg_deposit_prompt
    mov ah, 9
    int 21h

    call INPUT_NUMBER      

    mov ax, [b]          
    add ax, cx           
    mov [b], ax            
    mov nowbalance,ax  
    
   
    ; Add transaction
    mov ax, cx  ; Amount
    mov bl, 0   ; Type: 0 for deposit
    call add_transaction
   
   
    
    lea dx, msg_press_key
    mov ah, 9
    int 21h

    mov ah, 1
    int 21h
    jmp banking_menu

Cashwithdraw:  
    call NEXT_LINE
    lea dx, msg_withdraw
    mov ah,9
    int 21h 
    
    call INPUT_NUMBER
    
    
    mov ax, [b]          
    sub ax, cx           
    mov [b], ax            
    mov nowbalance,ax 
    
    ; Add transaction
    mov ax, cx  ; Amount
    mov bl, 1   ; Type: 1 for withdrawal
    call add_transaction
    
   
    call NEXT_LINE
    
    
    cmp ax,cx
    jl notenoughfund 
    
     
    lea dx,tr_success
    mov ah,9
    int 21h 
    
    lea dx,msg_press_key
    mov ah,9
    int 21h
    mov ah,1
    int 21h
    jmp banking_menu
    
notenoughfund:
    lea dx,tr_fail
    mov ah,9
    int 21h 
    
    call NEXT_LINE
    lea dx,msg_press_key
    mov ah,9
    int 21h
    
    mov ah,1
    int 21h 
    jmp banking_menu
    
recipt:
    call print_receipt
    jmp banking_menu
    
    
add_transaction PROC
    ; Input: AX = amount, BL = type (0 for deposit, 1 for withdrawal)
    push bx
    push cx
    push si

    mov si, transaction_count
    shl si, 1  ; Multiply by 2 for word-sized elements
    mov transaction_amounts[si], ax

    mov si, transaction_count
    mov transaction_types[si], bl

    inc transaction_count

    pop si
    pop cx
    pop bx
    ret
add_transaction ENDP

print_receipt PROC
    push ax
    push bx
    push cx
    push dx
    push si

    ; Print receipt header
    lea dx, msg_receipt_header
    mov ah, 09h
    int 21h

    ; Check if there are any transactions
    mov ax, transaction_count
    cmp ax, 0
    je no_transactions

    mov cx, transaction_count
    xor si, si  ; Initialize index to 0

print_transaction_loop:
    ; Print transaction type
    lea dx, msg_receipt_line
    mov ah, 09h
    int 21h

    mov al, transaction_types[si]
    cmp al, 0
    je print_deposit
    jmp print_withdrawal

print_deposit:
    lea dx, msg_deposit
    jmp print_type

print_withdrawal:
    lea dx, msg_withdrawal

print_type:
    mov ah, 09h
    int 21h

    ; Print amount
    lea dx, msg_receipt_amount
    mov ah, 09h
    int 21h

    mov ax, transaction_amounts[si]
    call display_number

    ; New line
    call NEXT_LINE

    add si, 2  ; Move to next transaction (word-sized)
    loop print_transaction_loop

    jmp end_receipt

no_transactions:
    lea dx, msg_no_transactions
    mov ah, 09h
    int 21h

end_receipt:
    ; Wait for key press
    lea dx, msg_press_key
    mov ah, 09h
    int 21h

    mov ah, 01h
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_receipt ENDP



INPUT_NUMBER:
      MOV AX,0
      MOV CX,0
INPUT_LOOP:
      MOV AH,1         
      INT 21H         
      CMP AL,0DH       
      JE INPUT_DONE    
    
      AND AX,000FH     
      PUSH AX          
      MOV AX,10
      MUL CX           
      MOV CX,AX
      POP AX           
      ADD CX,AX       
      JMP INPUT_LOOP
    
INPUT_DONE:
      RET


NEXT_LINE:
      MOV AH,2
      MOV DL,0DH
      INT 21H
      MOV DL,0AH
      INT 21H
      RET 
 
                                                            







                                                           
forex_calculator:
    lea dx, msg_forex_menu
    mov ah, 09h
    int 21h

    ; Get user choice
    mov ah, 01h
    int 21h
    sub al, '0'
    
    cmp al, 3
    je banking_menu
    
    ; Store choice properly
    mov conversion_choice, al    ; Store 1 for USD->BDT, 2 for BDT->USD
    
    cmp al, 1
    je get_amount
    cmp al, 2
    je get_amount
    jmp forex_calculator

get_amount:
    ; Get amount
    lea dx, msg_enter_amount
    mov ah, 09h
    int 21h

    ; Read amount
    mov ah, 0Ah
    lea dx, amount_buffer
    int 21h

    ; Convert string to number
    xor ax, ax
    mov cl, [amount_buffer+1]
    mov si, offset amount_buffer + 2
    xor bx, bx

convert_loop:
    mul ten
    mov bl, [si]
    sub bl, '0'
    add ax, bx
    inc si
    loop convert_loop

    mov temp, ax    ; Save input amount
    
    ; Check conversion type
    mov al, conversion_choice
    cmp al, 1
    je usd_to_bdt_conv
    jmp bdt_to_usd_conv

usd_to_bdt_conv:
    ; Convert USD to BDT (multiply by 110)
    mov ax, temp        ; Get USD amount
    mov bx, exchange_rate
    mul bx              ; DX:AX = amount * 110
    
    ; Check for overflow
    cmp dx, 0
    jne overflow_error
    
    mov temp, ax       ; Store result
    xor dx, dx         ; Clear DX for display
    jmp display_whole_result

bdt_to_usd_conv:
    ; Convert BDT to USD
    mov ax, temp       ; Get BDT amount
    mov dx, 0          ; Clear dx
    
    ; First divide by exchange rate (110) to avoid overflow
    mov bx, exchange_rate
    div bx            ; AX = amount / 110, DX = remainder
    mov temp, ax      ; Store whole number part
    
    ; Handle decimal part
    mov ax, dx        ; Get remainder
    mov dx, 0
    mov bx, 100       ; Multiply remainder by 100 for 2 decimal places
    mul bx            ; DX:AX = remainder * 100
    
    mov bx, exchange_rate
    div bx            ; AX = decimal part
    
    mov temp2, ax     ; Store decimal part
    jmp display_decimal_result

display_whole_result:
    ; For USD to BDT - show whole number only
    lea dx, msg_result
    mov ah, 09h
    int 21h

    mov ax, temp
    call display_number
    jmp forex_end

display_decimal_result:
    ; For BDT to USD - show number with decimals
    lea dx, msg_result
    mov ah, 09h
    int 21h

    ; Display whole number part
    mov ax, temp
    call display_number

    ; Display decimal point
    mov dl, '.'
    mov ah, 02h
    int 21h

    ; Display decimal part with leading zeros if needed
    mov ax, temp2
    call display_number_padded
    jmp forex_end

overflow_error:
    ; Display overflow error message
    lea dx, msg_overflow
    mov ah, 09h
    int 21h
    jmp forex_end

forex_end:              ; New label for ending forex calculations
    ; Print newline
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    int 21h

    ; Wait for key press
    lea dx, msg_press_any_key
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h

    jmp forex_calculator    ; Return to forex calculator menu

login_fail:
    ; Display failure message
    lea dx, msg_login_fail
    mov ah, 09h
    int 21h
    jmp main_menu

user_limit_reached:
    lea dx, msg_user_limit
    mov ah, 09h
    int 21h
    jmp main_menu

    ; Before exiting, restore old INT 0 vector 
    
;exit_program:       Made change here. AS Mismatch was occuring. It doesn't effect other works
    ;cli
    ;mov ax, 0
    ;mov es, ax
    ;mov ax, old_int0_offset
    ;mov es:[0], ax
    ;mov ax, old_int0_segment
    ;mov es:[2], ax
    ;sti
    
    ;mov ah, 4Ch
    ;int 21h

;MAIN ENDP
    


; Divide error handler
divide_error_handler PROC
    push ax
    push dx
    
    mov ax, @DATA
    mov ds, ax
    
    ; Display error message
    lea dx, msg_divide_error
    mov ah, 9
    int 21h
    
    pop dx
    pop ax
    
    ; Jump back to forex calculator
    jmp forex_calculator
divide_error_handler ENDP

; Separate procedures
display_number_padded PROC
    push ax
    push bx
    push cx
    push dx

    ; Always show two digits
    mov bx, ax        ; Save number
    cmp ax, 10
    jae no_leading_zero
    
    ; Show leading zero
    push ax
    mov dl, '0'
    mov ah, 02h
    int 21h
    pop ax

no_leading_zero:
    mov ax, bx
    call display_number
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
display_number_padded ENDP

get_input PROC
    mov ah, 0Ah
    lea dx, input_buffer
    int 21h
    ret
ENDP

store_input PROC
    push cx          
    lea di, input_buffer + 2 
    mov cl, [input_buffer+1] 
    mov ch, 0        
    
store_loop:
    mov al, [di]     
    mov [si], al     
    inc di
    inc si
    loop store_loop
    
    pop cx           
    ret
ENDP

compare_strings PROC
    push cx          
    push si
    push di

    mov cl, [input_buffer+1] 
    mov ch, 0        
    lea di, input_buffer + 2 

compare_loop:
    mov al, [di]     
    mov bl, [si]     
    cmp al, bl       
    jne not_equal    
    inc di           
    inc si
    loop compare_loop

    pop di
    pop si
    pop cx
    mov ax, 1        
    ret

not_equal:
    pop di
    pop si
    pop cx
    xor ax, ax       
    ret
ENDP

display_number PROC
    push ax
    push bx
    push cx
    push dx

    mov cx, 0          ; Digit counter
    mov bx, 10         ; Divisor

convert_to_ascii:
    xor dx, dx         ; Clear DX for division
    div bx             ; Divide by 10
    push dx            ; Save remainder
    inc cx             ; Increment counter
    test ax, ax        ; Check if quotient is 0
    jnz convert_to_ascii

print_digits:
    pop dx             ; Get digit
    add dl, '0'        ; Convert to ASCII
    mov ah, 02h        ; DOS print character function
    int 21h
    loop print_digits

    pop dx
    pop cx
    pop bx
    pop ax
    ret
display_number ENDP 



END MAIN




