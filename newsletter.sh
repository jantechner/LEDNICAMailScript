#!/bin/bash

source env.sh

if [ `cat dane.txt | wc -l` -eq 0 ];
then
	zenity --warning --text "Nie udało się połączyć z bazą danych"
else  # połączono z bazą danych
	choice=$(zenity --list --radiolist --text="Select mode" --column="" --column="" --hide-header FALSE "Print only" FALSE "Send" 2>/dev/null)
	if [ $? -eq 1 ]; 
	then
		rm dane.txt
		exit 1
	else  # wybrano poprawny tryb wysyłania
		recipients=$(zenity --list --radiolist --text="Select recipients" --column="" --column="" --hide-header FALSE "Ladies" FALSE "Men" TRUE "All" 2>/dev/null)	
		if [ $? -eq 1 ]; then
			rm dane.txt
			exit 1
		else  # wybrano adresatów
		
			if [ $recipients = "All" ];
			then 
				cat dane.txt | cut -d " " -f 4 | sed '/^\s*$/d' | sed 's/$/;/' | tr -s ';' | uniq > temp.txt
			elif [ $recipients = "Ladies" ];
			then
				cat dane.txt | cut -d " " -f 1,4 | grep -E '^.*a .*$' | cut -d " " -f 2 | sed '/^\s*$/d' | sed 's/$/;/' | tr -s ';' | uniq > temp.txt
			elif [ $recipients = "Men" ];
			then
				cat dane.txt | cut -d " " -f 1,4 | grep -Ev '^.*a .*$' | cut -d " " -f 2 | sed '/^\s*$/d' | sed 's/$/;/' | tr -s ';' | uniq > temp.txt
			fi
			
			if [ "$choice" = "Print only" ];
			then 
				number=$(zenity --entry --entry-text "30" --text "Lines in one split" 2>/dev/null)
				if [ $? -eq 1 ]; then
					rm temp.txt
					rm dane.txt
					exit 1
				else  # wybrano liczbę linii
						
					touch temp1.txt result.txt
					
					while [ `cat temp.txt | wc -l` -gt 0 ];
					do
						cat temp.txt | head -n $number >> result.txt;
						echo -en '\n' >> result.txt;
						cat temp.txt | tail -n +$[number+1] > temp1.txt;
						cat temp1.txt > temp.txt;
					done

					rm temp1.txt;
					rm temp.txt;
					rm dane.txt;
					gedit result.txt;
					rm result.txt;
				fi  # wybrano liczbę linii
			elif [ $choice = "Send" ];
			then
				subject1=$(zenity --forms --add-entry=Subject --text="Message subject" 2>/dev/null)
				subject=`echo $subject1 | base64 | sed 's/^/=?UTF-8?B?/' | sed 's/$/?=/'`
				if [ $? -eq 1 ]; then
					rm temp.txt
					rm dane.txt
					exit 1
				else
				file=$(zenity --file-selection --save --file-filter="*.html" 2>/dev/null)
				if [ $? -eq 1 ]; then
					rm temp.txt
					rm dane.txt
					exit 1
				else
					attachment1=$(zenity --file-selection --multiple --separator=" " 2>/dev/null)
					if [ "$attachment1" = "" ]; then 
						attachment=""
					else 
						attachment=`echo $attachment1 | sed 's/^/-a /'` 
					fi
					
					test=$(zenity --list --radiolist --text="Select test" --column="" --column="" --hide-header TRUE "Test to me" FALSE "Send to all" 2>/dev/null)
					if [ $? -eq 1 ]; then
						rm temp.txt
						rm dane.txt
						exit 1
					else
						if [ "$test" = "Test to me" ];
						then 
							sendemail -f $from -t $to -s $host -xu $login -xp $password -o tls=yes -l $logDirectory -o message-file=$file -o message-content-type=html -o message-charset=utf-8 -q -u $subject $attachment
						else
							sed -i 's/.$//' temp.txt
							
							touch temp1.txt portion.txt
					
							while [ `cat temp.txt | wc -l` -gt 0 ];
							do
								cat temp.txt | head -n 30 > portion.txt;
								cat temp.txt | tail -n +31 > temp1.txt;
								cat temp1.txt > temp.txt;
								sed -i ':a;N;$!ba;s/\n/ /g' portion.txt #usuń spacje
								
								sendemail -f $from -bcc `cat portion.txt` -s $host -xu $login -xp $password -o tls=yes -l $logDirectory -o message-file=$file -o message-content-type=html -o message-charset=utf-8 -q -u $subject $attachment
							done
							
						fi
						rm temp1.txt
						rm portion.txt
						rm temp.txt
						rm dane.txt
						exit 0
					fi
				fi
				fi
			fi
		fi  # wybrano adresatów
	fi  # wybrano poprawny tryb wysyłania
fi  # połączono z bazą danych
#END
