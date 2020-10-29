using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EnigmaCoding
{
    public class CsCoding
    {
        /*Tablica zawierająca pierścienie szyfrujące*/
        string[] codingRings = new string[] {"EKMFLGDQVZNTOWYHXUSPAIBRCJ",
                                   "AJDKSIRUXBLHWTMCQGZNPYFVOE",
                                   "BDFHJLCPRTXVZNYEIWGAKMUSQO",
                                   "ESOVPZJAYQUIRHXLNFTGKDCMWB",
                                   "VZBRGITYUPSDNHLXAWMJQOFECK"};

        /*Przeniesienie - dla każdego pierścienia szyfrującego obrót następuje przy innej literze
         (dla pierwszego przy literze R, dla drugiego F itd.)*/
        const string carriage = "RFWKA";

        /*Bęben odwracający*/
        const string invertingCylinder = "YRUHQSLDPXNGOKMIEBFZCWVJAT";

        /*Kolejność pierścieni szyfrujących*/
        int codingRingsOrder;

        /*connectorState - początkowy stan łącznicy
         wordToEncrypt - tekst do zaszyfrowania*/
        public string connectorState, wordToEncrypt;

        /*Początkowe ustawienie bębnów szyfrujących*/
        public char[] initialRingsLayout;

        /*Zaszyfrowany tekst*/
        public char[] encryptedWord;

        /* Konstruktor klasy, jako parametry przyjmuje niezainicjalizowane pola klasy,
         są to parametry wejściowe podane przez użytkownika */
        public CsCoding(int codingRingsOrder, char[] initialRingsLayout, string connectorState, string wordToEncrypt)
        {
            this.codingRingsOrder = codingRingsOrder;
            this.initialRingsLayout = initialRingsLayout;
            this.connectorState = connectorState;
            this.wordToEncrypt = wordToEncrypt;
            this.encryptedWord = new char[this.wordToEncrypt.Length];
        }

        /*Funkcja szyfrująca*/
        public void encryption()
        {
            //Stopwatch stopwatch = new Stopwatch();

            /*Zmienna pomocnicza powiązana z kolejnością pierścieni szyfrujących*/
            int[] ring = new int[3];

            /* initialRingsLayoutIndex - zmienna pomocnicza ustalająca index w tablicy initialRingsLayout
             modifiedChar - zmienna pomocnicza zawierająca przetwarzany znak */
            int initialRingsLayoutIndex, modifiedChar;

            /* Zmienna pomocnicza przechowująca wartość warunku nastąpienia obrotu pierścienia */
            bool move;

            /* Tablica znaków zawartych w łącznicy wtyczkowej */
            char[] connector = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' };

            // stopwatch.Start();

            /*Ustawienie w tablicy ring[] numerów pierścieni na i-tych pozycjach*/
            for (int i = 2; i >= 0; i--)
            {
                ring[i] = (codingRingsOrder % 10) - 1;
                codingRingsOrder /= 10;
            }
            connectorState = connectorState.ToUpper();

            /*Ustawienie znaków w łącznicy, w zależności od jej początkowego stanu*/
            for (int i = 0; i < connectorState.Length - 1; i++)
            {
                connector[connectorState[i] - 65] = connectorState[i + 1];
                connector[connectorState[i + 1] - 65] = connectorState[i];
            }

            /*Modyfikacja tekstu przed zaszyfrowaniem - ujednolicenie wielkości liter 
             oraz zastąpienie spacji znakiem 'X'*/
            wordToEncrypt = wordToEncrypt.Replace(' ', 'X');
            wordToEncrypt = wordToEncrypt.ToUpper();

            /***********************Pętla główna*********************************/
            for (int i = 0; i <= wordToEncrypt.Length - 1; i++)
            {
                move = true;
                /* Ruch pierścieni szyfrujących */
                while (move == true)
                {
                    for (int j = 2; move && (j >= 0); j--)
                    {
                        move = (initialRingsLayout[j] == carriage[ring[j]]);
                        initialRingsLayout[j] = Convert.ToChar(65 + (initialRingsLayout[j] - 64) % 26);
                    }
                }
                /* W zmiennej modifiedChar przechowywane są kolejne znaki szyfrogramu*/
                modifiedChar = wordToEncrypt[i];
                /*Przejście przez łącznice wtyczkową*/
                modifiedChar = connector[modifiedChar - 65];


                /*Przejście przez pierścienie w kieruku bębna odwracającego*/
                for (int j = 2; j >= 0; j--)
                {
                    initialRingsLayoutIndex = initialRingsLayout[j] - 65;
                    modifiedChar = codingRings[ring[j]][(modifiedChar - 65 + initialRingsLayoutIndex) % 26];
                    modifiedChar = 65 + (modifiedChar - 39 - initialRingsLayoutIndex) % 26;
                }
                /*Przejście przez bęben odwracający*/
                modifiedChar = invertingCylinder[modifiedChar - 65];
                /*Powrót przez pierścienie w w odwrotnym kierunku*/
                for (int j = 0; j < 3; j++)
                {
                    initialRingsLayoutIndex = initialRingsLayout[j] - 65;
                    modifiedChar = 65 + (modifiedChar - 65 + initialRingsLayoutIndex) % 26;
                    for (codingRingsOrder = 0; codingRings[ring[j]][codingRingsOrder] != modifiedChar; codingRingsOrder++) ;
                    modifiedChar = 65 + (26 + codingRingsOrder - initialRingsLayoutIndex) % 26;
                }

                /*Przejście przez łącznicę wtyczkową*/
                modifiedChar = connector[modifiedChar - 65];
                //stopwatch.Stop();
                //System.IO.File.WriteAllText("czas50.txt", "" + stopwatch.ElapsedMilliseconds);

                /*Zapis znaku do łańcucha wynikowego*/
                encryptedWord[i] = Convert.ToChar(modifiedChar);
            }
        }
    }
}