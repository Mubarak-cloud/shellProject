#!/bin/bash
function check_then_run {
        if [[ -d ~/DBMS ]]
        then
                main_menu
        else
                mkdir ~/DBMS
                main_menu
        fi
}

function main_menu {
        select choice in "Create Database" "List Databases" "Connect to Database" "Drop Database" "Exit"
        do
                case $REPLY in
                1) create_database;;
                2) ls ~/DBMS; main_menu;;
                3) connect_database;;
                4) remove_database;;
                5) exit;;
                *) echo "wrong choice, please enter a correct choice"; main_menu;;
                esac
        done
}

function create_database {
	echo -e "Enter Database Name that you want to create : \c"
  	read database_name
	mkdir ~/DBMS/$database_name 2>>/dev/null
	if [[ $? == 0 ]]
	then
		echo "$database_name database Created Successfully"
	else
		echo "There is something wrong, creating database $database_name failed"
	fi
	cd ~/DBMS/$database_name 2>>/dev/null
	tables_control_menu
}

function connect_database {
	echo -e "Enter Database Name that you want to connect : \c"
  	read database_name
	cd ~/DBMS/$database_name 2>>/dev/null
	if [[ $? == 0 ]];
		then tables_control_menu
	else
		echo "$database_name not found, enter a correct name"
		connect_database
	fi	
}

function remove_database {
	echo -e "Enter Database Name that you want to remove : \c"
  	read database_name
	rm -r ~/DBMS/$database_name 2>>/dev/null
	if [[ $? == 0 ]];
		then echo "$database_name is deleted successfully"
		main_menu
	else
		echo "There is something wrong, please try again and make sure that database name is correct"
		remove_database
	fi	
}


function tables_control_menu {
	select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Main menu" "Exit"
        do
                case $REPLY in
                1) create_table;;
                2) ls | cut -f1 -d .; tables_control_menu;;
                3) drop_table;;
                4) insert_row;;
                5) select_from_table;;
                6) delete_from_table;;
                7) cd ~/DBMS; main_menu;;
                8) exit;;
                *) echo "wrong choice, please enter a correct choice"; tables_control_menu;;
                esac
        done
}

function create_table {
	echo -e "Enter table name that you want to create : \c"
  	read table_name
  	if [[ -f $table_name ]]
  	then
		echo "This table is already exist"
		tables_control_menu
	fi
  	meta_data=""
  	primary_key=""
  	read -p "Enter number of columns : " cols_num;
  	for (( i = 1; i <= $cols_num; i++ ))
  	do
  		read -p "Enter the name of column $i : " column_name;  		
  		echo -e "Enter the type of column $i : ";
  		select col_type in "int" "string"
  		do
  			case $col_type in
  				int) col_type="int";break;;
  				string) col_type="string";break;;
  				*) echo "You entered a wrong choice";;
  			esac
  		done
  		if [[ $primary_key == "" ]]
  		then
  			echo -e "Do you want to make this column as primary key ?"
			select isPK in "yes" "no"
			do
				case $isPK in
					yes ) 	if [[ $i == $cols_num ]]
						then
							primary_key="PK"; meta_data+="$column_name,$col_type,$primary_key"; 
						else
							primary_key="PK"; meta_data+="$column_name,$col_type,$primary_key\n";
						fi
						break;;
  					no) if [[ $i == $cols_num ]]
  					    then
  					    	meta_data+="$column_name,$col_type";
  					    else
  					    	meta_data+="$column_name,$col_type\n";
  					    fi
  					    break;;
  					* ) echo "Wrong Choice" ;;
  				esac
			done
		else
			if [[ $i == $cols_num ]]
			then
				meta_data+="$column_name,$col_type";
			else
				meta_data+="$column_name,$col_type\n";
			fi
		fi
	done
	touch "$table_name.csv"
	touch ".$table_name"
  	chmod -R 744 ~/DBMS
	echo -e $meta_data >> ".$table_name"
	if [[ $? == 0 ]]
	then
		echo "Table $table_name created successfuly"
		tables_control_menu
	else
		echo "There something wrong, try again please."
		tables_control_menu
	fi
}

function drop_table {
	echo -e "Enter the table name that you want to drop : \c"
	read table_name
	rm "$table_name.csv" 2>>/dev/null
	rm .$table_name 2>>/dev/null
	if [[ $? == 0 ]];
		then echo "$table_name is deleted successfully"
		tables_control_menu
	else
		echo "There is something wrong, please try again and make sure that table name is correct"
		remove_database
	fi	
}


