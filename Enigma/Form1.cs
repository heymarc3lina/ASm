using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using EnigmaCoding;
using System.Management;

namespace Enigma
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }
       
        /*Funkcja wykrywająca ilość rdzeni logicznych procesora*/
        private int threadDetecting()
        {
            int numberOfProcessors = Convert.ToInt32(System.Environment.GetEnvironmentVariable("NUMBER_OF_PROCESSORS"));
            return numberOfProcessors;
        }

        /*Obsługa przycisku 'Start'*/
        private void button1Click(object sender, EventArgs e)
        {
            /*Liczba wątków*/
            int numberOfThreads = 0;
            Console.WriteLine(textBoxWatki.Text);
            if (textBoxWatki.Text.Equals("") || radioButton1.Checked 
                || textBoxWatki.Text.CompareTo("64") == 1 ||textBoxWatki.Text.CompareTo("1") == -1 )
            {
                numberOfThreads = threadDetecting();
            }
            else
            {
                numberOfThreads = Int32.Parse(textBoxWatki.Text);
            }
            

            if (System.IO.File.Exists(textBox4.Text))
            {
                //textBox4.Text
                /*Tekst do zaszyfrowania*/
                string text = System.IO.File.ReadAllText(@"L:\enigma\Enigma\plik.txt");
                /*Zmienna przechowująca długość łańcuch przetwarzanego przez jeden wątek*/
                int len = setLen(text.Length, numberOfThreads);
                /*Tablica części tektu podzielonego w zależności od liczby wątków*/
                string[] onePart = new string[numberOfThreads];
                /*Zapisywanie do tablicy odpowiednich części tektu, 
                 z uwzględnieniem, że ostatni wątek może zawierać mniej znaków*/
                for(int i = 0; i < numberOfThreads; i++)
                {
                    for (int j = 0; j <len; j++)
                    {
                        if(i*len+j < text.Length)
                        {
                            onePart[i] += text[i * len + j];
                        }
                    }
                }

                /*Wybór implementacji w zależności od zawartości pola*/
                Stopwatch stopwatch = new Stopwatch();
                if (this.comboBox1.Text == "C#")
                {

                    stopwatch.Start();
                   string ans = csImplementation(onePart, len, numberOfThreads);
                    stopwatch.Stop();
                    System.IO.File.WriteAllText(("odp_"+ numberOfThreads + ".txt"), ans );
                    
                    float fTime = stopwatch.ElapsedMilliseconds;
                    MessageBox.Show("Czas trwania w sekundach: " + fTime/1000);
                    //Console.WriteLine(Convert.ToDouble(stopwatch.ElapsedMilliseconds/1000));



                }
                else if (this.comboBox1.Text == "Asm")
                {
                   stopwatch.Start();
                   string ans = assemblerImplement(onePart, len, numberOfThreads);
                    stopwatch.Stop();
                    System.IO.File.WriteAllText(("odp_asm_"+ numberOfThreads+ ".txt"), ans);
                    float fTime = stopwatch.ElapsedMilliseconds;
                    MessageBox.Show("Czas trwania w sekundach: " + fTime / 1000);
                }
                                
          }
           else
           {
                MessageBox.Show("Brak podanego pliku!");
            }

        }              


        /*Funkcja ustalająca długość tekstu przetwarzanego przez jeden wątek
         Jako parametry przyjmuje length - dlugość tekstu oraz numberofThread - liczbę wątków*/
        private int setLen(int length, int numberofThread)
        {
            int len = length / numberofThread;
            if(len*numberofThread < length)
            {
                len++;
            }
            return len;
        }

        /*Wygaszanie pola do wpisania wybanej ilości wątków*/
        private void ifRadioButtonCLickd(object sender, EventArgs e)
        {
            if (radioButton2.Checked == true)
            {
                textBoxWatki.Visible = true;
            }
            if (radioButton1.Checked == true)
            {
                textBoxWatki.Visible = false;
            }
            
            
        }

        /*Funkcja ustalająca początkowe ustawienie pierścieni szyfrujących w zależności od numeru wątku
        Jako parametry przyjmuje startingRingsLayout - początkowe ustawienie pierścieni szyfrujących,
        threadLength - długość jednego wątku oraz threadId - numer wątku*/
        private char[] setInitialRingsLayout(string startingRingsLayout, int threadLength, int threadId)
        {
            char[] x = new char[3];
            int circle = threadLength * threadId;
            int lastCircleCounter = 1;
            int secondCircleCounter = 1;
            if (circle > lastCircleCounter + 25)
                lastCircleCounter++;
            if (circle > secondCircleCounter + 25 * 25)
                secondCircleCounter++;
            for (int i = 0; i < startingRingsLayout.Length; i++)
                x[i] = startingRingsLayout[i];
            x[2] = Convert.ToChar(Convert.ToInt32(x[2]) + circle);
            if (x[2] > 90)
            {
                x[2] = Convert.ToChar(Convert.ToInt32(x[2] - 26));
            }
            if (lastCircleCounter > 1)
                x[1] += Convert.ToChar(lastCircleCounter - 1);
            if (secondCircleCounter > 1)
                x[0] += Convert.ToChar(secondCircleCounter - 1);
            return x;
        }

        /*Funkcja przygotowująca tekst do przetworzenia go przez DLL napisaną w Asm 
        Jako parametry przyjmuje onePart - tablicę z podzielonym tekstem, len - dlugość jednej części tekstu
        oraz numberOfThreads - liczbę wątków*/
        private string assemblerImplement(string[] onePart, int len, int numberOfThreads)
        {
            /*Lista wątków*/
            List<Thread> threadList = new List<Thread>();
            /*Lista obiektów klasy Engine wywołującej funkcję z biblioteki DLL w Asemblerze*/
            AsmEngine[] eList = new AsmEngine[numberOfThreads];

            /*Inicjalizacja obiektów pracujących na poszczególnych częściach tekstu*/
            for (int i = 0; i < numberOfThreads; i++)
            {
                char[] startRingsLayout = setInitialRingsLayout(textBox2.Text.ToUpper(), len, i);
                string q = new string(startRingsLayout);
                eList[i] = new AsmEngine(onePart[i], q);
            }
            /*Przypisanie funkcji do wątków*/
            foreach (AsmEngine c in eList)
            {
                Thread tr = new Thread(() => c.encryptionAsm());
                threadList.Add(tr);
            }

            /*Uruchomienie równoległe wątków*/
            foreach (Thread t in threadList)
            {
                t.Start();
            }
            foreach (Thread t in threadList)
            {
                t.Join();
            }
            /*Inicjalizacja zmiennej zawierającej zaszyfrowany tekst*/
            string ans = "";
            /*Zapisanie całości zaszyfrowanego tekstu do zmiennej ans*/
            for (int i = 0; i < numberOfThreads; i++)
            {
                ans += eList[i].encryptedWord;
            }

            /*Funkcja zwraca zaszyfrowany tekst*/
            return ans;

        }

        /*Funkcja przygotowująca tekst do przetworzenia go przez DLL napisaną w C# 
         Jako parametry przyjmuje onePart - tablicę z podzielonym tekstem, len - dlugość jednej części tekstu
         oraz numberOfThreads - liczbę wątków*/
        private string csImplementation(string[] onePart, int len, int numberOfThreads)
        {
            /*Lista wątków*/
            List<Thread> threadList = new List<Thread>();
            /*Lista obiektów klasy CsCoding zawartej w bibliotece DDL*/
            CsCoding[] cList = new CsCoding[numberOfThreads];

            /*Inicjalizacja obiektów pracujących na poszczególnych częściach tekstu*/
            for (int i = 0; i < numberOfThreads; i++)
            {
                char[] startRingsLayout = setInitialRingsLayout(textBox2.Text.ToUpper(), len, i);
                cList[i] = new CsCoding(System.Int32.Parse(textBox1.Text), startRingsLayout, textBox3.Text, onePart[i]);
            }
            /*Przypisanie funkcji do wątków*/
            foreach (CsCoding c in cList)
            {
                Thread tr = new Thread(() => c.encryption());
                threadList.Add(tr);
            }

            /*Uruchomienie równoległe wątków*/
            foreach (Thread t in threadList)
            {
                t.Start();
            }
            /*Proces główny czeka na zakończenie wszystkich wątków*/
            foreach (Thread t in threadList)
            {
                t.Join();
            }
            /*Tablica zaszyfrowanych części tekstu*/
            string[] encryptedPart = new string[numberOfThreads];
            /*Inicjalizacja zmiennej zawierającej zaszyfrowany tekst*/
            string ans = "";
            /*Wypełnienie tablicy zaszyfrowanymi częściami tekstu i zapisanie całości do zmiennej ans*/
            for (int i = 0; i < numberOfThreads; i++)
            {
                encryptedPart[i] = new string(cList[i].encryptedWord);
                ans += encryptedPart[i];
            }
            /*Funkcja zwraca zaszyfrowany tekst*/
            return ans;
        }

        /* Obsługa przycisku 'Ustawienia domyślne. Wypełnia pola domyślnymi wartościami. */
        private void button2Click(object sender, EventArgs e)
        {
            textBox1.Text = "123";
            textBox2.Text = "AAZ";
        }
    }

    

}
