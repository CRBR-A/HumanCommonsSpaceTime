// program: calendar.c
// function: print different calendar
// author: Cerbere Ace (cerbere.ace@gmail.com)
// license: [Unlicense](unlicense.txt)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// WeekDay indexes
#define SUNDAY		 0
#define MONDAY		 1
#define TUESDAY		 2
#define WEDNESDAY	 3
#define THURSDAY	 4
#define FRIDAY		 5
#define SATURDAY 	 6

// Month indexes
#define JANUARY    0
#define FEBRUARY   1
#define MARCH      2
#define APRIL      3
#define MAY        4
#define JUNE       5
#define JULY       6
#define AUGUST     7
#define SEPTEMBER  8
#define OCTOBER    9
#define NOVEMBER  10
#define DECEMBER  11

//CALENDARS REFERENCES
#define JULIAN_END_WEEKDAY      THURSDAY
#define JULIAN_END_DAY          4
#define JULIAN_END_MONTH        OCTOBER
#define GREGORIAN_START_WEEKDAY FRIDAY
#define GREGORIAN_START_DAY     15
#define GREGORIAN_START_MONTH   OCTOBER
#define GREGORIAN_START_YEAR    1582


#define OPT_NONE          'n'
#define OPT_YES           'y'
#define OPT_LEFT          'l'
#define OPT_RIGHT         'r'
#define OPT_BOTH          'b'
#define OPT_VIEW_GRID     'g'
#define OPT_VIEW_LINEAR   'l'
#define OPT_VIEW_VERTICAL 'v'
#define OPT_LYC_DEFAULT   'd'
#define OPT_LYC_JULIAN    'j'
#define OPT_LYC_GREGORIAN 'g'

//Options indexes
#define OPT_IDX_WKN      0
#define OPT_IDX_DOY      1
#define OPT_IDX_LEFT     2
#define OPT_IDX_WD       3
#define OPT_IDX_DN       4
#define OPT_IDX_MONTH    5
#define OPT_IDX_VIEW     6
#define OPT_IDX_COMPACT  7
#define OPT_IDX_LYC      8  //LeapYear calculation
#define OPT_IDX_LYD      9  //Print LeapYear Day
#define OPT_IDX_FIRSTWD  10
#define OPT_IDX_NBCOL    11
#define OPT_IDX_FIXED    12

#define OPTS_IDX_PRINTED 4


//Chars for end of line 
static const char endLine[4]="\n";

static const char* headerStr[6]={
  "WkN", //week number
  "DoY", //day of the year
  "DLf", //days left
  "WD",  //WeekDay 
  "DN",  //Day number
  "Mon"  //Month
};

//Days in week
static const char* weekdays[7]={
  "Sunday", 
  "Monday", 
  "Tuesday", 
  "Wednesday", 
  "Thursday", 
  "Friday", 
  "Saturday"
};

//months in year
static const char* months[12]={
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
};

