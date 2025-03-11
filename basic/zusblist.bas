   10 /* zusb sample --- list USB devices
   20 /***********************************************************************
   30 int devid,vid,pid
   40 str mstr,pstr,sstr
   50 int ino,cl,subcl,proto
   60 int ep,dir,xfer,maxpkt
   70 /***********************************************************************
   80 zusb_open()
   90 while zusb_find(devid,vid,pid,mstr,pstr,sstr) > 0
  100   print using "devid:### &  &:&  &";devid,right$("000"+hex$(vid),4),right$("000"+hex$(pid),4)
  110   print using " manufacturer:&        & product:&                              & serial:&      &";mstr,pstr,sstr
  120   while zusb_getif(ino,cl,subcl,proto) > 0
  130     print using "  _## class:### subclass:### protocol:###";ino,cl,subcl,proto
  140     while zusb_getep(ep,dir,xfer,maxpkt) > 0
  150       print using "    ep:&  & mode:# maxpkt:####";right$("0"+hex$(ep),4),xfer,maxpkt
  160     endwhile
  170   endwhile
  180 endwhile
  190 zusb_close()
