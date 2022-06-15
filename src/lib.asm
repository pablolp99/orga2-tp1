global intCmp
global intClone
global intDelete
global intPrint
global strCmp
global strClone
global strDelete
global strPrint
global strLen
global arrayNew
global arrayGetSize
global arrayAddLast
global arrayGet
global arrayRemove
global arraySwap
global arrayDelete
global listNew
global listGetSize
global listAddFirst
global listGet
global listRemove
global listSwap
global listClone
global listDelete
; global listPrint
global cardNew
global cardGetSuit
global cardGetNumber
global cardGetStacked
global cardCmp
global cardClone
global cardAddStacked
global cardDelete
global cardPrint

section .rodata
	intFmt: db "%d", 0    
	strFmt: db "%s", 0
	strNull: db "NULL",0
	llaveOpen: db "{",0
	separate: db "-",0
	llaveClose: db "}",0

	%define NULL_POINTER 0 ; Puntero a Null

	%define INT_SIZE 4

	%define LIST_ELEM_DATA 0
	%define LIST_ELEM_NEXT 8
	%define LIST_ELEM_PREV 16
	%define LIST_ELEM_TOTAL_SIZE 24

	%define LIST_TYPE 0
	%define LIST_SIZE 4
	%define LIST_FIRST 8
	%define LIST_LAST 16
	%define LIST_TOTAL_SIZE 24

	%define ARRAY_SIZE 24 ; 24 bytes

	%define CARD_SUIT 0
	%define CARD_NUMBER 8
	%define CARD_STACKED 16
	%define CARD_SIZE 24
	%define CARD_TYPE 3



section .text

extern malloc
extern free
extern fprintf

extern getCloneFunction
extern getDeleteFunction

extern listAddLast
extern listPrint

; ** Int **
; int32_t intCmp(int32_t* a, int32_t* b)
intCmp:
    ; *a -> RDI 
    ; *b -> RSI
    xor rax, rax    ; EQUAL 0
    mov ecx, [rdi]

    cmp ecx, [rsi]   
    je .retIntCmp
    jg .greater

    mov rax, 1      ; LOWER 1
    jmp .retIntCmp

    .greater:
    mov rax, -1     ; GREATER -1

    .retIntCmp:
    ret

; int32_t* intClone(int32_t* a)
intClone:
    ; *a -> RDI
    push rdi            ; Alineo pila y guardo *a

	mov rdi, INT_SIZE   ; Pido 4bytes (32bits)
    call malloc         ; Devuelve en RAX la posicion de memoria allocated

    pop rdi             ; Recupero *a
    mov edi, [rdi]      ; Obtengo a
    mov [rax], edi      ; Copio a en la memoria pedida

    ret

; void intDelete(int32_t* a)
intDelete:
    ; *a -> RDI
	call free
    ret

; void intPrint(int32_t* a, FILE* pFile)
intPrint:
    ; *a     -> RDI
    ; *pFile -> RSI
    push rbp
	mov rbp, rsp

    mov edx, [rdi]      ; rdx -> int32_t 
    mov rdi, rsi        ; rdi -> FILE*
    mov rsi, intFmt     ; rsi -> Formato
	call fprintf        

    pop rbp
    ret

; ** String **

; int32_t strCmp(char* a, char* b)
strCmp:
	; [a] -> rdi
	; [b] -> rsi
	push rbp
	mov rbp, rsp

	.cmpCycle:
	; Veo el char
	mov dl, [rsi]
	cmp BYTE [rdi], dl

	jl .jumpLessCmp
	jg .jumpGreaterCmp

	; Si llego aca, son =
	; Y si es 0, termino el string
	cmp BYTE [rdi], 0
	je .jumpEqualCmp

	inc rdi
	inc rsi
	jmp .cmpCycle

	.jumpLessCmp:
	mov rax, 1
	jmp .cmpRet

	.jumpGreaterCmp:
	mov rax, -1
	jmp .cmpRet

	.jumpEqualCmp:
	mov rax, 0

	.cmpRet:
	pop rbp
	ret