//number of days per month
static const int daysPerMonth[12]={
  31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

//Print a day number
static void printDayNumber(int dayNumber, int numLetters, char separator){
  int c;
  int nbDigits=0;
  int tmp=dayNumber;
  
  //calculate the number of digits
  while(tmp!=0){
    //remove the right digit
    tmp=tmp/10;
    //Increment digit counter
    nbDigits++;
  }
  
  //space the missing characters
  for(c=nbDigits; c<numLetters; c++){
    printf("%c", separator);
  }
  
  //And print the day number
  printf("%d", dayNumber);
}

//Print the day name, of numLetter length
static void printWeekDayName(int dayWeek, int numLetters){
  int c;
  int len=strlen(weekdays[dayWeek]);
  if(numLetters==0 || len<=numLetters){
    //Length OK : print the weekday
    printf("%s", weekdays[dayWeek]);
    //Add spaces to complete the size
    for(c=len;c<numLetters;c++){
      printf(" ");
    }
  }else{
    //Print the numLetters characters of the weekday name
    for(c=0;c<numLetters;c++){
      printf("%c", (weekdays[dayWeek])[c]);
    }
  }
}

//return the month name, of numLetter length
static void printMonthName(int month, int numLetters){
  int c;
  int len=strlen(months[month]);
  if(numLetters==0 || len<=numLetters){
    //Length OK : print the month
    printf("%s", months[month]);
    //Add spaces to complete the size
    for(c=len;c<numLetters;c++){
      printf(" ");
    }
  }else{
    //Print the numLetters characters of the Month name
    for(c=0;c<numLetters;c++){
      printf("%c", (months[month])[c]);
    }
  }
}

//Return 0 if not a leap year, 1 if is a leap year
//Depending of the OPT_IDX_LYC option
static int isLeapYear(int year, char* opts){
  int leapDay;
  int checkGregorianOpt=(opts[OPT_IDX_LYC]==OPT_LYC_GREGORIAN);
  int checkJulianOpt=(opts[OPT_IDX_LYC]==OPT_LYC_JULIAN);
  int checkDefaultOpt=(opts[OPT_IDX_LYC]==OPT_LYC_DEFAULT);
  
  if(checkGregorianOpt || (checkDefaultOpt && year>GREGORIAN_START_YEAR)){
    //Gregorian calculation
    leapDay=(((year%4==0) && (year%100!=0)) || year%400==0);
  }else if(checkJulianOpt || (checkDefaultOpt && year<=GREGORIAN_START_YEAR)){
    //Julian calculation
    leapDay=(year%4==0);
  }
  
  return leapDay;
}

//Return the number of days for a month given
static int getDaysPerMonth(int month, int year, char* opts){
  //set the number of days for the month
  int days=daysPerMonth[month];
  
  //If month is FEBRUARY, check the leap day
  if(month==FEBRUARY){
    days=days+isLeapYear(year, opts);
  }
  
  return days;
}


//return a new day by adding (positive value) 
//or Subtracting (negative value) days
static int changeWeekDay(int weekday, int value){
  int i;
  int signValue;
  
  //Get the sign (add or subtract)
  if(value>=0){
    signValue=1;
  }else{
    signValue=-1;
    value=-value;
  }
  
  //Remove all FULL weeks : No change in the weekday
  value=value%7;
  
  //loop days
  for(i=0; i<value; i++){
    //Add or subtract (depending the sign) a weekday
    weekday=weekday+signValue;

   //if limits exceeded, correct the weekday
    if(weekday<0){
      weekday=6;
    }else if(weekday>6){
      weekday=0;
    }
  }
  
  return weekday;
}

//return a new month by adding (positive value) 
//or Subtracting (negative value) months
static int changeMonth(int month, int value){
  int i;
  int signValue;
  
  //Get the sign (to add or subtract)
  if(value>=0){
    signValue=1;
  }else{
    signValue=-1;
    value=-value;
  }
  
  //Remove all FULL years : No change in the month
  value=value%12;
  
  //loop days
  for(i=0; i<value; i++){
    //Add or subtract (depending the sign) a month
    month=month+signValue;

   //if limits exceeded, correct the month
    if(month<JANUARY){
      month=DECEMBER;
    }else if(month>DECEMBER){
      month=JANUARY;
    }
  }
  
  return month;
}

//Return the day of the year (or the number of days passed)
static int getDayOfYear(int day, int month, int year, char* opts){
  int daysPassed=day;
  int previousMonth;
   
  //Sum the days passed
  for(previousMonth=JANUARY; previousMonth<month; previousMonth++){
    daysPassed=daysPassed+getDaysPerMonth(previousMonth, year, opts);
  }
  
  return daysPassed;
}

//Return the number of days for the year
//Can do '365+leapYear' but why not using variables and functions ?
static int getDaysInfYear(int year, char* opts){
  //get the number of days of December
  int daysInDecember=getDaysPerMonth(DECEMBER, year, opts);
  //Return the number of days from JANUARY to DECEMBER (excluded), 
  //with the number of days of DECEMBER
  return getDayOfYear(daysInDecember, DECEMBER, year, opts);
}

//Return the first WeekDay of the month
static int getFirstWDMonth(int month, int year, char* opts){
  int tYear, yearsRemaining;
  int calWD, calDay, calMonth, calYear;
  int firstWD;
  int daysInMonth;
  int signValue;
  int previousDays;
  int checkGregorianOpt=(opts[OPT_IDX_LYC]==OPT_LYC_GREGORIAN);
  int checkJulianOpt=(opts[OPT_IDX_LYC]==OPT_LYC_JULIAN);
  int checkDefaultOpt=(opts[OPT_IDX_LYC]==OPT_LYC_DEFAULT);
  
  //Check if date is After Or before the GREGORIAN_START_YEAR
  if(year>GREGORIAN_START_YEAR){
    signValue=1;
  }else{
    signValue=-1;
  }
  
  if(checkGregorianOpt || (checkDefaultOpt && signValue>0)){
    //Gregorian References point
    calDay=GREGORIAN_START_DAY;
    calMonth=GREGORIAN_START_MONTH;
    calYear=GREGORIAN_START_YEAR;
    calWD=GREGORIAN_START_WEEKDAY;
  }else if(checkJulianOpt || (checkDefaultOpt && signValue<0)){
    //Julian References point
    calDay=JULIAN_END_DAY;
    calMonth=JULIAN_END_MONTH;
    calYear=GREGORIAN_START_YEAR;
    calWD=JULIAN_END_WEEKDAY;
  }

  //Backward to the 1st of January 
  previousDays=1-getDayOfYear(calDay, calMonth, calYear, opts);
  firstWD=changeWeekDay(calWD, previousDays);
  
  //If backward year, begin with the previous year (as current year is done)
  if(signValue<0){
    calYear=calYear-1;
  }
  
  //For each year (previous or next, depending of the signValue)
  tYear=calYear;
  while((signValue<0 && year<=tYear) || (signValue>0 && tYear<year)){
    //remove/add 1 day (+1 day if it's a leap year)
    firstWD=changeWeekDay(firstWD, (signValue*(1+isLeapYear(tYear, opts))));
    tYear=tYear+signValue;
  }
  
  //Add the days passed until the month
  firstWD=changeWeekDay(firstWD, getDayOfYear(0, month, year, opts));
  
  return firstWD;
}

//Return the WeekDay of the day
static int getWeekDay(int day, int month, int year, char* opts){
  int firstWDMonth=getFirstWDMonth(month, year, opts);
  int weekday=changeWeekDay(firstWDMonth, day-1);
  return weekday;
}

//Return the offset (number of days present/absent in the 1st week)
static int getOffsetMonth(int direction, int month, int year, char* opts){
  int weekday;
  int firstWD=opts[OPT_IDX_FIRSTWD]-'0';
  int days=0;
  
  //Calculate the days
  weekday=getFirstWDMonth(month, year, opts);
  while(weekday!=firstWD){
    weekday=changeWeekDay(weekday, direction);
    days++;
  }
  
  return days;
}  

//Return the number of weeks for a month
static int getNumberWeeksMonth(int month, int year, char* opts){
  int offset, weekday;
  int firstWD=opts[OPT_IDX_FIRSTWD]-'0';
  int nbWeeks=0;
  int daysInMonth=getDaysPerMonth(month, year, opts);
  
  //Calculate the offset of the first Week
  offset=getOffsetMonth(1, month, year, opts);
  
  //If not a full week for the 1st week, add 1 week
  if(offset>0){
    nbWeeks++;
  }

  //Remove the offset
  daysInMonth=daysInMonth-offset;
  //Calculate all full weeks
  nbWeeks=nbWeeks+(daysInMonth/7);
  
  //Add 1 week if any remaining days (not full weeks)
  if((daysInMonth%7)>0){
    nbWeeks++;
  }

  return nbWeeks;
}

//Return the weekNumber (ISO weekday !)
static int getWeekNumber(int day, int month, int year, char* opts){
  int daysPassed;
  int daysOnset, daysOffset, weekday, firstDayOfYear;
  int weekNumber, maxWeeks;
  int firstWD=opts[OPT_IDX_FIRSTWD]-'0';

  //get the days passed
  daysPassed=getDayOfYear(day, month, year, opts);
  
  //get the 1st Day of the year
  firstDayOfYear=getFirstWDMonth(JANUARY, year, opts);
  
  //Calculate the days present in the 1st week of January
  daysOnset=getOffsetMonth(1, JANUARY, year, opts);
  
  //Calculate the days absent (offset) in the 1st week of January
  daysOffset=getOffsetMonth(-1, JANUARY, year, opts);
  
  if(firstDayOfYear==SUNDAY || firstDayOfYear>=FRIDAY){
    //if it's Friday OR Saturday with leapYearN-1
    if((firstDayOfYear==FRIDAY) || (firstDayOfYear==SATURDAY && isLeapYear(year-1, opts))){
      weekNumber=53;
    }else{
      //Sunday OR Saturday without LeapYearN-1
      weekNumber=52;
    }
  }else{
    weekNumber=1;
  }
  
  //Calculate if there are 52 or 53 weeks for this year (limit)
  if((firstDayOfYear==THURSDAY) 
      || (firstDayOfYear==WEDNESDAY && isLeapYear(year, opts))){
    maxWeeks=53;
  }else{
    maxWeeks=52;
  }

  if(daysPassed>daysOnset){
    //get the number of full weeks
    weekNumber=(daysPassed-daysOnset)/7;

    //If there are remaining days, add a new week
    if(((daysPassed-daysOnset)%7)>0){
      weekNumber++;
    }
    
    //if there are odd days : add a week
    if(daysOnset>0){
      weekNumber++;
      
      //remove 1 week if year start with week 52 or 53
      if(firstDayOfYear==SUNDAY || firstDayOfYear>=FRIDAY){
        weekNumber=weekNumber-1;
      }
    }

    //Set to W1 if weekNumber exceed the number of weeks expected
    if(weekNumber>maxWeeks){
        weekNumber=1;
    }
  }
  
  return weekNumber;
}

//Return the number of characters used for headers
static int getSizeHeader(char* opts){
  int cPos, headerIdx;
  int tmpCheckOpt, checkLeft, checkRight;
  int sizeResult=0;
  
  for(cPos=-1; cPos<2; cPos++){
    for(headerIdx=0; headerIdx<OPTS_IDX_PRINTED; headerIdx++){
      tmpCheckOpt=(opts[headerIdx]==OPT_LEFT || opts[headerIdx]==OPT_BOTH);
      checkLeft=(cPos<0 && tmpCheckOpt);
      tmpCheckOpt=(opts[headerIdx]==OPT_RIGHT || opts[headerIdx]==OPT_BOTH);
      checkRight=(cPos>0 && tmpCheckOpt);
        
      if(opts[headerIdx]!=OPT_NONE){
        //Right Column : add a space BEFORE writing the week header
        if(checkRight){
          sizeResult++;
        }

        if(checkLeft || checkRight){
          sizeResult=sizeResult+strlen(headerStr[headerIdx]);
        }
        
        //Left Column: Add a space AFTER writing the week header
        if(checkLeft){
          sizeResult++;
        }
      }
    }
  }

  return sizeResult;
}

//print the headerIdx header
//cPos=-1 : a left column, cPos=1 : a right column
//cPos=-2 : Force left column, 
// cPos=0 : force centered
// cPos=2 : Force right column
static void printHeader(int headerIdx, int cPos, char* opts){
  int checkLeft=(cPos<0);
  int checkRight=(cPos>0);
  if(cPos==-1){
    checkLeft=(opts[headerIdx]==OPT_LEFT || opts[headerIdx]==OPT_BOTH);
  }
  if(cPos==1){
    checkRight=(opts[headerIdx]==OPT_RIGHT || opts[headerIdx]==OPT_BOTH);
  }
  
  if(cPos!=-1 || cPos!=1 || opts[headerIdx]!=OPT_NONE){
    //Right Column : add a space BEFORE writing the week header
    if(checkRight){
      printf(" ");
    }

    if(cPos==0 || checkLeft || checkRight){
      //Print the header
      printf("%s", headerStr[headerIdx]);
    }
    
    //Left Column: Add a space AFTER writing the week header
    if(checkLeft){
      printf(" ");
    }
  }
}

//print the week number
//if day=0 : escape the field (=same week than before)
static void printWeekNumber(int day, int month, int year, char* opts){
  if(day>0){
    //Get the week number
    int weekNumber=getWeekNumber(day, month, year, opts);
    
    //Print the week number ("W01", "W02"...)
    printf("W");
    printDayNumber(weekNumber, strlen(headerStr[OPT_IDX_WKN])-1, '0');
  }else{
    //space the week number
    printf("   ");
  }
}

//print the number of days left
//if day=0 : escape the field
static void printDaysLeft(int day, int month, int year, char* opts){    
  if(day>0){
    //Calculate the days passed
    int daysInYear=getDaysInfYear(year, opts);
    int daysPassed=getDayOfYear(day, month, year, opts);
    int daysLeft=daysInYear-daysPassed;
    
    //Print the days left
    printDayNumber(daysLeft, strlen(headerStr[OPT_IDX_LEFT]), ' ');
  }else{
    //space the days left
    printf("   ");
  }
}

//Print the day of the year
//if day=0 : escape the field
static void printDayOfYear(int day, int month, int year, char* opts){
  if(day>0){
    //get the day of the year
    int dayOfYear=getDayOfYear(day, month, year, opts);
      
    //Print the day
    printDayNumber(dayOfYear, strlen(headerStr[OPT_IDX_DOY]), ' ');
  }else{
    //space the day of the year
    printf("   ");
  }
}

//Print the WeekDay (name)
//if day=-1 : escape the field
static void printWeekDay(int dayWeek, int numLetters){    
  if(dayWeek>-1){
    //Print the weekday
    printWeekDayName(dayWeek, numLetters);
  }else{
    //Escape the numLetters
    for(int c=0;c<numLetters;c++){
      printf(" ");
    }
  }
}

//print headers, depending of opts
//cPos=-1 : a left column, cPos=1 : a right column
static void printHeaders(int cPos, char* opts){
  int i;
  if(cPos<0){
    //print the headers
    for(i=0; i<OPTS_IDX_PRINTED; i++){
      printHeader(i, cPos, opts);
    }
  }else{
    //print the header (inverted)
    for(i=OPTS_IDX_PRINTED-1; i>-1; i--){
      printHeader(i, cPos, opts);
    }
  }
}

//print info
//cPos=-1 : a left column, cPos=1 : a right column
static int printInfo(int day, int month, int year, int cPos, 
                      int optsIdx, char* opts, int numLetters){
  int printed=0;
  int checkLeft=(cPos<0);
  int checkRight=(cPos>0);
  int weekday;
  if(cPos==-1){
    checkLeft=(opts[optsIdx]==OPT_LEFT || opts[optsIdx]==OPT_BOTH);
  }
  if(cPos==1){
    checkRight=(opts[optsIdx]==OPT_RIGHT || opts[optsIdx]==OPT_BOTH);
  }
  
  if(cPos!=-1 || cPos!=1 || opts[optsIdx]!=OPT_NONE){
    //Right Column : add a space BEFORE writing the info
    if(checkRight){
      printf(" ");
      printed++;
    }

    if(opts[optsIdx]!=OPT_NONE && (cPos==0 || checkLeft || checkRight)){
      if(optsIdx==OPT_IDX_WKN){
        printWeekNumber(day, month, year, opts);
        printed=printed+3;
      }else if(optsIdx==OPT_IDX_LEFT){
        printDaysLeft(day, month, year, opts);
        printed=printed+3;
      }else if(optsIdx==OPT_IDX_DOY){
        printDayOfYear(day, month, year, opts);
        printed=printed+3;
      }else if(optsIdx==OPT_IDX_WD){
        weekday=getWeekDay(day, month, year, opts);
        printWeekDay(weekday, numLetters);
        printed=printed+numLetters;
      }else if(optsIdx==OPT_IDX_LYD){
        printf("%d", isLeapYear(year, opts));
        printed++; //Only 0 or 1
      }
    }
    
    //Left Column: Add a space AFTER writing the info
    if(checkLeft){
      printf(" ");
      printed++;
    }
  }
  
  return printed;
}

//print information, depending of opts
static void printInfos(int day, int month, int year, int cPos, char* opts){
  for(int idx=0; idx<OPTS_IDX_PRINTED; idx++){
    printInfo(day, month, year, cPos, idx, opts, 2);
  }
  //print the Leap Year information
  printInfo(day, month, year, cPos, OPT_IDX_LYD, opts, 2);
}

//
static void printDayInfos(int day, int month, int year, int cPos, char* opts){
  int escapeCol=0;
  int printResult;
  for(int idx=0; idx<OPTS_IDX_PRINTED; idx++){
    printResult=printInfo(day, month, year, escapeCol, idx, opts, 0);
    if(printResult>0){
      //escape the next col (use checkRight)
      escapeCol=1;
    }
  }
  //print the Leap Year information
  printInfo(day, month, year, escapeCol, OPT_IDX_LYD, opts, 0);
}

//print a Grid calendar
//- use a full-week/line print technique, NEEDED for printing multiples cols
//for 1 month print, the linear approach is better :
//     (print all days, add an endline when last day of the week)
static void printGCal(int monthStart, int monthEnd, int year, char* opts){

  int day;      //1-31, the day of the month
  int month;
  int weekday;        //0-7 : sunday to saturday
  int dayCount;     //increment to print all days
  int daysInMonth, daysInPreviousMonth;
  int firstWD=opts[OPT_IDX_FIRSTWD]-'0';
  int offset;
  int monthsToPrint=opts[OPT_IDX_NBCOL]-'A'; //nb of month to print
  int printedMonth;
  int lastMonthToPrint;
  int rowSize;
  int numberWeeksMonth, numberWeeksToPrint;
  
  //Header : for multiples months, print the year in 1st line
  if(monthsToPrint>1){
    printf("%d:%s", year, endLine);
    rowSize=(7*3-1)+getSizeHeader(opts)+2;
  }else{
    rowSize=0;
  }
  
  //Print all months
  for(month=monthStart; month<=monthEnd; month=month+monthsToPrint){
    
    //Check the last month to print
    if(month+monthsToPrint>DECEMBER){
      lastMonthToPrint=DECEMBER+1;
    }else{
      lastMonthToPrint=month+monthsToPrint;
    }
    
    //HEADER : if not compact view : print the full Month name
    if(opts[OPT_IDX_COMPACT]!=OPT_YES){
      //Do for each print month
      for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
        printMonthName(printedMonth, rowSize);
      }
    }
      
    //HEADERS
    if(month==monthStart || opts[OPT_IDX_COMPACT]!=OPT_YES){

      if(monthsToPrint==1){
        //print the year
        printf(" %d:", year);
      }
      
      //Escape the line (months)
      printf("%s", endLine);
      
      //Compact views : print a month column
      if(opts[OPT_IDX_COMPACT]==OPT_YES){
        printHeader(OPT_IDX_MONTH, -2, opts);
      }
      
      //Do for each print month
      for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
        //print Left HEADER columns
        printHeaders(-1, opts);

        //HEADER : Day names
        weekday=firstWD;
        
        for(dayCount=0; dayCount<7; dayCount++){
          //print the day names (short : 2 characters)
          printWeekDayName(weekday, 2);
          //Add a space between days
          if(dayCount<6){
            printf(" ");
          }
          //Go to the next day and increment the number days
          weekday=changeWeekDay(weekday, 1);
        }
        
        //HEADER : right columns
        printHeaders(1, opts);
        
        if(printedMonth<lastMonthToPrint-1){
          //escape months
          printf("  ");
        }
      }
      
      //HEADER : END 
      printf("%s", endLine);
    }
    
    //Found the number of weeks (= lines) to print
    numberWeeksToPrint=0;
    for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
      numberWeeksMonth=getNumberWeeksMonth(printedMonth, year, opts);
      if(numberWeeksToPrint<numberWeeksMonth){
        numberWeeksToPrint=numberWeeksMonth;
      }
    }
    
    
    //Printing each weeks (=lines)
    for(int weekInMonth=1; weekInMonth<=numberWeeksToPrint; weekInMonth++){
    
      //Do for each print month
      for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
                
        daysInMonth=getDaysPerMonth(printedMonth, year, opts);

        //Found the offset days in the month
        offset=getOffsetMonth(-1, printedMonth, year, opts);
          
        //Set the day
        day=1+(7*(weekInMonth-1))-offset;
        //If start with days from previous month, 
        if(day<1){
          if(opts[OPT_IDX_COMPACT]==OPT_YES 
              && weekInMonth==1 && printedMonth!=monthStart){
            //compact mode, the 1st days already printed previously, escape 
            weekInMonth++;
            day=1+(7*(weekInMonth-1))-offset;
          }else{
            //set it '1' for printing info (weeknumber...)
            day=1;
          }
        }
        
        if(opts[OPT_IDX_COMPACT]==OPT_YES){
          if(day<=1){
            //Print month name
            printMonthName(printedMonth, 3);
          }else if(weekInMonth<=numberWeeksMonth && day>(daysInMonth-6)){
            //Print the NEXT month name (compact)
            printMonthName(changeMonth(printedMonth, 1), 3);
          }else{
            //Escape the month (same)
            printf("   ");
          }
          printf(" ");
        }
        
        //Set empty day, if week printed exceed number of week month
        numberWeeksMonth=getNumberWeeksMonth(printedMonth, year, opts);
        if(weekInMonth>numberWeeksMonth){
          day=-1;
        }
        
        //print the left columns
        printInfos(day, printedMonth, year, -1, opts);

        //Print the 7 days
        for(dayCount=0; dayCount<7; dayCount++){
         
          //Set the day
          day=1+(7*(weekInMonth-1))+dayCount-offset;
          
          if(day>0 && day<=daysInMonth){
            //Print the day
            printDayNumber(day, 2, ' ');
          }else{
            if(numberWeeksMonth<=numberWeeksToPrint && opts[OPT_IDX_COMPACT]==OPT_YES){
              if(day<1){
                //get the number days of previous month
                daysInPreviousMonth=getDaysPerMonth(changeMonth(printedMonth, -1), year, opts);
                day=1+daysInPreviousMonth+dayCount-offset;
              }else{
                //(day>daysInMonth)
                day=day-daysInMonth;
              }
              //Print the day number
              printDayNumber(day, 2, ' ');
            }else{
              //Escape the day number
              printf("  ");
            }
          }
           
          //Add a space between day numbers
          if(dayCount<6){
            printf(" ");
          }
        }
        
        //Print right columns
        printInfos(day, printedMonth, year, 1, opts);
        
        if(printedMonth==lastMonthToPrint-1){
          //End of the line
          printf("%s", endLine);
        }else{
          //Escape months
          printf("  ");
        }
      }
    }
    
    if(lastMonthToPrint<=DECEMBER && opts[OPT_IDX_COMPACT]!=OPT_YES){
      //Print a line separator between group of months
      printf("%s", endLine);
    }
  }
}

