BEGIN {

    colon = ":"
    semis = ";"
    flag = 0 

    }

{
    
  while (1) {

  gsub(/\r/,"", $0)
  gsub(/\t+/,"", $0)
  gsub(/^[ ]+/," ", $0)
  gsub(/[ ]+$/," ", $0)
  gsub(/[ ]+/," ", $0)
  gsub(/^[^ ]/," ", $0)

#    print ">" $1 "|" $(NF) "<"

    if (/^$/) break

    if ($1 == "user") {
            print " : " $2 " user ;"
            break
            }   

    if ($1 == "variable") {
            print " : " $2 " variable ;"
            break
            }   

    if ($2 == "constant") {
            print " : " $3 " constant ;"
            break
            }   

    if ($1 == colon) flag = 1
 
    if ($1 == semis) flag = 0
    
    if ($(NF) == semis) flag = 0

    if (flag == 0) {
        print $0
        }
    else {
        printf "%s", $0
        }   
        
    break
    }
}

END {

    }
