```
*--------------------------------------------------------------*
|Program Name: Head.sas                                        |
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
```

```
*--------------------------------------------------------------*
|Program Name: Tail.sas                                        |
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
```

```
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