//print a Linear calendar (=purely Horizontal)
static void printHCal(int monthStart, int monthEnd, int year, char* opts){

  int day;      //1-31, the day of the month
  int month, lastMonthToPrint;
  int weekday;        //0-7 : sunday to saturday
  int dayCount;   //increment to print all days
  int dayMaxToPrint, dayMaxMonth, dayPosition;
  int firstWDMonth;   //get 1st day 
  int daysInMonth;
  int firstWD=opts[OPT_IDX_FIRSTWD]-'0';
  int monthsToPrint=opts[OPT_IDX_NBCOL]-'A'; //nb of month to print
  int offset;
  
  //Check the last month to print
  if(monthStart+monthsToPrint>DECEMBER){
    lastMonthToPrint=DECEMBER+1;
  }else{
    lastMonthToPrint=monthStart+monthsToPrint;
  }
  
  //Calculate the number of days to print 
  dayMaxToPrint=0;
  //Print all the months
  for(month=monthStart; month<lastMonthToPrint; month++){
    //Calculate the offset of the first Week
    offset=getOffsetMonth(1, month, year, opts);

    //Calculate the maximum of days to print
    dayMaxMonth=0;
    //If not a full week for the 1st week, add 1 week
    if(offset>0){
      dayMaxMonth=7;
    }
    //Remove the offset
    dayMaxMonth=dayMaxMonth+getDaysPerMonth(month, year, opts)-offset;
    
    if(dayMaxToPrint<dayMaxMonth){
      dayMaxToPrint=dayMaxMonth;
    }
  }
  
  //Print all the months
  for(month=monthStart; month<lastMonthToPrint; month++){

    //set values
    day=1;
    daysInMonth=getDaysPerMonth(month, year, opts);
    firstWDMonth=getFirstWDMonth(month, year, opts);

    //HEADER : if not compact view : print the Month name
    if(opts[OPT_IDX_COMPACT]!=OPT_YES){
      printMonthName(month, 0);
      printf(" ");
    }
      
    //HEADERS
    if(month==monthStart || opts[OPT_IDX_COMPACT]!=OPT_YES){

      //print the year
      printf("%d:%s", year, endLine);
      
      //Compact views : print a month column
      if(opts[OPT_IDX_COMPACT]==OPT_YES){
        printHeader(OPT_IDX_MONTH, -2, opts);
      }
      
      //print Left HEADER columns
      printHeaders(-1, opts);

      //HEADER : print weekDay names
      if(opts[OPT_IDX_FIXED]==OPT_YES){
        //Restart with the 1st day of week
        weekday=firstWD;
      }else{
        //print only the days in the month
        dayMaxToPrint=daysInMonth;
        //start with the 1st WD of the month
        weekday=firstWDMonth;
      }
      
      for(dayCount=0; dayCount<dayMaxToPrint; dayCount++){
        //print the day names (short : 2 characters)
        printWeekDayName(weekday, 2);
        //Add a space between days
        if(dayCount<dayMaxToPrint-1){
          printf(" ");
        }
        //Go to the next day
        weekday=changeWeekDay(weekday, 1);
      }
      
      //HEADER : right columns
      printHeaders(1, opts);
      
      //HEADER : END
      printf("%s", endLine);
    }
    
    //reset dayPosition
    dayPosition=0;
    //Reset the weekday depending on Fixed mode
    if(opts[OPT_IDX_FIXED]==OPT_YES){
      weekday=firstWD;
    }else{
      weekday=firstWDMonth;
    }

    if(opts[OPT_IDX_COMPACT]==OPT_YES && dayPosition==0 && day==1){
        //Print month name (compact, 1st day)
        printMonthName(month, 3);
        printf(" ");
    }
    
    //print the left columns
    printInfos(day, month, year, -1, opts);

    //Escape the 1st missing days before the 1st day printed
    while(firstWDMonth!=weekday){
      //add spaces
      printf("   ");
      
      dayPosition++;
      weekday=changeWeekDay(weekday, 1);
    }

    //Main loop : print days
    while(day<=daysInMonth){

      //Print the day
      printDayNumber(day, 2, ' ');
      
      //increment values
      day++;
      dayPosition++;
      weekday=changeWeekDay(weekday, 1);
      
      //add a space between days printed
      if(dayPosition<dayMaxToPrint){
        printf(" ");
      }
    }
      
    //Add spaces after the last day printed, to finish the line
    while(dayPosition<dayMaxToPrint){
      printf("  "); //an empty day number
      dayPosition++;
      weekday=changeWeekDay(weekday, 1);

      if(dayPosition<dayMaxToPrint){
        //add a space between day numbers
        printf(" ");
      }
    }
      
    //print the right columns
    printInfos(daysInMonth, month, year, 1, opts);
    
    //End the line
    printf("%s", endLine);
    
    if(opts[OPT_IDX_COMPACT]!=OPT_YES 
        && monthStart!=lastMonthToPrint && month!=lastMonthToPrint){
      //Print a line separator between months
      printf("%s", endLine);
    }
  }
}

