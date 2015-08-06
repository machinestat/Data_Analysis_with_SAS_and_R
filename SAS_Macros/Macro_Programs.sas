/*Macro that transpose data from long format to wide format*/
%macro makewide(DATA =, /*The name of the input data set*/
				OUT =, /*The name of the output data set*/
				COPY =, /*A list of variables that occur repeatedly with each 
						 observation for a subject and will be copied to the 
						 resulting data set.*/
				ID =, /*The name of the ID variable that identifies the subject*/
				VAR =, /*The variable that holds the values to be transposed. */
				TIME = time /*The variable that numerates the repeated measurements*/);
	PROC SORT DATA = &data;
		BY &ID &copy;
	RUN;

	PROC TRANSPOSE DATA = &data PREFIX = &var
						  OUT = &out(DROP = _NAME_);
		BY &ID &copy;
		VAR &var;
		ID &time;
	RUN;
%mend makewide;

/*This SAS program first read all the file names in the same folder, 
the files must be in the same type. Then read all the files and create 
a SAS data set for each file, finally use SAS to merge all the data 
sets to a single summary data set.

In my work, I have 45 excel files in the same folder, all have one tab 
in the same format. I read the same tab from all excel files to SAS and 
then create a summary data set.*/

/*This SAS macro program reads all the file names in the same folder, 
the files must be the same type*/
%macro GetFiles(Folder, Ext);
	FILENAME DIRLIST PIPE %sysfunc(quote(dir "&Folder\*.&Ext"));    
    /*Use the PIPE engine in the FILENAME statement to access the 
    directory information. */
	DATA dirlist ;                                               
		INFILE dirlist LRECL = 200 TRUNCOVER;                          
		INPUT  line $200.; 
		length file_name $ 200; 
		file_name="&Folder\"||scan(line,-1," ");  
	 	IF SCAN(line, -1, ".") NOT IN ("&Ext") THEN DELETE;
		KEEP file_name;
	RUN; 
%mend GetFiles;
/*example: %GetFiles(C:\Data\Green Energy Act\2015\Target Finder, xlsx) */

/*create macro variables for SAS to read the files */
DATA Files;
	SET Dirlist END = End_Var;
	FileNum = 'file'||LEFT(_N_);
	IF End_Var THEN CALL SYMPUT('MAX', _N_);
	CALL SYMPUT(FileNum, File_Name);
RUN;

/* read all the raw data files to SAS */
%macro ReadIn;
%DO i = 1 %TO &MAX;
	PROC IMPORT  OUT= file&i 
	             		DATAFILE= "&&file&i" 
	             		DBMS=EXCEL REPLACE;
		RANGE="Summary$"; 
		GETNAMES=YES;
		MIXED=NO;
		SCANTEXT=YES;
		USEDATE=YES;
		SCANTIME=YES;
				 
	RUN;
%END;
%mend ReadIn;
%ReadIn

/*merge all the SAS data sets */
DATA Total;
		/*first we need to take care of the same variables that 
		has different length in each data set*/
		LENGTH School_Board $80.;
		FORMAT School_Board $80.;
		INFORMAT School_Board $80.;
		SET file1 - file%left(&MAX);
RUN;

/*Finally, delete all the data sets we don't need.*/
PROC DATASETS LIBRARY = work NOLIST;
	DELETE file1 - file%left(&MAX) Dirlist Files;
RUN;
QUIT;


*--------------------------------------------------------------*
|Macro Name: Head.sas                                          |
|Purpose: Macro which prints out the first 8 observations or   |
|         the first n observations.                            |
|Argument: %Head(Dat, N = )                                    |
|Examples: %Head(Test)                                         |
|          %Head(Test, N = 10)                                 |
*-------------------------------------------------------------*;

%macro Head(Dat, N = 8);
    PROC PRINT DATA = &Dat(OBS = &N);
        TITLE "The First &N Observations of Data Set &Dat";
    RUN;
%mend Head;


*--------------------------------------------------------------*
|Macro Name: Tail.sas                                          |
|Purpose: Macro which prints out the Last 8 observations or    |
|         the Last n observations.                             |
|Argument: %Tail(Dat, N = )                                    |
|Examples: %Tail(Test)                                         |
|          %Tail(Test, N = 10)                                 |
*-------------------------------------------------------------*;
%macro Tail(Dat, N = 8);
    Data New;
        SET &Dat NOBS = TNumbs;
        TotalNum = TNumbs;
    RUN;
    PROC SQL NOPRINT;
        SELECT TotalNum INTO : NRows
        FROM New;
    QUIT;
    PROC PRINT DATA = New (FIRSTOBS = %eval(&NRows - &N + 1)
				DROP = TotalNum);
        TITLE " The Last &N Observations of Data set &Dat";
    RUN;
