BEGIN {

    colon = ":"
    semis = ";"

    }

{
    
  gsub(/\r/,"", $0)

  gsub(/\t+/,"", $0)

  gsub(/^[ ]+/," ", $0)

  gsub(/[ ]+$/," ", $0)

  gsub(/[ ]+/," ", $0)

  gsub(/^[ ]*:[ ]+/," : ", $0)

  gsub(/[ ]*;[ ]*$/," ; ", $0)
  
  # strip coments

  gsub(/ \( .* \) /," ", $0)

  # strip insides 

  gsub(/ code[ .* ]code /," code[ ]code ", $0)

  gsub(/ c" .*" /," c\" ", $0)

  gsub(/ s" .*" /," s\" ", $0)
  
  gsub(/ \." .*" /," \.\" ", $0)

  if ($1 == colon && $(NF) == semis) print $0

}

END {

    }