//print a column (or vertical) calendar 
static void printVCal(int monthStart, int monthEnd, int year, char* opts){
  int month;
  int day, dayPrinted;
  int weekNumber;
  int firstWD=opts[OPT_IDX_FIRSTWD]-'0';
  int weekday, weekdayRow;
  int offset;
  int dayMaxToPrint,dayMaxMonth,  daysForPrintedMonth;
  int monthsToPrint=opts[OPT_IDX_NBCOL]-'A'; //nb of month to print
  int printedMonth;
  int lastMonthToPrint;
  int rowSize;  //for month printing
  
  //Check the WD columns in fixed mode.
  int checkFixedOpt, tmpCheck;
  checkFixedOpt=(opts[OPT_IDX_FIXED]==OPT_YES);
  tmpCheck=(opts[OPT_IDX_WD]==(OPT_BOTH-'a'+'A'));
  int checkBothFixedWD=(checkFixedOpt && tmpCheck);
  tmpCheck=(checkFixedOpt && opts[OPT_IDX_WD]==(OPT_LEFT-'a'+'A'));
  int checkFixedWDLeft=(checkBothFixedWD || tmpCheck);
  tmpCheck=(checkFixedOpt && opts[OPT_IDX_WD]==(OPT_RIGHT-'a'+'A'));
  int checkFixedWDRight=(checkBothFixedWD || tmpCheck);
  
  //Header : for multiples months, print the year in 1st line
  if(monthsToPrint>1){
    printf("%d:%s", year, endLine);
  }
  
  //Print all months
  for(month=monthStart; month<=monthEnd; month=month+monthsToPrint){
    day=1;
    
    //Check the last month to print
    if(month+monthsToPrint>DECEMBER){
      lastMonthToPrint=DECEMBER+1;
    }else{
      lastMonthToPrint=month+monthsToPrint;
    }
    
    //Check the number of days to print
    if(opts[OPT_IDX_FIXED]==OPT_YES){
      //Calculate the number of days to print 
      dayMaxToPrint=0;
      //Print all the months
      for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
        //Calculate the offset of the first Week
        offset=getOffsetMonth(1, printedMonth, year, opts);

        //If not a full week for the 1st week, add 1 week
        if(offset>0){
          dayMaxMonth=7;
        }else{
          dayMaxMonth=0;
        }
        //Add days of the months
        dayMaxMonth=dayMaxMonth+getDaysPerMonth(printedMonth, year, opts);
        //Remove the offset
        dayMaxMonth=dayMaxMonth-offset;
        
        if(dayMaxToPrint<dayMaxMonth){
          dayMaxToPrint=dayMaxMonth;
        }
      }
      weekdayRow=firstWD;
    }else if(monthsToPrint>1){
      dayMaxToPrint=31;
    }else{
      dayMaxToPrint=getDaysPerMonth(month, year, opts);
    }
    
    if(monthsToPrint>1){
      rowSize=2+getSizeHeader(opts);
    }else{
      rowSize=0;
    }
    
    
    //Print HEADER for subset months
    for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
      
      //header : Escape the weekday name
      if(monthsToPrint>1 && printedMonth==month && checkFixedWDLeft){
        printf("   ");
      }
      
      //HEADER : print Month(s)
      printMonthName(printedMonth, rowSize);
      if(monthsToPrint==1){
        //Print the year, next to the month (if not multiple months)
        printf(" %d:", year);
      }else{
        //escape months
        if(printedMonth<(lastMonthToPrint-1)){
          printf("  ");
        }
      }
      
      //header : Escape the weekday name
      if(printedMonth==(lastMonthToPrint-1) && checkFixedWDRight){
        printf("   ");
      }
    }
    //HEADER (months) : End the line
    printf("%s", endLine);

   
    //Print Headers for current month(s)
    for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
      
      if(printedMonth==month && checkFixedWDLeft){
        //force-print the weekday name
        printHeader(OPT_IDX_WD, -2, opts);
      }
      
      //Header : print left columns
      printHeaders(-1, opts);
      //HEADER : force-print the day number (centered)
      printHeader(OPT_IDX_DN, 0, opts);
      //HEADER : right columns
      printHeaders(1, opts);
      

      if(printedMonth==lastMonthToPrint-1){
        if(checkFixedWDRight){
          //force-print the weekday name
          printHeader(OPT_IDX_WD, 2, opts);
        }
      }else{
        if(monthsToPrint>1){
          //Print space between multiples  months
          printf("  ");
        }
      }
    }
    //HEADER : ENDline
    printf("%s", endLine);

    //Main loop : print days
    while(day<=dayMaxToPrint){
      
      if(checkFixedWDLeft){
        //print the day names (short : 2 characters) at left
        printWeekDayName(weekdayRow, 2);
        printf(" ");
      }
    
      //Do for each print month
      for(printedMonth=month; printedMonth<lastMonthToPrint; printedMonth++){
      
        //check the number of days for the printed month
        daysForPrintedMonth=getDaysPerMonth(printedMonth, year, opts);

        //check the correct day number to print
        if(opts[OPT_IDX_FIXED]==OPT_YES){
          //Subtract the daysOnset
          dayPrinted=day-getOffsetMonth(-1, printedMonth, year, opts);
        }else{
          dayPrinted=day;
        }
        
        //Check value of the dayPrinted
        if(dayPrinted<0 || dayPrinted>daysForPrintedMonth){
          dayPrinted=0;
        }
        
        // Calculate the 1st day of the printed month...
        weekday=getFirstWDMonth(printedMonth, year, opts);

        //Found the WeekDay by adding the number of days passed
        weekday=changeWeekDay(weekday, dayPrinted-1);
      
        //PRINT INFO (ON THE LEFT)
        if(dayPrinted>0 && (weekday==firstWD || (dayPrinted==1 && monthsToPrint==1))){
          //A new week : Print the week number
          printInfo(dayPrinted, printedMonth, year, -1, OPT_IDX_WKN, opts, 0);
        }else{
          //Not a new week, escape the week number (day=0)
          printInfo(0, printedMonth, year, -1, OPT_IDX_WKN, opts, 0);
        }
        printInfo(dayPrinted, printedMonth, year, -1, OPT_IDX_LEFT, opts, 0);
        printInfo(dayPrinted, printedMonth, year, -1, OPT_IDX_DOY, opts, 0);
        if(dayPrinted>0 && dayPrinted<=dayMaxToPrint){
          //Print Weekday name (before the Day number)
          printInfo(dayPrinted, printedMonth, year, -1, OPT_IDX_WD, opts, 2);
        }else{
          //Escape the weekday name
          printInfo(-1, printedMonth, year, -1, OPT_IDX_WD, opts, 2);
        }


        //Print the day number
        if(dayPrinted>0 && dayPrinted<=dayMaxToPrint){
          printDayNumber(dayPrinted, 2, ' ');
        }else{
          printf("  ");
        }
        
        //PRINT INFO (ON THE RIGHT)
        if(dayPrinted>0 && dayPrinted<=dayMaxToPrint){
          //Print the Weekday name (after the day number)
          printInfo(weekday, printedMonth, year, 1, OPT_IDX_WD, opts, 2);
        }else{
          //Escape the weekday name
          printInfo(-1, printedMonth, year, 1, OPT_IDX_WD, opts, 2);
        }
        if(dayPrinted>0 && weekday==firstWD){
          //A new week, print the number
          printInfo(dayPrinted, printedMonth, year, 1, OPT_IDX_WKN, opts, 0);
        }else{
          //Not a new week, escape the week number (day=0) -RIGHT column-
          printInfo(0, printedMonth, year, 1, OPT_IDX_WKN, opts, 0);
        }
        printInfo(dayPrinted, printedMonth, year, 1, OPT_IDX_LEFT, opts, 0);
        printInfo(dayPrinted, printedMonth, year, 1, OPT_IDX_DOY, opts, 0);
        

        if(printedMonth==lastMonthToPrint-1){
          if(checkFixedWDRight){
            //print the day names (short : 2 characters)
            printInfo(dayPrinted, printedMonth, year, 1, OPT_IDX_WD, opts, 2);
          }
        }else{
          if(monthsToPrint>1){
            //Escape the months
            printf("  ");
          }
        }
      }
      
      //Increment values
      day++;
      weekdayRow=changeWeekDay(weekdayRow, 1);

      if(day<=dayMaxToPrint){
        //End of the line
        printf("%s", endLine);
      }
    }
    
    //End the line
    printf("%s", endLine);
    
    if(printedMonth<=monthEnd){
      //Add another newline for multiples months
      printf("%s", endLine);
    }
  }
}