; char* strClone(char* a)
; Clona una string
strClone:
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	; Guardo la posicion del string original
	mov r12, rdi

	; Calculo la longitud del string para pedir memoria
	call strLen
	; Tengo en rax el tamano del string
	mov rdi, rax
	; Sumo 1 al tamano del string
	inc rdi
	call malloc
	; Tengo en rax el espacio pedido
	; Primero lo guardo para no perderlo
	mov r13, rax

	; Ahora voy char por char copiando, hasta llegar al \0
	.cloneCycle:
	cmp BYTE [r12], 0
	; Si es 0, termino el string
	je .strCloneRet
	; Si no, copio a [rax] el char
	mov dl, [r12]
	mov BYTE [rax], dl
	; Y avanzo rax y r12, para copiar el siguiente
	inc rax
	inc r12
	jmp .cloneCycle

	.strCloneRet:
	; Copio el 0 al final del string
	mov BYTE [rax], 0

	mov rax, r13

	pop r14
	pop r13
	pop r12
	pop rbp
	ret

; void strDelete(char* a)
strDelete:
	push rbp
	mov rbp, rsp

	; Llama a free del puntero pasado
	call free

	pop rbp
	ret

; void strPrint(char* a, FILE* pFile)
strPrint:
	push rbp
	mov rbp, rsp

	; Muevo el char* a rdx
	mov rdx, rdi

	; Si el string es vacio seteo NULL
	mov cl, [rdi]
	cmp cl, 0
	jne noEmpty
	mov rdx, strNull

	noEmpty:
	; Muevo a RDI el puntero pFile (RSI)
	mov rdi, rsi
	; Copio a RSI el formato
	mov rsi, strFmt
	; call printf
	call fprintf

	pop rbp
	ret

	; uint32_t strLen(char* a)
strLen:
	; [a] -> rdi
	; ret -> rax

	push rbp
	mov rbp, rsp

	; Inicializo un contador en 0
	mov rax, 0

	.compareCycle:
	mov cl, [rdi]
	cmp cl, 0
	je .strLenRet

	inc rax
	inc rdi
	jmp .compareCycle

	.strLenRet:
	pop rbp
	ret

; ** Array **

; array_t* arrayNew(type_t t, uint8_t capacity)
arrayNew:
	; RDI -> t
	; RSI -> capacity
	; ---
	; RAX -> *array_t
	push rbp
	mov rbp, rsp

	sub rsp, 8
	push r12
	push r13
	push r14

	; Guardo los parametros
	mov r12, rdi
	mov r13, rsi

	mov rdi, ARRAY_SIZE
	; Pido 24 bytes en memoria
	call malloc
	; En RAX la posicion del nuevo bloque de la
	; cabeza del array

	mov [rax], r12
	mov DWORD [rax + 4], 0
	mov [rax + 8], r13
	mov QWORD [rax + 16], NULL_POINTER

	mov r14, rax

	; Multiplicar por 8 es shiftear 3 veces a la izquierda
	mov rdi, r13
	shl rdi, 3
	call malloc

	mov [r14 + 16], rax

	mov rax, r14

	pop r14
	pop r13
	pop r12

	add rsp, 8

	pop rbp
	ret

; uint8_t  arrayGetSize(array_t* a)
arrayGetSize:
	xor eax, eax
	mov eax, [rdi+4]
	ret

