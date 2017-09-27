* Encoding: UTF-8.
* Merge student and school data files PISA 2012 and 2015

* PISA 2015 * 

* First we will merge the 2015 student and school data files

GET FILE = 'G:\CIES Proposal Idea\PISA 2015 Data\PISA 2015 Student File.sav'.
SORT CASES BY CNTSCHID.
SAVE OUTFILE = 'G:\CIES Proposal Idea\PISA 2015 Data\PISA2015_stu_merge.sav'.

GET FILE = 'G:\CIES Proposal Idea\PISA 2015 Data\PISA 2015 School File.sav'.
SORT CASES BY CNTSCHID.
SAVE OUTFILE = 'G:\CIES Proposal Idea\PISA 2015 Data\PISA2015_sch_merge.sav'.

MATCH FILES 
    FILE= 'G:\CIES Proposal Idea\PISA 2015 Data\PISA2015_stu_merge.sav' 
    TABLE= 'G:\CIES Proposal Idea\PISA 2015 Data\PISA2015_sch_merge.sav'
BY CNTSCHID.
SAVE OUTFILE = 'G:\CIES Proposal Idea\PISA 2015 Data\PISA2015_merged.sav'.

* PISA 2012 *

* Now we will do the same procedure with the PISA 2012 data files

GET FILE = 'G:\CIES Proposal Idea\PISA 2012 Data\PISA 2012 Student File.sav'.
SORT CASES BY CNT SCHOOLID.
SAVE OUTFILE = 'G:\CIES Proposal Idea\PISA 2012 Data\PISA2012_stu_merge.sav'.

GET FILE = 'G:\CIES Proposal Idea\PISA 2012 Data\PISA 2012 School File.sav'.
SORT CASES BY CNT SCHOOLID.
SAVE OUTFILE = 'G:\CIES Proposal Idea\PISA 2012 Data\PISA2012_sch_merge.sav'.

MATCH FILES 
    FILE= 'G:\CIES Proposal Idea\PISA 2012 Data\PISA2012_stu_merge.sav' 
    TABLE= 'G:\CIES Proposal Idea\PISA 2012 Data\PISA2012_sch_merge.sav'
BY CNT SCHOOLID.
SAVE OUTFILE = 'G:\CIES Proposal Idea\PISA 2012 Data\PISA2012_merged.sav'.

* Now we weill save each of the data files as .csv

GET
  FILE='G:\CIES Proposal Idea\PISA 2015 Data\PISA2015_merged.sav'.
DATASET NAME DataSet1 WINDOW=FRONT.

SAVE TRANSLATE OUTFILE='G:\CIES Proposal Idea\PISA2015_merged.csv'
  /TYPE=CSV
  /ENCODING='UTF8'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.

GET
  FILE='G:\CIES Proposal Idea\PISA 2012 Data\PISA2012_merged.sav'.
DATASET NAME DataSet1 WINDOW=FRONT.

SAVE TRANSLATE OUTFILE='G:\CIES Proposal Idea\PISA2012_merged.csv'
  /TYPE=CSV
  /ENCODING='UTF8'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.






