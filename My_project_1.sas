/* Imorting Project Data */
FILENAME REFFILE '/home/u63421294/project-demog.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.my_project;
	GETNAMES=YES;
RUN;

/* Creating Age Variable */
data my_project_1;
	set my_project;
dob = compress(cat(day,'/',month,'/',year));
num_dob = input(dob,ddmmyy10.);
age = (diagdt-num_dob)/365;
output;
trt=2;
output;
run;

proc sort data=my_project_1;
by trt;
run;

/* Summarizing Age Variable */
proc means data=my_project_1 noprint;
var age;
by trt;
output out = age_stat;
run;

data age_stat;
	set age_stat;
length value $10.;
ord = 1;
 if _stat_ = 'N' then do; subord = 1; Value = strip(put(age,8.));end;
 if _stat_ = 'MEAN' then do; subord = 2; value = strip(put(age,8.1));end;
 if _stat_ = 'STD' then do; subord = 3; Value = strip(put(age,8.2));end;
 if _stat_ = 'MIN' then do; subord = 4; value = strip(put(age,8.1));end;
 if _stat_ = 'MAX' then do; subord = 5; value = strip(put(age,8.1));end;
 drop _type_ _freq_ age;
rename _stat_=Stat;
 run;

/* Create AGEGROUP variable */
data my_project_1;
	set my_project_1;
    if age <= 18 then AGEGROUP = "< 18 years";
	else if age <= 65 then AGEGROUP = "18 to 65 years";
	else AGEGROUP = "> 65 years";
RUN;

/* Summary of Agegroup variable */
proc freq data=my_project_1 noprint;
	table trt*agegroup / outpct out = agegroup_stat;
	run;
	
data Agegroup_stat;
	set Agegroup_stat;
Value = cat(count,' (',round(pct_row,.1),'%)');
ord = 2;
if Agegroup = '< 18 years' then subord = 1;
else if Agegroup ='18 to 65 y' then subord = 2;
else if Agegroup = '> 65 years' then subord = 3;
drop count percent pct_row pct_col;
rename Agegroup=Stat;
run;

/* Creting Gender Variable */	
proc format;
value gender_value
1 = "Male"
2 = "Female"
;
run;

data my_project_1;
	set my_project_1;
sex =put(gender,gender_value.);
run;

/* Summarizing Gender Variable */
proc freq data=my_project_1 noprint;
table trt*sex / outpct out = gender_stat;
run;

data gender_stat;
set gender_stat;
Value = cat(count,' (',round(pct_row,.1),'%)');
ord = 3;
if sex = "Male" then subord = 1;
else subord = 2;
drop count percent pct_row pct_col;
rename sex=Stat;
run;


/* Cerating Race Variable  */
proc format;
value race_value
1 = "Asian"
2 = "African American"
3 = "Hispanic"
4 = "White"
5 = "Other"
;
run;

data my_project_1;
	set my_project_1;
races = put(race,race_value.);
run;

/* Summarizing Races Variable */
proc freq data=my_project_1 noprint;
table trt*races / outpct out = race_stat;
run;

data race_stat;
set race_stat;
Value = cat(count,' (',round(pct_row,.1),'%)');
ord = 4;
if races ="Asian" then subord = 1;
else if races ="African American" then subord = 2;
else if races ="Hispanic" then subord = 3;
else if races ="White" then subord = 4;
else if races ="Other" then subord = 5;

drop count percent pct_row pct_col;
rename races=Stat;
run;

/* Merging all Datsets */
data allstats;
	set age_stat agegroup_stat gender_stat race_stat;
run;

proc sort data = allstats;
by ord subord Stat;
run;

/*Transposing the Allstat Dataset  */
proc transpose data=allstats out = t_allstats prefix=_;
var Value;
id trt;
by ord subord Stat;
run;

data final;
length Stat $30;
	set t_allstats;
	by ord subord;
	output;
	if first.ord then do;
		if ord=1 then stat = 'Age (Years)';
		if ord=2 then stat = 'Age Group';
		if ord=3 then stat = 'Gender';
		if ord=4 then stat = 'Race';
		subord=0;
		_0="";
		_1= "";
		_2= "";
		output;
		end;
		
proc sort;
by ord subord;
run;

proc sql noprint;
select count(*) into : placebo from my_project_1 where trt=0;
select count(*) into :active from my_project_1 where trt=1;
select count(*) into :total from my_project_1 where trt=2;
quit;

title 'Table 1.1';
title2 'Demographic and Baseline Characteristic by Treatment Group';
title3 'Randomized Poplution';
footnote 'Note: Percentages are based on the number of non-missing values in each treatment group.';


proc report data=final split='/';
column ord subord Stat _0 _1 _2;
define ord / noprint order;
define subord / noprint order;
define Stat/ display width=80 "";
define _0/ display width=30 "Placebo /(N=&placebo)";
define _1/ display width = 50 "Active Treatment /(N=&active)";
define _2/ display width = 50"All Patients /(N=&total)";
run;
	