; void  arrayAddLast(array_t* a, void* data)
arrayAddLast:
	push rbp
	mov rbp, rsp

	sub rsp, 8
	; Me reservo unos registros para varialbes
	push r12
	push r13
	push r14

	mov r12, rdi
	mov r13, rsi

	; Veo si tengo espacio disponible en el arreglo
	xor rdi, rdi
	xor rsi, rsi
	mov edi, [r12 + 4] ; edi <- a.size
	mov esi, [r12 + 8] ; esi <- a.capacity

	; Si a.size >= a.capacity retorno
	cmp rsi, rdi
	je .arrayAddLastRet

	; Entonces a.size < a.capacity 
	; => Tengo por lo menos 1 slot disponible

	; Avanzo a la posicion a[size] (que esa esta vacia)
	; Multiplico a.size * 8
	xor rdi, rdi
	mov edi, [r12 + 4]
	shl edi, 3

	; Avanzo a la pos
	; a.data[i]
	mov r14, [r12 + 16]
	add r14, rdi

	; Busco la funcion de clonacion del tipo
	mov rdi, [r12]
	call getCloneFunction
	; Clono el dato
	mov rdi, r13
	call rax

	; Almaceno el dato
	mov [r14], rax

	; Incremento en 1 el size
	xor rdi, rdi
	mov edi, [r12 + 4]
	inc edi
	mov [r12 + 4], edi

	.arrayAddLastRet:
	pop r14
	pop r13
	pop r12
	add rsp, 8

	pop rbp
	ret

; void* arrayGet(array_t* a, uint8_t i)
arrayGet:
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14

	xor r12, r12
	xor r13, r13

	mov r12, rdi
	mov r13, rsi
	; 1. Verifico que i este en el rango
	cmp DWORD [r12 + 4], r13d
	jle .arrayGetReturn0

	; 2. Accedo al i-esimo elemento
	mov rax, [r12 + 16]
	; Tengo en rax el inicio del arreglo
	; Calculo cuanto me tengo que mover
	shl rsi, 3
	; Es decir, multiplico por 8 el i,
	; esto me da la cantidad de bytes que me
	; tengo que mover
	add rax, rsi
	mov rax, [rax]
	jmp .arrayGetRet

	.arrayGetReturn0:
	mov rax, 0

	.arrayGetRet:
	pop r14
	pop r13
	pop r12

	pop rbp
	ret

; void* arrayRemove(array_t* a, uint8_t i)
arrayRemove:
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14

	mov r12, rdi
	mov r13, rsi

	; 1. Miro si i esta en el rango
	mov r8d, [r12 + 4]
	cmp r8, r13
	jle .arrayRemoveReturn0

	; 2. guardo el i-esimo dato
	shl rsi, 3
	mov rdi, [r12+16]
	add rdi, rsi
	mov r14, [rdi]

	; Ahora tengo que reacomodar los datos
	; Ejemplo, borro el 0
	; [ 0 | 1 | 2 | 3 ]
	;      /   /   /
	;     /   /   /
	;    /   /   /
	;   v   v   v
	; [ 0 | 1 | 2 | 3 ]
	; El 1 -> 0 ; 2 -> 1 ; ...
	; El 3 queda vacio

	; Como estoy parado en i, hago que apunte a i+1
	; Si i+1 esta dentro del size - 1

	; En rdi estoy parado en i puntero, hago que apunte a i+1,
	; pero tengo que ver si i+1 esta en el size (original)
	; Aca ciclo para reordenar

	mov rdx, r13
	mov DWORD r8d, [r12 + 4]
	; veo si i+1 esta en el size

	.arrayRemoveCiclo:	
	inc rdx
	cmp r8, rdx
	; Si esta sigo, sino retorno
	je .arrayRemoveSuccess

	; Si no, sigo el ciclo
	mov rcx, [rdi + 8]
	mov [rdi], rcx
	add rdi, 8

	jmp .arrayRemoveCiclo

	.arrayRemoveSuccess:
	; Retorno el dato
	mov rax, r14
	; Resto 1 al size
	mov rdi, [r12 + 4]
	sub rdi, 1
	mov [r12 + 4], rdi

	jmp .arrayRemoveRet

	.arrayRemoveReturn0:
	mov rax, 0

	.arrayRemoveRet:
	pop r14
	pop r13
	pop r12

	pop rbp
	ret

