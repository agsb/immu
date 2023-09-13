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

  deepth = 0;

  this_deep = 0;
  
  this_core = 0;

}

#
# read all file 
#
{

  if ( $1 == colon && $(NF) == semis ) {

    word = $2 

    qtde[word] = NF - 3 ;
  
    for (n = 3; n < NF; n++) {
        
        words[key,n - 3] = $(n);
        
        cnts[$(n)] = cnts[$(n)] + 1
    
        }

    cnt++;

  }

} 


function deep( word ) {

  deepth++;

  if (deepth > this_deep) this_deep = deepth

  m = qtde[word]

  for (n = 0; n < m; n++) {

    next_word = words[word,n]

    #print " >>> ", deepth " " word " " n " " m " " next_word 

    if ( qtde[next_word] > 1) { deep( next_word ) } 
    else { 
        this_core++ 
        this = this_line FS " . " next_word 
        this_line = this
        }
  
    }
    
  deepth--

  #print " <<< " deepth " " word " " n " " m 

  return (deepth);
  }


END {



  for (word in qtde) {

    print qtde[word] " " cnte[word] " " word 
  
    deepth = 0 
  
    this_core = 0

    this_deep = 0

    this_line = 0

    if (qtde[word] > 1) { deep(word); }

    print " ~ " this_deep " " this_core " " qtde[word] " : " word " " this_line " ; "

    }

  print " ~~~~ "

  }

  

