_TEXT SEGMENT

_DllMainCRTStartup PROC 

mov    EAX, 1 
ret

_DllMainCRTStartup ENDP

.data
		;Tablica przetrzymuj¹ca pierœcienie szyfruj¹ce
		codingRings:
		BYTE 'EKMFLGDQVZNTOWYHXUSPAIBRCJ'
		BYTE 'AJDKSIRUXBLHWTMCQGZNPYFVOE'
		BYTE 'BDFHJLCPRTXVZNYEIWGAKMUSQO'
		BYTE 'ESOVPZJAYQUIRHXLNFTGKDCMWB' 
		BYTE 'VZBRGITYUPSDNHLXAWMJQOFECK'

		;Przeniesienie. Dla ka¿dego pierœcienia szyfruj¹cego nastêpuje obrót przy innej literze
		;przyk³adowo dla pierwszego przy literze R, drugiego F itd
		carriage QWORD 'RFWKA'

		;Bêben odwracaj¹cy
		invertingCylinder BYTE 'YRUHQSLDPXNGOKMIEBFZCWVJAT',0

		;Pocz¹tkowe ustawienie bêbnów szyfruj¹cych
		;InitialRingsLayout BYTE 'AAZ'

		;Zmienna pomocnicza przechowuj¹ca wartoœæ warunku nast¹pienia obrotu pierœcienia
		move BYTE 1

		;Licznik pêtli g³ównej
		counter BYTE 1
		
		;Maski wykorzystywane przy funkcjach MMX
		mmx_0x60 dq 6060606060606060h
		mmx_0x7a dq 7a7a7a7a7a7a7a7ah
		mmx_0x00 dq 0000000000000000h
		mmx_0x20 dq 2020202020202020h
		mmx_0x78 dq 7878787878787878h

