#
# define parameters
#
BEGIN {

  FS = " ";

  RS = "\n";

  SUBSEP = " ";

  colon = ":";
  
  semis = ";";

  dp = 0;

  np = 0;

}

#
# loop 
#
{
	
  gsub(/\r/,"", $0)
  gsub(/\t+/,"", $0)
  gsub(/^[ ]+/,"", $0)
  gsub(/[ ]+$/,"", $0)
  gsub(/[ ]+/," ", $0)

  if ( $1 == colon && $(NF) == semis ) {

  word = $2 

  qtde[word] = NF - 3 ;
  
  for (n = 3; n < NF; n++) {
    
    words[word,n - 3] = $(n);
  
    }

  }

} 


END {


  for (key in qtde) {

      dp = 0 
      
      np = 0

   #   deep(key) 

      print " ~ " key " " np " " qtde[key]   

      }


  }

  
function deep( key ) {

  dp++

  if (dp > np) np = dp

  m = qtde[key]

  for (n = 0; n < m; n++) {
    
    yek = words[key,n]

    if ( qtde[yek] > 1) { deep( yek ) } 
    
    }
    
  dp--
}

