BEGIN{x=0}/```/{if(x == 0){x = 1;next;}else{x = 0;}}x{print}
