*--------------------------------------------------------------*
|Program Name: Head.sas                                        |
|Purpose: Macro which prints out the first 8 observations or   |
|         the first n observations.                            |
|Argument: %Head(Dat, N = )                                    |
|Examples: %Head(Test)                                         |
|          %Head(Test, N = 10)                                 |
*-------------------------------------------------------------*;
```
%macro Head(Dat, N = 8);
    PROC PRINT DATA = &Dat(OBS = &N) NOOBS;
        TITLE "The First &N Observations of Data Set &Dat";
    RUN;
%mend Head;
```
