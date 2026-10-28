; Official EL05 1.0.5.0.2, assumed image base 0x08002000.
; Analyst interpretation; literal pools are data, not executable instructions.

; mechPos copied to state and separately wrapped theta_mech_1
08004844  ldr        r0, [pc, #0x3a8] ; literal[0x8004bf0]=0x200001dc
08004846  vldr       s0, [r0, #8]
0800484a  ldr        r0, [pc, #0x3a8] ; literal[0x8004bf4]=0x20000544
0800484c  vstr       s0, [r0, #0x24]
08004850  ldr        r0, [pc, #0x39c] ; literal[0x8004bf0]=0x200001dc
08004852  vldr       s0, [r0, #0x10]
08004856  ldr        r0, [pc, #0x39c] ; literal[0x8004bf4]=0x20000544
08004858  vstr       s0, [r0, #0x20]
0800485c  vldr       s0, [r0, #0x20]
08004860  vldr       s1, [pc, #0x394] ; literal[0x8004bf8]=0x41490fdb
08004864  vcmpe.f32  s0, s1
08004868  vmrs       apsr_nzcv, fpscr
0800486c  ble        #0x80048b4
0800486e  vldr       s0, [r0, #0x20]
08004872  vldr       s1, [pc, #0x384] ; literal[0x8004bf8]=0x41490fdb
08004876  vsub.f32   s0, s0, s1
0800487a  vldr       s1, [pc, #0x380] ; literal[0x8004bfc]=0x41c90fdb
0800487e  vdiv.f32   s2, s0, s1
08004882  vcvt.s32.f32 s0, s2
08004886  vcvt.f32.s32 s0, s0
0800488a  vmov.f32   s1, #8.000000e+00
0800488e  vmul.f32   s1, s0, s1
08004892  vldr       s0, [r0, #0x20]
08004896  vldr       s2, [pc, #0x360] ; literal[0x8004bf8]=0x41490fdb
0800489a  vsub.f32   s0, s0, s2
0800489e  vldr       s2, [pc, #0x360] ; literal[0x8004c00]=0x40490fdb
080048a2  vmls.f32   s0, s1, s2
080048a6  vldr       s1, [pc, #0x350] ; literal[0x8004bf8]=0x41490fdb
080048aa  vsub.f32   s0, s0, s1
080048ae  vstr       s0, [r0, #0x28]
080048b2  b          #0x8004918
080048b4  ldr        r0, [pc, #0x33c] ; literal[0x8004bf4]=0x20000544
080048b6  vldr       s0, [r0, #0x20]
080048ba  vldr       s1, [pc, #0x348] ; literal[0x8004c04]=0xc1490fdb
080048be  vcmpe.f32  s0, s1
080048c2  vmrs       apsr_nzcv, fpscr
080048c6  bhs        #0x800490e
080048c8  vldr       s0, [r0, #0x20]
080048cc  vldr       s1, [pc, #0x328] ; literal[0x8004bf8]=0x41490fdb
080048d0  vadd.f32   s0, s0, s1
080048d4  vldr       s1, [pc, #0x324] ; literal[0x8004bfc]=0x41c90fdb
080048d8  vdiv.f32   s2, s0, s1
080048dc  vcvt.s32.f32 s0, s2
080048e0  vcvt.f32.s32 s0, s0
080048e4  vmov.f32   s1, #8.000000e+00
080048e8  vmul.f32   s1, s0, s1
080048ec  vldr       s0, [r0, #0x20]
080048f0  vldr       s2, [pc, #0x304] ; literal[0x8004bf8]=0x41490fdb
080048f4  vadd.f32   s0, s0, s2
080048f8  vldr       s2, [pc, #0x304] ; literal[0x8004c00]=0x40490fdb
080048fc  vmls.f32   s0, s1, s2
08004900  vldr       s1, [pc, #0x2f4] ; literal[0x8004bf8]=0x41490fdb
08004904  vadd.f32   s0, s0, s1
08004908  vstr       s0, [r0, #0x28]
0800490c  b          #0x8004918
0800490e  ldr        r0, [pc, #0x2e4] ; literal[0x8004bf4]=0x20000544
08004910  vldr       s0, [r0, #0x20]
08004914  vstr       s0, [r0, #0x28]
08004918  ldr        r0, [pc, #0x2ec] ; literal[0x8004c08]=0x200008cc

; PD loop called with base 0x20000544
08004cae  ldr        r0, [pc, #0x60] ; literal[0x8004d10]=0x20000544
08004cb0  ldr.w      r0, [r0, #0xa4]
08004cb4  ldr        r1, [pc, #0x68] ; literal[0x8004d20]=0x200008d4
08004cb6  ldr        r1, [r1]
08004cb8  cmp        r0, r1
08004cba  bls        #0x8004cca
08004cbc  ldr        r0, [pc, #0x60] ; literal[0x8004d20]=0x200008d4
08004cbe  ldr        r0, [r0]
08004cc0  cbz        r0, #0x8004cca
08004cc2  ldr        r0, [pc, #0x4c] ; literal[0x8004d10]=0x20000544
08004cc4  bl         #0x800f5f8
08004cc8  b          #0x8004cd0
08004cca  ldr        r0, [pc, #0x44] ; literal[0x8004d10]=0x20000544
08004ccc  bl         #0x800f620

; Position PD error reads cmdPos at +0xb0 and mechPos at +0x20
0800f620  push       {r4, lr}
0800f622  vpush      {d8}
0800f626  mov        r4, r0
0800f628  vldr       s0, [r4, #0xb0]
0800f62c  vldr       s1, [r4, #0x20]
0800f630  vsub.f32   s1, s0, s1
0800f634  vldr       s0, [r4, #0xc0]
0800f638  vldr       s2, [r4, #0xb8]
0800f63c  vmla.f32   s0, s2, s1
0800f640  vldr       s1, [r4, #0xb4]
0800f644  vldr       s2, [r4, #0x2c]
0800f648  vsub.f32   s1, s1, s2
0800f64c  vldr       s2, [r4, #0xbc]
0800f650  vmla.f32   s0, s2, s1
0800f654  vmov.f32   s16, s0
