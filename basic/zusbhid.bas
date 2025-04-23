   10 /* zusb sample --- HID input test
   20 /***********************************************************************
   30 int devid,vid,pid
   40 str mstr,pstr,sstr
   50 int ino,cl,subcl,proto
   60 int ep,dir,xfer,maxpkt,npipe
   70 zusb_open()
   80 /***********************************************************************
   90 while zusb_find(devid,vid,pid,mstr,pstr) > 0
  100   while zusb_getif(ino,cl,subcl,proto) > 0
  110     if cl=3 then {
  120       print using "devid:### ";devid;:print pstr;" (";mstr;")"
  130       break
  140     }
  150   endwhile
  160 endwhile
  170 /***********************************************************************
  180 input "デバイスIDを入力してください:",devid
  190 if zusb_seek(devid) <= 0 then print "指定したデバイスIDは存在しません":zusb_close():end
  200 dim int mlen(7),mpos(7)
  210 int ppos=0
  220 while zusb_getif(ino,cl,subcl,proto) > 0
  230   if cl=3 then {
  240     zusb_connect(1,ino):print using "Connect devid:### interfece:#";devid,ino
  250     while zusb_getep(ep,dir,xfer,maxpkt) > 0
  260       if not (dir=1 and xfer=3) then continue
  270       mlen(npipe)=maxpkt:mpos(npipe)=ppos:ppos=ppos+maxpkt
  280       zusb_bind(npipe,ep)
  290       print using "  _## ep:&  & mode:# maxpkt:####";npipe,right$("0"+hex$(ep),4),xfer,maxpkt
  300       npipe = npipe + 1
  310     endwhile
  320   }
  330 endwhile
  340 /***********************************************************************
  350 print
  360 dim char data(256)
  370 for i=0 to npipe-1:zusb_readasync(data,mlen(i),i,mpos(i)):next
  380 for i=0 to 100
  390   repeat:m=zusb_stat():until m>0
  400   for e=0 to 7:if m and (1 shl e) then break
  410   next
  420   len = zusb_wait(e)
  430   print using "_##  ";e;
  440   for j=0 to len-1:print right$("0"+hex$(data(j)),2);" ";:next:print 
  450   zusb_readasync(data,mlen(e),e,mpos(e))
  460 next
  470 zusb_close()
