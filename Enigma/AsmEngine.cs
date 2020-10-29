using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

namespace Enigma
{
    /*Klasa odpowiadająca za komunikację z biblioteką DDL, wywołuje oana fukncje szyfrującą z tej biblioteki.*/
    class AsmEngine
    {
        public string wordToEncrypt, initialRingsLayout, encryptedWord;
        /*Konstruktor przyjmujący tekst do zaszyfrowania oraz początkowe ustawienie pierścieni szyfrujących*/
        public AsmEngine(string wordToEncrypt, string initialRingsLayout)
        {
            this.wordToEncrypt = wordToEncrypt;
            this.initialRingsLayout = initialRingsLayout;
        }
        [DllImport("AsmEnigma.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern void Encryption(string a, string initialRingsLayout, byte[] output);

        
        /*Publiczna metoda wywołująca funkcję szyfrującą*/
        public void encryptionAsm()
        {
            /*Zaszyfrowany tekst zapisywany jest do tablicy bajtów*/
            byte[] encryptedWordInByte = new byte[wordToEncrypt.Length];
            Encryption(wordToEncrypt, initialRingsLayout, encryptedWordInByte);
            /*Konwersja tekstu zapisanego w tablicy bajtów na łańcych znakowy*/
            encryptedWord = System.Text.Encoding.ASCII.GetString(encryptedWordInByte);
        }
    }
}
