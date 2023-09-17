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
   
  line = "";

}

function trimspc( line ) {

	return (line)

}
#
# loop 
#
{
	
	gsub(/[ ]+/," ", $0)

  	if ( $1 == colon && $(NF) == semis ) {

    word = $2 

    qtde[word] = NF - 3 ;
  
    for (n = 3; n < NF; n++) {
        
        words[word,n - 3] = $(n);
        
        cnte[$(n)] = cnte[$(n)] + 1

        lines[word] = $0
    
    }

  cnt++;

  }

} 


function deep( key ) {

  dp++;

  if (dp > ct) ct = dp

  m = qtde[key]

  for (n = 0; n < m; n++) {

    nex = words[key,n]

    print " >>> ", dp " " key " " n " " m " " nex 

    if ( qtde[nex] > 1) { deep( nex ) } 
    else { 
        
        nt++ 

        line = line " " nex

  	print " <<< ", dp " " key " " n " " m 

  	return (dp);
        
	}
  
    }
    
  dp--


  }


END {


  for (key in qtde) {

    print qtde[key] " " cnte[key] " " key " " lines[key]
  
    ct = 0

    nt = 0

    dp = 0 
  
    line = "";

    if (qtde[key] > 1) { deep(key); }

    print " ~ " ct " " nt " " qtde[key] " : " key " " line " ; "

    }

  print " ~~~~ "

  }

  

