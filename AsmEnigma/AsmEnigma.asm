_TEXT SEGMENT

_DllMainCRTStartup PROC 

mov    EAX, 1 
ret

_DllMainCRTStartup ENDP

.data
		;Tablica przetrzymuj�ca pier�cienie szyfruj�ce
		codingRings:
		BYTE 'EKMFLGDQVZNTOWYHXUSPAIBRCJ'
		BYTE 'AJDKSIRUXBLHWTMCQGZNPYFVOE'
		BYTE 'BDFHJLCPRTXVZNYEIWGAKMUSQO'
		BYTE 'ESOVPZJAYQUIRHXLNFTGKDCMWB' 
		BYTE 'VZBRGITYUPSDNHLXAWMJQOFECK'

		;Przeniesienie. Dla ka�dego pier�cienia szyfruj�cego nast�puje obr�t przy innej literze
		;przyk�adowo dla pierwszego przy literze R, drugiego F itd
		carriage QWORD 'RFWKA'

		;B�ben odwracaj�cy
		invertingCylinder BYTE 'YRUHQSLDPXNGOKMIEBFZCWVJAT',0

		;Pocz�tkowe ustawienie b�bn�w szyfruj�cych
		InitialRingsLayout BYTE 'AAZ'

		;Zmienna pomocnicza przechowuj�ca warto�� warunku nast�pienia obrotu pier�cienia
		move BYTE 1

		;Licznik p�tli g��wnej
		counter BYTE 1
		
		;Maski wykorzystywane przy funkcjach MMX
		mmx_0x60 dq 6060606060606060h
		mmx_0x7a dq 7a7a7a7a7a7a7a7ah
		mmx_0x00 dq 0000000000000000h
		mmx_0x20 dq 2020202020202020h
		mmx_0x78 dq 7878787878787878h

.code
;Funkcja szyfruj�ca. Parametry to tekst do zaszyfrowania, pocz�tkowe ustaweinie pier�cieni
;szyfruj�cych oraz zmienna przechowuj�c� zaszyfrowany tekst
Encryption PROC  
	local wordToEncrypt:QWORD  ;rcx
	local startRingsLayout:DWORD  ;rdx
	local encryptedWord:QWORD  ;r8


		mov rsi, rcx					;pobiera dane spod adresu przetrzymywanego w rejestrze rcx i prznosi je do rejestru rbx
		mov rdi, rdx
			
		;mov QWORD PTR [r8], rbx					rejestr r8 przetrzymywa� b�zie adres do danych z rejestru rbx(z tego rejestru dane wychodz� z kodu asm)