function insert_row {
	row=""
	read -p "Enter the table name : " table_name;
	if ! [[ -f "$table_name.csv" ]]
	then
		echo "The $table_name table is not exist, please try with correct data"
		tables_control_menu
	fi
	cols_num=`awk 'END{print NR}' .$table_name`
	for (( i = 1; i <= $cols_num; i++ ))
	do
		col_name=$(awk 'BEGIN{FS=","}{if(NR=='$i') print $1}' .$table_name)
		col_type=$(awk 'BEGIN{FS=","}{if(NR=='$i') print $2}' .$table_name)
		col_isPK=$(awk 'BEGIN{FS=","}{if(NR=='$i') print $3}' .$table_name)
		read -p "Enter the value for $col_name ($col_type) : " value		
		if [[ $col_type == "int" ]]
		then
			while ! [[ $value =~ ^[0-9]*$ ]]
			do
				read -p "Invalid datatype, enter a valid value for $col_name ($col_type) : " value
			done
		fi
		if [[ $col_isPK == "PK" ]]
		then
			while [[ $value =~ ^[`awk 'BEGIN{FS="," ; ORS=" "}{if(NR != 1)print $(('$i'))}' $table_name'.csv'`]$ ]]
			do
				read -p "Primary key can't be repeated, enter a valid value for $col_name ($col_type) : " value
				if [[ $col_type == "int" && $value =~ ^[0-9]*$ ]]
				then
					echo "correct value, please continue inserting"
				else
					read -p "Invalid datatype, enter a valid value for $col_name ($col_type) : " value
				fi
			done
		fi
		if [[ $i == $cols_num ]]
		then
			row+="$value"		
		else
			row+="$value,"
		fi		
	done
	echo $row >> "$table_name.csv" 2>>/dev/null
	if [[ $? == 0 ]]
	then
		#sed '1d' $table_name.csv
		echo "Recored inserted successfully"
		tables_control_menu
	else
		echo "There is something wrong, insert operation field"
		tables_control_menu
	fi
}

function select_from_table {
	select choice in "Select all rows" "Select a specifiec column" "Tables menu"
        do
                case $REPLY in
                1) select_all;;
                2) select_column;;
                3) tables_control_menu;;
                *) echo "wrong choice, please enter a correct choice"; main_menu;;
                esac
        done
}

function select_all {
	read -p "Enter table name : " table_name
	if ! [[ -f "$table_name.csv" ]]
	then
		echo "Table $table_name doesn't exist"
		tables_control_menu
	fi
	row=""
	cols_num=$(awk 'END{print NR}' .$table_name)
	echo -e ""
	row+=$(awk 'BEGIN{FS=","} {print $1, " | " }' .$table_name)	
	echo $row | sed 's/.$//'
	echo "---------------------------------------------------------"
	#column -t -s ',' -o ' | ' "$table_name.csv" 2>>/dev/null
	awk 'BEGIN{FS=","}{for (i=1;i<=NF;i++) printf "%-5s",$i; print ""}' $table_name.csv
	if [[ $? != 0 ]]
	then
		echo "There is some thing wrong"
		tables_control_menu
	fi
	echo -e ""
	tables_control_menu
}

function select_column {
	read -p "Enter table name : " table_name
	if ! [[ -f "$table_name.csv" ]]
	then
		echo "Table $table_name doesn't exist"
	  	tables_control_menu		
	fi
	awk 'BEGIN{FS=","}{print NR,$1}' .$table_name
  	read -p "Enter column number : " col_num
  	awk 'BEGIN{FS=","}{print $'$col_num'}' $table_name'.csv'
  	tables_control_menu
}

function delete_from_table {
	select choice in "Truncate table" "delete by row number" "Tables menu"
	do
		case $REPLY in
		1) truncate;;
		2) delete_row;;
		3) tables_control_menu;;
		*) echo "wrong choice, please enter a correct choice"; main_menu;;
		esac
	done
}

function truncate {
	read -p "Enter table name : " table_name
  	if ! [[ -f "$table_name.csv" ]]
	then	
	  	echo "Table $table_name doesn't exist"
	  	tables_control_menu
	fi
	echo "" > $table_name.csv 2>>/dev/null
	tables_control_menu
}

function delete_row {
	read -p "Enter table name that you want to delete from : " table_name
	if ! [[ -f $table_name.csv ]]
	then
		echo "Table $table_name doesnot exist"
		delete_from_table
	fi
	read -p "Enter number of row that you want to delete : " row_num
	table_rows_num=$(awk 'END{print NR}' $table_name.csv)
	if [[ $row_num -gt $table_rows_num ]]
	then
		echo "Wrong row number"
		delete_from_table
	else
		sed $row_num"d" $table_name.csv > temp && mv temp $table_name.csv
		echo "Row $row_num deleted successfully"
		tables_control_menu
	fi
	delete_from_table		
}

check_then_run