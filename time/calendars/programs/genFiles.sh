# script: genFiles.sh
# function: use and format the output of calendar program, to produce generic calendar texts
# Author: Cerbere Ace (cerbere.ace@gmail.com)
# License: [Unlicense](unlicense.txt)

#Const
calendarBin="./calendar.exe" #or "./calendar" for unix
typesOfYear=("Common" "Leap")
months=("January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December")
days=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")
startingDays=("Monday" "Sunday") #can include Saturday ???
# List of different calendars (depending of the 1st day of year)
# Common-Sunday to Common-Saturday + Common-Saturday-W53 + Leap-Sunday to Leap-Saturday
yearsList=(2006 2001 2002 2003 2009 2010 2011 2005 2012 2024 2008 2020 2004 2016 2000)
indexFile="index.txt"
yearsFile="years.txt"

#return the next/previous day
#$1 is the currentDay
#$2=1 to return the next day, $2=-1 to return the previous day
getDay() {
  dayArg="$1"
  direction="$2"
  dayIdx=0
  maxIdx=$((${#days[@]}-1))
  
  #Search the idx of the corresponding day 
  while [[ "${days[${dayIdx}]}" != "${dayArg}" ]]; do
    dayIdx=$((dayIdx + direction))
    #Check limits
    if [[ "${dayIdx}" -gt "${maxIdx}" ]]; then
      dayIdx=0
    else 
      if [[ "${dayIdx}" -lt 0 ]]; then
        dayIdx=$((maxIdx))
      fi
    fi
  done
  
  #Add/remove 1 day from the Idx found
  dayIdx=$((dayIdx+direction))
  #Check limit again
  if [[ "${dayIdx}" -gt "$maxIdx" ]]; then
    dayIdx=0
  else 
    if [[ "${dayIdx}" -lt 0 ]]; then
      dayIdx=$((maxIdx))
    fi
  fi
  
  #return the day found
  echo "${days[${dayIdx}]}"
}

#Complete the string ($1) with space at the end to correct the length ($2)
completeWithSpace() {
  aString="$1"
  size="$2"
  stringResult="${aString}"
  len=$((${#stringResult}))
  
  #Complete the string with trailing space
  for((c=len; c<size; c++)); do
    stringResult="${stringResult} "
  done
  
  echo "$stringResult"
}


doColumnMode(){
  startingDay="$1"
  doRegex="yes"
  doYAML="yes"

  #YEAR LOOP
  for year in "${yearsList[@]}"; do
  
    #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`

    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/columns/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      FolderDayName="${FolderDayName}-W53"
    fi
    
    #Create the day folder
    path="${path}/${FolderDayName,,}"

    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi
    
    #Add the title to the index file
    echo "" >> "${path}/${indexFile}"
    echo "## Calendars" >> "${path}/${indexFile}"
    echo "" >> "${path}/${indexFile}"
      
    #MONTH LOOP
    for((month=1; month<13; month++)); do 
    
      monthName="${months[${month}-1]}"
      #Add the month to the filename
      if (( month < 10 )); then
        newFile="${path}/m0${month}-${monthName,,}.txt"
      else
        newFile="${path}/m${month}-${monthName,,}.txt"
      fi
      #Get the filename (used to link to the file)
      filename="${newFile##*/}"
      
      #Continue only if the file doesn't exist
      if [[ ! -e "${newFile}" ]]; then
      
        if [[ -e "${path}/${indexFile}" ]]; then
          # Add the month to the index file
          echo "[${monthName}](./${filename})" >> "${path}/${indexFile}"
        fi
      
        #call the program, write the result to a file
        $calendarBin "${month}" "${year}" "-view=v" "-start=${startingDay}" "-WkN=left" "-WD" > "${newFile}"
        
        #######################################################################
        ##REGEX 
        if [[ "${doRegex}" == "yes" ]]; then
          
          addSpacesMonth=""
          for((i=${#monthName}; i<9; i++)); do
            addSpacesMonth="${addSpacesMonth} "
          done

          #LINES with no week number
          regexPattern="^(   ) (..) (..)"
          regexReplace="|   +--+------+\n|\1|\2|\3    |"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
          
          #LINES with a week number : add a separator BEFORE the week number
          regexPattern="^(W[0-9][0-9]) (..) (..)"
          regexReplace="+---+--+------+\n|\1|\2|\3    |"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"

          #SUB-HEADER
          regexPattern="^(W[^0-9 ][^0-9 ]) (..) (..)"
          regexReplace="|\1|\2|\3    |"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"

          #replace the 1st line separator for the sub-header
          regexPattern="^\+---\+--\+------\+"
          regexReplace="+===+==+======+"
          sed "-i" "-E" "-e" "0,/${regexPattern}/{s/${regexPattern}/${regexReplace}/}" "${newFile}"
          
          #YEAR HEADER
          regexPattern="^${monthName} [^\n]*"
          regexReplace="+---+---------+\n"
          regexReplace="${regexReplace}|   |${monthName}${addSpacesMonth}|\n"
          regexReplace="${regexReplace}+---+--+------+"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"

          #Add the end of the table manually...
          echo "+---+--+------+" >>"${newFile}"
        fi
        
        #######################################################################
        ##YAML 
        if [[ "${doYAML}" == "yes" ]]; then
        
          #YAML : Add current section to the file
          echo "" >> "${newFile}"
          echo "---" >> "${newFile}"
          echo "current:" >> "${newFile}"
          echo "  month: ${monthName}" >> "${newFile}"
          echo "  year: " >> "${newFile}"
          echo "    starting: ${dayName}" >> "${newFile}"
          echo "    type: ${typeOfYear}" >> "${newFile}"
          echo "    index: <./${indexFile}>" >> "${newFile}"
          echo "  file: <./${filename}>" >> "${newFile}"
          echo "    license: public domain" >> "${newFile}"

          #YAML : Add the "previous" section to the CURRENT file
          echo "previous:" >> "${newFile}"
          if (( "${month}" > 1 )); then
            #Set for previous month in the current year
            previousMonth=$((${month}-1))
            previousMonthName="${months[${previousMonth}-1]}"
            if (( previousMonth < 10 )); then
              previousFileName="./m0${previousMonth}-${previousMonthName,,}.txt"
            else
              previousFileName="./m${previousMonth}-${previousMonthName,,}.txt"
            fi
            echo "  month: ${previousMonthName}" >> "${newFile}"
            echo "  file: <${previousFileName}>" >> "${newFile}"
          else
            #Set for December in the previous year
            previousMonthName="${months[11]}"
            previousFileName="m12-${previousMonthName,,}.txt"
            #Get 1st day of previous year, common (-1d) and leap (-2d)
            previousDayNameCommon=`getDay "${dayName}" "-1"`
            previousDayNameLeap=`getDay "${previousDayNameCommon}" "-1"`
            echo "  month: ${previousMonthName}" >> "${newFile}"
            echo "  year: " >> "${newFile}"
            #Check if current year is common or not
            if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
              #Saturday+W53 is an exception (a Common year AFTER a leap year)
              if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
                #(NO list) Link to the previous Leap year
                leapDay="${previousDayNameLeap}"
                switchTypeOfYear="${typesOfYear[1]}"
                relativePathFile="../../${switchTypeOfYear,,}/${leapDay,,}/${previousFileName}"
                echo "    type: ${typesOfYear[1]}" >> "${newFile}"
                echo "    starting: ${leapDay}" >> "${newFile}"
                echo "    file: <${relativePathFile}>" >> "${newFile}"
              else
                #(list) Link to the previous Common year (current year: Common)
                commonDay="${previousDayNameCommon}"
                switchTypeOfYear="${typesOfYear[0]}"
                relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${previousFileName}"
                echo "    - type: ${typesOfYear[0]}" >> "${newFile}"
                echo "      starting: ${commonDay}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
                #(list) Link to the previous Leap year (current year: Common)
                leapDay="${previousDayNameLeap}"
                switchTypeOfYear="${typesOfYear[1]}"
                relativePathFile="../../${switchTypeOfYear,,}/${leapDay,,}/${previousFileName}"
                echo "    - type: ${typesOfYear[1]}" >> "${newFile}"
                echo "      starting: ${leapDay}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
              fi
            else
              #(No list) Link to the previous common year only (current year: leap)
              commonDay="${previousDayNameCommon}"
              switchTypeOfYear="${typesOfYear[0]}"
              relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${previousFileName}"
              echo "    type: ${typesOfYear[0]}" >> "${newFile}"
              echo "    starting: ${commonDay}" >> "${newFile}"
              echo "    file: <${relativePathFile}>" >> "${newFile}"
            fi
          fi
          
          #YAML : Add "next" section to the CURRENT file
          echo "next:" >> "${newFile}"
          if (( "${month}" < 12 )); then
            nextMonth=$((${month}+1))
            nextMonthName="${months[${nextMonth}-1]}"
            if (( nextMonth < 10 )); then
              nextFileName="./m0${nextMonth}-${nextMonthName,,}.txt"
            else
              nextFileName="./m${nextMonth}-${nextMonthName,,}.txt"
            fi
            echo "  month: ${nextMonthName}" >> "${newFile}"
            echo "  file: <${nextFileName}>" >> "${newFile}"
          else
            nextMonthName="${months[0]}"
            nextFileName="m01-${nextMonthName,,}.txt"
            echo "  month: ${nextMonthName}" >> "${newFile}"
            echo "  year: " >> "${newFile}"
            nextDayName=`getDay "${dayName}" "1"`
            #Check the current type of the year
            if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
              echo "    starting: ${nextDayName}" >> "${newFile}"
              if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
                #(NO list) link to the next common year (as leap was previous)
                switchTypeOfYear="${typesOfYear[0]}"
                relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
                echo "    type: ${switchTypeOfYear}" >> "${newFile}"
                echo "    file: <${relativePathFile}>" >> "${newFile}"
              else
                #(list) link to next common year (current year: Common)
                switchTypeOfYear="${typesOfYear[0]}"
                relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
                echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
                #(list) link to next leap year (current year: Common)
                switchTypeOfYear="${typesOfYear[1]}"
                relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
                echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
              fi
            else
              #link to the next Common year ONLY (current year: Leap)
              nextDayName=`getDay "${nextDayName}" "1"`
              #Saturday+W53 is an exception (a Common year AFTER a leap year)
              if [[ "${nextDayName}" == "Saturday" ]]; then
                #Check the week number 
                nextYear=$((year+1))
                nextWeekNumber=`$calendarBin 1 1 "${nextYear}" "-start=${startingDay}" -WkN`
                #if week number is W53 (and current day Saturday) : add W53 to the name
                if [[ "${nextWeekNumber}" == "W53" ]]; then
                  nextDayName="${nextDayName}-W53"
                fi
              fi
              switchTypeOfYear="${typesOfYear[0]}"
              relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
              echo "    starting: ${nextDayName}" >> "${newFile}"
              echo "    type: ${switchTypeOfYear}" >> "${newFile}"
              echo "    file: <${relativePathFile}>" >> "${newFile}"
            fi
          fi
          
          #End of YAML section
          echo "..." >> "${newFile}"
        fi
      fi
    done
  done
}

doGridMode(){
  startingDay="$1"
  doRegex="yes"
  doYAML="yes"

  #YEAR LOOP
  for year in "${yearsList[@]}"; do
  
    #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`

    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/grid/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      FolderDayName="${FolderDayName}-W53"
    fi
    
    #Create the weekday folder
    path="${path}/${FolderDayName,,}"

    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi

    #Add the title to the index file
    echo "" >> "${path}/${indexFile}"
    echo "## Calendars" >> "${path}/${indexFile}"
    echo "" >> "${path}/${indexFile}"

    #MONTH LOOP
    for (( month=1; month<13; month++ )); do 
    
      monthName="${months[${month}-1]}"
      #Add the month to the filename
      if (( month < 10 )); then
        newFile="${path}/m0${month}-${monthName,,}.txt"
      else
        newFile="${path}/m${month}-${monthName,,}.txt"
      fi
      #Get the filename (used to link to the file)
      filename="${newFile##*/}"

      #Continue if file doesn't exist
      if [[ ! -f "${newFile}" ]]; then

        if [[ -e "${path}/${indexFile}" ]]; then
          # Add the month to the index file
          echo "[${monthName}](./${filename})" >> "${path}/${indexFile}"
        fi

        #call the program, write the result to a file
        $calendarBin "${month}" "${year}" "-view=g" "-start=${startingDay}" "-WkN=left" "-WD" > "${newFile}"
        
        #######################################################################
        ##REGEX
        if [[ "${doRegex}" == "yes" ]]; then
          #Add space to the month names
          addSpacesMonth=""
          for((i=${#monthName}; i<9; i++)); do
            addSpacesMonth="${addSpacesMonth} "
          done
          
          #YEAR HEADER (1st line)
          regexPattern="^${monthName} [^\n]*"
          regexReplace="+---+--------------------+\n"
          regexReplace="${regexReplace}|   |${monthName}${addSpacesMonth}           |\n"
          regexReplace="${regexReplace}+---+--+--+--+--+--+--+--+"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
          
          #SUB-HEADER
          regexPattern="^(W[^0-9][^0-9]) (..) (..) (..) (..) (..) (..) (..)"
          regexReplace="|\1|\2|\3|\4|\5|\6|\7|\8|\n"
          regexReplace="${regexReplace}+===+==+==+==+==+==+==+==+"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
          
          #LINES
          regexPattern="^(W[0-9][0-9]) (..) (..) (..) (..) (..) (..) (..)"
          regexReplace="|\1|\2|\3|\4|\5|\6|\7|\8|\n"
          regexReplace="${regexReplace}+---+--+--+--+--+--+--+--+"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        fi
        
        #######################################################################
        ##YAML 
        if [[ "${doYAML}" == "yes" ]]; then
        
          #YAML : Add current section to the file
          echo "" >> "${newFile}"
          echo "---" >> "${newFile}"
          echo "current:" >> "${newFile}"
          echo "  month: ${monthName}" >> "${newFile}"
          echo "  year: " >> "${newFile}"
          echo "    starting: ${dayName}" >> "${newFile}"
          echo "    type: ${typeOfYear}" >> "${newFile}"
          echo "    index: <./${indexFile}>" >> "${newFile}"
          echo "  file: <./${filename}>" >> "${newFile}"
          echo "    license: public domain" >> "${newFile}"

          #YAML : Add the "previous" section to the CURRENT file
          echo "previous:" >> "${newFile}"
          if (( "${month}" > 1 )); then
            #Set for previous month in the current year
            previousMonth=$((${month}-1))
            previousMonthName="${months[${previousMonth}-1]}"
            if (( previousMonth < 10 )); then
              previousFileName="./m0${previousMonth}-${previousMonthName,,}.txt"
            else
              previousFileName="./m${previousMonth}-${previousMonthName,,}.txt"
            fi
            echo "  month: ${previousMonthName}" >> "${newFile}"
            echo "  file: <${previousFileName}>" >> "${newFile}"
          else
            #Set for December in the previous year
            previousMonthName="${months[11]}"
            previousFileName="m12-${previousMonthName,,}.txt"
            #Get 1st day of previous year, common (-1d) and leap (-2d)
            previousDayNameCommon=`getDay "${dayName}" "-1"`
            previousDayNameLeap=`getDay "${previousDayNameCommon}" "-1"`
            echo "  month: ${previousMonthName}" >> "${newFile}"
            echo "  year: " >> "${newFile}"
            #Check if current year is common or not
            if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
              #Saturday+W53 is an exception (a Common year AFTER a leap year)
              if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
                #(NO list) Link to the previous Leap year
                leapDay="${previousDayNameLeap}"
                switchTypeOfYear="${typesOfYear[1]}"
                relativePathFile="../../${switchTypeOfYear,,}/${leapDay,,}/${previousFileName}"
                echo "    type: ${typesOfYear[1]}" >> "${newFile}"
                echo "    starting: ${leapDay}" >> "${newFile}"
                echo "    file: <${relativePathFile}>" >> "${newFile}"
              else
                #(list) Link to the previous Common year (current year: Common)
                commonDay="${previousDayNameCommon}"
                switchTypeOfYear="${typesOfYear[0]}"
                relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${previousFileName}"
                echo "    - type: ${typesOfYear[0]}" >> "${newFile}"
                echo "      starting: ${commonDay}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
                #(list) Link to the previous Leap year (current year: Common)
                leapDay="${previousDayNameLeap}"
                switchTypeOfYear="${typesOfYear[1]}"
                relativePathFile="../../${switchTypeOfYear,,}/${leapDay,,}/${previousFileName}"
                echo "    - type: ${typesOfYear[1]}" >> "${newFile}"
                echo "      starting: ${leapDay}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
              fi
            else
              #(No list) Link to the previous common year only (current year: leap)
              commonDay="${previousDayNameCommon}"
              switchTypeOfYear="${typesOfYear[0]}"
              relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${previousFileName}"
              echo "    type: ${typesOfYear[0]}" >> "${newFile}"
              echo "    starting: ${commonDay}" >> "${newFile}"
              echo "    file: <${relativePathFile}>" >> "${newFile}"
            fi
          fi
          
          #YAML : Add "next" section to the CURRENT file
          echo "next:" >> "${newFile}"
          if (( "${month}" < 12 )); then
            nextMonth=$((${month}+1))
            nextMonthName="${months[${nextMonth}-1]}"
            if (( nextMonth < 10 )); then
              nextFileName="./m0${nextMonth}-${nextMonthName,,}.txt"
            else
              nextFileName="./m${nextMonth}-${nextMonthName,,}.txt"
            fi
            echo "  month: ${nextMonthName}" >> "${newFile}"
            echo "  file: <${nextFileName}>" >> "${newFile}"
          else
            nextMonthName="${months[0]}"
            nextFileName="m01-${nextMonthName,,}.txt"
            echo "  month: ${nextMonthName}" >> "${newFile}"
            echo "  year: " >> "${newFile}"
            nextDayName=`getDay "${dayName}" "1"`
            #Check the current type of the year
            if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
              echo "    starting: ${nextDayName}" >> "${newFile}"
              if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
                #(NO list) link to the next common year (as leap was previous)
                switchTypeOfYear="${typesOfYear[0]}"
                relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
                echo "    type: ${switchTypeOfYear}" >> "${newFile}"
                echo "    file: <${relativePathFile}>" >> "${newFile}"
              else
                #(list) link to next common year (current year: Common)
                switchTypeOfYear="${typesOfYear[0]}"
                relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
                echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
                #(list) link to next leap year (current year: Common)
                switchTypeOfYear="${typesOfYear[1]}"
                relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
                echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
                echo "      file: <${relativePathFile}>" >> "${newFile}"
              fi
            else
              #link to the next Common year ONLY (current year: Leap)
              nextDayName=`getDay "${nextDayName}" "1"`
              #Saturday+W53 is an exception (a Common year AFTER a leap year)
              if [[ "${nextDayName}" == "Saturday" ]]; then
                #Check the week number 
                nextYear=$((year+1))
                nextWeekNumber=`$calendarBin 1 1 "${nextYear}" "-start=${startingDay}" -WkN`
                #if week number is W53 (and current day Saturday) : add W53 to the name
                if [[ "${nextWeekNumber}" == "W53" ]]; then
                  nextDayName="${nextDayName}-W53"
                fi
              fi
              switchTypeOfYear="${typesOfYear[0]}"
              relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${nextFileName}"
              echo "    starting: ${nextDayName}" >> "${newFile}"
              echo "    type: ${switchTypeOfYear}" >> "${newFile}"
              echo "    file: <${relativePathFile}>" >> "${newFile}"
            fi
          fi
          
          #End of YAML section
          echo "..." >> "${newFile}"
          
        fi
      fi
    done
  done
}

doContinousView(){
  startingDay="$1"
  doRegex="yes"
  doYAML="yes"
  
  #YEAR LOOP
  for year in "${yearsList[@]}"; do
  
      #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`

    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/grid/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      FolderDayName="${FolderDayName}-W53"
    fi
    
    #Create the weekday folder
    path="${path}/${FolderDayName,,}"

    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi
  
    #Add the month to the filename
    newFile="${path}/continuous.txt"
      
    #Get the filename (used to link to the file)
    filename="${newFile##*/}"

    #Continue if file doesn't exist
    if [[ ! -f "${newFile}" ]]; then

      #Add the file to index
      if [[ -e "${path}/${indexFile}" ]]; then
        echo "" >> "${path}/${indexFile}"
        echo "[Continuous](./${filename})" >> "${path}/${indexFile}"
      fi

      $calendarBin "${year}" "-view=g" "-start=${startingDay}" "-WkN=left" "-compact" > "${newFile}"

      if [[ "${doRegex}" == "yes" ]]; then
        
        #LINES with same month
        regexPattern="^(   ) (W[0-9][0-9]) (..) (..) (..) (..) (..) (..) (..)"
        regexReplace="+   +---+--+--+--+--+--+--+--+\n"
        regexReplace="${regexReplace}|\1|\2|\3|\4|\5|\6|\7|\8|\9|"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        
        #LINES with new month
        regexPattern="^(...) (W[0-9][0-9]) (..) (..) (..) (..) (..) (..) (..)"
        regexReplace="+---+---+--+--+--+--+--+--+--+\n"
        regexReplace="${regexReplace}|\1|\2|\3|\4|\5|\6|\7|\8|\9|"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        
        #replace the 1st line separator for the sub-header
        regexPattern="^\+---\+---\+--\+--\+--\+--\+--\+--\+--\+"
        regexReplace="+===+===+==+==+==+==+==+==+==+"
        sed "-i" "-E" "-e" "0,/${regexPattern}/{s/${regexPattern}/${regexReplace}/}" "${newFile}"
        
        #replace the year with table border
        regexPattern="^.*${year}:"
        regexReplace="+---+---+--+--+--+--+--+--+--+"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        
        #Sub
        regexPattern="^(...) (W[^0-9][^0-9]) (..) (..) (..) (..) (..) (..) (..)"
        regexReplace="|\1|\2|\3|\4|\5|\6|\7|\8|\9|"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"

        #Add the end of the table manually...
        echo "+---+---+--+--+--+--+--+--+--+" >>"${newFile}"

      fi

      #######################################################################
      ##YAML 
      if [[ "${doYAML}" == "yes" ]]; then

        #YAML : Add current section to the file
        echo "" >> "${newFile}"
        echo "---" >> "${newFile}"
        echo "current:" >> "${newFile}"
        echo "  year: " >> "${newFile}"
        echo "    starting: ${dayName}" >> "${newFile}"
        echo "    type: ${typeOfYear}" >> "${newFile}"
        echo "    index: <./${indexFile}>" >> "${newFile}"
        echo "  file: <./${filename}>" >> "${newFile}"
        echo "    license: public domain" >> "${newFile}"

        #YAML : Add the "previous" section to the CURRENT file
        echo "previous:" >> "${newFile}"

        previousDayNameCommon=`getDay "${dayName}" "-1"`
        previousDayNameLeap=`getDay "${previousDayNameCommon}" "-1"`

        echo "  year: " >> "${newFile}"
        #Check if current year is common or not
        if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
          #Saturday+W53 is an exception (a Common year AFTER a leap year)
          if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
            #(NO list) Link to the previous Leap year
            commonDay="${previousDayNameCommon}"
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${filename}"
            echo "    type: ${typesOfYear[0]}" >> "${newFile}"
            echo "    starting: ${commonDay}" >> "${newFile}"
            echo "    file: <${relativePathFile}>" >> "${newFile}"
          else
            #(list) Link to the previous Common year (current year: Common)
            commonDay="${previousDayNameCommon}"
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${filename}"
            echo "    - type: ${typesOfYear[0]}" >> "${newFile}"
            echo "      starting: ${commonDay}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
            #(list) Link to the previous Leap year (current year: Common)
            leapDay="${previousDayNameLeap}"
            switchTypeOfYear="${typesOfYear[1]}"
            relativePathFile="../../${switchTypeOfYear,,}/${leapDay,,}/${filename}"
            echo "    - type: ${typesOfYear[1]}" >> "${newFile}"
            echo "      starting: ${leapDay}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
          fi
        else
          #a Leap year : Link to the next common year only
          commonDay="${previousDayNameCommon}"
          switchTypeOfYear="${typesOfYear[0]}"
          relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${filename}"
          echo "    type: ${typesOfYear[0]}" >> "${newFile}"
          echo "    starting: ${commonDay}" >> "${newFile}"
          echo "    file: <${relativePathFile}>" >> "${newFile}"
        fi

        #Get the next dayname
        nextDayName=`getDay "${dayName}" "1"`

        #If current year is leap, add +1day
        if [[ "${typeOfYear}" == "${typesOfYear[1]}" ]]; then
          nextDayName=`getDay "${nextDayName}" "1"`
          #Saturday+W53 is an exception (a Common year AFTER a leap year)
          if [[ "${nextDayName}" == "Saturday" ]]; then
            #Check the week number 
            nextYear=$((year+1))
            nextWeekNumber=`$calendarBin 1 1 "${nextYear}" "-start=${startingDay}" -WkN`
            #if week number is W53 (and current day Saturday) : add W53 to the name
            if [[ "${nextWeekNumber}" == "W53" ]]; then
              nextDayName="${nextDayName}-W53"
            fi
          fi
        fi

        echo "next:" >> "${newFile}"
        echo "  year: " >> "${newFile}"
        echo "    starting: ${nextDayName}" >> "${newFile}"
        #Check if the previous year is common or not
        if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
          #Saturday+W53 is an exception (a Common year AFTER a leap year)
          if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
            #(NO list) Link to the next common year
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
            echo "    type: ${switchTypeOfYear}" >> "${newFile}"
            echo "    file: <${relativePathFile}>" >> "${newFile}"
          else
            #(list) link to next common year for a Common year
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
            echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
            #(list) link to next leap year for a Common year
            switchTypeOfYear="${typesOfYear[1]}"
            relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
            echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
          fi
        else
          #(No list) Link to the previous common year only (current year: leap)
          switchTypeOfYear="${typesOfYear[0]}"
          relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
          echo "    type: ${switchTypeOfYear}" >> "${newFile}"
          echo "    file: <${relativePathFile}>" >> "${newFile}"
        fi

        #End of YAML section
        echo "..." >> "${newFile}"

      fi
    fi
  done
}

doMultipleView(){
  startingDay="$1"
  doRegex="yes"
  doYAML="yes"
  
  
  #YEAR LOOP
  for year in "${yearsList[@]}"; do
  
    #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`

    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/grid/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      FolderDayName="${FolderDayName}-W53"
    fi
    
    #Create the weekday folder
    path="${path}/${FolderDayName,,}"

    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi
  
    #Add the month to the filename
    newFile="${path}/all-months.txt"
      
    #Get the filename (used to link to the file)
    filename="${newFile##*/}"

    #Continue if file doesn't exist
    if [[ ! -f "${newFile}" ]]; then
  
      #Add the file to index
      if [[ -e "${path}/${indexFile}" ]]; then
        echo "" >> "${path}/${indexFile}"
        echo "[All months](./${filename})" >> "${path}/${indexFile}"
      fi
  
      $calendarBin "${year}" "-view=g" "-start=${startingDay}" "-WkN=left" "-col" "3" > "${newFile}"
      
      if [[ "${doRegex}" == "yes" ]]; then

        #Add the line separator
        regexPattern="^([W ][0-9 ][0-9 ] .*)"
        regexReplace="\1\n"
        regexReplace="${regexReplace}+---+--+--+--+--+--+--+--+"
        regexReplace="${regexReplace} +---+--+--+--+--+--+--+--+"
        regexReplace="${regexReplace} +---+--+--+--+--+--+--+--+"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        
        # HEADER
        regexPattern="^(W[^0-9 ][^0-9 ] .*)"
        regexReplace="\1\n"
        regexReplace="${regexReplace}+===+==+==+==+==+==+==+==+"
        regexReplace="${regexReplace} +===+==+==+==+==+==+==+==+"
        regexReplace="${regexReplace} +===+==+==+==+==+==+==+==+"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"

        for((i=0; i<4; i++)); do
          #Correct the header 
          regexPattern="(W[^0-9 ][^0-9 ]) (..) (..) (..) (..) (..) (..) (..)"
          regexReplace="|\1|\2|\3|\4|\5|\6|\7|\8|"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
          
          #Change the lines
          regexPattern="([W ][0-9 ][0-9 ]) ([0-9 ][0-9 ]) ([0-9 ][0-9 ]) ([0-9 ][0-9 ]) ([0-9 ][0-9 ]) ([0-9 ][0-9 ]) ([0-9 ][0-9 ]) ([0-9 ][0-9 ])"
          regexReplace="|\1|\2|\3|\4|\5|\6|\7|\8|"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        done

        #replace the year with table border
        regexPattern="${year}:"
        regexReplace="+---+--------------------+"
        regexReplace="${regexReplace} +---+--------------------+"
        regexReplace="${regexReplace} +---+--------------------+"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"

        for((row=0; row<12; row=row+3)); do
          regexPattern="${months[$row]} *${months[$row+1]} *${months[$row+2]} *"
          spacedFirstMonth=`completeWithSpace "${months[$row]}" "20"`
          spacedSecondMonth=`completeWithSpace "${months[$row+1]}" "20"`
          spacedThirdMonth=`completeWithSpace "${months[$row+2]}" "20"`
          
          if(( row > 0 )); then
            #not the 1st months : add a (top) table border
            regexReplace="+---+--------------------+"
            regexReplace="${regexReplace} +---+--------------------+"
            regexReplace="${regexReplace} +---+--------------------+\n"
          else
            #1st months have top-border from previous regex
            regexReplace=""
          fi
          
          regexReplace="${regexReplace}|   |${spacedFirstMonth}| "
          regexReplace="${regexReplace}|   |${spacedSecondMonth}| "
          regexReplace="${regexReplace}|   |${spacedThirdMonth}|\n"
          regexReplace="${regexReplace}+---+--+--+--+--+--+--+--+"
          regexReplace="${regexReplace} +---+--+--+--+--+--+--+--+"
          regexReplace="${regexReplace} +---+--+--+--+--+--+--+--+"
          sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        done
        
        #Correct the columns space, between months
        regexPattern="\|\|"
        regexReplace="| |"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        regexPattern="\|  *\|W"
        regexReplace="| |W"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
        regexPattern="\| *$"
        regexReplace="|"
        sed "-i" "-E" "-e" "s/${regexPattern}/${regexReplace}/gm" "${newFile}"
       
      fi
        
      #######################################################################
      ##YAML 
      if [[ "${doYAML}" == "yes" ]]; then
        
        #YAML : Add current section to the file
        echo "" >> "${newFile}"
        echo "---" >> "${newFile}"
        echo "current:" >> "${newFile}"
        echo "  year: " >> "${newFile}"
        echo "    starting: ${dayName}" >> "${newFile}"
        echo "    type: ${typeOfYear}" >> "${newFile}"
        echo "    index: <./${indexFile}>" >> "${newFile}"
        echo "  file: <./${filename}>" >> "${newFile}"
        echo "    license: public domain" >> "${newFile}"

        #YAML : Add the "previous" section to the CURRENT file
        echo "previous:" >> "${newFile}"

        previousDayNameCommon=`getDay "${dayName}" "-1"`
        previousDayNameLeap=`getDay "${previousDayNameCommon}" "-1"`

        echo "  year: " >> "${newFile}"
        #Check if current year is common or not
        if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
          #Saturday+W53 is an exception (a Common year AFTER a leap year)
          if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
            #(NO list) Link to the previous Leap year
            commonDay="${previousDayNameCommon}"
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${filename}"
            echo "    - type: ${typesOfYear[0]}" >> "${newFile}"
            echo "      starting: ${commonDay}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
          else
            #(list) Link to the previous Common year (current year: Common)
            commonDay="${previousDayNameCommon}"
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${filename}"
            echo "    - type: ${typesOfYear[0]}" >> "${newFile}"
            echo "      starting: ${commonDay}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
            #(list) Link to the previous Leap year (current year: Common)
            leapDay="${previousDayNameLeap}"
            switchTypeOfYear="${typesOfYear[1]}"
            relativePathFile="../../${switchTypeOfYear,,}/${leapDay,,}/${filename}"
            echo "    - type: ${typesOfYear[1]}" >> "${newFile}"
            echo "      starting: ${leapDay}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
          fi
        else
          #(No list) Link to the previous common year only (current year: leap)
          commonDay="${previousDayNameCommon}"
          switchTypeOfYear="${typesOfYear[0]}"
          relativePathFile="../../${switchTypeOfYear,,}/${commonDay,,}/${filename}"
          echo "    type: ${typesOfYear[0]}" >> "${newFile}"
          echo "    starting: ${commonDay}" >> "${newFile}"
          echo "    file: <${relativePathFile}>" >> "${newFile}"
        fi
        
        #Get the next dayname
        nextDayName=`getDay "${dayName}" "1"`
        
        #If current year is leap, add +1day
        if [[ "${typeOfYear}" == "${typesOfYear[1]}" ]]; then
          nextDayName=`getDay "${nextDayName}" "1"`
          #Saturday+W53 is an exception (a Common year AFTER a leap year)
          if [[ "${nextDayName}" == "Saturday" ]]; then
            #Check the week number 
            nextYear=$((year+1))
            nextWeekNumber=`$calendarBin 1 1 "${nextYear}" "-start=${startingDay}" -WkN`
            #if week number is W53 (and current day Saturday) : add W53 to the name
            if [[ "${nextWeekNumber}" == "W53" ]]; then
              nextDayName="${nextDayName}-W53"
            fi
          fi
        fi
        
        echo "next:" >> "${newFile}"
        echo "  year: " >> "${newFile}"
        echo "    starting: ${nextDayName}" >> "${newFile}"
        #Check if the previous year is common or not
        if [[ "${typeOfYear}" == "${typesOfYear[0]}" ]]; then
          #Saturday+W53 is an exception (a Common year AFTER a leap year)
          if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
            #(NO list) Link to the next common year
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
            echo "    type: ${switchTypeOfYear}" >> "${newFile}"
            echo "    file: <${relativePathFile}>" >> "${newFile}"
          else
            #(list) Link to the next common year
            switchTypeOfYear="${typesOfYear[0]}"
            relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
            echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
            #(list) link to next leap year for a Common year
            switchTypeOfYear="${typesOfYear[1]}"
            relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
            echo "    - type: ${switchTypeOfYear}" >> "${newFile}"
            echo "      file: <${relativePathFile}>" >> "${newFile}"
          fi
        else
          #a Leap year : link to the next Common year only
          switchTypeOfYear="${typesOfYear[0]}"
          relativePathFile="../../${switchTypeOfYear,,}/${nextDayName,,}/${filename}"
          echo "    type: ${switchTypeOfYear}" >> "${newFile}"
          echo "    file: <${relativePathFile}>" >> "${newFile}"
        fi

        #End of YAML section
        echo "..." >> "${newFile}"
      fi
    fi
  done
}

createIndexFile(){
  startingDay="$1"
  currentMode="$2"

  for year in "${yearsList[@]}"; do

    #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`

    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/${currentMode}/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      dayName="${dayName}-W53"
    fi
    
    #Create the weekday folder
    path="${path}/${dayName,,}"
    
    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi

    #Create the Index file
    echo "${typeOfYear} years starting ${dayName}" > "${path}/${indexFile}"
  done
}

doPrintYears(){
  startingDay="$1"
  currentMode="$2"
  startYear="$3"
  endYear="$4"
  
  #Create the path
  path="${startingDay,,}/${currentMode}"

  #Create folders if needed
  if [ ! -d "${path}" ]; then
    mkdir -p "${path}"
  fi

  # Create an index with all years
  echo "| Year | Type | 1st January |" > "${path}/${indexFile}"
  echo "| ---- | ---- | ----------- |" >> "${path}/${indexFile}"


 #Create a list of year
 for year in "${yearsList[@]}"; do

    #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`

    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/${currentMode}/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      dayName="${dayName}-W53"
    fi
    
    #Create the weekday folder
    path="${path}/${dayName,,}"
    
    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi

    #Create a YEARS list
    echo "| ${typeOfYear} years starting ${dayName} |" > "${path}/${yearsFile}"
    echo "| --- |" >> "${path}/${yearsFile}"
    
    #Add line to the indexfile
    echo "" >> "${path}/${indexFile}"
    echo "## Years" >> "${path}/${indexFile}"
    echo "" >> "${path}/${indexFile}"
    echo "[List of years](./${yearsFile})" >> "${path}/${indexFile}"
  done

  #YEAR LOOP
  for((year=startYear; year<endYear+1; year++)); do
  
    #Get information from the year
    isLeap=`$calendarBin 1 "${year}" "-start=${startingDay}" -LeapYear`
    weekNumber=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WkN`
    dayName=`$calendarBin 1 1 "${year}" "-start=${startingDay}" -WD`
    
    #Get the type of the year (common or leap)
    typeOfYear="${typesOfYear[${isLeap}]}"
    #Create the path
    path="${startingDay,,}/${currentMode}/${typeOfYear,,}"
    
    #Saturday+W53 is an exception
    FolderDayName="${dayName}"
    if [[ "${weekNumber}" == "W53" && "${dayName}" == "Saturday" ]]; then
      dayName="${dayName}-W53"
    fi
    
    #Create the weekday folder
    path="${path}/${dayName,,}"

    #Create folders if needed
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
    fi

    # Add the year to the Year list
    echo "| ${year} | ${typeOfYear} | [${dayName}](./${typeOfYear,,}/${dayName,,}/${indexFile}) |" >> "${startingDay,,}/${currentMode}/${indexFile}"
    
    #Add this year to the weekday-year file
    echo "| ${year} |" >> "${path}/${yearsFile}"
  done
  
}

for weekDay in "${startingDays[@]}"; do
    echo "Creating Grid files, for ${weekDay} folder"
    createIndexFile "${weekDay}" "grid"
    doGridMode "${weekDay}" 
    doContinousView "${weekDay}"
    doMultipleView "${weekDay}"

    echo "Creating Columns files, for ${weekDay} folder"
    createIndexFile "${weekDay}" "columns"
    doColumnMode "${weekDay}"
    
    echo "Creating Year list (Grid), for ${weekDay} folder"
    doPrintYears "${weekDay}" "grid" 1583 3000
    echo "Creating Year list (Columns), for ${weekDay} folder"
    doPrintYears "${weekDay}" "columns"  1583 3000
done

