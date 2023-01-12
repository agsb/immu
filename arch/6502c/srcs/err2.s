

.macro link_list
      .local last
last  .word link
link  .set last
; some struct for data
.endmacro

link_list one

