; Static inspection of official EL05 application images, base 0x08002000.
; Analyst labels. Literal pools are data; zero assignments are conditional paths,
; not a claim that each instruction is executed on every boot.

; EL05_1.0.5.0.1.bin: conditional rotation clear path
08002cb0  strb       r0, [r1]
08002cb2  b          #0x8003022
08002cb4  ldr        r0, [pc, #0x3b8] ; literal[0x8003070]=0x200008b4
08002cb6  ldrb       r0, [r0]
08002cb8  cbnz       r0, #0x8002cd0
08002cba  movs       r0, #1
08002cbc  ldr        r1, [pc, #0x3b0] ; literal[0x8003070]=0x200008b4
08002cbe  strb       r0, [r1]
08002cc0  ldr        r1, [pc, #0x3b0] ; literal[0x8003074]=0x200008b5
08002cc2  strb       r0, [r1]
08002cc4  movs       r0, #0
08002cc6  ldr        r1, [pc, #0x3b0] ; literal[0x8003078]=0x200001dc
08002cc8  str.w      r0, [r1, #0x14c]
08002ccc  strb.w     r0, [r1, #0x354]
08002cd0  b          #0x800295a

; EL05_1.0.5.0.2.bin: conditional rotation clear path
08002cc0  strb       r0, [r1]
08002cc2  b          #0x8002f0e
08002cc4  ldr        r0, [pc, #0x368] ; literal[0x8003030]=0x200008b8
08002cc6  ldrb       r0, [r0]
08002cc8  cbnz       r0, #0x8002ce0
08002cca  movs       r0, #1
08002ccc  ldr        r1, [pc, #0x360] ; literal[0x8003030]=0x200008b8
08002cce  strb       r0, [r1]
08002cd0  ldr        r1, [pc, #0x360] ; literal[0x8003034]=0x200008b9
08002cd2  strb       r0, [r1]
08002cd4  movs       r0, #0
08002cd6  ldr        r1, [pc, #0x360] ; literal[0x8003038]=0x200001dc
08002cd8  str.w      r0, [r1, #0x14c]
08002cdc  strb.w     r0, [r1, #0x354]
08002ce0  b          #0x800296a

; EL05_1.0.5.0.4.bin: conditional rotation clear path
08002e28  strb       r0, [r1]
08002e2a  b          #0x800319e
08002e2c  ldr        r0, [pc, #0x234] ; literal[0x8003064]=0x200012f8
08002e2e  ldrb       r0, [r0]
08002e30  cbnz       r0, #0x8002e48
08002e32  movs       r0, #1
08002e34  ldr        r1, [pc, #0x22c] ; literal[0x8003064]=0x200012f8
08002e36  strb       r0, [r1]
08002e38  ldr        r1, [pc, #0x230] ; literal[0x800306c]=0x200012f9
08002e3a  strb       r0, [r1]
08002e3c  movs       r0, #0
08002e3e  ldr        r1, [pc, #0x234] ; literal[0x8003074]=0x200001f0
08002e40  str.w      r0, [r1, #0x14c]
08002e44  strb.w     r0, [r1, #0x354]
08002e48  movs       r0, #0

; el05_1.0.5.0.6.bin: conditional rotation clear path
08002f4a  strb       r0, [r1]
08002f4c  b          #0x8003314
08002f4e  ldr        r0, [pc, #0x138] ; literal[0x8003088]=0x20001414
08002f50  ldrb       r0, [r0]
08002f52  cbnz       r0, #0x8002f6a
08002f54  movs       r0, #1
08002f56  ldr        r1, [pc, #0x130] ; literal[0x8003088]=0x20001414
08002f58  strb       r0, [r1]
08002f5a  ldr        r1, [pc, #0x134] ; literal[0x8003090]=0x20001415
08002f5c  strb       r0, [r1]
08002f5e  movs       r0, #0
08002f60  ldr        r1, [pc, #0x140] ; literal[0x80030a4]=0x2000020c
08002f62  str.w      r0, [r1, #0x144]
08002f66  strb.w     r0, [r1, #0x34c]
08002f6a  movs       r0, #0

; Latest EL05 1.0.5.0.6: mech_angle_rotations initialization clear
08003da8  push       {r4, lr}
08003daa  bl         #0x8010df8
08003dae  ldr        r0, [pc, #0xa0] ; literal[0x8003e50]=0x2000020c
08003db0  vldr       s0, [r0, #0xf0]
08003db4  vstr       s0, [r0, #0xec]
08003db8  movs       r0, #0
08003dba  ldr        r1, [pc, #0x94] ; literal[0x8003e50]=0x2000020c
08003dbc  str.w      r0, [r1, #0xf8]
08003dc0  bl         #0x8010df8
08003dc4  ldr        r0, [pc, #0x88] ; literal[0x8003e50]=0x2000020c
08003dc6  vldr       s0, [r0, #0xf0]
08003dca  vstr       s0, [r0, #0xec]
08003dce  movs       r0, #0
08003dd0  ldr        r1, [pc, #0x7c] ; literal[0x8003e50]=0x2000020c
08003dd2  str.w      r0, [r1, #0xf8]
08003dd6  bl         #0x8010df8
08003dda  ldr        r0, [pc, #0x74] ; literal[0x8003e50]=0x2000020c
08003ddc  vldr       s0, [r0, #0xf0]
08003de0  vstr       s0, [r0, #0xec]
08003de4  movs       r0, #0
08003de6  ldr        r1, [pc, #0x68] ; literal[0x8003e50]=0x2000020c
08003de8  str.w      r0, [r1, #0xf8]
08003dec  bl         #0x8003e54
08003df0  ldr        r0, [pc, #0x5c] ; literal[0x8003e50]=0x2000020c
08003df2  vldr       s0, [r0, #0x18]
08003df6  vstr       s0, [r0, #0x104]
08003dfa  movs       r0, #0
08003dfc  ldr        r1, [pc, #0x50] ; literal[0x8003e50]=0x2000020c
08003dfe  str.w      r0, [r1, #0x114]
08003e02  bl         #0x8003e54
08003e06  ldr        r0, [pc, #0x48] ; literal[0x8003e50]=0x2000020c
08003e08  vldr       s0, [r0, #0x18]
08003e0c  vstr       s0, [r0, #0x104]
08003e10  movs       r0, #0
08003e12  ldr        r1, [pc, #0x3c] ; literal[0x8003e50]=0x2000020c
08003e14  str.w      r0, [r1, #0x114]
08003e18  bl         #0x8003e54
08003e1c  bl         #0x8010df8
08003e20  ldr        r0, [pc, #0x2c] ; literal[0x8003e50]=0x2000020c
08003e22  vldr       s0, [r0, #0xf0]
08003e26  vstr       s0, [r0, #0xec]
08003e2a  movs       r0, #0
08003e2c  ldr        r1, [pc, #0x20] ; literal[0x8003e50]=0x2000020c
08003e2e  str.w      r0, [r1, #0xf8]
08003e32  bl         #0x8010df8
08003e36  ldr        r0, [pc, #0x18] ; literal[0x8003e50]=0x2000020c
08003e38  vldr       s0, [r0, #0xf0]
08003e3c  vstr       s0, [r0, #0xec]
08003e40  movs       r0, #0
08003e42  ldr        r1, [pc, #0xc] ; literal[0x8003e50]=0x2000020c
08003e44  str.w      r0, [r1, #0xf8]
08003e48  bl         #0x8010df8
08003e4c  pop        {r4, pc}
08003e4e  movs       r0, r0
08003e50  lsls       r4, r1, #8

; Latest EL05 1.0.5.0.6: additional nonvolatile block load
080045da  movs       r2, #0x28
080045dc  ldr        r1, [pc, #0x1a0] ; literal[0x8004780]=0x807a800
080045de  ldr        r0, [pc, #0x170] ; literal[0x8004750]=0x20001480
080045e0  adds       r0, #0x88
080045e2  bl         #0x8002422
080045e6  movs       r0, #0
080045e8  b          #0x8004604
080045ea  ldr        r1, [pc, #0x164] ; literal[0x8004750]=0x20001480
080045ec  adds       r1, #0x88
080045ee  ldr.w      r1, [r1, r0, lsl #2]
080045f2  adds       r1, r1, #1
080045f4  cbnz       r1, #0x8004600
080045f6  movs       r2, #0
080045f8  ldr        r1, [pc, #0x154] ; literal[0x8004750]=0x20001480
080045fa  adds       r1, #0x88
080045fc  str.w      r2, [r1, r0, lsl #2]
08004600  adds       r1, r0, #1
08004602  uxtb       r0, r1
08004604  cmp        r0, #0xa
08004606  blt        #0x80045ea
08004608  ldr        r0, [pc, #0x178] ; literal[0x8004784]=0x200026bc
0800460a  ldrb       r0, [r0, #8]
0800460c  ldr        r1, [pc, #0x174] ; literal[0x8004784]=0x200026bc
0800460e  strb       r0, [r1, #6]
08004610  ldr        r0, [pc, #0x174] ; literal[0x8004788]=0x200012f4
08004612  ldr        r2, [pc, #0x178] ; literal[0x800478c]=0x807a000
08004614  ldm        r2, {r1, r2}
08004616  strd       r1, r2, [r0, #8]
0800461a  movs       r0, #0
0800461c  b          #0x8004638
0800461e  ldr        r1, [pc, #0x168] ; literal[0x8004788]=0x200012f4
08004620  adds       r1, #8
08004622  ldr.w      r1, [r1, r0, lsl #2]
08004626  adds       r1, r1, #1
08004628  cbnz       r1, #0x8004634
0800462a  movs       r2, #0
0800462c  ldr        r1, [pc, #0x158] ; literal[0x8004788]=0x200012f4
0800462e  adds       r1, #8
08004630  str.w      r2, [r1, r0, lsl #2]
08004634  adds       r1, r0, #1
08004636  uxtb       r0, r1
08004638  cmp        r0, #2
0800463a  blt        #0x800461e
0800463c  ldr        r4, [pc, #0x14c] ; literal[0x800478c]=0x807a000
0800463e  adds       r4, #8
08004640  ldr        r0, [pc, #0x144] ; literal[0x8004788]=0x200012f4
08004642  subs       r0, #0x80
08004644  ldr        r1, [r4]
08004646  str        r1, [r0, #0x78]
08004648  ldr        r1, [r4, #4]
0800464a  str        r1, [r0, #0x7c]
0800464c  sub.w      r0, r0, #0xd00
08004650  ldr.w      r0, [r0, #0xd78]
08004654  adds       r0, r0, #1
08004656  cbz        r0, #0x8004660
08004658  ldr        r0, [pc, #0x134] ; literal[0x8004790]=0x20000574
0800465a  ldr        r1, [r4]
0800465c  str.w      r1, [r0, #0xd5c]
08004660  adds       r4, r4, #4
08004662  ldr        r0, [pc, #0x12c] ; literal[0x8004790]=0x20000574
08004664  ldr.w      r0, [r0, #0xd7c]
08004668  adds       r0, r0, #1
0800466a  cbz        r0, #0x8004674
0800466c  ldr        r0, [pc, #0x120] ; literal[0x8004790]=0x20000574
0800466e  ldr        r1, [r4]
08004670  str.w      r1, [r0, #0xd60]
08004674  adds       r4, r4, #4
08004676  ldr        r0, [pc, #0x110] ; literal[0x8004788]=0x200012f4
08004678  subs       r0, #0x80
0800467a  ldr        r1, [r4]
0800467c  str        r1, [r0, #0x78]
0800467e  ldr        r1, [r4, #4]
08004680  str        r1, [r0, #0x7c]
08004682  ldr        r0, [pc, #0x10c] ; literal[0x8004790]=0x20000574
08004684  ldr.w      r0, [r0, #0xd78]
08004688  adds       r0, r0, #1
0800468a  cbz        r0, #0x8004694
0800468c  ldr        r0, [pc, #0x100] ; literal[0x8004790]=0x20000574
0800468e  ldrb       r1, [r4]
08004690  strb.w     r1, [r0, #0xd85]
08004694  adds       r4, r4, #4
08004696  ldr        r0, [pc, #0xf8] ; literal[0x8004790]=0x20000574
08004698  ldr.w      r0, [r0, #0xd7c]
0800469c  adds       r0, r0, #1
0800469e  cbz        r0, #0x80046a8
080046a0  ldr        r0, [pc, #0xec] ; literal[0x8004790]=0x20000574
080046a2  ldr        r1, [r4]
080046a4  str.w      r1, [r0, #0xd64]
080046a8  adds       r4, r4, #4
080046aa  ldr        r0, [pc, #0xdc] ; literal[0x8004788]=0x200012f4
080046ac  subs       r0, #0x80
080046ae  ldr        r1, [r4]
080046b0  str        r1, [r0, #0x78]
080046b2  ldr        r1, [r4, #4]
080046b4  str        r1, [r0, #0x7c]
080046b6  ldr        r0, [pc, #0xd8] ; literal[0x8004790]=0x20000574
080046b8  ldr.w      r0, [r0, #0xd78]
080046bc  adds       r0, r0, #1
080046be  cbz        r0, #0x80046c8
080046c0  ldr        r0, [pc, #0xb0] ; literal[0x8004774]=0x2000020c
080046c2  ldr        r1, [r4]
080046c4  str.w      r1, [r0, #0x120]
080046c8  ldr        r4, [pc, #0xc8] ; literal[0x8004794]=0x8079800
080046ca  ldr        r0, [pc, #0xc4] ; literal[0x8004790]=0x20000574
080046cc  ldr        r1, [r4]
080046ce  str.w      r1, [r0, #0xd78]
080046d2  ldr        r4, [pc, #0xc4] ; literal[0x8004798]=0x8079000
080046d4  ldr        r1, [r4]
080046d6  str.w      r1, [r0, #0xd7c]
080046da  ldr.w      r0, [r0, #0xd78]
080046de  adds       r0, r0, #1
080046e0  cbz        r0, #0x80046ec
080046e2  ldr        r0, [pc, #0xac] ; literal[0x8004790]=0x20000574
080046e4  ldr.w      r0, [r0, #0xd7c]
080046e8  adds       r0, r0, #1
080046ea  cbnz       r0, #0x8004700
080046ec  vldr       s0, [pc, #0xac] ; literal[0x800479c]=0x0
080046f0  ldr        r0, [pc, #0x9c] ; literal[0x8004790]=0x20000574
080046f2  vstr       s0, [r0, #0x2e0]
080046f6  vldr       s0, [pc, #0xa4] ; literal[0x800479c]=0x0
080046fa  vstr       s0, [r0, #0x2e4]
080046fe  b          #0x800471c
08004700  ldr        r4, [pc, #0x90] ; literal[0x8004794]=0x8079800
08004702  mov.w      r2, #0x640
08004706  mov        r1, r4
08004708  ldr        r0, [pc, #0x94] ; literal[0x80047a0]=0x20000854
0800470a  bl         #0x8002398
0800470e  ldr        r4, [pc, #0x88] ; literal[0x8004798]=0x8079000
08004710  mov.w      r2, #0x3ac
08004714  mov        r1, r4
08004716  ldr        r0, [pc, #0x8c] ; literal[0x80047a4]=0x20000e94
08004718  bl         #0x8002398
0800471c  ldr        r4, [pc, #0x88] ; literal[0x80047a8]=0x8078800
0800471e  ldr        r0, [pc, #0x70] ; literal[0x8004790]=0x20000574
08004720  ldr        r1, [r4]
08004722  str.w      r1, [r0, #0xd78]
08004726  ldr.w      r0, [r0, #0xd78]
0800472a  adds       r0, r0, #1
0800472c  cbnz       r0, #0x8004738
0800472e  movs       r0, #1
08004730  ldr        r1, [pc, #0x1c] ; literal[0x8004750]=0x20001480
08004732  strb.w     r0, [r1, #0x7a]
08004736  b          #0x8004742
08004738  movs       r2, #0x78
0800473a  mov        r1, r4
0800473c  ldr        r0, [pc, #0x10] ; literal[0x8004750]=0x20001480
0800473e  bl         #0x8002398
08004742  mov        r0, r6
08004744  pop        {r1, r2, r3, r4, r5, r6, r7, pc}
08004746  movs       r0, r0
08004748  movs       r7, #8
0800474a  movs       r0, #0
0800474c  b          #0x8004750
0800474e  lsrs       r7, r0, #0x20
08004750  asrs       r0, r0, #0x12
08004752  movs       r0, #0
08004754  lsls       r2, r7, #4
08004756  movs       r0, #0
08004758  movs       r0, r0
0800475a  lsrs       r0, r1, #0x20
0800475c  strh       r0, [r6, #0x26]
0800475e  lsrs       r1, r0, #0x20
08004760  strh       r3, [r3, #0x26]
08004762  lsrs       r1, r0, #0x20
08004764  strh       r0, [r2, #0x26]
08004766  lsrs       r1, r0, #0x20
08004768  add        r5, sl
0800476a  movs       r2, #0x33
0800476c  bhi        #0x8004770
0800476e  lsrs       r7, r0, #0x20
08004770  lsls       r0, r3, #0xd
08004772  movs       r0, #0
08004774  lsls       r4, r1, #8
08004776  movs       r0, #0
08004778  bgt        #0x800477c
0800477a  lsrs       r7, r0, #0x20
0800477c  asrs       r0, r6, #0x11
0800477e  movs       r0, #0
08004780  add        r0, sp, #0
08004782  lsrs       r7, r0, #0x20
08004784  movs       r6, #0xbc
08004786  movs       r0, #0
08004788  asrs       r4, r6, #0xb
0800478a  movs       r0, #0
0800478c  adr        r0, #0
0800478e  lsrs       r7, r0, #0x20
08004790  lsls       r4, r6, #0x15
08004792  movs       r0, #0
08004794  ldr        r0, [sp]
08004796  lsrs       r7, r0, #0x20
08004798  str        r0, [sp]
0800479a  lsrs       r7, r0, #0x20
0800479c  movs       r0, r0
0800479e  movs       r0, r0
080047a0  lsrs       r4, r2, #1
080047a2  movs       r0, #0
080047a4  lsrs       r4, r2, #0x1a
080047a6  movs       r0, #0
080047a8  ldrh       r0, [r0]

; Latest EL05 1.0.5.0.6: additional block writes
08004df8  push.w     {r4, r5, r6, r7, r8, lr}
08004dfc  movs       r6, #0
08004dfe  movs       r5, #0
08004e00  mov        r8, r5
08004e02  cpsid      i
08004e04  bl         #0x800ab9c
08004e08  movw       r0, #0x307
08004e0c  bl         #0x800a9a4
08004e10  ldr        r0, [pc, #0x44] ; literal[0x8004e58]=0x8079800
08004e12  bl         #0x800aab0
08004e16  mov        r6, r0
08004e18  cbz        r6, #0x8004e20
08004e1a  mov.w      r8, #1
08004e1e  b          #0x8004e4c
08004e20  ldr        r4, [pc, #0x34] ; literal[0x8004e58]=0x8079800
08004e22  movs       r5, #0
08004e24  b          #0x8004e44
08004e26  ldr        r0, [pc, #0x34] ; literal[0x8004e5c]=0x20000854
08004e28  ldr.w      r7, [r0, r5, lsl #2]
08004e2c  mov        r1, r7
08004e2e  mov        r0, r4
08004e30  bl         #0x800abe0
08004e34  mov        r6, r0
08004e36  cbz        r6, #0x8004e3e
08004e38  mov.w      r8, #2
08004e3c  b          #0x8004e4c
08004e3e  adds       r4, r4, #4
08004e40  adds       r0, r5, #1
08004e42  uxth       r5, r0
08004e44  cmp.w      r5, #0x190
08004e48  blt        #0x8004e26
08004e4a  nop        
08004e4c  bl         #0x800aa84
08004e50  cpsie      i
08004e52  mov        r0, r8
08004e54  pop.w      {r4, r5, r6, r7, r8, pc}
08004e58  ldr        r0, [sp]
08004e5a  lsrs       r7, r0, #0x20
08004e5c  lsrs       r4, r2, #1
08004e5e  movs       r0, #0
08004e60  push.w     {r4, r5, r6, r7, r8, lr}
08004e64  movs       r6, #0
08004e66  movs       r5, #0
08004e68  mov        r8, r5
08004e6a  cpsid      i
08004e6c  bl         #0x800ab9c
08004e70  movw       r0, #0x307
08004e74  bl         #0x800a9a4
08004e78  ldr        r0, [pc, #0x48] ; literal[0x8004ec4]=0x8079000
08004e7a  bl         #0x800aab0
08004e7e  mov        r6, r0
08004e80  cbz        r6, #0x8004e88
08004e82  mov.w      r8, #1
08004e86  b          #0x8004eb8
08004e88  ldr        r4, [pc, #0x38] ; literal[0x8004ec4]=0x8079000
08004e8a  mov.w      r5, #0x190
08004e8e  b          #0x8004eae
08004e90  ldr        r0, [pc, #0x34] ; literal[0x8004ec8]=0x20000854
08004e92  ldr.w      r7, [r0, r5, lsl #2]
08004e96  mov        r1, r7
08004e98  mov        r0, r4
08004e9a  bl         #0x800abe0
08004e9e  mov        r6, r0
08004ea0  cbz        r6, #0x8004ea8
08004ea2  mov.w      r8, #2
08004ea6  b          #0x8004eb8
08004ea8  adds       r4, r4, #4
08004eaa  adds       r0, r5, #1
08004eac  uxth       r5, r0
08004eae  movw       r0, #0x27b
08004eb2  cmp        r5, r0
08004eb4  blt        #0x8004e90
08004eb6  nop        
08004eb8  bl         #0x800aa84
08004ebc  cpsie      i
08004ebe  mov        r0, r8
08004ec0  pop.w      {r4, r5, r6, r7, r8, pc}
08004ec4  str        r0, [sp]
08004ec6  lsrs       r7, r0, #0x20
08004ec8  lsrs       r4, r2, #1
08004eca  movs       r0, #0
08004ecc  push.w     {r4, r5, r6, r7, r8, lr}
08004ed0  movs       r6, #0
08004ed2  movs       r5, #0
08004ed4  movs       r7, #0
08004ed6  cpsid      i
08004ed8  bl         #0x800ab9c
08004edc  movw       r0, #0x307
08004ee0  bl         #0x800a9a4
08004ee4  ldr        r0, [pc, #0x3c] ; literal[0x8004f24]=0x807a800
08004ee6  bl         #0x800aab0
08004eea  mov        r6, r0
08004eec  cbz        r6, #0x8004ef2
08004eee  movs       r7, #1
08004ef0  b          #0x8004f18
08004ef2  ldr        r4, [pc, #0x30] ; literal[0x8004f24]=0x807a800
08004ef4  movs       r5, #0
08004ef6  b          #0x8004f12
08004ef8  ldr        r0, [pc, #0x2c] ; literal[0x8004f28]=0x20001508
08004efa  ldr.w      r1, [r0, r5, lsl #2]
08004efe  mov        r0, r4
08004f00  bl         #0x800abe0
08004f04  mov        r6, r0
08004f06  cbz        r6, #0x8004f0c
08004f08  movs       r7, #2
08004f0a  b          #0x8004f18
08004f0c  adds       r4, r4, #4
08004f0e  adds       r0, r5, #1
08004f10  uxth       r5, r0
08004f12  cmp        r5, #0xa
08004f14  blt        #0x8004ef8
08004f16  nop        
08004f18  bl         #0x800aa84
08004f1c  cpsie      i
08004f1e  mov        r0, r7
08004f20  pop.w      {r4, r5, r6, r7, r8, pc}
08004f24  add        r0, sp, #0
08004f26  lsrs       r7, r0, #0x20
08004f28  asrs       r0, r1, #0x14
08004f2a  movs       r0, #0
08004f2c  push.w     {r4, r5, r6, r7, r8, lr}
08004f30  movs       r4, #0
08004f32  movs       r6, #0
08004f34  mov        r8, r4
08004f36  cpsid      i
08004f38  bl         #0x800ab9c
08004f3c  movw       r0, #0x307
08004f40  bl         #0x800a9a4
08004f44  ldr        r0, [pc, #0xc0] ; literal[0x8005008]=0x807a000
08004f46  bl         #0x800aab0
08004f4a  mov        r4, r0
08004f4c  cbz        r4, #0x8004f54
08004f4e  mov.w      r8, #1
08004f52  b          #0x8004ffc
08004f54  ldr        r5, [pc, #0xb0] ; literal[0x8005008]=0x807a000
08004f56  movs       r6, #0
08004f58  b          #0x8004f76
08004f5a  ldr        r0, [pc, #0xb0] ; literal[0x800500c]=0x200012fc
08004f5c  ldr.w      r1, [r0, r6, lsl #2]
08004f60  mov        r0, r5
08004f62  bl         #0x800abe0
08004f66  mov        r4, r0
08004f68  cbz        r4, #0x8004f70
08004f6a  mov.w      r8, #2
08004f6e  b          #0x8004ffc
08004f70  adds       r5, r5, #4
08004f72  adds       r0, r6, #1
08004f74  uxth       r6, r0
08004f76  cmp        r6, #2
08004f78  blt        #0x8004f5a
08004f7a  ldr        r0, [pc, #0x94] ; literal[0x8005010]=0x20000574
08004f7c  ldr.w      r7, [r0, #0xd5c]
08004f80  mov        r1, r7
08004f82  mov        r0, r5
08004f84  bl         #0x800abe0
08004f88  mov        r4, r0
08004f8a  cbz        r4, #0x8004f92
08004f8c  mov.w      r8, #2
08004f90  b          #0x8004ffc
08004f92  adds       r5, r5, #4
08004f94  ldr        r0, [pc, #0x78] ; literal[0x8005010]=0x20000574
08004f96  ldr.w      r7, [r0, #0xd60]
08004f9a  mov        r1, r7
08004f9c  mov        r0, r5
08004f9e  bl         #0x800abe0
08004fa2  mov        r4, r0
08004fa4  cbz        r4, #0x8004fac
08004fa6  mov.w      r8, #2
08004faa  b          #0x8004ffc
08004fac  adds       r5, r5, #4
08004fae  ldr        r0, [pc, #0x60] ; literal[0x8005010]=0x20000574
08004fb0  ldr.w      r7, [r0, #0xd85]
08004fb4  mov        r1, r7
08004fb6  mov        r0, r5
08004fb8  bl         #0x800abe0
08004fbc  mov        r4, r0
08004fbe  cbz        r4, #0x8004fc6
08004fc0  mov.w      r8, #2
08004fc4  b          #0x8004ffc
08004fc6  adds       r5, r5, #4
08004fc8  ldr        r0, [pc, #0x44] ; literal[0x8005010]=0x20000574
08004fca  ldr.w      r7, [r0, #0xd64]
08004fce  mov        r1, r7
08004fd0  mov        r0, r5
08004fd2  bl         #0x800abe0
08004fd6  mov        r4, r0
08004fd8  cbz        r4, #0x8004fe0
08004fda  mov.w      r8, #2
08004fde  b          #0x8004ffc
08004fe0  adds       r5, r5, #4
08004fe2  ldr        r0, [pc, #0x30] ; literal[0x8005014]=0x2000020c
08004fe4  ldr.w      r7, [r0, #0x120]
08004fe8  mov        r1, r7
08004fea  mov        r0, r5
08004fec  bl         #0x800abe0
08004ff0  mov        r4, r0
08004ff2  cbz        r4, #0x8004ffa
08004ff4  mov.w      r8, #2
08004ff8  b          #0x8004ffc
08004ffa  nop        
08004ffc  bl         #0x800aa84
08005000  cpsie      i
08005002  mov        r0, r8
08005004  pop.w      {r4, r5, r6, r7, r8, pc}
08005008  adr        r0, #0
0800500a  lsrs       r7, r0, #0x20
0800500c  asrs       r4, r7, #0xb
0800500e  movs       r0, #0
08005010  lsls       r4, r6, #0x15
08005012  movs       r0, #0
08005014  lsls       r4, r1, #8

; Latest EL05 1.0.5.0.6: parameter backup image construction and write
08005018  push.w     {r4, r5, r6, r7, r8, lr}
0800501c  ldr        r0, [pc, #0x1bc] ; literal[0x80051dc]=0x2000020c
0800501e  vldr       s0, [r0, #0x20]
08005022  ldr        r0, [pc, #0x1bc] ; literal[0x80051e0]=0x20001480
08005024  vstr       s0, [r0]
08005028  ldr        r0, [pc, #0x1b0] ; literal[0x80051dc]=0x2000020c
0800502a  vldr       s0, [r0, #0xe0]
0800502e  ldr        r0, [pc, #0x1b0] ; literal[0x80051e0]=0x20001480
08005030  vstr       s0, [r0, #4]
08005034  ldr        r0, [pc, #0x1ac] ; literal[0x80051e4]=0x2000002c
08005036  ldrb       r0, [r0]
08005038  vmov       s0, r0
0800503c  vcvt.f32.u32 s0, s0
08005040  ldr        r0, [pc, #0x19c] ; literal[0x80051e0]=0x20001480
08005042  vstr       s0, [r0, #8]
08005046  ldr        r0, [pc, #0x1a0] ; literal[0x80051e8]=0x20001471
08005048  ldrb       r0, [r0]
0800504a  vmov       s0, r0
0800504e  vcvt.f32.u32 s0, s0
08005052  ldr        r0, [pc, #0x18c] ; literal[0x80051e0]=0x20001480
08005054  vstr       s0, [r0, #0xc]
08005058  ldr        r0, [pc, #0x190] ; literal[0x80051ec]=0x20001474
0800505a  vldr       s0, [r0]
0800505e  vcvt.f32.u32 s0, s0
08005062  ldr        r0, [pc, #0x17c] ; literal[0x80051e0]=0x20001480
08005064  vstr       s0, [r0, #0x10]
08005068  ldr        r0, [pc, #0x184] ; literal[0x80051f0]=0x20000574
0800506a  vldr       s0, [r0, #0x6c]
0800506e  ldr        r0, [pc, #0x170] ; literal[0x80051e0]=0x20001480
08005070  vstr       s0, [r0, #0x14]
08005074  ldr        r0, [pc, #0x178] ; literal[0x80051f0]=0x20000574
08005076  vldr       s0, [r0, #0x64]
0800507a  ldr        r0, [pc, #0x164] ; literal[0x80051e0]=0x20001480
0800507c  vstr       s0, [r0, #0x18]
08005080  ldr        r0, [pc, #0x16c] ; literal[0x80051f0]=0x20000574
08005082  vldr       s0, [r0, #0x68]
08005086  ldr        r0, [pc, #0x158] ; literal[0x80051e0]=0x20001480
08005088  vstr       s0, [r0, #0x1c]
0800508c  ldr        r0, [pc, #0x164] ; literal[0x80051f4]=0x20001174
0800508e  vldr       s0, [r0, #0xf8]
08005092  ldr        r0, [pc, #0x14c] ; literal[0x80051e0]=0x20001480
08005094  vstr       s0, [r0, #0x20]
08005098  ldr        r0, [pc, #0x158] ; literal[0x80051f4]=0x20001174
0800509a  vldr       s0, [r0, #0xfc]
0800509e  ldr        r0, [pc, #0x140] ; literal[0x80051e0]=0x20001480
080050a0  vstr       s0, [r0, #0x24]
080050a4  ldr        r0, [pc, #0x14c] ; literal[0x80051f4]=0x20001174
080050a6  vldr       s0, [r0, #0x124]
080050aa  ldr        r0, [pc, #0x134] ; literal[0x80051e0]=0x20001480
080050ac  vstr       s0, [r0, #0x28]
080050b0  ldr        r0, [pc, #0x140] ; literal[0x80051f4]=0x20001174
080050b2  vldr       s0, [r0, #0x114]
080050b6  ldr        r0, [pc, #0x128] ; literal[0x80051e0]=0x20001480
080050b8  vstr       s0, [r0, #0x2c]
080050bc  ldr        r0, [pc, #0x134] ; literal[0x80051f4]=0x20001174
080050be  vldr       s0, [r0, #0x13c]
080050c2  ldr        r0, [pc, #0x11c] ; literal[0x80051e0]=0x20001480
080050c4  vstr       s0, [r0, #0x30]
080050c8  ldr        r0, [pc, #0x128] ; literal[0x80051f4]=0x20001174
080050ca  vldr       s0, [r0, #0x118]
080050ce  ldr        r0, [pc, #0x110] ; literal[0x80051e0]=0x20001480
080050d0  vstr       s0, [r0, #0x34]
080050d4  ldr        r0, [pc, #0x11c] ; literal[0x80051f4]=0x20001174
080050d6  vldr       s0, [r0, #0x140]
080050da  ldr        r0, [pc, #0x104] ; literal[0x80051e0]=0x20001480
080050dc  vstr       s0, [r0, #0x38]
080050e0  ldr        r0, [pc, #0x10c] ; literal[0x80051f0]=0x20000574
080050e2  ldrb.w     r0, [r0, #0xd84]
080050e6  vmov       s0, r0
080050ea  vcvt.f32.u32 s0, s0
080050ee  ldr        r0, [pc, #0xf0] ; literal[0x80051e0]=0x20001480
080050f0  vstr       s0, [r0, #0x3c]
080050f4  ldr        r0, [pc, #0xe4] ; literal[0x80051dc]=0x2000020c
080050f6  ldrb.w     r0, [r0, #0x358]
080050fa  vmov       s0, r0
080050fe  vcvt.f32.u32 s0, s0
08005102  ldr        r0, [pc, #0xdc] ; literal[0x80051e0]=0x20001480
08005104  vstr       s0, [r0, #0x40]
08005108  ldr        r0, [pc, #0xd0] ; literal[0x80051dc]=0x2000020c
0800510a  vldr       s0, [r0, #4]
0800510e  ldr        r0, [pc, #0xd0] ; literal[0x80051e0]=0x20001480
08005110  vstr       s0, [r0, #0x44]
08005114  ldr        r0, [pc, #0xe0] ; literal[0x80051f8]=0x200026bc
08005116  ldrb       r0, [r0, #8]
08005118  vmov       s0, r0
0800511c  vcvt.f32.u32 s0, s0
08005120  ldr        r0, [pc, #0xbc] ; literal[0x80051e0]=0x20001480
08005122  vstr       s0, [r0, #0x48]
08005126  ldrb.w     r0, [r0, #0x85]
0800512a  vmov       s0, r0
0800512e  vcvt.f32.u32 s0, s0
08005132  ldr        r0, [pc, #0xac] ; literal[0x80051e0]=0x20001480
08005134  vstr       s0, [r0, #0x4c]
08005138  ldr        r0, [pc, #0xa0] ; literal[0x80051dc]=0x2000020c
0800513a  vldr       s0, [r0, #0x350]
0800513e  ldr        r0, [pc, #0xa0] ; literal[0x80051e0]=0x20001480
08005140  vstr       s0, [r0, #0x50]
08005144  ldr        r0, [pc, #0xa8] ; literal[0x80051f0]=0x20000574
08005146  ldrb.w     r0, [r0, #0xd9c]
0800514a  vmov       s0, r0
0800514e  vcvt.f32.u32 s0, s0
08005152  ldr        r0, [pc, #0x8c] ; literal[0x80051e0]=0x20001480
08005154  vstr       s0, [r0, #0x54]
08005158  ldr        r0, [pc, #0x94] ; literal[0x80051f0]=0x20000574
0800515a  ldrb.w     r0, [r0, #0xd9f]
0800515e  vmov       s0, r0
08005162  vcvt.f32.u32 s0, s0
08005166  ldr        r0, [pc, #0x78] ; literal[0x80051e0]=0x20001480
08005168  vstr       s0, [r0, #0x58]
0800516c  ldr        r0, [pc, #0x8c] ; literal[0x80051fc]=0x20000150
0800516e  ldrb.w     r0, [r0, #0x7c]
08005172  vmov       s0, r0
08005176  vcvt.f32.u32 s0, s0
0800517a  ldr        r0, [pc, #0x64] ; literal[0x80051e0]=0x20001480
0800517c  vstr       s0, [r0, #0x5c]
08005180  movs       r6, #0
08005182  movs       r5, #0
08005184  mov        r8, r5
08005186  cpsid      i
08005188  bl         #0x800ab9c
0800518c  movw       r0, #0x307
08005190  bl         #0x800a9a4
08005194  ldr        r0, [pc, #0x68] ; literal[0x8005200]=0x8078800
08005196  bl         #0x800aab0
0800519a  mov        r6, r0
0800519c  cbz        r6, #0x80051a4
0800519e  mov.w      r8, #1
080051a2  b          #0x80051ce
080051a4  ldr        r4, [pc, #0x58] ; literal[0x8005200]=0x8078800
080051a6  movs       r5, #0
080051a8  b          #0x80051c8
080051aa  ldr        r0, [pc, #0x34] ; literal[0x80051e0]=0x20001480
080051ac  ldr.w      r7, [r0, r5, lsl #2]
080051b0  mov        r1, r7
080051b2  mov        r0, r4
080051b4  bl         #0x800abe0
080051b8  mov        r6, r0
080051ba  cbz        r6, #0x80051c2
080051bc  mov.w      r8, #2
080051c0  b          #0x80051ce
080051c2  adds       r4, r4, #4
080051c4  adds       r0, r5, #1
080051c6  uxth       r5, r0
080051c8  cmp        r5, #0x1e
080051ca  blt        #0x80051aa
080051cc  nop        
080051ce  bl         #0x800aa84
080051d2  cpsie      i
080051d4  mov        r0, r8
080051d6  pop.w      {r4, r5, r6, r7, r8, pc}
080051da  movs       r0, r0
080051dc  lsls       r4, r1, #8
080051de  movs       r0, #0
080051e0  asrs       r0, r0, #0x12
080051e2  movs       r0, #0
080051e4  movs       r4, r5
080051e6  movs       r0, #0
080051e8  asrs       r1, r6, #0x11
080051ea  movs       r0, #0
080051ec  asrs       r4, r6, #0x11
080051ee  movs       r0, #0
080051f0  lsls       r4, r6, #0x15
080051f2  movs       r0, #0
080051f4  asrs       r4, r6, #5
080051f6  movs       r0, #0
080051f8  movs       r6, #0xbc
080051fa  movs       r0, #0
080051fc  lsls       r0, r2, #5
080051fe  movs       r0, #0
08005200  ldrh       r0, [r0]
