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

  ct = 0;
  
  nt = 0;

}

#
# loop 
#
{

  if ( $1 == ":" && $(NF) == ";" ) {

    key = $2 

    qtde[key] = NF - 3 ;
  
  # print "~~~~~~~~~~~~"

    for (n = 3; n < NF; n++) {
        
        #print key " " n " " $(n) 
        
        word[key,n - 3] = $(n);
        
        cnte[$(n)] = cnte[$(n)] + 1
    
    }

  cnt++;

  }

} 


function deep( key ) {

  dp++;

  if (dp > ct) ct = dp

  m = qtde[key]

  for (n = 0; n < m; n++) {

    nex = word[key,n]

    print " >>> ", dp " " key " " n " " m " " nex 

    if ( qtde[nex] > 1) { deep( nex ) } 
    else { nt++ }
  
    }
    
  dp--

  print " <<< ", dp " " key " " n " " m 

  return (dp);
  }


END {


  for (key in qtde) {

    print qtde[key] " " cnte[key] " " key 
  
    if (0) {
        for (n = 0; n < qtde[key]; n++) {
            printf " %s", word[key,n]
            }
        print
        }
    
    ct = 0

    nt = 0

    dp = 0 
  
    if (qtde[key] > 1) { deep(key); }

    print " ~ " ct " " nt " " qtde[key] " " key

    }

  print " ~~~~ "

  }

  