%mend Tail;


*--------------------------------------------------------------*
|Macro Name: HighLowNPercent                                   |
|Purpose: To list the upper and lower n percent of values      |
|Arguments: Dat     - Data set name                            |
|           Var     - Variable to test                         |
|           Percent - Upper and lower n percent                |
|           Idvar   - ID variable                              |
|Example: %HighLow_nPercent(Dat=P4,                            |
|                           Var=DDABal,                        |
|                           Percent=2,                         |
|                           Idvar=AcctAge)                     |
--------------------------------------------------------------*;
%macro HighLow_nPercent(Dat=, Var=, Percent=, Idvar=);
	%LET Low = %EVAL(&Percent - 1); 
 	%LET High = %EVAL(100 - &Percent); 
	PROC FORMAT;
		VALUE rnk 0 - &Low = 'Low'
	 			&High - 99 = 'High';
	RUN;
	 
	PROC RANK DATA = &Dat(KEEP=&Var &Idvar)
	 			OUT = New(WHERE = (&Var IS NOT MISSING))
				GROUPS = 100;
		VAR &Var;
		RANKS Range;
	RUN;
	***Sort and keep top and bottom n%;
	PROC SORT DATA=New(WHERE=(Range le &Low or Range GE &High));
		BY &Var;
	RUN;
	***Produce the report;
	PROC PRINT DATA = New;
		TITLE "Upper and Lower &Percent.% Values for %UPCASE(&Var)";
		ID &Idvar;
		VAR Range &Var;
		FORMAT Range rnk.;
	RUN;

	PROC DATASETS LIBRARY = work NOLIST;
		DELETE New;
	RUN;
	QUIT;
%mend HighLow_nPercent; 


