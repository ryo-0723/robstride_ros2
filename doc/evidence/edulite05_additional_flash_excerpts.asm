; Official distributed EL05 1.0.5.0.2, image base 0x08002000.
; Analyst labels; inline literal pools are data, not executable instructions.

; Type 9 group bounds, descriptor lookup and word read
0800ae44  push.w     {r0, r4, r5, r6, r7, r8, sb, sl, fp, lr}
0800ae48  ldrh.w     r0, [sp]
0800ae4c  lsrs       r7, r0, #0xc
0800ae4e  ldrh.w     r0, [sp]
0800ae52  ubfx       r5, r0, #0, #0xc
0800ae56  mov.w      sl, #0
0800ae5a  ldr        r0, [pc, #0x14c] ; literal[0x800afa8]=0x2000000c
0800ae5c  ldrb       r0, [r0, #7]
0800ae5e  bic        r0, r0, #0x1f
0800ae62  adds       r0, #9
0800ae64  ldr        r1, [pc, #0x140] ; literal[0x800afa8]=0x2000000c
0800ae66  strb       r0, [r1, #7]
0800ae68  ldr        r0, [pc, #0x140] ; literal[0x800afac]=0x20000022
0800ae6a  ldrb       r1, [r0]
0800ae6c  ldr        r0, [pc, #0x138] ; literal[0x800afa8]=0x2000000c
0800ae6e  ldr        r0, [r0, #4]
0800ae70  bfi        r0, r1, #0, #8
0800ae74  ldr        r1, [pc, #0x130] ; literal[0x800afa8]=0x2000000c
0800ae76  str        r0, [r1, #4]
0800ae78  ldr        r0, [pc, #0x134] ; literal[0x800afb0]=0x20000020
0800ae7a  ldrb       r1, [r0]
0800ae7c  ldr        r0, [pc, #0x128] ; literal[0x800afa8]=0x2000000c
0800ae7e  ldr        r0, [r0, #4]
0800ae80  bfi        r0, r1, #8, #0x10
0800ae84  ldr        r1, [pc, #0x120] ; literal[0x800afa8]=0x2000000c
0800ae86  str        r0, [r1, #4]
0800ae88  mov        r0, r1
0800ae8a  ldr        r0, [r0, #4]
0800ae8c  bic        r0, r0, #0xe0000000
0800ae90  str        r0, [r1, #4]
0800ae92  movs       r0, #8
0800ae94  strb       r0, [r1, #0xa]
0800ae96  mov        r0, r1
0800ae98  ldrh.w     r1, [sp]
0800ae9c  strh.w     r1, [r0, #0xb]
0800aea0  ldr        r0, [pc, #0x110] ; literal[0x800afb4]=0x8014c62
0800aea2  ldrh.w     r0, [r0, r7, lsl #1]
0800aea6  cmp        r0, r5
0800aea8  ble        #0x800aeae
0800aeaa  cmp        r7, #4
0800aeac  blt        #0x800aedc
0800aeae  mov.w      sl, #1
0800aeb2  ldr        r0, [pc, #0xf4] ; literal[0x800afa8]=0x2000000c
0800aeb4  ldr        r0, [r0, #4]
0800aeb6  lsrs       r0, r0, #8
0800aeb8  orr.w      r1, r0, sl, lsl #8
0800aebc  ldr        r0, [pc, #0xe8] ; literal[0x800afa8]=0x2000000c
0800aebe  ldr        r0, [r0, #4]
0800aec0  bfi        r0, r1, #8, #0x10
0800aec4  ldr        r1, [pc, #0xe0] ; literal[0x800afa8]=0x2000000c
0800aec6  str        r0, [r1, #4]
0800aec8  adds       r0, r1, #5
0800aeca  movs       r1, #0
0800aecc  str        r1, [r0, #8]
0800aece  strh       r1, [r0, #0xc]
0800aed0  subs       r1, r0, #5
0800aed2  ldr        r0, [pc, #0xe4] ; literal[0x800afb8]=0x40006400
0800aed4  bl         #0x8008334
0800aed8  pop.w      {r3, r4, r5, r6, r7, r8, sb, sl, fp, pc}
0800aedc  mov.w      r8, #0
0800aee0  cbz        r7, #0x800aef0
0800aee2  cmp        r7, #1
0800aee4  beq        #0x800aefe
0800aee6  cmp        r7, #2
0800aee8  beq        #0x800af0c
0800aeea  cmp        r7, #3
0800aeec  bne        #0x800af3e
0800aeee  b          #0x800af24
0800aef0  movs       r6, #0xa
0800aef2  ldr        r0, [pc, #0xc8] ; literal[0x800afbc]=0x80152a0
0800aef4  add.w      r0, r0, r5, lsl #3
0800aef8  ldr.w      r8, [r0, #4]
0800aefc  b          #0x800af40
0800aefe  movs       r6, #0xa
0800af00  ldr        r0, [pc, #0xbc] ; literal[0x800afc0]=0x8015260
0800af02  add.w      r0, r0, r5, lsl #3
0800af06  ldr.w      r8, [r0, #4]
0800af0a  b          #0x800af40
0800af0c  ldr        r0, [pc, #0xb4] ; literal[0x800afc4]=0x8014c6c
0800af0e  add.w      r0, r0, r5, lsl #4
0800af12  ldrb       r0, [r0, #0xd]
0800af14  and        r6, r0, #0x1f
0800af18  ldr        r0, [pc, #0xa8] ; literal[0x800afc4]=0x8014c6c
0800af1a  add.w      r0, r0, r5, lsl #4
0800af1e  ldr.w      r8, [r0, #4]
0800af22  b          #0x800af40
0800af24  add.w      r0, r5, r5, lsl #1
0800af28  ldr        r1, [pc, #0x9c] ; literal[0x800afc8]=0x8014eac
0800af2a  add.w      r0, r1, r0, lsl #2
0800af2e  ldrb       r6, [r0, #8]
0800af30  add.w      r0, r5, r5, lsl #1
0800af34  add.w      r0, r1, r0, lsl #2
0800af38  ldr.w      r8, [r0, #4]
0800af3c  b          #0x800af40
0800af3e  b          #0x800aed8
0800af40  nop        
0800af42  ldr        r0, [pc, #0x64] ; literal[0x800afa8]=0x2000000c
0800af44  strb       r6, [r0, #0xd]
0800af46  ldr        r0, [pc, #0x84] ; literal[0x800afcc]=0x8014c57
0800af48  ldrb       r4, [r0, r6]
0800af4a  mov        r0, r4
0800af4c  asrs       r2, r4, #0x1f
0800af4e  add.w      r2, r4, r2, lsr #30
0800af52  asrs       r2, r2, #2
0800af54  mov        r1, r4
0800af56  asrs       r3, r4, #0x1f
0800af58  add.w      r3, r4, r3, lsr #30
0800af5c  asrs       r3, r3, #2
0800af5e  sub.w      r3, r4, r3, lsl #2
0800af62  cbz        r3, #0x800af68
0800af64  movs       r3, #1
0800af66  b          #0x800af6a
0800af68  movs       r3, #0
0800af6a  add        r2, r3
0800af6c  and        sb, r2, #0xff
0800af70  mov.w      fp, #0
0800af74  b          #0x800af9e
0800af76  ldr        r0, [pc, #0x30] ; literal[0x800afa8]=0x2000000c
0800af78  strb.w     fp, [r0, #0xe]
0800af7c  add.w      r1, r8, fp, lsl #2
0800af80  ldr        r1, [r1]
0800af82  str.w      r1, [r0, #0xf]
0800af86  mov        r1, r0
0800af88  ldr        r0, [pc, #0x2c] ; literal[0x800afb8]=0x40006400
0800af8a  bl         #0x8008334
0800af8e  mov.w      r0, #0x1f4
0800af92  bl         #0x8006db0
0800af96  add.w      r0, fp, #1
0800af9a  and        fp, r0, #0xff
0800af9e  cmp        fp, sb
0800afa0  blt        #0x800af76
0800afa2  nop        
0800afa4  b          #0x800aed8
0800afa6  movs       r0, r0
0800afa8  movs       r4, r1
0800afaa  movs       r0, #0
0800afac  movs       r2, r4
0800afae  movs       r0, #0
0800afb0  movs       r0, r4
0800afb2  movs       r0, #0
0800afb4  ldr        r4, [pc, #0x188] ; literal[0x800b140]=0xf8d14941
0800afb6  lsrs       r1, r0, #0x20
0800afb8  str        r0, [r0, #0x40]
0800afba  ands       r0, r0
0800afbc  strh       r0, [r4, r2]
0800afbe  lsrs       r1, r0, #0x20
0800afc0  strh       r0, [r4, r1]
0800afc2  lsrs       r1, r0, #0x20
0800afc4  ldr        r4, [pc, #0x1b0] ; literal[0x800b178]=0x4832e037
0800afc6  lsrs       r1, r0, #0x20
0800afc8  ldr        r6, [pc, #0x2b0] ; literal[0x800b27c]=0xf8b048fc
0800afca  lsrs       r1, r0, #0x20
0800afcc  ldr        r4, [pc, #0x15c] ; literal[0x800b12c]=0xe05c100f

; calibration and separate flash records
080044d0  movs       r7, #0
080044d2  cpsid      i
080044d4  bl         #0x8009900
080044d8  movw       r0, #0x307
080044dc  bl         #0x8009708
080044e0  ldr        r0, [pc, #0x74] ; literal[0x8004558]=0x807d800
080044e2  bl         #0x8009814
080044e6  mov        r4, r0
080044e8  cbz        r4, #0x80044ee
080044ea  movs       r7, #1
080044ec  b          #0x800454a
080044ee  ldr        r5, [pc, #0x68] ; literal[0x8004558]=0x807d800
080044f0  movs       r6, #0
080044f2  b          #0x800450e
080044f4  ldr        r0, [pc, #0x64] ; literal[0x800455c]=0x20000330
080044f6  ldr.w      r1, [r0, r6, lsl #2]
080044fa  mov        r0, r5
080044fc  bl         #0x8009944
08004500  mov        r4, r0
08004502  cbz        r4, #0x8004508
08004504  movs       r7, #2
08004506  b          #0x800454a
08004508  adds       r5, r5, #4
0800450a  adds       r0, r6, #1
0800450c  uxth       r6, r0
0800450e  cmp        r6, #0x80
08004510  blt        #0x80044f4
08004512  ldr        r0, [pc, #0x4c] ; literal[0x8004560]=0x200001dc
08004514  ldr        r1, [r0, #0xc]
08004516  ldr        r0, [pc, #0x4c] ; literal[0x8004564]=0x807dc00
08004518  bl         #0x8009944
0800451c  mov        r4, r0
0800451e  cbz        r4, #0x8004524
08004520  movs       r7, #3
08004522  b          #0x800454a
08004524  ldr        r0, [pc, #0x40] ; literal[0x8004568]=0x200008d0
08004526  ldrb       r1, [r0]
08004528  ldr        r0, [pc, #0x38] ; literal[0x8004564]=0x807dc00
0800452a  adds       r0, #8
0800452c  bl         #0x8009728
08004530  mov        r4, r0
08004532  cbz        r4, #0x8004538
08004534  movs       r7, #4
08004536  b          #0x800454a
08004538  ldr        r1, [pc, #0x30] ; literal[0x800456c]=0x22334455
0800453a  ldr        r0, [pc, #0x34] ; literal[0x8004570]=0x807dffc
0800453c  bl         #0x8009944
08004540  mov        r4, r0
08004542  cbz        r4, #0x8004548
08004544  movs       r7, #5
08004546  b          #0x800454a
08004548  nop        
0800454a  bl         #0x80097e8
0800454e  cpsie      i
08004550  mov        r0, r7
08004552  pop.w      {r4, r5, r6, r7, r8, pc}
08004556  movs       r0, r0
08004558  bhi        #0x800455c
0800455a  lsrs       r7, r0, #0x20
0800455c  lsls       r0, r6, #0xc
0800455e  movs       r0, #0
08004560  lsls       r4, r3, #7
08004562  movs       r0, #0
08004564  bgt        #0x8004568
08004566  lsrs       r7, r0, #0x20
08004568  lsrs       r0, r2, #3
0800456a  movs       r0, #0
0800456c  add        r5, sl
0800456e  movs       r2, #0x33
08004570  svc        #0xfc
08004572  lsrs       r7, r0, #0x20
08004574  push.w     {r4, r5, r6, r7, r8, sb, sl, lr}
08004578  mov        r7, r0
0800457a  mov        r8, r1
0800457c  cmp        r7, #2
0800457e  blt        #0x8004586
08004580  movs       r0, #1
08004582  pop.w      {r4, r5, r6, r7, r8, sb, sl, pc}
08004586  movs       r6, #0
08004588  movs       r4, #0
0800458a  movs       r5, #0
0800458c  mov        sb, r4
0800458e  cpsid      i
08004590  bl         #0x8009900
08004594  movw       r0, #0x307
08004598  bl         #0x8009708
0800459c  ldr        r0, [pc, #0xac] ; literal[0x800464c]=0x807b800
0800459e  bl         #0x8009814
080045a2  mov        r6, r0
080045a4  cbz        r6, #0x80045ac
080045a6  mov.w      sb, #2
080045aa  b          #0x8004642
080045ac  movs       r4, #0
080045ae  b          #0x80045ca
080045b0  ldr        r2, [pc, #0x9c] ; literal[0x8004650]=0x807b000
080045b2  ldr        r1, [r4, r2]
080045b4  ldr        r2, [pc, #0x94] ; literal[0x800464c]=0x807b800
080045b6  adds       r0, r4, r2
080045b8  bl         #0x8009944
080045bc  mov        r6, r0
080045be  cbz        r6, #0x80045c6
080045c0  mov.w      sb, #3
080045c4  b          #0x8004642
080045c6  adds       r0, r4, #4
080045c8  uxth       r4, r0
080045ca  cmp        r4, #0x20
080045cc  blt        #0x80045b0
080045ce  ldr        r0, [pc, #0x80] ; literal[0x8004650]=0x807b000
080045d0  bl         #0x8009814
080045d4  mov        r6, r0
080045d6  cbz        r6, #0x80045de
080045d8  mov.w      sb, #4
080045dc  b          #0x8004642
080045de  movs       r4, #0
080045e0  b          #0x800463c
080045e2  cmp        r4, r7
080045e4  bne        #0x800460e
080045e6  movs       r5, #0
080045e8  b          #0x8004608
080045ea  ldr.w      r1, [r8, r5]
080045ee  ldr        r2, [pc, #0x60] ; literal[0x8004650]=0x807b000
080045f0  add.w      r2, r2, r4, lsl #4
080045f4  adds       r0, r2, r5
080045f6  bl         #0x8009944
080045fa  mov        r6, r0
080045fc  cbz        r6, #0x8004604
080045fe  mov.w      sb, #5
08004602  b          #0x8004642
08004604  adds       r0, r5, #4
08004606  uxth       r5, r0
08004608  cmp        r5, #0x10
0800460a  blt        #0x80045ea
0800460c  b          #0x8004638
0800460e  movs       r5, #0
08004610  b          #0x8004634
08004612  ldr        r2, [pc, #0x3c] ; literal[0x8004650]=0x807b000
08004614  add.w      r2, r2, r4, lsl #4
08004618  ldr        r1, [r2, r5]
0800461a  ldr        r2, [pc, #0x34] ; literal[0x8004650]=0x807b000
0800461c  add.w      r2, r2, r4, lsl #4
08004620  adds       r0, r2, r5
08004622  bl         #0x8009944
08004626  mov        r6, r0
08004628  cbz        r6, #0x8004630
0800462a  mov.w      sb, #6
0800462e  b          #0x8004642
08004630  adds       r0, r5, #4
08004632  uxth       r5, r0
08004634  cmp        r5, #0x10
08004636  blt        #0x8004612
08004638  adds       r0, r4, #1
0800463a  uxth       r4, r0
0800463c  cmp        r4, #2
0800463e  blt        #0x80045e2
08004640  nop        
08004642  bl         #0x80097e8
08004646  cpsie      i
08004648  mov        r0, sb
0800464a  b          #0x8004582
0800464c  .byte      0x00, 0xb8
0800464e  lsrs       r7, r0, #0x20
08004650  add        sp, #0
08004652  lsrs       r7, r0, #0x20
08004654  push.w     {r4, r5, r6, r7, r8, lr}
08004658  movs       r6, #0
0800465a  movs       r5, #0
0800465c  movs       r7, #0
0800465e  cpsid      i
08004660  bl         #0x8009900
08004664  movw       r0, #0x307
08004668  bl         #0x8009708
0800466c  ldr        r0, [pc, #0x3c] ; literal[0x80046ac]=0x807a800
0800466e  bl         #0x8009814
08004672  mov        r6, r0
08004674  cbz        r6, #0x800467a
08004676  movs       r7, #1
08004678  b          #0x80046a0
0800467a  ldr        r4, [pc, #0x30] ; literal[0x80046ac]=0x807a800
0800467c  movs       r5, #0
0800467e  b          #0x800469a
08004680  ldr        r0, [pc, #0x2c] ; literal[0x80046b0]=0x2000090c
08004682  ldr.w      r1, [r0, r5, lsl #2]
08004686  mov        r0, r4
08004688  bl         #0x8009944
0800468c  mov        r6, r0
0800468e  cbz        r6, #0x8004694
08004690  movs       r7, #2
08004692  b          #0x80046a0
08004694  adds       r4, r4, #4
08004696  adds       r0, r5, #1
08004698  uxth       r5, r0
0800469a  cmp        r5, #0xa
0800469c  blt        #0x8004680
0800469e  nop        
080046a0  bl         #0x80097e8
080046a4  cpsie      i
080046a6  mov        r0, r7
080046a8  pop.w      {r4, r5, r6, r7, r8, pc}
080046ac  add        r0, sp, #0
080046ae  lsrs       r7, r0, #0x20
080046b0  lsrs       r4, r1, #4

; factory six-word record write
0801332c  push.w     {r4, r5, r6, r7, r8, lr}
08013330  ldr        r0, [pc, #0xc8] ; literal[0x80133fc]=0x20001a3c
08013332  ldrb       r4, [r0, #0xe]
08013334  ldrb       r0, [r0, #0xd]
08013336  add.w      r0, r0, r4, lsl #8
0801333a  uxth       r1, r0
0801333c  ldr        r0, [pc, #0xc0] ; literal[0x8013400]=0x20001b0c
0801333e  strh       r1, [r0, #0x16]
08013340  ldr        r0, [pc, #0xb8] ; literal[0x80133fc]=0x20001a3c
08013342  ldrb       r4, [r0, #0x10]
08013344  ldrb       r0, [r0, #0xf]
08013346  add.w      r0, r0, r4, lsl #8
0801334a  uxth       r1, r0
0801334c  ldr        r0, [pc, #0xb0] ; literal[0x8013400]=0x20001b0c
0801334e  strh       r1, [r0, #0x18]
08013350  ldr        r0, [pc, #0xa8] ; literal[0x80133fc]=0x20001a3c
08013352  ldrb       r4, [r0, #0x12]
08013354  ldrb       r0, [r0, #0x11]
08013356  add.w      r0, r0, r4, lsl #8
0801335a  uxth       r1, r0
0801335c  ldr        r0, [pc, #0xa0] ; literal[0x8013400]=0x20001b0c
0801335e  strh       r1, [r0, #0x1a]
08013360  movs       r7, #0
08013362  ldr        r6, [pc, #0xa0] ; literal[0x8013404]=0x807d000
08013364  cpsid      i
08013366  bl         #0x8009900
0801336a  movw       r0, #0x307
0801336e  bl         #0x8009708
08013372  ldr        r0, [pc, #0x90] ; literal[0x8013404]=0x807d000
08013374  bl         #0x8009814
08013378  mov        r7, r0
0801337a  movs       r5, #0
0801337c  b          #0x8013394
0801337e  ldr        r0, [pc, #0x80] ; literal[0x8013400]=0x20001b0c
08013380  adds       r0, #0x10
08013382  ldrh.w     r1, [r0, r5, lsl #1]
08013386  mov        r0, r6
08013388  bl         #0x8009728
0801338c  mov        r7, r0
0801338e  adds       r6, r6, #2
08013390  adds       r0, r5, #1
08013392  uxtb       r5, r0
08013394  cmp        r5, #6
08013396  blt        #0x801337e
08013398  bl         #0x80097e8
0801339c  cpsie      i
0801339e  ldr        r0, [pc, #0x68] ; literal[0x8013408]=0x20000022
080133a0  ldrb       r1, [r0]
080133a2  ldr        r0, [pc, #0x68] ; literal[0x801340c]=0x2000000c
080133a4  ldr        r0, [r0, #4]
080133a6  bfi        r0, r1, #0, #8
080133aa  ldr        r1, [pc, #0x60] ; literal[0x801340c]=0x2000000c
080133ac  str        r0, [r1, #4]
080133ae  mov        r0, r1
080133b0  ldrb       r0, [r0, #7]
080133b2  bic        r0, r0, #0x1f
080133b6  adds       r0, r0, #2
080133b8  strb       r0, [r1, #7]
080133ba  ldr        r0, [pc, #0x54] ; literal[0x8013410]=0x200008d8
080133bc  ldrb       r0, [r0]
080133be  ldr        r1, [pc, #0x54] ; literal[0x8013414]=0x20000020
080133c0  ldrb       r1, [r1]
080133c2  orr.w      r1, r1, r0, lsl #8
080133c6  ldr        r0, [pc, #0x44] ; literal[0x801340c]=0x2000000c
080133c8  ldr        r0, [r0, #4]
080133ca  bfi        r0, r1, #8, #0x10
080133ce  ldr        r1, [pc, #0x3c] ; literal[0x801340c]=0x2000000c
080133d0  str        r0, [r1, #4]
080133d2  movs       r0, #8
080133d4  strb       r0, [r1, #0xa]
080133d6  movs       r0, #0
080133d8  strb       r0, [r1, #0xb]
080133da  movs       r1, #0xa2
080133dc  ldr        r0, [pc, #0x2c] ; literal[0x801340c]=0x2000000c
080133de  strb       r1, [r0, #0xc]
080133e0  adds       r0, r0, #5
080133e2  ldr        r1, [pc, #0x18] ; literal[0x80133fc]=0x20001a3c
080133e4  adds       r1, r1, #5
080133e6  ldr        r2, [r1, #8]
080133e8  str        r2, [r0, #8]
080133ea  ldrh       r1, [r1, #0xc]
080133ec  strh       r1, [r0, #0xc]
080133ee  subs       r1, r0, #5
080133f0  ldr        r0, [pc, #0x24] ; literal[0x8013418]=0x40006400
080133f2  bl         #0x8008334
080133f6  pop.w      {r4, r5, r6, r7, r8, pc}
080133fa  movs       r0, r0
080133fc  subs       r4, r7, r0
080133fe  movs       r0, #0
08013400  subs       r4, r1, r4
08013402  movs       r0, #0
08013404  beq        #0x8013408
08013406  lsrs       r7, r0, #0x20
08013408  movs       r2, r4
0801340a  movs       r0, #0
0801340c  movs       r4, r1
0801340e  movs       r0, #0
08013410  lsrs       r0, r3, #3