; void  arraySwap(array_t* a, uint8_t i, uint8_t j)
arraySwap:
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14

	mov r12, rdi

	; Verifico si i y j estan en rango
	cmp [r12 + 4], rsi
	jle .arraySwapRet
	cmp [r12 + 4], rdx
	jle .arraySwapRet

	; Guardo los valores de a[i] y a[j]
	shl rsi, 3
	shl rdx, 3

	mov rdi, [r12 + 16]
	add rdi, rsi
	mov r13, [rdi]

	mov rdi, [r12 + 16]
	add rdi, rdx
	mov r14, [rdi]

	; Los cambio
	; En j -> a[i]
	; En i -> a[j]
	mov [rdi], r13

	sub rdi, rdx
	add rdi, rsi
	mov [rdi], r14

	.arraySwapRet:
	pop r14
	pop r13
	pop r12

	pop rbp
	ret

; void  arrayDelete(array_t* a)
arrayDelete:
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15

	mov r12, rdi
	; Obtengo la funcion delete del tipo del array
	mov edi, [r12]
	call getDeleteFunction
	mov r13, rax

	; Itero por el arreglo para hacer el delete de cada elemento

	mov r14, [r12 + 16]
	; Inicializo un contador en size
	mov r15d, [r12 + 4]
	cmp r15d, 0
	jz .noItero

	.arrayDeleteCycle:
	; Pongo en rdi el elemento
	mov rdi, [r14]
	; Llamo a la deleteFunction del tipo
	call r13
	add r14, 8
	sub r15d, 1
	cmp r15d, 0


	je .arrayDeleteContinueToBlock
	jmp .arrayDeleteCycle

	.noItero:

	.arrayDeleteContinueToBlock:
	mov rdi, [r12 + 16]
	call free
	mov rdi, r12
	call free

	pop r15
	pop r14
	pop r13
	pop r12

	pop rbp
	ret

; ** Lista **

; list_t* listNew(type_t t)
listNew:
    ; t -> EDI
    push rdi

    mov rdi, LIST_TOTAL_SIZE                    ; Pido 24bytes
    call malloc

    pop rdi
    mov dword [rax + LIST_TYPE ], edi           ; Seteo type t
    mov dword [rax + LIST_SIZE ], 0             ; Seteo size 0
    mov qword [rax + LIST_FIRST], NULL_POINTER  ; Seteo first a nullpointer
    mov qword [rax + LIST_LAST ], NULL_POINTER  ; Seteo last a nullpointer

    ret

; uint8_t  listGetSize(list_t* l)
listGetSize:
    ; *l -> RDI
    mov rax, [rdi + LIST_SIZE]
    ret

; void listAddFirst(list_t* l, void* data)
listAddFirst:
    ; *l    -> RDI
    ; *data -> RSI
    push rbp
    mov rbp, rsp
    push r12                    
    push r13

    mov r12, rdi                                ; R12 = *l
    mov r13, rsi                                ; R13 = *data

    mov rdi, [r12 + LIST_TYPE]  
    call getCloneFunction

    mov rdi, r13                                ; Paso *data como parametro
    call rax                                    ; Call Clone del type      
    
    mov r13, rax                                ; R13 = new *data

    mov rdi, LIST_ELEM_TOTAL_SIZE               ; Pido 24bytes
    call malloc

    mov [rax + LIST_ELEM_DATA], r13             ; Copio new *data
    
    mov rdi, [r12 + LIST_FIRST]                 ; Pido el 1ero de la lista
    mov [rax + LIST_ELEM_NEXT], rdi             ; Lo seteo al next del agregado
    mov qword [rax + LIST_ELEM_PREV], NULL_POINTER    ; Seteo nullpointer a prev
    
    cmp qword [r12 + LIST_FIRST], NULL_POINTER
    je .setLast

    mov rdi, [r12 + LIST_FIRST]                 ; Busco el que era primero
    mov [rdi + LIST_ELEM_PREV], rax             ; Seteo prev
    
    jmp .retListAddFirst

    .setLast:
    mov [r12 + LIST_LAST], rax                  ; Seteo FIRST = LAST

    .retListAddFirst:
    mov [r12 + LIST_FIRST], rax                 ; Seteo el elemento 1ero en la lista

    mov edi, [r12 + LIST_SIZE]                  ; Obtengo size de lista
    inc edi                                     ; Size++
    mov dword [r12 + LIST_SIZE], edi            ; Actualizo size de lista

    pop r13
    pop r12
    pop rbp
    ret

