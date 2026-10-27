; Static disassembly of official release files. Image base 0x08002000.
; Labels are analyst descriptions, not vendor symbol names.
; Inline data and literal pools must not be treated as executable code.

; V25.12.09/EL05_1.0.5.0.2: parameter flash load
08003e38  push       {r1, r2, r3, r4, r5, r6, r7, lr}
08003e3a  movs       r4, #0
08003e3c  movs       r6, #0
08003e3e  movs       r5, #0
08003e40  ldr        r0, [pc, #0x1ac] ; literal[0x8003ff0]=0x20001a78
08003e42  bl         #0x8009b54
08003e46  ldr        r2, [pc, #0x1ac] ; literal[0x8003ff4]=0x807e000
08003e48  ldrd       r1, r0, [r2]
08003e4c  ldr        r2, [r2, #8]
08003e4e  strd       r0, r2, [sp, #4]
08003e52  str        r1, [sp]
08003e54  ldrh.w     r0, [sp]
08003e58  movw       r1, #0xffff
08003e5c  cmp        r0, r1
08003e5e  bne        #0x8003e66
08003e60  orr        r5, r5, #1
08003e64  b          #0x8003f70
08003e66  movs       r4, #0xa
08003e68  b          #0x8003e76
08003e6a  ldr        r0, [pc, #0x188] ; literal[0x8003ff4]=0x807e000
08003e6c  ldrh       r6, [r4, r0]
08003e6e  cbz        r6, #0x8003e72
08003e70  b          #0x8003e7e
08003e72  adds       r0, r4, #2
08003e74  uxth       r4, r0
08003e76  ldrh.w     r0, [sp, #8]
08003e7a  cmp        r0, r4
08003e7c  bgt        #0x8003e6a
08003e7e  nop        
08003e80  sub.w      r0, r4, #0xa
08003e84  ubfx       r0, r0, #1, #0x10
08003e88  ldr        r1, [pc, #0x16c] ; literal[0x8003ff8]=0x20000128
08003e8a  strh       r0, [r1]
08003e8c  mov        r0, r1
08003e8e  ldrh       r0, [r0]
08003e90  cbnz       r0, #0x8003e98
08003e92  orr        r5, r5, #2
08003e96  b          #0x8003f70
08003e98  ldrh.w     r0, [sp, #8]
08003e9c  ldr        r1, [pc, #0x154] ; literal[0x8003ff4]=0x807e000
08003e9e  add        r1, r0
08003ea0  ldrh.w     r0, [sp, #4]
08003ea4  ldr        r2, [pc, #0x150] ; literal[0x8003ff8]=0x20000128
08003ea6  ldrh       r2, [r2]
08003ea8  mla        r7, r2, r0, r1
08003eac  ldr        r0, [pc, #0x14c] ; literal[0x8003ffc]=0x8080000
08003eae  cmp        r7, r0
08003eb0  blo        #0x8003eb8
08003eb2  orr        r5, r5, #4
08003eb6  b          #0x8003f70
08003eb8  ldrh.w     r0, [sp, #4]
08003ebc  subs       r7, r7, r0
08003ebe  ldrh.w     r0, [sp]
08003ec2  ldr        r1, [pc, #0x12c] ; literal[0x8003ff0]=0x20001a78
08003ec4  ldrh       r1, [r1]
08003ec6  cmp        r0, r1
08003ec8  bne        #0x8003f3a
08003eca  ldrh.w     r0, [sp, #2]
08003ece  ldr        r1, [pc, #0x120] ; literal[0x8003ff0]=0x20001a78
08003ed0  ldrh       r1, [r1, #2]
08003ed2  cmp        r0, r1
08003ed4  beq        #0x8003eda
08003ed6  orr        r5, r5, #8
08003eda  ldrh.w     r0, [sp, #2]
08003ede  ldr        r1, [pc, #0x110] ; literal[0x8003ff0]=0x20001a78
08003ee0  ldrh       r1, [r1, #2]
08003ee2  cmp        r0, r1
08003ee4  bge        #0x8003eec
08003ee6  ldrh.w     r0, [sp, #2]
08003eea  b          #0x8003ef0
08003eec  ldr        r0, [pc, #0x100] ; literal[0x8003ff0]=0x20001a78
08003eee  ldrh       r0, [r0, #2]
08003ef0  mov        r6, r0
08003ef2  movs       r4, #0
08003ef4  b          #0x8003f34
08003ef6  mov        r1, r7
08003ef8  mov        r0, r4
08003efa  bl         #0x80088b0
08003efe  cbnz       r0, #0x8003f1e
08003f00  ldr        r1, [pc, #0xfc] ; literal[0x8004000]=0x8014c6c
08003f02  add.w      r1, r1, r4, lsl #4
08003f06  ldrb       r1, [r1, #0xd]
08003f08  and        r1, r1, #0x1f
08003f0c  ldr        r3, [pc, #0xf4] ; literal[0x8004004]=0x8014c57
08003f0e  ldrb       r2, [r3, r1]
08003f10  ldr        r1, [pc, #0xec] ; literal[0x8004000]=0x8014c6c
08003f12  add.w      r1, r1, r4, lsl #4
08003f16  ldr        r0, [r1, #4]
08003f18  mov        r1, r7
08003f1a  bl         #0x8002398
08003f1e  ldr        r0, [pc, #0xe0] ; literal[0x8004000]=0x8014c6c
08003f20  add.w      r0, r0, r4, lsl #4
08003f24  ldrb       r0, [r0, #0xd]
08003f26  and        r0, r0, #0x1f
08003f2a  ldr        r1, [pc, #0xdc] ; literal[0x8004008]=0x8014c4c
08003f2c  ldrb       r0, [r1, r0]
08003f2e  add        r7, r0
08003f30  adds       r0, r4, #1
08003f32  uxth       r4, r0
08003f34  cmp        r4, r6
08003f36  blt        #0x8003ef6
08003f38  b          #0x8003f3e

; V25.12.09/EL05_1.0.5.0.2: parameter flash save
08004368  push.w     {r4, r5, r6, r7, r8, lr}
0800436c  movs       r7, #0
0800436e  movs       r4, #0
08004370  movs       r6, #0
08004372  mov        r8, r4
08004374  cpsid      i
08004376  bl         #0x8009900
0800437a  movw       r0, #0x307
0800437e  bl         #0x8009708
08004382  ldr        r0, [pc, #0x128] ; literal[0x80044ac]=0x20000128
08004384  ldrh       r0, [r0]
08004386  cbz        r0, #0x8004394
08004388  ldr        r0, [pc, #0x124] ; literal[0x80044b0]=0x20001a78
0800438a  ldrh       r0, [r0, #6]
0800438c  ldr        r1, [pc, #0x11c] ; literal[0x80044ac]=0x20000128
0800438e  ldrh       r1, [r1]
08004390  cmp        r0, r1
08004392  bne        #0x80043dc
08004394  movs       r5, #0
08004396  b          #0x80043ae
08004398  ldr        r1, [pc, #0x118] ; literal[0x80044b4]=0x807e000
0800439a  adds       r0, r5, r1
0800439c  bl         #0x8009814
080043a0  mov        r7, r0
080043a2  cbz        r7, #0x80043aa
080043a4  mov.w      r8, #1
080043a8  b          #0x8004494
080043aa  add.w      r5, r5, #0x800
080043ae  cmp.w      r5, #0x2000
080043b2  blo        #0x8004398
080043b4  movs       r4, #0
080043b6  b          #0x80043d2
080043b8  ldr        r2, [pc, #0xf4] ; literal[0x80044b0]=0x20001a78
080043ba  ldrh       r1, [r2, r4]
080043bc  ldr        r2, [pc, #0xf4] ; literal[0x80044b4]=0x807e000
080043be  adds       r0, r4, r2
080043c0  bl         #0x8009728
080043c4  mov        r7, r0
080043c6  cbz        r7, #0x80043ce
080043c8  mov.w      r8, #2
080043cc  b          #0x8004494
080043ce  adds       r0, r4, #2
080043d0  uxth       r4, r0
080043d2  cmp        r4, #0xa
080043d4  blo        #0x80043b8
080043d6  movs       r0, #0
080043d8  ldr        r1, [pc, #0xd0] ; literal[0x80044ac]=0x20000128
080043da  strh       r0, [r1]
080043dc  ldr        r0, [pc, #0xd0] ; literal[0x80044b0]=0x20001a78
080043de  ldrh       r0, [r0, #8]
080043e0  ldr        r1, [pc, #0xd0] ; literal[0x80044b4]=0x807e000
080043e2  add        r0, r1
080043e4  ldr        r1, [pc, #0xc8] ; literal[0x80044b0]=0x20001a78
080043e6  ldrh       r1, [r1, #4]
080043e8  ldr        r2, [pc, #0xc0] ; literal[0x80044ac]=0x20000128
080043ea  ldrh       r2, [r2]
080043ec  mla        r5, r2, r1, r0
080043f0  movs       r4, #0
080043f2  b          #0x8004466
080043f4  movs       r6, #0
080043f6  b          #0x800443e
080043f8  ldr        r0, [pc, #0xbc] ; literal[0x80044b8]=0x8014c6c
080043fa  add.w      r0, r0, r4, lsl #4
080043fe  ldrb       r0, [r0, #0xd]
08004400  and        r0, r0, #0x1f
08004404  ldr        r1, [pc, #0xb4] ; literal[0x80044bc]=0x8014c57
08004406  ldrb       r0, [r1, r0]
08004408  cmp        r0, #1
0800440a  bne        #0x8004420
0800440c  ldr        r2, [pc, #0xa8] ; literal[0x80044b8]=0x8014c6c
0800440e  add.w      r2, r2, r4, lsl #4
08004412  ldr        r2, [r2, #4]
08004414  ldrb       r1, [r2]
08004416  adds       r0, r5, r6
08004418  bl         #0x8009728
0800441c  mov        r7, r0
0800441e  b          #0x8004432
08004420  ldr        r2, [pc, #0x94] ; literal[0x80044b8]=0x8014c6c
08004422  add.w      r2, r2, r4, lsl #4
08004426  ldr        r2, [r2, #4]
08004428  ldrh       r1, [r2, r6]
0800442a  adds       r0, r5, r6
0800442c  bl         #0x8009728
08004430  mov        r7, r0
08004432  cbz        r7, #0x800443a
08004434  mov.w      r8, #3
08004438  b          #0x8004494
0800443a  adds       r0, r6, #2
0800443c  uxtb       r6, r0
0800443e  ldr        r0, [pc, #0x78] ; literal[0x80044b8]=0x8014c6c
08004440  add.w      r0, r0, r4, lsl #4
08004444  ldrb       r0, [r0, #0xd]
08004446  and        r0, r0, #0x1f
0800444a  ldr        r1, [pc, #0x74] ; literal[0x80044c0]=0x8014c4c
0800444c  ldrb       r0, [r1, r0]
0800444e  cmp        r0, r6
08004450  bgt        #0x80043f8
08004452  ldr        r0, [pc, #0x64] ; literal[0x80044b8]=0x8014c6c
08004454  add.w      r0, r0, r4, lsl #4
08004458  ldrb       r0, [r0, #0xd]
0800445a  and        r0, r0, #0x1f
0800445e  ldrb       r0, [r1, r0]
08004460  add        r5, r0
08004462  adds       r0, r4, #1
08004464  uxth       r4, r0
08004466  cmp        r4, #0x24
08004468  blt        #0x80043f4
0800446a  ldr        r0, [pc, #0x40] ; literal[0x80044ac]=0x20000128
0800446c  ldrh       r0, [r0]
0800446e  ldr        r1, [pc, #0x44] ; literal[0x80044b4]=0x807e000
08004470  adds       r1, #0xa
08004472  add.w      r5, r1, r0, lsl #1
08004476  movs       r1, #0
08004478  mov        r0, r5
0800447a  bl         #0x8009728
0800447e  mov        r7, r0
08004480  cbz        r7, #0x8004488
08004482  mov.w      r8, #4
08004486  b          #0x8004494
08004488  ldr        r0, [pc, #0x20] ; literal[0x80044ac]=0x20000128
0800448a  ldrh       r0, [r0]
0800448c  adds       r0, r0, #1
0800448e  ldr        r1, [pc, #0x1c] ; literal[0x80044ac]=0x20000128
08004490  strh       r0, [r1]
08004492  nop        
08004494  bl         #0x80097e8
08004498  cpsie      i
0800449a  ldr        r0, [pc, #0x28] ; literal[0x80044c4]=0x200008e0
0800449c  ldr        r0, [r0, #0x4c]
0800449e  adds       r0, r0, #1
080044a0  ldr        r1, [pc, #0x20] ; literal[0x80044c4]=0x200008e0
080044a2  str        r0, [r1, #0x4c]
080044a4  mov        r0, r8
080044a6  pop.w      {r4, r5, r6, r7, r8, pc}

; V26.05.19/el05_1.0.5.0.6: parameter flash save
08004ae4  push.w     {r4, r5, r6, r7, r8, sb, sl, lr}
08004ae8  movs       r6, #0
08004aea  movs       r4, #0
08004aec  movs       r7, #0
08004aee  mov        sb, r4
08004af0  cpsid      i
08004af2  bl         #0x800ab9c
08004af6  movw       r0, #0x307
08004afa  bl         #0x800a9a4
08004afe  ldr        r0, [pc, #0x150] ; literal[0x8004c50]=0x2000013a
08004b00  ldrh.w     r8, [r0]
08004b04  movs       r0, #0
08004b06  ldr        r1, [pc, #0x148] ; literal[0x8004c50]=0x2000013a
08004b08  strh       r0, [r1]
08004b0a  mov        r0, r1
08004b0c  ldrh       r0, [r0]
08004b0e  cbz        r0, #0x8004b1a
08004b10  ldr        r0, [pc, #0x140] ; literal[0x8004c54]=0x20002708
08004b12  ldrh       r0, [r0, #6]
08004b14  ldrh       r1, [r1]
08004b16  cmp        r0, r1
08004b18  bne        #0x8004b78
08004b1a  cmp.w      r8, #3
08004b1e  bge        #0x8004b30
08004b20  ldr        r0, [pc, #0x134] ; literal[0x8004c58]=0x807e000
08004b22  bl         #0x800aab0
08004b26  mov        r6, r0
08004b28  cbz        r6, #0x8004b50
08004b2a  mov.w      sb, #1
08004b2e  b          #0x8004c30
08004b30  movs       r5, #0
08004b32  b          #0x8004b4a
08004b34  ldr        r1, [pc, #0x120] ; literal[0x8004c58]=0x807e000
08004b36  adds       r0, r5, r1
08004b38  bl         #0x800aab0
08004b3c  mov        r6, r0
08004b3e  cbz        r6, #0x8004b46
08004b40  mov.w      sb, #1
08004b44  b          #0x8004c30
08004b46  add.w      r5, r5, #0x800
08004b4a  cmp.w      r5, #0x2000
08004b4e  blo        #0x8004b34
08004b50  movs       r4, #0
08004b52  b          #0x8004b6e
08004b54  ldr        r2, [pc, #0xfc] ; literal[0x8004c54]=0x20002708
08004b56  ldrh       r1, [r2, r4]
08004b58  ldr        r2, [pc, #0xfc] ; literal[0x8004c58]=0x807e000
08004b5a  adds       r0, r4, r2
08004b5c  bl         #0x800a9c4
08004b60  mov        r6, r0
08004b62  cbz        r6, #0x8004b6a
08004b64  mov.w      sb, #2
08004b68  b          #0x8004c30
08004b6a  adds       r0, r4, #2
08004b6c  uxth       r4, r0
08004b6e  cmp        r4, #0xa
08004b70  blo        #0x8004b54
08004b72  movs       r0, #0
08004b74  ldr        r1, [pc, #0xd8] ; literal[0x8004c50]=0x2000013a
08004b76  strh       r0, [r1]
08004b78  ldr        r0, [pc, #0xd8] ; literal[0x8004c54]=0x20002708
08004b7a  ldrh       r0, [r0, #8]
08004b7c  ldr        r1, [pc, #0xd8] ; literal[0x8004c58]=0x807e000
08004b7e  add        r0, r1
08004b80  ldr        r1, [pc, #0xd0] ; literal[0x8004c54]=0x20002708
08004b82  ldrh       r1, [r1, #4]
08004b84  ldr        r2, [pc, #0xc8] ; literal[0x8004c50]=0x2000013a
08004b86  ldrh       r2, [r2]
08004b88  mla        r5, r2, r1, r0
08004b8c  movs       r4, #0
08004b8e  b          #0x8004c02
08004b90  movs       r7, #0
08004b92  b          #0x8004bda
08004b94  ldr        r0, [pc, #0xc4] ; literal[0x8004c5c]=0x80184f0
08004b96  add.w      r0, r0, r4, lsl #4
08004b9a  ldrb       r0, [r0, #0xd]
08004b9c  and        r0, r0, #0x1f
08004ba0  ldr        r1, [pc, #0xbc] ; literal[0x8004c60]=0x80184db
08004ba2  ldrb       r0, [r1, r0]
08004ba4  cmp        r0, #1
08004ba6  bne        #0x8004bbc
08004ba8  ldr        r2, [pc, #0xb0] ; literal[0x8004c5c]=0x80184f0
08004baa  add.w      r2, r2, r4, lsl #4
08004bae  ldr        r2, [r2, #4]
08004bb0  ldrb       r1, [r2]
08004bb2  adds       r0, r5, r7
08004bb4  bl         #0x800a9c4
08004bb8  mov        r6, r0
08004bba  b          #0x8004bce
08004bbc  ldr        r2, [pc, #0x9c] ; literal[0x8004c5c]=0x80184f0
08004bbe  add.w      r2, r2, r4, lsl #4
08004bc2  ldr        r2, [r2, #4]
08004bc4  ldrh       r1, [r2, r7]
08004bc6  adds       r0, r5, r7
08004bc8  bl         #0x800a9c4
08004bcc  mov        r6, r0
08004bce  cbz        r6, #0x8004bd6
08004bd0  mov.w      sb, #3
08004bd4  b          #0x8004c30
08004bd6  adds       r0, r7, #2
08004bd8  uxtb       r7, r0
08004bda  ldr        r0, [pc, #0x80] ; literal[0x8004c5c]=0x80184f0
08004bdc  add.w      r0, r0, r4, lsl #4
08004be0  ldrb       r0, [r0, #0xd]
08004be2  and        r0, r0, #0x1f
08004be6  ldr        r1, [pc, #0x7c] ; literal[0x8004c64]=0x80184d0
08004be8  ldrb       r0, [r1, r0]
08004bea  cmp        r0, r7
08004bec  bgt        #0x8004b94
08004bee  ldr        r0, [pc, #0x6c] ; literal[0x8004c5c]=0x80184f0
08004bf0  add.w      r0, r0, r4, lsl #4
08004bf4  ldrb       r0, [r0, #0xd]
08004bf6  and        r0, r0, #0x1f
08004bfa  ldrb       r0, [r1, r0]
08004bfc  add        r5, r0
08004bfe  adds       r0, r4, #1
08004c00  uxth       r4, r0
08004c02  cmp        r4, #0x28
08004c04  blt        #0x8004b90
08004c06  ldr        r0, [pc, #0x48] ; literal[0x8004c50]=0x2000013a
08004c08  ldrh       r0, [r0]
08004c0a  ldr        r1, [pc, #0x4c] ; literal[0x8004c58]=0x807e000
08004c0c  adds       r1, #0xa
08004c0e  add.w      r5, r1, r0, lsl #1
08004c12  movs       r1, #0
08004c14  mov        r0, r5
08004c16  bl         #0x800a9c4
08004c1a  mov        r6, r0
08004c1c  cbz        r6, #0x8004c24
08004c1e  mov.w      sb, #4
08004c22  b          #0x8004c30
08004c24  ldr        r0, [pc, #0x28] ; literal[0x8004c50]=0x2000013a
08004c26  ldrh       r0, [r0]
08004c28  adds       r0, r0, #1
08004c2a  ldr        r1, [pc, #0x24] ; literal[0x8004c50]=0x2000013a
08004c2c  strh       r0, [r1]
08004c2e  nop        
08004c30  bl         #0x800aa84
08004c34  cpsie      i
08004c36  ldr        r0, [pc, #0x30] ; literal[0x8004c68]=0x20001480
08004c38  ldr.w      r0, [r0, #0xa8]
08004c3c  adds       r0, r0, #1
08004c3e  ldr        r1, [pc, #0x28] ; literal[0x8004c68]=0x20001480
08004c40  str.w      r0, [r1, #0xa8]
08004c44  bl         #0x8005018
08004c48  mov        r0, sb
08004c4a  pop.w      {r4, r5, r6, r7, r8, sb, sl, pc}