;Zapisanie poszczeg�lnych liter pocz�tkowego ustawienia pier�cieni szyfruj�cych do tablicy
		mov r9b, byte ptr[rdi]   ;pobieram bajt z adresu rdi i przenosi do rejestru r9b
		mov byte ptr[InitialRingsLayout], r9b  ;bajt z adresu r9b zostaje zapisany w zmiennej InitialRingsLayout
		mov r9b, byte ptr[rdi+1]  ;pobieram kolejny bajt z adresu rdi i przenosi do rejestru r9b
		mov byte ptr[InitialRingsLayout+1], r9b   ;bajt z adresu r9b zostaje zapisany w zmiennej InitialRingsLayout
		mov r9b, byte ptr[rdi+2]  ;pobieram kolejny bajt z adresu rdi i przenosi do rejestru r9b
		mov byte ptr[InitialRingsLayout+2], r9b   ;bajt z adresu r9b zostaje zapisany w zmiennej InitialRingsLayout
		
		mov rsp, rsi
		mov r11, offset carriage
		mov r12, offset codingRings
		mov r13, offset invertingCylinder

		;Zamiana wielko�ci liter oraz zamiana spacji na znaki 'X'
		S:
		mov r9b, byte ptr[rsi]
		mov counter, r9b
		cmp counter, 32
		je Sto
		cmp counter, 65
		jb E
		cmp counter, 122
		ja E
		cmp counter, 90
		jbe Sto
		cmp counter, 97
		jb E
		Sto:
			movq mm0, qword ptr[rsi]       				;zapisanie przetwarzanego ci�gu do rejestru mm0    
			movq mm1, mm0									;zapisanie przetwarzanego ci�gu do rejestr�w mm1, oraz mm2
			movq mm2, mm0            
			movq mm3, mmx_0x00								;zapisanie masek do rejestr�w
			movq mm4, mmx_0x20
			movq mm5, mmx_0x60
			movq mm6, mmx_0x7a

			psubusb mm1, mm5								; wszystkie bajty mniejsze od 0x61
			psubusb mm2, mm6								; i 0x7a zostan� wyzerowane
			pcmpeqb mm1, mm3								; mm1 = (bajt <  'a') ? 0xff : 0x00
			pcmpeqb mm2, mm3								; mm2 = (bajt <= 'z') ? 0xff : 0x00
			pandn   mm1, mm2								; mm1 = (bajt >= 'a' && bajt <= 'z') ? 0xff : 0x00
			pand    mm1, mm4								; dla odpowiednich bajt�w przypisz mask�
			pxor    mm0, mm1								; zanegowanie 5-go bitu - ma�e litery na du�e

			movq	mm1, mm0
			pcmpeqb mm1, mmx_0x20							; mm1 = (bajt = ' ')? 0xff :0x00
			pand    mm1, mmx_0x78							;dla odpowiednich bajt�w przypisanie maski
			pxor	mm0, mm1								;zanegowanie bit�w
	
			movq qword ptr[rsi], mm0 						;przeniesienie przetworzonej cz�ci spowrotem pod adres zmiennej
		
			add rsi, 8						      			;zwi�kszenie licznika o 8, bo taka jest d�ugo�� rejestru
			jmp S		
		
			E:
			mov rsi, rsp	

			Start:						;for (int i = 0; i <= wordToEncrypt.Length - 1; i++)
			mov al, byte ptr[rsi]		;r9b - przetwarzany znak, sprawdzamy czy jest r�wny 0
			mov counter, al
			cmp counter, 0
			je Koniec						;je�li tak to koniec p�tli, bo �a�cuch zako�czony jest zerem
			mov move, 1
				petlaWhile:
					cmp move,1
					jne koniecWhile
					mov ecx,3
			petla:
					mov al, byte ptr[rdi+rcx-1]
					add r11w, cx
					sub r11w,1
					mov r10,0
					mov r10b , byte ptr[r11]
					sub r11w, cx ; wykonanie odwrotnego dzialania do lini 124, �eby r11w(carigge) zosta�o niezmienione
					add r11w,1	 ; wykonanie odwrotnego dzialania do lini 125, �eby r11w(carigge) zosta�o niezmienione
					mov rbx, r10
					mov ah, bl
					cmp al, ah
					je Rowne
					mov move,0
			Rowne:
					mov ah,0
					sub al,64
					mov bl,26
					div bl
					add ah,65
					mov byte ptr[rdi+rcx-1], ah
					cmp move,1
			loope petla
			koniecWhile:
			mov al, counter
			mov ecx, 3

			petlaFor:
				mov ah, byte ptr[rdi+rcx-1]
				sub ah,65
				add al, ah
				sub al,65
				mov ah,0
				mov bl,26
				div bl
				mov bl,ah
				mov al, cl
				dec al
				mov bh,26
				mul bh
				mov bh, 0
				add ax, bx
				mov bx, cx
				mov cx, ax

				mov al, byte ptr[r12+rcx]
				mov cx, bx
				mov ah, byte ptr[rdi+rcx-1]
				sub ah,65
				sub al, ah
				sub al, 39
				mov ah,0
				mov bl,26
				div bl
				add ah,65
				mov al, ah
				loop petlaFor
			KoniecFor:
				mov cl, ah
				sub cl, 65
				add r13w,cx
				mov al, byte ptr[r13]
				sub r13w, cx
				mov ecx,0

			ostatniFor:
				mov ah, byte ptr[rdi+rcx]
				sub ah, 65
				add al, ah
				sub al, 65
				mov ah,0
				mov bl,26
				div bl
				add ah,65
				mov dx, 0
				mov bl, ah

				wewnetrznyWhile:
					mov al, cl
					mov bh,26
					mul bh
					add ax, dx
					mov bh, cl
					mov cx, ax
					mov al, byte ptr[r12+rcx]
					mov cl, bh
					cmp bl,al 
					je wyjdz
					inc  dx
					jmp wewnetrznyWhile
			wyjdz:
			mov ah, byte ptr[rdi +rcx]
			sub ah,65
			add dl,26
			sub dl, ah
			mov ax, dx
			mov bl,26
			div bl
			add ah,65
			mov al,ah
			inc ecx
			cmp ecx,3
			jb ostatniFor
		mov byte ptr[r8], al
		mov byte ptr[r8+1],0
		inc rsi
		inc r8
		jmp Start






		; mo�na dorobic petle, zeby skopiowal caly teksto do adresu, kt�ry bedzie widoczny poza asm
		;mov rax, QWORD PTR [rcx]   
		;mov QWORD PTR [r8], rax
		;
		;mov rax, QWORD PTR [rsp+8]
		;mov QWORD PTR [r8+8], rax
		;
		;mov rax, QWORD PTR [rsp+16]
		;mov QWORD PTR [r8+16], rax
		Koniec:
			ret
Encryption ENDP

_TEXT ENDS
END 