; void* listGet(list_t* l, uint8_t i)
listGet:
    ; *l -> RDI
    ; i  -> ESI
    push rbp
    mov rbp, rsp

    call listGetElem                ; Obtengo list_elem_t* iesimo elem
    
    cmp rax, 0
    je .retListGet                  ; Retorno 0
    
    mov rax, [rax + LIST_ELEM_DATA] ; Obtengo Data del iesimo elem
    
    .retListGet:
    pop rbp
    ret

; list_elem_t* listGetElem(list_t* l, uint8_t i)
listGetElem:
    ; *l -> RDI
    ; i  -> ESI
    push rbp
    mov rbp,rsp

    xor rax, rax
    
    mov ecx, esi    
    cmp ecx, [rdi + LIST_SIZE] 
    jge .retListGet             ; Si i>=size retorna 0

    mov rdi, [rdi + LIST_FIRST] ; Obtengo 1er elem

    cmp ecx, 0                  
    je .noItero                 ; Si i==0 retorna 1er elem
    jl .retListGet              ; Si i<0 retorna 0

    .iteroElems:                ; ECX list size
        mov rdi, [rdi + LIST_ELEM_NEXT] ; Paso al Next Elem        
    loop .iteroElems            ; ecx-- y corta en ecx=0

    .noItero:
    mov rax, rdi                ; Retorno iesimo elem
    .retListGet:
    pop rbp
    ret

; void* listRemove(list_t* l, uint8_t i)
listRemove:
    ; *l -> RDI
    ; i  -> ESI
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi                        ; r12 -> *l (Guardo *l)
    call listGetElem                    ; rax -> iesimo elem (0 si esta fuera de rango)

    cmp rax, 0          
    je .retListRemove                   ; Si i fuera de rango retorno 0
 
    mov edi, [r12 + LIST_SIZE]          ; Obtengo size de lista
    dec edi                             ; Size--
    mov dword [r12 + LIST_SIZE], edi    ; Actualizo size de lista

    mov rdi, [rax + LIST_ELEM_NEXT]     ; RDI -> NEXT
    mov rsi, [rax + LIST_ELEM_PREV]     ; RSI -> PREV
    mov r13, rax                        ; R13 -> iesimo elem

    cmp rdi, rsi                        ; Si next==prev es por que son ambos null
    je .isUnic

    cmp rdi, NULL_POINTER
    je .isLast

    cmp rsi, NULL_POINTER
    je .isFirst

    .isMiddle:
    mov [rsi + LIST_ELEM_NEXT], rdi     ; prev->next = i->next
    mov [rdi + LIST_ELEM_PREV], rsi     ; next->prev = i->prev
    jmp .deleteElem

    .isUnic:
    mov qword [r12 + LIST_FIRST], NULL_POINTER  ; l->first = 0
    mov qword [r12 + LIST_LAST ], NULL_POINTER  ; l->last = 0
    jmp .deleteElem

    .isLast:
    mov qword [rsi + LIST_ELEM_NEXT], NULL_POINTER  ; prev->next = 0
    mov [r12 + LIST_LAST], rsi                      ; l->last = i->prev
    jmp .deleteElem

    .isFirst:
    mov qword [rdi + LIST_ELEM_PREV], NULL_POINTER  ; prev->next = 0
    mov [r12 + LIST_FIRST], rdi                     ; l->first = i->next

    .deleteElem:
    mov r12, [r13 + LIST_ELEM_DATA]	; Obtengo *data para retornar
    
	mov rdi, r13
    call free                       ; Delete elem

    mov rax, r12                    ; Devuelvo *data

    .retListRemove:
    pop r13
    pop r12
    pop rbp
    ret

