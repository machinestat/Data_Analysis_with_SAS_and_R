---
title: "SAS Questions"
author: "Shu Guo"
date: "Friday, July 31, 2015"
output: pdf_document
---

1.  SAS stattements can be used in both DATA and PROC steps?  

 BY, WHERE, LABEL, FORMAT 

2.  Some procedures that support the BY statement?

REPORT, SORT (required), COMPARE, CORR, FREQ, TABULATE, MEANS, PLOT, TRANSPOSE, PRINT, UNIVARIATE

3.  Some of the procedures that support the WHERE statement?

REPORT, COMPARE, SORT, CORR, FREQ, TABULATE, MEANS, PLOT, TRANSPOSE, PRINT, UNIVARIATE

4. four types of variable-lists notations?

*numbered range lists*: Var1 - Var3 for Var1, Var2, Var3

*named range lists*: ID -- Age refers to all the variables in the order of variable creation from ID to Age.

*name prefix lists*: refer to all variables that begin with a specified character string such as Score:

*special SAS name list*: _NUMERIC_, _CHARACTER_, _ALL_ refer to all numeric, character and all the variables defined in the DATA step, respectively.

5. What are some of the differences between a WHERE and an IF statement? 

WHERE conditions are applied before the data enters the input buffer while IF conditions are applied after the data enters the program data vector. This is the reason why the WHERE condition is faster because not all observations have to be read and because it can only be applied on variables that exist in the input data set. 

  (1) No difference between WHERE and IF conditions:  
      Using variables in data set  
	 Using SET, MERGE or UPDATE statement if within the DATA step  
Example:  
DATA exam; 
    INPUT Name $ Class $ Score ; 
DATALINES; 
Tim math 9 
Tim history 8   
Tim science 7 
Sally math 10 
Sally science 7 
Sally history 10 
John math 8 
John history 8 
John science 9 
; 
RUN; 
DATA student1;
    SET exam;
    *Can use WHERE condition because NAME variable is a data set variable;
    *WHERE condition requires all data set variables;
    WHERE Name = 'Tim' OR Name = 'Sally';
RUN;

/*apply the IF statement instead of the WHERE statement to get the same results.*/
DATA student1;
    SET exam;
    IF Name = 'Tim' OR Name = 'Sally';
RUN;

  (2) Must use IF condition
 	 Accessing raw data file using INPUT statement
      Example:
DATA exam; 
    INPUT Name $ Class $ Score; 
    IF Name = 'Tim' OR Name = 'Sally';
DATALINES; 
Tim math 9 
Tim history 8   
Tim science 7 
Sally math 10 
Sally science 7 
Sally history 10 
John math 8 
John history 8 
John science 9 
; 
RUN; 

/*    Using automatic variables such as _N_, FIRST.BY, LAST.BY*/
DATA exam; 
  INPUT Name $ Class $ Score ; 
DATALINES; 
Tim math 9 
Tim history 8   
Tim science 7 
Sally math 10 
Sally science 7 
Sally history 10 
John math 8 
John history 8 
John science 9 
;
RUN;
PROC SORT DATA = exam OUT = student2;
    BY Name;
RUN;

DATA student2;
    SET student2;
    BY Name;
    *Use IF condition because NAME is the BY variable;
    IF First.Name;
RUN;

/*    Using newly created variables in data set*/
DATA student3;
    SET exam;
    *Create CLASSNUM variable;
    IF class = 'math' THEN classnum = 1;
    ELSE IF class = 'science' THEN classnum = 2;
    ELSE IF class = 'history' THEN classnum = 3;
    *Use IF condition because CLASSNUM variable was created within the DATA step;
    IF classnum = 3;
RUN;
/*    In combination with data set options such as OBS =**, POINT = , FIRSTOBS = */
/*    To conditionally execute statement*/

/*(3) Must use WHERE Condition*/
/*    Using special operators*** such as LIKE or CONTAINS*/
DATA student;
    SET exam;
    *Can use WHERE condition because NAME variable is a data set variable;
    *WHERE condition requires all data set variables;
    WHERE Name =: 'T' OR Name = 'ally';
RUN;
/*    Directly using any SAS Procedure*/
PROC PRINT DATA = exam;
    WHERE Name = 'Tim' OR Name = 'Sally';
RUN;
/*    More efficiently**** */
/*    Using index, if available*/
/*    When subsetting as a data set option*/
/*    When subsetting using Proc SQL*/

/*(4) When merging data sets */
DATA School;                               
    INPUT Name $ Class $ Score ;             
DATALINES;                                   
A math 10                                 
B history 10                               
C science 10                              
;                                         
RUN;  
DATA School_Data;
    INPUT Name $ Class $ Score ;
DATALINES; 
A math 10
B history 8 
C science 7 
; 
RUN; 

/*    subset before merging: WHERE*/
DATA School_Where;
    MERGE school school_data;  
    BY Name;
    *subsets BEFORE merging;
    WHERE Score = 10;
RUN;

/*    subset after merging: IF*/
DATA School_If;
    MERGE School School_data;
    BY Name;
    *subsets AFTER merging;
    IF Score = 10;
RUN;

2.	What are some of the differences between a Class and a BY statement in proc summary?  
     *  The input dataset must be sorted by the BY variables. It doesn't have to be sorted by the CLASS variables.
     *  Without the NWAY option in the PROC MEANS statement, the CLASS statement will calculate summaries for each class variable separately as well as for each possible combination of class variables. The BY statement only provides summaries for the groups created by the combination of all BY variables.
    *  The BY summaries are reported in separate tables (pages) whereas the CLASS summaries appear in a single table.
    *  The MEANS procedure is more efficient at treating BY groups than CLASS groups.

3.	What are the difference between MANE function and PROC MEANS?  
  *  By default Proc Means calculate the summary statistics like N, Mean, Std deviation, Minimum and maximum, Where as 
  *  Mean function compute only the mean values.