//print a cal 
static void printCal(int monthStart, int monthEnd, int year, char* opts){
  if(opts[OPT_IDX_VIEW]==OPT_VIEW_VERTICAL){
    printVCal(monthStart, monthEnd, year, opts);
  }else if(opts[OPT_IDX_VIEW]==OPT_VIEW_GRID){
    printGCal(monthStart, monthEnd, year, opts);
  }else if(opts[OPT_IDX_VIEW]==OPT_VIEW_LINEAR){
    printHCal(monthStart, monthEnd, year, opts);
  }
}

int main(int argc, char* argv[]){
  //program args
  char strArg[20];
  int argValue;
  int currentArg;
  char str[80];
  
  //Date values
  int year=-1;
  int month=-1;
  int day=-1;
  int monthStart;
  int monthEnd;
  
  //options
  char opts[13];
  //Default values :
  opts[OPT_IDX_WKN]=OPT_NONE;
  opts[OPT_IDX_DOY]=OPT_NONE;
  opts[OPT_IDX_LEFT]=OPT_NONE;
  opts[OPT_IDX_WD]=OPT_NONE;
  opts[OPT_IDX_VIEW]=OPT_VIEW_GRID;  //gridview
  opts[OPT_IDX_COMPACT]=OPT_NONE;    //no compact mode
  opts[OPT_IDX_DN]=OPT_NONE;         //not used
  opts[OPT_IDX_MONTH]=OPT_NONE;      //not used
  opts[OPT_IDX_FIRSTWD]=SUNDAY+'0';
  opts[OPT_IDX_LYD]=OPT_NONE;        //No print leapYear
  opts[OPT_IDX_LYC]=OPT_LYC_DEFAULT; //Default LeapYear calculation
  opts[OPT_IDX_NBCOL]=1+'A';         //1 column printed
  opts[OPT_IDX_FIXED]=OPT_NONE;      //no Fixed mode
  
  //Fetch the parameters
  currentArg=1;
  while(currentArg<argc){
    strncpy(strArg, argv[currentArg], 15);
    argValue=atoi(strArg);
    
    //Parameter is an integer (= day, month or year)
    if(argValue!=0){
      
      //Parameter : (YYYY) MM (DD) or (DD) MM (YYYY) 
     
      if(year>0){
        if(month>0){
          day=argValue;
        }else{
          month=argValue;
        }
      }else{
        if(argValue>31 || strlen(strArg)>2){
          //definitely a year !
          year=argValue;
          
          if(day>0 && month<1){
            //day and year, no month ? month=day value
            month=day;
            day=-1;
          }
        }else{
          if(day>0){
            month=argValue;
          }else{
            day=argValue;
          }
        }
      }
    }else{
      //construct the argument "WeekDay start"
      for(int weekday=0; weekday<7; weekday++){
        strcpy(str, "-start=");
        strcat(str, weekdays[weekday]);
        //check the argument
        if(strcmp(strArg,str)==0){
          opts[OPT_IDX_FIRSTWD]=weekday+'0';
        }
      }
      
      //construct arguments for printing headers left and right
      for(int hCol=0; hCol<OPTS_IDX_PRINTED; hCol++){
        for(int hPos=0; hPos<4; hPos++){
          strcpy(str, "-");
          strcat(str, headerStr[hCol]);
          if(hPos==0){
           strcat(str, "=left");
          }else if(hPos==1){
            strcat(str, "=right");
          }else if(hPos==2){
            strcat(str, "=both");
          }
          //check if it's the parameter
          if(strcmp(strArg,str)==0){
            if(hPos==0 || hPos==3){
              opts[hCol]=OPT_LEFT;
            }else if(hPos==1){
              opts[hCol]=OPT_RIGHT;
            }else if(opts[hCol]!=OPT_NONE || hPos==2) {
              opts[hCol]=OPT_BOTH;
            }
          }
        }
      }
      
      if(strcmp(strArg,"-view=v")==0){
        opts[OPT_IDX_VIEW]=OPT_VIEW_VERTICAL;
      }
      if(strcmp(strArg,"-view=g")==0){
        opts[OPT_IDX_VIEW]=OPT_VIEW_GRID;
      }
      if(strcmp(strArg,"-view=l")==0){
        opts[OPT_IDX_VIEW]=OPT_VIEW_LINEAR;
      }
      
      if(strcmp(strArg,"-compact")==0){
        opts[OPT_IDX_COMPACT]=OPT_YES;
      }
      if(strcmp(strArg,"-fixed")==0){
        opts[OPT_IDX_FIXED]=OPT_YES;
      }
      
      if(strcmp(strArg,"-leap=julian")==0){
        opts[OPT_IDX_LYC]=OPT_LYC_JULIAN;
      }
      if(strcmp(strArg,"-leap=gregorian")==0){
        opts[OPT_IDX_LYC]=OPT_LYC_GREGORIAN;
      }

      if(strcmp(strArg,"-LeapYear")==0){
        opts[OPT_IDX_LYD]=OPT_YES;
      }
      
      if(strcmp(strArg,"-col")==0){
        currentArg++;
        strncpy(strArg, argv[currentArg], 15);
        argValue=atoi(strArg);
        if(argValue!=0){
          if(argValue<0){
            //Set 1 month to print
            argValue=1;
          }else if(argValue>12){
            //Set all months to print
            argValue=12;
          }
          //Trick : use a character to indicate 1-12 value
          opts[OPT_IDX_NBCOL]=argValue+'A';
        }
      }
    }
    //Go to the next argument
    currentArg++;
  }
  
  //Only a 'day' ? it's the month
  if(day>=JANUARY && day<=DECEMBER+1 && month<0){
    month=day;
    day=-1;
  }
  
  if(day<1){
    
    //Remove the WD opts in grid mode (there are already printed)
    if(opts[OPT_IDX_VIEW]==OPT_VIEW_GRID){
      opts[OPT_IDX_WD]=OPT_NONE;
    }
    
    //Need to fix weekdays in linear-compact mode
    if(opts[OPT_IDX_VIEW]==OPT_VIEW_LINEAR && opts[OPT_IDX_COMPACT]==OPT_YES){
      opts[OPT_IDX_FIXED]=OPT_YES;
    }
    
    //Need to the WeekDay (Left) for vertical-fixed view
    if(opts[OPT_IDX_VIEW]==OPT_VIEW_VERTICAL && opts[OPT_IDX_FIXED]==OPT_YES){
      if(opts[OPT_IDX_WD]==OPT_NONE){
        opts[OPT_IDX_WD]=OPT_LEFT;
      }
      opts[OPT_IDX_WD]=opts[OPT_IDX_WD]-'a'+'A';
    }
  }
  
  //No year given : get the 
  if(year<0){
    time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    year=tm.tm_year+1900;

    if(month<1){
      //add the month if empty
      month=tm.tm_mon+1;
    }
  }
  
  //print all or only the month asked
  if(month<0){
    monthStart=JANUARY;
    monthEnd=DECEMBER;
  }else{
    //index start at 0, need subtract 1
    monthStart=month-1;
    monthEnd=month-1;
  }
  
  if(day>0 || (opts[OPT_IDX_LYD]==OPT_YES)){
    printDayInfos(day, monthStart, year, 0, opts);
  }else{
    printCal(monthStart, monthEnd, year, opts);
  }

  return 0;
}
