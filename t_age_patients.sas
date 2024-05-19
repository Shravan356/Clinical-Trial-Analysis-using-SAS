FILENAME REFFILE '/home/u63421294/Patients.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.Patients;
	GETNAMES=YES;
RUN;

data patients1;
	set patients;
	
dob = compress(cat(day,'/',month,'/',year));
dob1 = input(dob,ddmmyy10.);
format dob1 date9.;
age = (today()-dob1)/365;
run;

proc sort data= patients1;
by sex;
run;

proc means data = patients1;
var age;
run;

proc means data = patients1;
var age;
by sex;
run;

/* Create AGEGROUP variable */
DATA patients1;
	SET patients1;
    if age <= 18 THEN AGEGROUP = "<=18 years";
	ELSE IF age <= 65 THEN AGEGROUP = "18 to 65 years";
	ELSE AGEGROUP = ">65 years";
RUN;

/* Summary of frequency report */
PROC FREQ DATA=patients1;
	TABLES AGEGROUP*sex;
	RUN;





 
 