*--------------------------------------------------------------*
|Macro Name: HighLowN                                          |
|Purpose: To list the "n" highest and lowest values            |
|Arguments: Dat      - Data set name (one- or two-level        |
|           Var      - Variable to list                        |
|           Idvar    - ID variable                             |
|           n        - Number of variables to list             |
|Example: %HighLowN(Dat = P4,                                  |
|                   Var = DDABal,                              |
|                   Idvar = AcctAge                            |
|                   n = 7)                                     |
*-------------------------------------------------------------*;

%macro HighLowN(Dat =, Var =, Idvar =, n =);
    PROC SORT DATA = &Dat(KEEP=&Idvar &Var
           		 WHERE=(&Var is not missing)) out=tmp;
        by &Var;
    run;

    DATA _NULL_;
        SET tmp NOBS = Num_Obs;
        CALL SYMPUT('Num', Num_Obs);
        STOP;
    RUN;

    %LET High = %EVAL(&Num - &n + 1);

    TITLE "&n Highest and Lowest Values for &Var";
    DATA _NULL_;
        SET tmp(obs = &n)    /* lowest values         */
            tmp(firstobs = &high) /* highest values    */;
        FILE PRINT;
        IF _N_ LE &n THEN DO;
            IF _N_ = 1 THEN PUT / "&n Lowest Values";
            PUT "&Idvar = " &Idvar @15 "Value = " &Var;
        END;

        ELSE IF _N_ GE %EVAL(&n + 1) THEN DO;
            IF _N_ = %EVAL(&n + 1) THEN PUT / "&n Highest Values";
            PUT "&Idvar = " &Idvar @15 "Value = " &Var;
        END;
    RUN;

    PROC DATASETS LIBRARY = work NOLIST;
        DELETE tmp;
    RUN;
    QUIT;
%mend HighLowN;


*-------------------------------------------------------------*
| Macro Name: Diff_each_OBS                                   |
| Purpose: Creates a new data set with all the variables in   | 
|          the original longitudinal data set plus the        | 
|          difference between the current value and the       |
|          previous value for all variables in the VARLIST.   |
| Arguments: In_Dat = Input data set name                     |
|            Out_Dat = Output data set name                   |
|            Varlist = List of variables for differences      |
*-------------------------------------------------------------*;
%Macro OBS_Diff(In_Dat, Out_Dat, Varlist);
	***Create a list of variable names to hold the differences
     and add a D_ to the beginning of each variable name;
	%LET Temp = %STR( &Varlist); * concatenates a blank to the beginning of the variable list
	%LET Dlist = %SYSFUNC(TRANWRD(&Temp, %STR( ), %STR( D_)));
	/*all the blanks in the VARLIST are replaced by a blank 
       and "D_."*/

	DATA &Out_Dat;
		SET &In_Dat;
		ARRAY VARS[*] &Varlist;
		ARRAY DIFF[*] &Dlist;

		DO i = 1 TO DIM(VARS);
			DIFF[i] = DIF(VARS[i]);
		END;
		DROP i;
	RUN;
%Mend Diff_Each_OBS;


*--------------------------------------------------------------*
| Macro Name: Diff_First_Last                                  |
| Purpose: Using an input longitudinal data set, creates a new |
|          data set containing the difference between the first|
|          and last observation for each value of an ID        |
|          variable, for all the variables listed in the       |
|          VARLIST. The names for the difference variables will|
|          be the names in the VARLIST with a "D_" added to the|
|          beginning of each name.                             |
| Arguments: In_Dat = Input data set name                      |
|            Out_Dat = Output data set name                    |
|            ID_Var = ID variable                              |
|            VARLIST = List of variables for differences       |
| Example: %DIFF_FIRST_LAST(CLINICAL,NEW,PATIENT,HR SBP DBP)   |
*-------------------------------------------------------------*;
%MACRO Diff_First_Last(In_Dat,Out_Dat,ID_Var,Varlist);
	%LET Temp = %STR( &Varlist);
	%LET Dlist = %SYSFUNC(TRANWRD(&Temp,%STR( ),%STR( D_)));
	PROC SORT DATA=&In_Dat OUT=Tmp;
		BY &ID_Var;
	RUN;
		DATA &Out_Dat;
		SET &In_Dat;
		BY &ID_Var;
		ARRAY VARS[*] &Varlist;
		ARRAY DIFF[*] &Dlist;
		IF First.&ID_Var = 1 OR Last.&ID_VAR = 1 THEN
		DO i = 1 TO DIM(VARS);
			DIFF[i] = DIF(VARS[i]);
		END;
		IF Last.&ID_Var = 1 THEN OUTPUT;
		DROP i;
	RUN;
	PROC DATASETS LIBRARY=WORK;
		DELETE Temp;
	RUN;
%MEND Diff_First_Last;


*--------------------------------------------------------------*
| Macro Name: Moving_Ave                                       |
| Purpose: Computes a moving average based on "N" observations |
| Arguments: In_Dat = Data set name                            |
|            Out_Dat = Output data set name                    |
|            In_Var = Variable to compute average              |
|            Out_Var = Variable to hold the moving average     |
|            N = Number of obs for the average                 |
*-------------------------------------------------------------*;
%MACRO Moving_Ave(In_Dat,Out_Dat,In_Var,Out_Var,N);
	DATA &Out_Dat;
		SET &In_Dat;
		*Compute the lags;
			_X1 = &In_Var;
			%DO i = 1 %TO &N;
				%LET Num = %EVAL(&i + 1);
				_X&Num = LAG&i(&In_Var);
			%END;
			
			/*If the observation number is greater than 
                or equal to the number of values needed for the 
                moving average	output;*/
		IF _N_ GE &N THEN DO;
			&OUT_VAR = MEAN(OF _X1 - _X&N);
			OUTPUT;
		END;
		DROP _X: ;
	RUN;
%MEND Moving_Ave;


*--------------------------------------------------------------*
| Macro Name: Count_OBS                                        |
| Purpose: Counts the number of observations per subject in a  |
|          longitudinal data set                               |  
| Arguments: In_Dat = Data set name                            |
|            Out_Dsn = Output data set name                    |
|            ID_Var =  ID Variable                             |
|            Count = Variable to hold the count                |
*-------------------------------------------------------------*;
%Macro Count_OBS(In_Dat, Out_Dat, ID_Var, Count);
	PROC SQL;
		CREATE TABLE &Out_Dat AS
		SELECT *,
			   COUNT(&ID_Var) AS &Count
		FROM &In_Dat
		GROUP BY &ID_Var;
	QUIT;
%Mend Count_OBS;






