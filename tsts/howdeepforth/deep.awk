#
# define parameters
#
BEGIN {

    FS = " ";

    RS = "\n";

    cnt = 0;

    colon = ":";
    
    semis = ";";

    cnt = 0 ;
}

#
# loop 
#
{

    # print " raw: >" $1 " >" $NF " (" $0 ") "

    if ( $1 == ":" && $(NF) == ";" ) {

        dict_qtde[$2] = NF - 3 ;
         
        dict_line[$2] = $0 ;

        for (n = 2; n < NF; n++) {

            dict_cnte[$(n)] = dict_cnte[$(n)] + 1
            
            }

        cnt++;

        }

} 


function deep ( ) {

    }

END {

    for (key in dict_qtde) {

        print dict_qtde[key] " " key " " dict_cnte[key] " " dict_qtde[key] "  "dict_line[key] ;
    
        }

}
        