; void  listSwap(list_t* l, uint8_t i, uint8_t j)
listSwap:
    ; *l -> RDI
    ; i  -> ESI
    ; j  -> EDX
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13d, edx

    call listGetElem                ; Obtengo en rax el iesimo elem
    cmp rax, 0  
    je .retListSwap                 ; RET si esta fuera de rango 

    ; Armo parametros para el call listGet
    mov rdi, r12                    ; *l -> rdi 
    mov esi, r13d                   ; j  -> esi
    mov r12, rax                    ; iesimo elem -> r12

    call listGetElem                ; Obtengo en rax jesimo elem 
    cmp rax, 0  
    je .retListSwap                 ; RET si esta fuera de rango 
    
    mov rdi, [r12 + LIST_ELEM_DATA] ; *data i -> rdi
    mov r13, [rax + LIST_ELEM_DATA] ; *data j -> r13
    
    ; Swap
    mov [r12 + LIST_ELEM_DATA], r13 
    mov [rax + LIST_ELEM_DATA], rdi 

    .retListSwap:
    pop r13
    pop r12
    pop rbp
    ret

; void* listClone(list_t* l, list_t* l2)
listClone:
	; *l -> RDI
	; *l2 -> RSI
	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r12, rdi		; R12 Lista orig
	mov r13, rsi		; R13 lista dest

	mov ecx, [r12 + LIST_SIZE]
	
	cmp ecx, 0                  
    je .noItero                 ; Si i==0 no agrego nada
	
	mov r12, [r12 + LIST_FIRST]	; Obtengo 1er elemento
	.iteroElems:
		mov rdi, r13
		mov rsi, [r12 + LIST_ELEM_DATA]
		sub rsp, 8
		push rcx
		call listAddLast
		pop rcx
		add rsp, 8
		mov r12, [r12 + LIST_ELEM_NEXT]

	loop .iteroElems     
						

	.noItero:
	pop r13
	pop r12
	pop rbp
	ret

; void listDelete(list_t* l)
listDelete:
    ; *l -> RDI
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                ; Guardo *l
    
    mov rdi, [r12 + LIST_TYPE]  ; Levanto el type
    call getDeleteFunction      
    mov r13, rax                ; Guardo deleteFunc en R13

    mov ecx, [r12 + LIST_SIZE]  ; Guardo en r15 el size
    cmp ecx, 0
    je .emptyList

    mov r14, [r12 + LIST_FIRST] ; Obtengo 1er elem

    .iteroElems:                ; ECX list size
        mov r15d, ecx

        mov rdi, [r14 + LIST_ELEM_DATA] 
        call r13                ; Free data

        mov rdi, r14            
        mov r14, [r14 + LIST_ELEM_NEXT] ; Guardo el Next Elem
        call free               ; Free List Elem
        
        mov ecx, r15d
    loop .iteroElems            ; ecx-- y corta en ecx=0

    .emptyList:
    mov rdi, r12
    call free                   ; Free List
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; ** Card **

; card_t* cardNew(char* suit, int32_t* number)
cardNew:
	; *suit -> RDI
	; *number -> RSI
	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r12, rdi	; *suit -> R12
	mov r13, rsi	; *number -> R13

	mov rdi, CARD_SIZE	; Pedimos memoria para carta
	call malloc

	mov rdi, r12		; Clonamos *suit
	mov r12, rax		; *card -> R12
	call strClone

	mov [r12 + CARD_SUIT], rax	; Asignamos *suit a *card

	mov rdi, r13		; Clonamos *number
	call intClone

	mov [r12 + CARD_NUMBER], rax	; Asignamos *number a *card

	mov rdi, CARD_TYPE				; Creamos lista de cards vacia
	call listNew

	mov [r12 + CARD_STACKED], rax 	; Asignamos *list a *card

	mov rax, r12	; Retornamos *card

	pop r13
	pop r12
	pop rbp
	ret	