.code
;Funkcja szyfruj¹ca. Parametry to tekst do zaszyfrowania, pocz¹tkowe ustaweinie pierœcieni
;szyfruj¹cych oraz zmienna przechowuj¹c¹ zaszyfrowany tekst
Encryption PROC  
	local wordToEncrypt:QWORD  ;rcx
	local startRingsLayout:DWORD  ;rdx
	local encryptedWord:QWORD  ;r8


		mov rsi, rcx			;rcx przechowuje adres tekstu,który zosta³ przekazany do procedury. Ten adres zostaje 
								;zostaje przeniesiony do rejestru rsi
		mov rdi, rdx			;pod adresem rdx s¹ dane przekazane do procedury. Adres danych spod adresu rdx zostaje
								;przeniesiony do rdi
			
		;mov QWORD PTR [r8], rbx					rejestr r8 przetrzymywaæ bêzie adres do danych z rejestru rbx(z tego rejestru dane wychodz¹ z kodu asm)


		;Zapisanie poszczególnych liter pocz¹tkowego ustawienia pierœcieni szyfruj¹cych do tablicy
		;mov r9b, byte ptr[rdi]   ;pobiera bajt z adresu rdi i przenosi do rejestru r9b
		;mov byte ptr[InitialRingsLayout], r9b  ;bajt z adresu r9b zostaje zapisany w zmiennej InitialRingsLayout
		;mov r9b, byte ptr[rdi+1]  ;pobiera kolejny bajt z adresu rdi i przenosi do rejestru r9b
		;mov byte ptr[InitialRingsLayout+1], r9b   ;bajt z adresu r9b zostaje zapisany w zmiennej InitialRingsLayout
		;mov r9b, byte ptr[rdi+2]  ;pobiera kolejny bajt z adresu rdi i przenosi do rejestru r9b
		;mov byte ptr[InitialRingsLayout+2], r9b   ;bajt z adresu r9b zostaje zapisany w zmiennej InitialRingsLayout
		
		mov rsp, rsi							;zapisanie zawartosci rejestru rsi do ejestru rsp
		mov r11, offset carriage				;zapisanie do rejestru r11 offsetu zmiennej carriage
		mov r12, offset codingRings				;zapisanie do rejestru r12 offsetu zmiennej codingRings
		mov r13, offset invertingCylinder		;zapisanie do rejestru r13 offsetu zmiennej invertingCylinder

		
	;*******************************************************************************************************;	
		;Zamiana wielkoœci liter oraz zamiana spacji na znaki 'X'
		;w c#: wordToEncrypt = wordToEncrypt.Replace(' ', 'X'); wordToEncrypt = wordToEncrypt.ToUpper();
		S:
		mov r9b, byte ptr[rsi]
		mov counter, r9b
		cmp counter, 32						;porównanie zmiennej counter do 32, czyli sprawdzenie czy to spacja
		je Sto								;je¿eli flaga ZR siê zmieni³a na 1 to znaczy, ¿e counter==32 i skok do Sto
		cmp counter, 65						;porownanie counter do 65 
		jb E								;flaga CY =1, skok jesli counter mniejszy niz 65 to skok do E
		cmp counter, 122					; porownanie countera do 122
		ja E								;flaga CY=0 i ZF=0 skok jesli counter jest powyzej 122 to skok do E
		cmp counter, 90						; porównanie counter z 90
		jbe Sto								;flaga CY=1 i ZF=1 skok jesli counter jest poni¿ej 122  lub równy to skok do STO
		cmp counter, 97						;porownanie counter z 97
		jb E								;flaga CY =1, skok jesli counter mniejszy niz 97 to skok do E
		Sto:
			movq mm0, qword ptr[rsi]       					;zapisanie przetwarzanego ci¹gu do rejestru mm0    
			movq mm1, mm0									;zapisanie przetwarzanego ci¹gu do rejestrów mm1
			movq mm2, mm0									;zapisanie przetwarzanego ciagu do rejestru mm2
			movq mm3, mmx_0x00								;zapisanie maseki do rejestru
			movq mm4, mmx_0x20								;zapisanie maseki do rejestru
			movq mm5, mmx_0x60								;zapisanie maseki do rejestru
			movq mm6, mmx_0x7a								;zapisanie maseki do rejestru

			;movq - ) przenosi 64 bity spakowanych danych z pamiêci do rejestru MMX i odwrotnie lub przesy³a dane miêdzy rejestrami MMX
			;pcmpeqb - realizuje porównanie odpowiadajacych sobie elementów ca³kowitych ze znakiem: czy s¹ równe lub czy wiêksze
			;w wyniku porównania do rejestru wpisywana maska sk³adajaca siê z zer i jedynek, nie zmienia flag
			;psubusb - odejmowanie w trybie z nasyceniem bez znaku
			;pandn- rozkaz operacji logicznych wykonywanej na bitach ca³ych 64-bitowych argumentów. Logiczne bitowe AND NOT
			;pand - rozkaz operacji logicznych wykonywanej na bitach ca³ych 64-bitowych argumentów. Logiczne bitowe AND
			;pxor - logiczne bitowe XOR. Rozkaz operacji logicznych wykonywanej na bitach ca³ych 64-bitowych argumentów
			;pxor, pand, pandn wy) wykonuj¹ bitowe logiczne operacje na operandzie Ÿród³owym i docelowym dla poczwórnego s³owa.
			

			psubusb mm1, mm5								; wszystkie bajty mniejsze od 0x61
			psubusb mm2, mm6								; i 0x7a zostan¹ wyzerowane
			pcmpeqb mm1, mm3								; mm1 = (bajt <  'a') ? 0xff : 0x00
			pcmpeqb mm2, mm3								; mm2 = (bajt <= 'z') ? 0xff : 0x00
			pandn   mm1, mm2								; mm1 = (bajt >= 'a' && bajt <= 'z') ? 0xff : 0x00
			pand    mm1, mm4								; dla odpowiednich bajtów przypisz maskê
			pxor    mm0, mm1								; zanegowanie 5-go bitu - ma³e litery na du¿e

			movq	mm1, mm0								;zapisanie danych z rejestru mm0 do rejestru mm1
			pcmpeqb mm1, mmx_0x20							; mm1 = (bajt = ' ')? 0xff :0x00
			pand    mm1, mmx_0x78							;dla odpowiednich bajtów przypisanie maski
			pxor	mm0, mm1								;zanegowanie bitów
	
			movq qword ptr[rsi], mm0 						;przeniesienie przetworzonej czêœci spowrotem pod adres zmiennej
		
			add rsi, 8						      			;zwiêkszenie licznika o 8, bo taka jest d³ugoœæ rejestru
			jmp S											;skok do S
			E:
			mov rsi, rsp									;powrócenie wska¿nika na dane do pocz¹tkowego miejsca.
															;Tekst jest ju¿ przetworzony

	;*********************************************************************************************************;
	
			Start:						;for (int i = 0; i <= wordToEncrypt.Length - 1; i++)
			mov al, byte ptr[rsi]		;al to- przetwarzany znak, sprawdzamy czy jest równy 0
			mov counter, al				;przeniesienie zawartoœæi al do counter
			cmp counter, 0				; porównanie counter do 0
			je Koniec					;jeœli równe to koniec pêtli, bo ³añcuch zakoñczony jest zerem
			mov move, 1					;move równe 1
				petlaWhile:				;while(move ==true)
					cmp move,1			;porównanie czy while równe 1
					jne koniecWhile		;jeœli nie równe to skok do koniecWhile
					mov ecx,3			;w rejestrze ecx wartoœæ 3. ecx to licznik pêtli -> ecx=0 to skok
										;wiêc nale¿y umieœciæ tam liczbê o jeden wiêksza ni¿ w for 
			petla:						;for (int j = 2; move && (j >= 0); j--) - ruch pierœcieni szyfruj¹cych
					mov al, byte ptr[rdi+rcx-1]		 ;przes³anie jednego bajta do al, al = initialRingsLayout[j]
					add r11w, cx       ;dodanie do rejestru r11w zawartoœæi rejestru cx
					sub r11w,1         ;odjêcie od rejestru r11w liczby 1
					mov r10,0			; wyzerowanie rejestru r10
					mov r10b , byte ptr[r11]	;przes³anie bajta do r10b r10b = carriage[ring[j]]
					sub r11w, cx ; wykonanie odwrotnego dzialania do lini 124, ¿eby r11w(carigge) zosta³o niezmienione
					add r11w,1	 ; wykonanie odwrotnego dzialania do lini 125, ¿eby r11w(carigge) zosta³o niezmienione
					mov rbx, r10 ;przeniesienie zawartosæi rejestru r10 do rejestru rbx
					mov ah, bl   ;przes³anie do ah zawartoœci rejestru bl
					cmp al, ah   ;porównanie rejestru ah z rejestrem al,  move = (initialRingsLayout[j] == carriage[ring[j]])
					je Rowne	;je¿eli równe to skok do Rowne, czyli move dalej równe true 
					mov move,0  ;move =0 
			Rowne:
					mov ah,0		;AH=0
					sub al,64		;al = al -64 inaczej initialRingsLayout[j]= initialRingsLayout[j] - 64
					mov bl,26		;bl=26
					div bl			;al =(ax div bl), ah=(ax mod bl) inaczej ah = (initialRingsLayout[j] - 64) % 26)
					add ah,65		;ah=ah+65 czyli initialRingsLayout[j] = 65 + (initialRingsLayout[j] - 64) % 26)
					mov byte ptr[rdi+rcx-1], ah  ;wpisanie przetworzonego znaku tekstu z ah
					cmp move,1   ;sprawdzenie czy move = 1
			loope petla
			koniecWhile:
			mov al, counter   ;Przes³anie do rejestru AL spowrotem przetwarzanego znaku
			mov ecx, 3       ;ecx=3

			
			;Przejœcie przez pierœcienie w kieruku bêbna odwracaj¹cego
			petlaFor:							;for (int j = 2; j >= 0; j--)
				mov ah, byte ptr[rdi+rcx-1]		;initialRingsLayoutIndex = initialRingsLayout[j]  (zapisanie bajta
												;do ah
				sub ah,65						;odjêcie 65 od ah   initialRingsLayoutIndex = initialRingsLayout[j] - 65
				add al, ah					    ;modifiedChar = codingRings[j][(modifiedChar - 65 + initialRingsLayoutIndex) % 26];
				sub al,65						;odjêcie od al 65(dalsza kontynuacja powy¿szej lini w c#)
				mov ah,0						;zerowanie rejestru AH, 
				mov bl,26						;zapisanie w rejestrze bl 
				div bl							;dzielenie zawartoœci AX przez rejestr bl czyli przez 26 26 ah=modifiedChar - 65 + initialRingsLayoutIndex % 26];
				mov bl,ah						;wynik w rejestrze al, reszta jest w rejestrze ah. Zawartoœæ rejestru bl
												;zapisana do bl
				mov al, cl						;ustalenie adresu
				dec al							;pomniejszenie zawartosæi w al
				mov bh,26						;zapisanie w rejestrze bh liczby 26
				mul bh							;ax=al*bh
				mov bh, 0						;wyzerowanie rejestru bh
				add ax, bx						;dodanie zawartosci bx do ax
				mov bx, cx						;zapis licznika do BX, bo CX jest potrzebny do przechowywania offsetu
				mov cx, ax						;zapisanie rejestru ax do cx

				mov al, byte ptr[r12+rcx]		;modifiedChar = codingRings[j][(modifiedChar - 65 + initialRingsLayoutIndex) % 26];
				mov cx, bx						;przeniesienie licznika z bx do cx
				mov ah, byte ptr[rdi+rcx-1]		;initialRingsLayoutIndex = initialRingsLayout[j] - 65
				sub ah,65						;kontynuacja powy¿szej linijki (czyli odjêcie od ah liczby 65)
				;modifiedChar = 65 + (modifiedChar - 39 - initialRingsLayoutIndex) % 26;
				sub al, ah						;modifiedChar - initialRingsLayoutIndexRings			
				sub al, 39						;(modifiedChar - initialRingsLayoutIndexRings)-39
				mov ah,0						;ah=0
				mov bl,26						;bl=26
				div bl							;al =(ax div bl), ah=(ax mod bl)
												;(modifiedChar - initialRingsLayoutIndexRings-39)%26
				add ah,65						;65 + (modifiedChar - 39 - initialRingsLayoutIndex) % 26
				mov al, ah						;al=ah
				loop petlaFor					;cx!=0 to skok na pocz¹tek
		
		;Przejœcie przez bêben odwracaj¹cy
		KoniecFor:								;tutaj bêdzie to: modifiedChar = invertingCylinder[modifiedChar - 65];
				mov cl, ah						;cl=ah
				sub cl, 65						;przejœcie przez bêben odwracaj¹cy 
				add r13w,cx						;dodanie do r13w zawartosci cx
				mov al, byte ptr[r13]			;modifiedChar = invertingCylinder[modifiedChar - 65]	
				sub r13w, cx					;wykonanie odwrotnego dzia³ania do lini r13w, ¿eby invertingCylinder
				mov ecx,0						;ecx ponownie licznikiem, ale teraz  bez wykorzystania LOOP, 
												;poniewa¿ pêtla musi iœæ od 0 do 3, a na odwrót

;Powrót przez pierœcienie w odwrotnym kierunku
			ostatniFor:							;for (int j = 0; j < 3; j++)
				mov ah, byte ptr[rdi+rcx]		;initialRingLayoutIndex = initialRingsLayout[j] 
				sub ah, 65						;initialRingLayoutIndex - 65
				add al, ah						;al=al+ah ; modifiedChar = modifiedChar + initialRingsLayoutIndex
				sub al, 65						;al = al-65  modifiedChar =modifiedChar - 65 + initialRingsLayoutIndex;
				mov ah,0						;ah=0
				mov bl,26						;bl=26
				div bl							;al =(ax div bl), ah=(ax mod bl) ah = (modifiedChar - 65 + initialRingsLayoutIndex) % 26;
				add ah,65						;ah = 65 + ah ah to modifiedChar
				mov dx, 0						;dx=0
				mov bl, ah						;w BL jest zapamiêtany modifiedChar

				wewnetrzWhile:				;for (codingRingsOrder = 0; codingRings[ring[j]][codingRingsOrder] != modifiedChar; codingRingsOrder++)
					mov al, cl				;al=cl
					mov bh,26				;bh=26
					mul bh					; ax=26*cx
					add ax, dx				;ax=ax+dx
					mov bh, cl				;bh=cl
					mov cx, ax				;cx=ax
					mov al, byte ptr[r12+rcx]	;przes³anie bajta z  codingRings do al	
					mov cl, bh				;cl = bh
					cmp bl,al				;sprawdzenie czy bl równe al
					je wyjdz				;jeœli równe to skok do wyjdz
					inc  dx					;jeœli nie równe to dx++
					jmp wewnetrzWhile		;skok na pocz¹tek wewnetrznyWhile
			wyjdz:
			mov ah, byte ptr[rdi +rcx]		;initialRingLayoutIndex = initialRingsLayout[j] 
			sub ah,65						;poszerzenie lini powy¿ej o odjêcie 65 czyli: initialRingLayoutIndex = initialRingsLayout[j] - 65
			;modifiedChar = 65 + (26 + codingRingsOrder - initialRingsLayoutIndex) % 26;
			add dl,26						;codingRingsOrder= 26 + codingRingsOrder				
			sub dl, ah						;codingRingsOrder= 26 + codingRingsOrder - initialRingsLayoutIndex
			mov ax, dx						;ax = 26 + codingRingsOrder - initialRingsLayoutIndex
			mov bl,26						;bl=26
			div bl							;al =(ax div bl), ah=(ax mod bl)
			add ah,65						;ah = 65 + (26 + codingRingsOrder - initialRingsLayoutIndex) % 26
			mov al,ah						;al = ah
			inc ecx							;ecx--
			cmp ecx,3						;sprawdzenie czy ecx równe 3 
			jb ostatniFor					;jeœli mniej ni¿ 3 to skok do ostatniFor
		mov byte ptr[r8], al				;rejestr r8 przetrzymywaæ bêdzie adres do zmodyfikowanych danych 
											;z rejestru al(z rejestru r8 dane wychodz¹ z kodu asm)
											; encryptedWord[i] = Convert.ToChar(modifiedChar);
		mov byte ptr[r8+1],0				;jako ostatni znak zapiszemy 0, zeby nie by³o na koñcu œmieciowych wartosci
		inc rsi								;przesuniêcie wskaŸnika o 1 aby dostaæ kolejn¹ partiê tekstu 
		inc r8								;przesuniêcie wskaŸnika o 1 aby móc zapisaæ potem kolejn¹ partiê tekstu,
											;a nie nadpisaæ stare
		jmp Start							;Skok na pocz¹tek


		Koniec:
			ret								;Powrót do programu
Encryption ENDP

_TEXT ENDS
END 