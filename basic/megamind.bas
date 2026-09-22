100 rem ==================================================================
110 rem = MEGAMind - OpenAI-compatible chat client for BASIC65 + Mega-IP
120 rem = UI modelled on mega-ip irc.bas (HTTP/1.0, no TLS)
130 rem ==================================================================
140 vs$="1.0":mh=10:dim hr$(mh):dim hc$(mh):dim rip(3):hn=0
150 bload"eth.bin",p($42000),r
160 print chr$(14);
170 key 1,chr$(133):key 3,chr$(135):key on
180 sprite 0,0
190 background 0:border 0
200 sv$="":po$="":pa$="":tk$="":md$="":ob$="":bd$="":ex$="":jb$=""
210 q$=chr$(34):bs$=chr$(92):lb$=chr$(123):rb$=chr$(125)
215 cr$=chr$(13)+chr$(10):mk=0:cn=0:bw=0:pd=0
220 gosub 800
230 window 0,2,67,22:cursor 0,0
240 print"Resetting Ethernet...":print
250 sys $42000
260 gosub 3470
270 sys $42015,1
280 rem == load API config, then optional edit ==
290 gosub 7200
300 gosub 7600
310 if left$(pa$,1)<>"/" then pa$="/"+pa$
320 rem == resolve host once ==
330 gosub 5000:if ef=1 then end
340 gosub 800
350 pr$="{yel}* HTTP ready. Type a prompt or /help":gosub 1050
360 pr$="{yel}* Host "+sv$+" port "+po$:gosub 1050
370 gosub 1120
410 rem ====================== main loop =========================
420 get k$:if k$<>"" then gosub 1800
430 if cn=1 then sys $42024:rreg a:if a<>0 then gosub 2110
440 goto 420
800 rem ================== build screen ==========================
810 cursor off:cc=0:cr=0
820 window 0,0,79,24:print"{wht}{clr}";
830 window 0,2,67,22,1
840 window 0,0,79,24:print chr$(19);chr$(19);:cursor 0,0
850 for zj=0 to 79:t@&(zj,0)=160:c@&(zj,0)=1:t@&(zj,1)=160:c@&(zj,1)=3:next
860 hd$="MEGAMind - Inference Chat"
870 if len(hd$)>64 then hd$=left$(hd$,64)
880 print"{rvon}{wht}";hd$;
890 cursor 65,0:print"{rvon}{lgrn}/help for menu";
900 cursor 0,1:print"{rvof}";
910 tb$="":if md$<>"" then tb$="Model: "+md$
920 if len(tb$)>79 then tb$=left$(tb$,79)
930 print"{rvon}{cyn}";tb$;
940 cursor 0,2:print"{rvof}";
950 gosub 1060
960 gosub 2540
970 gosub 1120
980 return
1040 rem -- print one line into the chat window --
1050 window 0,2,67,22:cursor cc,cr:print:print pr$;chr$(27);chr$(79);:rcursor cc,cr:return
1060 rem -- redraw fixed divider and input separator --
1070 window 0,0,79,24
1080 for zj=2 to 22:t@&(68,zj)=93:c@&(68,zj)=3:next
1090 for zj=0 to 79:t@&(zj,23)=64:c@&(zj,23)=3:next
1100 t@&(68,23)=113:c@&(68,23)=3
1110 window 0,2,67,22:return
1120 rem -- redraw the input line on row 24 --
1130 window 0,0,79,24:print chr$(19);chr$(19);:cursor 0,24
1140 if bw=1 then lm$="Waiting for model...":print"{yel}";lm$;:zk=77-len(lm$):if zk>0 then for zj=1 to zk:print" ";:next:window 0,2,67,22:return
1150 if len(ob$)>77 then id$=right$(ob$,77):else id$=ob$
1160 print"{wht}";id$;chr$(27);chr$(79);chr$(18);" ";chr$(146);
1170 zk=77-len(id$):if zk>0 then for zj=1 to zk:print" ";:next
1180 window 0,2,67,22:return
1800 rem ====================== keyboard ==========================
1810 if bw=1 then return
1820 if k$=chr$(147) or k$=chr$(19) then return
1830 if k$=chr$(13) then gosub 1900:gosub 1120:return
1840 if k$=chr$(20) then if len(ob$)>0 then ob$=left$(ob$,len(ob$)-1)
1850 if k$<>chr$(13) and k$<>chr$(20) and len(ob$)<200 then ob$=ob$+k$
1860 gosub 1120:return
1900 rem -- a line was entered --
1910 if ob$="" then return
1920 if left$(ob$,1)="/" then gosub 1980:ob$="":return
1930 rem user chat turn
1940 ux$=ob$:ob$=""
1942 ex$=ux$:gosub 7900
1944 gosub 7920
1960 hr$(hn)="u":hc$(hn)=sx$:hn=hn+1:if hn>mh then gosub 5900
1970 gosub 2540:gosub 6000:return
1980 rem -- slash command --
1990 if ob$="/help" then gosub 2130:return
2000 if left$(ob$,7)="/model " then md$=mid$(ob$,8):gosub 3080:gosub 2540:pr$="{wht}* model "+md$:gosub 1050:return
2010 if left$(ob$,6)="/host " then sv$=mid$(ob$,7):gosub 5000:if ef=0 then gosub 800:pr$="{wht}* host "+sv$:gosub 1050:return
2020 if left$(ob$,6)="/port " then po$=mid$(ob$,7):pr$="{wht}* port "+po$:gosub 1050:return
2030 if left$(ob$,6)="/path " then pa$=mid$(ob$,7):if left$(pa$,1)<>"/" then pa$="/"+pa$
2040 if left$(ob$,6)="/path " then pr$="{wht}* path "+pa$:gosub 1050:return
2050 if ob$="/token" then pp$=" - API Key: ":df$=tk$:mk=1:gosub 3890:tk$=an$:mk=0:pr$="{wht}* API key updated":gosub 1050:gosub 1120:return
2060 if ob$="/clear" then hn=0:gosub 2540:pr$="{yel}* history cleared":gosub 1050:return
2070 if ob$="/status" then gosub 2300:return
2072 if ob$="/save" then sm=1:gosub 7400:return
2074 if ob$="/config" then gosub 7600:gosub 800:gosub 5000:if ef=0 then pr$="{wht}* config updated":gosub 1050:return
2080 if ob$="/quit" then if cn=1 then sys $42021:sys $4205d
2090 if ob$="/quit" then print chr$(19);chr$(19);"{clr}{wht}disconnected.":end
2100 pr$="{lred}* unknown command.":gosub 1050:return
2110 rem -- tcp closed while idle --
2120 cn=0:sys $4205d:return
2130 rem -- help --
2140 pr$="":gosub 1050
2150 pr$="{lgrn}MEGAMind Help:":gosub 1050
2160 pr$="{lgrn}/model name   - set model":gosub 1050
2170 pr$="{lgrn}/host name    - set API host (re-resolve)":gosub 1050
2180 pr$="{lgrn}/port n       - set TCP port (HTTP)":gosub 1050
2190 pr$="{lgrn}/path /v1/... - set request path":gosub 1050
2200 pr$="{lgrn}/token        - set API key":gosub 1050
2202 pr$="{lgrn}/config       - edit API settings":gosub 1050
2204 pr$="{lgrn}/save         - write megamind.cfg":gosub 1050
2210 pr$="{lgrn}/clear        - clear chat history":gosub 1050
2220 pr$="{lgrn}/status       - show config":gosub 1050
2230 pr$="{lgrn}/quit         - disconnect":gosub 1050:return
2240 rem -- rreg ip into ad$ --
2250 rreg a,x,y,z
2260 ad$=mid$(str$(a),2)+"."+mid$(str$(x),2)+"."+mid$(str$(y),2)+"."+mid$(str$(z),2)
2270 return
2300 rem -- status dump --
2310 pr$="{yel}* host="+sv$+" port="+po$:gosub 1050
2320 pr$="{yel}* path="+pa$:gosub 1050
2330 pr$="{yel}* model="+md$+" msgs="+mid$(str$(hn),2):gosub 1050
2340 if tk$="" then pr$="{yel}* api key=(empty)":gosub 1050:return
2350 pr$="{yel}* api key=****"+right$(tk$,4):gosub 1050:return
2540 rem -- session side panel --
2550 window 0,0,79,24
2560 for zy=2 to 22:cursor 69,zy:print"          ";:next
2570 cursor 69,2:print"{cyn}session";
2580 cursor 69,4:print"{wht}msgs";
2590 cursor 69,5:print"{lgrn}";mid$(str$(hn),2);
2600 cursor 69,7:print"{wht}model";
2610 cursor 69,8:print"{lgrn}";left$(md$,10);
2620 if len(md$)>10 then cursor 69,9:print"{lgrn}";mid$(md$,11,10);
2630 cursor 69,11:print"{wht}host";
2640 cursor 69,12:print"{yel}";left$(sv$,10);
2650 if len(sv$)>10 then cursor 69,13:print"{yel}";mid$(sv$,11,10);
2660 cursor 69,15:print"{wht}port";
2670 cursor 69,16:print"{yel}";left$(po$,10);
2680 gosub 1060:window 0,2,67,22:return
3080 rem -- redraw model bar --
3090 window 0,0,79,24:for zj=0 to 79:t@&(zj,1)=160:c@&(zj,1)=3:next:cursor 0,1
3100 tb$="":if md$<>"" then tb$="Model: "+md$
3110 if len(tb$)>79 then tb$=left$(tb$,79)
3120 print"{rvon}{cyn}";tb$;
3130 cursor 0,2:print"{rvof}";
3140 window 0,2,67,22:return
3470 rem -- configure network like irc.bas --
3480 print:print" - [D]HCP Autoconfig or [M]anual Config":print
3490 getkey cf$
3500 if cf$="d" or cf$="D" then 3530
3510 if cf$="m" or cf$="M" then 3650
3520 goto 3490
3530 print" - Attempting DHCP autoconfig...":print
3540 sys $42042:a=-1
3550 for t=1 to 20000
3560 sys $42024:sys $42045:rreg b
3570 if b<>a and b=1 then print"..DISCOVER sent":a=b
3580 if b<>a and b=2 then print"..OFFER seen":a=b
3590 if b<>a and b=3 then print"..REQUEST sent":a=b
3600 if b<>a and b=4 then print"..IP Bound":a=b
3610 if b=4 then 3690
3620 if b=127 then 3640
3630 next:print"{lred}..DHCP timeout.{wht}":sleep 2:goto 3480
3640 print"{lred}..DHCP failed.{wht}":sleep 2:goto 3480
3650 input " - Local IP       :   192.168.1.76{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}";oc$:gosub 3770:if x=0 then 3650:else sys $42006,oc(0),oc(1),oc(2),oc(3)
3660 input " - Default Gateway:   192.168.1.1{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}";oc$:gosub 3770:if x=0 then 3660:else sys $42003,oc(0),oc(1),oc(2),oc(3)
3670 input " - Subnet Mask    :   255.255.255.0{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}";oc$:gosub 3770:if x=0 then 3670:else sys $42012,oc(0),oc(1),oc(2),oc(3)
3680 input " - Primary DNS    :   8.8.8.8{left}{left}{left}{left}{left}{left}{left}{left}{left}";oc$:gosub 3770:if x=0 then 3680:else sys $4204b,oc(0),oc(1),oc(2),oc(3)
3690 sys $4205d
3700 window 0,2,67,22,1:cc=0:cr=0:gosub 1060
3710 print"{wht}Network Settings:"
3720 print" Local IP       : ";:sys $4204e:gosub 2250:print ad$
3730 print" Default Gateway: ";:sys $42051:gosub 2250:print ad$
3740 print" Subnet Mask    : ";:sys $42054:gosub 2250:print ad$
3750 print" Primary DNS    : ";:sys $42057:gosub 2250:print ad$:print
3760 return
3770 rem -- octet string to oc() --
3780 x=0:oc(0)=0:oc(1)=0:oc(2)=0:oc(3)=0
3790 for t=1 to len(oc$)
3800 if mid$(oc$,t,1)="." then x=x+1
3810 next
3820 if x<>3 then x=0:return
3830 t$="":ct=0
3840 for t=1 to len(oc$)
3850 if mid$(oc$,t,1)="." then oc(ct)=val(t$):ct=ct+1:t$="":else t$=t$+mid$(oc$,t,1)
3860 next t:oc(ct)=val(t$)
3870 for t=0 to 3:if oc(t)<0 or oc(t)>255 then x=0:return
3880 next:x=1:return
3890 rem -- prompt: pp$ + editable default df$ -> an$ --
3900 an$=df$:dd=1:print pp$;:if mk=1 and len(an$)>0 then for z=1 to len(an$):print"*";:next
3910 if mk<>1 then print an$;
3920 gosub 4530
3930 getkey k$:gosub 4540
3940 if k$=chr$(147) or k$=chr$(19) then gosub 4530:goto 3930
3950 if k$=chr$(13) then print:return
3960 if k$=chr$(20) then dd=0:if len(an$)>0 then an$=left$(an$,len(an$)-1):print chr$(20);" ";chr$(20);
3970 if k$=chr$(20) then gosub 4530:goto 3930
3980 if len(k$)<>1 then gosub 4530:goto 3930
3990 if asc(k$)<32 then gosub 4530:goto 3930
4000 if dd=1 and df$<>"" then for z=1 to len(an$):print chr$(20);" ";chr$(20);:next:an$="":dd=0
4010 if len(an$)<80 then an$=an$+k$:if mk=1 then print"*";:else print k$;
4020 gosub 4530:goto 3930
4530 print chr$(18);" ";chr$(146);:return
4540 print chr$(20);" ";chr$(20);:return
5000 rem == DNS resolve sv$ into rip(0..3) ==
5010 ef=0:print:print"resolving ";sv$;" ";
5020 a$=sv$:sys $42063:rreg a
5030 if a=0 then print"{lred}bad name.{wht}":ef=1:return
5040 tt=ti
5050 sys $42024:sys $42036:rreg a
5060 if a=2 then 5090
5070 if a=3 then print"{lred}lookup failed.{wht}":ef=1:return
5080 if ti-tt<600 then 5050:else print"{lred}timed out.{wht}":ef=1:return
5090 sys $42033:rreg a,x,y,z
5100 rip(0)=a:rip(1)=x:rip(2)=y:rip(3)=z
5110 ad$=mid$(str$(a),2)+"."+mid$(str$(x),2)+"."+mid$(str$(y),2)+"."+mid$(str$(z),2)
5120 print"-> ";ad$:return
5300 rem == TCP connect using saved rip / po$ ==
5310 ef=0:rt=0
5320 if cn=1 then sys $42021:gosub 5450:sys $4205d:cn=0
5325 rem settle after prior close (TIME_WAIT / ARP)
5326 for wt=1 to 150:sys $42024:next wt
5330 po=val(po$):if po<1 or po>65535 then pr$="{lred}* bad port.":gosub 1050:ef=1:return
5340 sys $4200c,rip(0),rip(1),rip(2),rip(3)
5350 ph=int(po/256):pl=po-ph*256:sys $4200f,ph,pl
5360 rem ephemeral local port 49152-65535 (avoid reuse after close)
5362 lh=192+int(rnd(1)*64):ll=int(rnd(1)*256):sys $42009,lh,ll
5370 sys $42027:tt=ti
5372 sys $42024:sys $4202a:rreg a
5374 if (a and 1) then cn=1:ef=0:return
5376 if (a and 2) then 5390
5378 if ti-tt<2500 then 5372
5390 rem fail or timeout — cleanup + retry
5392 sys $42021:gosub 5450:sys $4205d:cn=0
5394 rt=rt+1:if rt<4 then sleep 1:goto 5340
5396 if (a and 2) then pr$="{lred}* connect failed.":gosub 1050:ef=1:return
5398 pr$="{lred}* connect timed out.":gosub 1050:ef=1:return
5450 rem wait tx idle
5452 for wt=1 to 3000:sys $42024:sys $42066:rreg a:if a=1 then return
5454 next wt:return
5900 rem == drop oldest 2 messages to keep under mh ==
5910 if hn<=mh then return
5920 for zi=0 to hn-3:hr$(zi)=hr$(zi+2):hc$(zi)=hc$(zi+2):next
5930 hn=hn-2:return
6000 rem == chat completion request ==
6010 if tk$="" then pr$="{lred}* set an API key with /token":gosub 1050:return
6020 if md$="" then pr$="{lred}* set a model with /model":gosub 1050:return
6030 bw=1:gosub 1120
6040 gosub 5300:if ef=1 then bw=0:gosub 1120:return
6050 gosub 8200:if ef=1 then bw=0:gosub 6400:gosub 1120:return
6060 rem HTTP headers (split so each piece << 255)
6062 hx$="POST "+pa$+" HTTP/1.0"+cr$
6064 hx$=hx$+"Host: "+sv$+":"+po$+cr$
6066 hx$=hx$+"Authorization: Bearer "+tk$+cr$
6068 if len(hx$)>230 then pr$="{lred}* headers too long":gosub 1050:bw=0:gosub 6400:gosub 1120:return
6070 tx$=hx$:gosub 6300:if ef=1 then bw=0:gosub 6400:gosub 1120:return
6072 hx$="Content-Type: application/json"+cr$
6074 hx$=hx$+"Content-Length: "+mid$(str$(tl),2)+cr$
6076 hx$=hx$+"Connection: close"+cr$+cr$
6078 tx$=hx$:gosub 6300:if ef=1 then bw=0:gosub 6400:gosub 1120:return
6080 gosub 8300:if ef=1 then bw=0:gosub 6400:gosub 1120:return
6090 gosub 6500:if ef=1 then bw=0:gosub 6400:gosub 1120:return
6100 gosub 6400
6110 if ex$="" then if sf=0 then pr$="{lred}* empty or unparsed response":gosub 1050:bw=0:gosub 1120:return
6112 if ex$="" then bw=0:gosub 2540:gosub 1120:return
6120 hr$(hn)="a":hc$(hn)=ex$:hn=hn+1:if hn>mh then gosub 5900
6130 gosub 6900
6140 bw=0:gosub 2540:gosub 1120:return
6300 rem == send tx$ in 235-byte chunks ==
6310 ef=0:si=1
6320 if si>len(tx$) then return
6330 a$=mid$(tx$,si,235):sys $4201b
6340 for wt=1 to 4000:sys $42024:sys $42066:rreg a:if a=1 then 6360
6350 next wt:pr$="{lred}* send timeout":gosub 1050:ef=1:return
6360 si=si+235:goto 6320
6400 rem == close tcp ==
6410 if cn=1 then sys $42021
6420 gosub 5450
6430 sys $4205d:cn=0:return
6500 rem == read HTTP; stream-parse content (no full-body string) ==
6505 rem BASIC65 strings max ~255 — never accumulate JSON into bd$
6510 ef=0:hl$="":hs=0:sc=0:ex$="":eol=0:tt=ti:ps=1:nm=0:eu=0:gf=0
6512 ns$=q$+"content"+q$+":"+q$:nl=len(ns$)
6514 sf=0:sl$="":sk=0:fh=1:mx=48
6520 sys $42024:rreg a
6530 cl=0:if (a and 1) or (a and 2) then cl=1
6540 sys $4201e:rreg a
6550 if a=0 then if cl=1 then 6620
6552 if a=0 then if ti-tt<18000 then 6520:else 6620
6560 tt=ti
6562 if hs=1 then gosub 6800:goto 6520
6564 rem header mode
6566 if a=13 then gosub 6680:eol=1:goto 6520
6568 if a=10 then if eol=1 then eol=0:goto 6520
6570 if a=10 then gosub 6680:eol=0:goto 6520
6572 eol=0:if len(hl$)<200 then hl$=hl$+chr$(a)
6574 goto 6520
6620 rem drain leftover ring bytes
6622 for zi=1 to 4000:sys $42024:sys $4201e:rreg a:if a=0 then 6650
6624 tt=ti
6626 if hs=1 then gosub 6800:goto 6648
6628 if a=13 then gosub 6680:eol=1:goto 6648
6630 if a=10 then if eol=1 then eol=0:goto 6648
6632 if a=10 then gosub 6680:eol=0:goto 6648
6634 eol=0:if len(hl$)<200 then hl$=hl$+chr$(a)
6648 next zi
6650 if sc>=400 then pr$="{lred}* HTTP "+mid$(str$(sc),2):gosub 1050:ef=1:return
6652 if gf=0 then pr$="{lred}* no response body":gosub 1050:ef=1:return
6654 if ex$="" then if sf=0 then pr$="{lred}* empty content":gosub 1050:ef=1:return
6656 gosub 6980:return
6680 rem -- end of header line --
6682 if hs=1 then return
6684 if hl$="" then hs=1:ps=1:nm=0:return
6686 if left$(hl$,5)="HTTP/" then sc=val(mid$(hl$,9,4))
6688 hl$="":return
6800 rem -- one body byte A: match "content":" then capture into ex$ --
6802 if ps=3 then return
6804 c$=chr$(a)
6806 if ps=2 then 6840
6810 rem ps=1 scan needle
6812 if c$=mid$(ns$,nm+1,1) then nm=nm+1:goto 6820
6814 if nm>0 then nm=0:if c$=left$(ns$,1) then nm=1
6816 return
6820 if nm>=nl then ps=2:nm=0:eu=0:gf=1
6822 return
6840 rem ps=2 capture
6842 if eu=1 then gosub 6870:return
6844 if a=34 then gosub 6980:ps=3:return
6846 if a=92 then eu=1:return
6848 qc=a:gosub 8550:if ac=0 then return
6850 gosub 6860:return
6860 rem store ac in ex$ (history, max 254) + stream to screen
6862 if len(ex$)<254 then ex$=ex$+chr$(ac)
6864 gosub 6950:return
6870 rem unescape
6872 eu=0
6874 if c$="n" or c$="t" then ac=32:gosub 6860:return
6876 if a=34 or a=92 or a=47 then ac=a:gosub 6860:return
6878 qc=a:gosub 8550:if ac=0 then return
6880 gosub 6860:return
6900 rem == print assistant (only if not already streamed) ==
6902 if sf=1 then sf=0:return
6904 gosub 7900
6906 pr$="{cyn}<{lgrn}mind{cyn}> {wht}"+left$(sx$,48):gosub 1050
6908 if len(sx$)<=48 then return
6910 zi=49
6912 if zi>len(sx$) then return
6914 pr$="{wht}"+mid$(sx$,zi,60):gosub 1050:zi=zi+60:goto 6912
6950 rem stream one char ac onto chat lines (full reply, not just history)
6952 sl$=sl$+chr$(ac):sk=sk+1:sf=1
6954 if sk<mx then return
6956 if fh=1 then pr$="{cyn}<{lgrn}mind{cyn}> {wht}"+sl$:fh=0:mx=60:goto 6960
6958 pr$="{wht}"+sl$
6960 gosub 1050:sl$="":sk=0:return
6980 rem flush partial stream line
6982 if sf=0 then return
6984 if sl$="" then return
6986 if fh=1 then pr$="{cyn}<{lgrn}mind{cyn}> {wht}"+sl$:goto 6990
6988 pr$="{wht}"+sl$
6990 gosub 1050:sl$="":sk=0:fh=0:return
7200 rem == load megamind.cfg or built-in defaults ==
7210 sv$="litellm.chronolink.lan":po$="4000":pa$="/v1/chat/completions"
7220 tk$="retrosystem":md$="Qwen/Qwen3.8-27B-FP8"
7230 print" - Loading megamind.cfg...";
7240 open 2,8,2,"megamind.cfg,s,r"
7250 if st<>0 then close 2:print" missing, using defaults.":return
7260 for zi=1 to 32
7270 input#2,ln$
7280 if (st and 64)<>0 then 7320
7290 if ln$="" then 7310
7300 gosub 7500
7310 next zi
7320 close 2:print" ok."
7330 return
7400 rem == save megamind.cfg (sm=1 -> also chat confirm) ==
7410 open 2,8,2,"@0:megamind.cfg,s,w"
7420 print#2,"HOST="+sv$
7430 print#2,"PORT="+po$
7440 print#2,"PATH="+pa$
7450 print#2,"TOKEN="+tk$
7460 print#2,"MODEL="+md$
7470 close 2
7480 print" - Saved megamind.cfg"
7485 if sm=1 then pr$="{wht}* saved megamind.cfg":gosub 1050
7487 sm=0:return
7500 rem == parse KEY=VALUE line ln$ ==
7510 eq=instr(ln$,"="):if eq<2 then return
7520 ky$=left$(ln$,eq-1):vl$=mid$(ln$,eq+1)
7530 if ky$="HOST" or ky$="host" then sv$=vl$:return
7540 if ky$="PORT" or ky$="port" then po$=vl$:return
7550 if ky$="PATH" or ky$="path" then pa$=vl$:return
7560 if ky$="TOKEN" or ky$="token" then tk$=vl$:return
7570 if ky$="MODEL" or ky$="model" then md$=vl$:return
7580 return
7600 rem == show API settings; optional change + save ==
7610 print:print" - API settings:"
7620 print"   Host : ";sv$
7630 print"   Port : ";po$
7640 print"   Path : ";pa$
7650 print"   Model: ";md$
7660 if tk$="" then print"   Key  : (empty)":goto 7680
7670 print"   Key  : ****";right$(tk$,4)
7680 print:print" - [K]eep settings or [C]hange API credentials?":print
7690 getkey cf$
7700 if cf$="k" or cf$="K" then return
7710 if cf$="c" or cf$="C" then 7730
7720 goto 7690
7730 print
7740 pp$=" - Host: ":df$=sv$:gosub 3890:sv$=an$
7750 pp$=" - Port: ":df$=po$:gosub 3890:po$=an$
7760 pp$=" - Path: ":df$=pa$:gosub 3890:pa$=an$
7770 pp$=" - API Key: ":df$=tk$:mk=1:gosub 3890:tk$=an$:mk=0
7780 pp$=" - Model: ":df$=md$:gosub 3890:md$=an$
7790 if left$(pa$,1)<>"/" then pa$="/"+pa$
7800 print:print" - [S]ave to megamind.cfg or [N]ot now?":print
7810 getkey cf$
7820 if cf$="s" or cf$="S" then gosub 7400:return
7830 if cf$="n" or cf$="N" then print" - Not saved.":return
7840 goto 7810
7900 rem sanitize ex$ -> sx$ (letters/punct only; no color/graphics)
7902 sx$=""
7904 for qx=1 to len(ex$)
7906 qc=asc(mid$(ex$,qx,1))
7908 if qc=13 or qc=10 then sx$=sx$+" ":goto 7914
7910 gosub 8550:if ac=0 then 7914
7912 sx$=sx$+chr$(ac)
7914 next qx
7916 if sx$="" then return
7918 if left$(sx$,1)=" " then sx$=mid$(sx$,2):goto 7918
7919 return
7920 rem print sx$ as user line
7922 pr$="{cyn}<{lred}you{cyn}> {lred}"+left$(sx$,48):gosub 1050
7924 if len(sx$)<=48 then return
7926 zi=49
7928 if zi>len(sx$) then return
7930 pr$="{lred}"+mid$(sx$,zi,60):gosub 1050:zi=zi+60:goto 7928
8200 rem == body length tl (must match bytes we send) ==
8202 ef=0:if hn<1 then ef=1:pr$="{lred}* nothing to send":gosub 1050:return
8204 tl=10+len(md$)+14
8206 for zi=0 to hn-1
8208 if zi>0 then tl=tl+1
8210 ro$="user":if hr$(zi)="a" then ro$="assistant"
8212 if hr$(zi)="s" then ro$="system"
8214 sx$=hc$(zi):gosub 8250
8216 tl=tl+9+len(ro$)+13+xl+2
8218 next zi
8220 tl=tl+2:return
8250 rem escaped length of sx$ -> xl (same filter as send)
8252 xl=0
8254 for qx=1 to len(sx$)
8256 c$=mid$(sx$,qx,1):qc=asc(c$)
8258 if c$=bs$ or c$=q$ then xl=xl+2:goto 8266
8260 if qc=13 or qc=10 then xl=xl+2:goto 8266
8262 gosub 8550:if ac<>0 then xl=xl+1
8266 next:return
8300 rem == send JSON body piecemeal (no full jb$) ==
8302 ef=0
8304 tx$=lb$+q$+"model"+q$+":"+q$+md$+q$+","+q$+"messages"+q$+":["
8306 gosub 6300:if ef=1 then return
8308 for zi=0 to hn-1
8310 if zi>0 then tx$=",":gosub 6300:if ef=1 then return
8312 ro$="user":if hr$(zi)="a" then ro$="assistant"
8314 if hr$(zi)="s" then ro$="system"
8316 tx$=lb$+q$+"role"+q$+":"+q$+ro$+q$+","+q$+"content"+q$+":"+q$
8318 gosub 6300:if ef=1 then return
8320 sx$=hc$(zi):gosub 8400:if ef=1 then return
8322 tx$=q$+rb$:gosub 6300:if ef=1 then return
8324 next zi
8326 tx$="]"+rb$:gosub 6300:return
8400 rem escape-send sx$ using bf$ (flush at 200)
8402 bf$="":ef=0
8404 for qx=1 to len(sx$)
8406 c$=mid$(sx$,qx,1):qc=asc(c$)
8408 if c$=bs$ then e1$=bs$+bs$:goto 8420
8410 if c$=q$ then e1$=bs$+q$:goto 8420
8412 if qc=13 or qc=10 then e1$=bs$+"n":goto 8420
8414 gosub 8550:if ac=0 then goto 8428
8416 e1$=chr$(ac)
8420 if len(bf$)+len(e1$)<=200 then 8426
8422 tx$=bf$:gosub 6300:if ef=1 then return
8424 bf$=""
8426 bf$=bf$+e1$
8428 next qx
8430 if bf$<>"" then tx$=bf$:gosub 6300
8432 return
8550 rem petscii qc -> ac (0=drop). keep letters/punct; drop color/graphics
8552 ac=0
8554 if qc>=193 and qc<=218 then ac=qc:return
8556 if qc>=65 and qc<=90 then ac=qc:return
8558 if qc>=32 and qc<=64 then ac=qc:return
8560 if qc>=91 and qc<=95 then ac=qc:return
8562 if qc=123 or qc=125 then ac=qc:return
8564 return