; char* cardGetSuit(card_t* c)
cardGetSuit:
	; *c -> RDI
	mov rax, [rdi + CARD_SUIT]
	ret

; int32_t* cardGetNumber(card_t* c) 
cardGetNumber:
	; *c -> RDI
	mov rax, [rdi + CARD_NUMBER]
	ret

; list_t* cardGetStacked(card_t* c)
cardGetStacked:
	; *c -> RDI
	mov rax, [rdi + CARD_STACKED]
	ret

; int32_t cardCmp(card_t* a, card_t* b)
cardCmp:
	; *a -> RDI
	; *b -> RSI
	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r12, rdi	; *a -> R12
	mov r13, rsi	; *b -> R13

	mov rdi, [r12 + CARD_SUIT]
	mov rsi, [r13 + CARD_SUIT]
	call strCmp					; Comparamos suits

	cmp rax, 0
	je .equals
	jg .smaller
	jl .greater
	
	.equals:
	mov rdi, [r12 + CARD_NUMBER] ; Comparamos numbers
	mov rsi, [r13 + CARD_NUMBER]
	call intCmp

	cmp rax, 0
	je .retCardCmp
	jg .smaller
		
	.greater:
	mov rax, -1
	jmp .retCardCmp
	.smaller:
	mov rax, 1
	jmp .retCardCmp
	.retCardCmp:
	pop r13
	pop r12
	pop rbp
	ret

; card_t* cardClone(card_t* c)
cardClone:
	; *c -> RDI
	push r12

	mov r12, rdi		; *c -> R12


	mov rdi, [r12 + CARD_SUIT]
	mov rsi, [r12 + CARD_NUMBER]
	call cardNew		; Creamos carta nueva con mismo suit y number

	mov rdi, [r12 + CARD_STACKED]
	mov rsi, [rax + CARD_STACKED]
	mov r12, rax		; *newCard -> R12
	call listClone		; Clonamos elems stacked

	mov rax, r12		; Retornamos *card

	pop r12
	ret

; void cardAddStacked(card_t* c, card_t* card)
cardAddStacked:
	; *c -> RDI
	; *card -> RSI
	push rbp
	mov rbp, rsp

	mov rdi, [rdi + CARD_STACKED]
	call listAddFirst

	pop rbp
	ret

; void cardDelete(card_t* c)
cardDelete:
	; *c -> RDI
	push r12
	mov r12, rdi

	mov rdi, [r12 + CARD_SUIT]
	call strDelete

	mov rdi, [r12 + CARD_NUMBER]
	call intDelete

	mov rdi, [r12 + CARD_STACKED]
	call listDelete

	mov rdi, r12
	call free

	pop r12
	ret

; void cardPrint(card_t* c, FILE* pFile)
cardPrint:
	; *c -> RDI
	; *pFile -> RSI
	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r12, rdi	; *c -> R12
	mov r13, rsi	; *pFile -> R13

	mov rdi, r13
	mov rsi, llaveOpen
	call fprintf

	mov rdi, [r12 + CARD_SUIT]
	mov rsi, r13
	call strPrint

	mov rdi, r13
	mov rsi, separate
	call fprintf

	mov rdi, [r12 + CARD_NUMBER]
	mov rsi, r13
	call intPrint

	mov rdi, r13
	mov rsi, separate
	call fprintf

	mov rdi, [r12 + CARD_STACKED]
	mov rsi, r13
	call listPrint

	mov rdi, r13
	mov rsi, llaveClose
	call fprintf

	pop r13
	pop r12
	pop rbp
	ret
