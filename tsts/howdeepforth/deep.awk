#
# define parameters
#
BEGIN {

    FS = " ";

    RS = "\n";

    SUBSEP = " ";

    cnt = 0;

    colon = ":";
    
    semis = ";";

    cnt = 0 ;

    dp = 0;
}

#
# loop 
#
{

    if ( $1 == ":" && $(NF) == ";" ) {

        key = $2 

        qtde[key] = NF - 3 ;
         
        for (n = 0; n < qtde[key]; n++) {
            word[key,n+3] = $(n);
            }

        if (qtde[key] > 1) {

        for (n = 3; n < NF; n++) {
            cnte[$(n)] = cnte[$(n)] + 1
            
            }
        }

        cnt++;

        }

} 


function deep( key ) {

    print ">> " dp " : " key

    if (qtde[key] > 1) {

        for (n = 0; n < qtde[key]; n++) {

            nex = word[key,n]

            dp++

            deep( nex );
            
            dp--

            }

        }

    return (0)

    }


END {

    for (key in qtde) {

        print qtde[key] " " cnte[key] " " key 
    
            dp = 0 ;
            
            deep(key)

            }

         print " ~~~~ "

     }

        

