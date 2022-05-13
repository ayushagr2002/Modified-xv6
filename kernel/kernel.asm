
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae013103          	ld	sp,-1312(sp) # 80008ae0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2bc78793          	addi	a5,a5,700 # 80006320 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7e0080e7          	jalr	2016(ra) # 8000290c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8ce080e7          	jalr	-1842(ra) # 80001a92 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	194080e7          	jalr	404(ra) # 80002368 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	6a6080e7          	jalr	1702(ra) # 800028b6 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	670080e7          	jalr	1648(ra) # 80002962 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	212080e7          	jalr	530(ra) # 80002658 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	8c878793          	addi	a5,a5,-1848 # 80022d40 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	db8080e7          	jalr	-584(ra) # 80002658 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a3c080e7          	jalr	-1476(ra) # 80002368 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00026797          	auipc	a5,0x26
    80000a10:	5f478793          	addi	a5,a5,1524 # 80027000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00026517          	auipc	a0,0x26
    80000ae0:	52450513          	addi	a0,a0,1316 # 80027000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	ef8080e7          	jalr	-264(ra) # 80001a76 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	ec6080e7          	jalr	-314(ra) # 80001a76 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	eba080e7          	jalr	-326(ra) # 80001a76 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	ea2080e7          	jalr	-350(ra) # 80001a76 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e62080e7          	jalr	-414(ra) # 80001a76 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e36080e7          	jalr	-458(ra) # 80001a76 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	bd0080e7          	jalr	-1072(ra) # 80001a66 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	bb4080e7          	jalr	-1100(ra) # 80001a66 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	cb6080e7          	jalr	-842(ra) # 80002b8a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	484080e7          	jalr	1156(ra) # 80006360 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	2d2080e7          	jalr	722(ra) # 800021b6 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	1c450513          	addi	a0,a0,452 # 800080c8 <digits+0x88>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	a6a080e7          	jalr	-1430(ra) # 800019b6 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c0e080e7          	jalr	-1010(ra) # 80002b62 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	c2e080e7          	jalr	-978(ra) # 80002b8a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	3e6080e7          	jalr	998(ra) # 8000634a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	3f4080e7          	jalr	1012(ra) # 80006360 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	5d8080e7          	jalr	1496(ra) # 8000354c <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	c68080e7          	jalr	-920(ra) # 80003be4 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	c12080e7          	jalr	-1006(ra) # 80004b96 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	4f6080e7          	jalr	1270(ra) # 80006482 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e14080e7          	jalr	-492(ra) # 80001da8 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	6d8080e7          	jalr	1752(ra) # 80001920 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <initquelist>:
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

void initquelist()
{
    80001846:	1141                	addi	sp,sp,-16
    80001848:	e422                	sd	s0,8(sp)
    8000184a:	0800                	addi	s0,sp,16
  struct qnode *t = &quelist[0];
    8000184c:	00010797          	auipc	a5,0x10
    80001850:	e8478793          	addi	a5,a5,-380 # 800116d0 <quelist>
  for (; t < &quelist[5]; t++)
  {
    t->lastidx = -1;
    80001854:	56fd                	li	a3,-1
  for (; t < &quelist[5]; t++)
    80001856:	00011717          	auipc	a4,0x11
    8000185a:	8a270713          	addi	a4,a4,-1886 # 800120f8 <proc>
    t->lastidx = -1;
    8000185e:	20d7a023          	sw	a3,512(a5)
  for (; t < &quelist[5]; t++)
    80001862:	20878793          	addi	a5,a5,520
    80001866:	fee79ce3          	bne	a5,a4,8000185e <initquelist+0x18>
  }
  return;
}
    8000186a:	6422                	ld	s0,8(sp)
    8000186c:	0141                	addi	sp,sp,16
    8000186e:	8082                	ret

0000000080001870 <push>:

void push(int queno, struct proc *p)
{
    80001870:	1141                	addi	sp,sp,-16
    80001872:	e422                	sd	s0,8(sp)
    80001874:	0800                	addi	s0,sp,16
  struct qnode *t = &quelist[queno];
  t->lastidx = (t->lastidx + 1);
    80001876:	00010697          	auipc	a3,0x10
    8000187a:	e5a68693          	addi	a3,a3,-422 # 800116d0 <quelist>
    8000187e:	00651793          	slli	a5,a0,0x6
    80001882:	00a78733          	add	a4,a5,a0
    80001886:	070e                	slli	a4,a4,0x3
    80001888:	9736                	add	a4,a4,a3
    8000188a:	20072603          	lw	a2,512(a4)
    8000188e:	2605                	addiw	a2,a2,1
    80001890:	0006081b          	sext.w	a6,a2
    80001894:	20c72023          	sw	a2,512(a4)
  t->proclist[t->lastidx] = p;
    80001898:	97aa                	add	a5,a5,a0
    8000189a:	97c2                	add	a5,a5,a6
    8000189c:	078e                	slli	a5,a5,0x3
    8000189e:	97b6                	add	a5,a5,a3
    800018a0:	e38c                	sd	a1,0(a5)

  p->queno = queno;
    800018a2:	1aa5a223          	sw	a0,420(a1) # 40001a4 <_entry-0x7bfffe5c>

  return;
}
    800018a6:	6422                	ld	s0,8(sp)
    800018a8:	0141                	addi	sp,sp,16
    800018aa:	8082                	ret

00000000800018ac <pop>:

void pop(int queno, struct proc *p)
{
    800018ac:	1141                	addi	sp,sp,-16
    800018ae:	e422                	sd	s0,8(sp)
    800018b0:	0800                	addi	s0,sp,16
  struct qnode *t = &quelist[queno];
  for (int i = 0; i < t->lastidx; i++)
    800018b2:	00651793          	slli	a5,a0,0x6
    800018b6:	97aa                	add	a5,a5,a0
    800018b8:	078e                	slli	a5,a5,0x3
    800018ba:	00010717          	auipc	a4,0x10
    800018be:	e1670713          	addi	a4,a4,-490 # 800116d0 <quelist>
    800018c2:	97ba                	add	a5,a5,a4
    800018c4:	2007a603          	lw	a2,512(a5)
    800018c8:	02c05d63          	blez	a2,80001902 <pop+0x56>
    800018cc:	00651713          	slli	a4,a0,0x6
    800018d0:	00a707b3          	add	a5,a4,a0
    800018d4:	078e                	slli	a5,a5,0x3
    800018d6:	00010697          	auipc	a3,0x10
    800018da:	dfa68693          	addi	a3,a3,-518 # 800116d0 <quelist>
    800018de:	97b6                	add	a5,a5,a3
    800018e0:	972a                	add	a4,a4,a0
    800018e2:	fff6069b          	addiw	a3,a2,-1
    800018e6:	1682                	slli	a3,a3,0x20
    800018e8:	9281                	srli	a3,a3,0x20
    800018ea:	9736                	add	a4,a4,a3
    800018ec:	070e                	slli	a4,a4,0x3
    800018ee:	00010697          	auipc	a3,0x10
    800018f2:	dea68693          	addi	a3,a3,-534 # 800116d8 <quelist+0x8>
    800018f6:	9736                	add	a4,a4,a3
  {
    t->proclist[i] = t->proclist[i + 1];
    800018f8:	6794                	ld	a3,8(a5)
    800018fa:	e394                	sd	a3,0(a5)
  for (int i = 0; i < t->lastidx; i++)
    800018fc:	07a1                	addi	a5,a5,8
    800018fe:	fee79de3          	bne	a5,a4,800018f8 <pop+0x4c>
  }
  t->lastidx = (t->lastidx - 1);
    80001902:	00651793          	slli	a5,a0,0x6
    80001906:	953e                	add	a0,a0,a5
    80001908:	050e                	slli	a0,a0,0x3
    8000190a:	00010797          	auipc	a5,0x10
    8000190e:	dc678793          	addi	a5,a5,-570 # 800116d0 <quelist>
    80001912:	953e                	add	a0,a0,a5
    80001914:	367d                	addiw	a2,a2,-1
    80001916:	20c52023          	sw	a2,512(a0)
  return;
}
    8000191a:	6422                	ld	s0,8(sp)
    8000191c:	0141                	addi	sp,sp,16
    8000191e:	8082                	ret

0000000080001920 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001920:	7139                	addi	sp,sp,-64
    80001922:	fc06                	sd	ra,56(sp)
    80001924:	f822                	sd	s0,48(sp)
    80001926:	f426                	sd	s1,40(sp)
    80001928:	f04a                	sd	s2,32(sp)
    8000192a:	ec4e                	sd	s3,24(sp)
    8000192c:	e852                	sd	s4,16(sp)
    8000192e:	e456                	sd	s5,8(sp)
    80001930:	e05a                	sd	s6,0(sp)
    80001932:	0080                	addi	s0,sp,64
    80001934:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001936:	00010497          	auipc	s1,0x10
    8000193a:	7c248493          	addi	s1,s1,1986 # 800120f8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000193e:	8b26                	mv	s6,s1
    80001940:	00006a97          	auipc	s5,0x6
    80001944:	6c0a8a93          	addi	s5,s5,1728 # 80008000 <etext>
    80001948:	04000937          	lui	s2,0x4000
    8000194c:	197d                	addi	s2,s2,-1
    8000194e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001950:	00017a17          	auipc	s4,0x17
    80001954:	1a8a0a13          	addi	s4,s4,424 # 80018af8 <tickslock>
    char *pa = kalloc();
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	19c080e7          	jalr	412(ra) # 80000af4 <kalloc>
    80001960:	862a                	mv	a2,a0
    if (pa == 0)
    80001962:	c131                	beqz	a0,800019a6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001964:	416485b3          	sub	a1,s1,s6
    80001968:	858d                	srai	a1,a1,0x3
    8000196a:	000ab783          	ld	a5,0(s5)
    8000196e:	02f585b3          	mul	a1,a1,a5
    80001972:	2585                	addiw	a1,a1,1
    80001974:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001978:	4719                	li	a4,6
    8000197a:	6685                	lui	a3,0x1
    8000197c:	40b905b3          	sub	a1,s2,a1
    80001980:	854e                	mv	a0,s3
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	7d6080e7          	jalr	2006(ra) # 80001158 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000198a:	1a848493          	addi	s1,s1,424
    8000198e:	fd4495e3          	bne	s1,s4,80001958 <proc_mapstacks+0x38>
  }
}
    80001992:	70e2                	ld	ra,56(sp)
    80001994:	7442                	ld	s0,48(sp)
    80001996:	74a2                	ld	s1,40(sp)
    80001998:	7902                	ld	s2,32(sp)
    8000199a:	69e2                	ld	s3,24(sp)
    8000199c:	6a42                	ld	s4,16(sp)
    8000199e:	6aa2                	ld	s5,8(sp)
    800019a0:	6b02                	ld	s6,0(sp)
    800019a2:	6121                	addi	sp,sp,64
    800019a4:	8082                	ret
      panic("kalloc");
    800019a6:	00007517          	auipc	a0,0x7
    800019aa:	83250513          	addi	a0,a0,-1998 # 800081d8 <digits+0x198>
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	b90080e7          	jalr	-1136(ra) # 8000053e <panic>

00000000800019b6 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800019b6:	7139                	addi	sp,sp,-64
    800019b8:	fc06                	sd	ra,56(sp)
    800019ba:	f822                	sd	s0,48(sp)
    800019bc:	f426                	sd	s1,40(sp)
    800019be:	f04a                	sd	s2,32(sp)
    800019c0:	ec4e                	sd	s3,24(sp)
    800019c2:	e852                	sd	s4,16(sp)
    800019c4:	e456                	sd	s5,8(sp)
    800019c6:	e05a                	sd	s6,0(sp)
    800019c8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019ca:	00007597          	auipc	a1,0x7
    800019ce:	81658593          	addi	a1,a1,-2026 # 800081e0 <digits+0x1a0>
    800019d2:	00010517          	auipc	a0,0x10
    800019d6:	8ce50513          	addi	a0,a0,-1842 # 800112a0 <pid_lock>
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	17a080e7          	jalr	378(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019e2:	00007597          	auipc	a1,0x7
    800019e6:	80658593          	addi	a1,a1,-2042 # 800081e8 <digits+0x1a8>
    800019ea:	00010517          	auipc	a0,0x10
    800019ee:	8ce50513          	addi	a0,a0,-1842 # 800112b8 <wait_lock>
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	162080e7          	jalr	354(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019fa:	00010497          	auipc	s1,0x10
    800019fe:	6fe48493          	addi	s1,s1,1790 # 800120f8 <proc>
  {
    initlock(&p->lock, "proc");
    80001a02:	00006b17          	auipc	s6,0x6
    80001a06:	7f6b0b13          	addi	s6,s6,2038 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001a0a:	8aa6                	mv	s5,s1
    80001a0c:	00006a17          	auipc	s4,0x6
    80001a10:	5f4a0a13          	addi	s4,s4,1524 # 80008000 <etext>
    80001a14:	04000937          	lui	s2,0x4000
    80001a18:	197d                	addi	s2,s2,-1
    80001a1a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a1c:	00017997          	auipc	s3,0x17
    80001a20:	0dc98993          	addi	s3,s3,220 # 80018af8 <tickslock>
    initlock(&p->lock, "proc");
    80001a24:	85da                	mv	a1,s6
    80001a26:	8526                	mv	a0,s1
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	12c080e7          	jalr	300(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001a30:	415487b3          	sub	a5,s1,s5
    80001a34:	878d                	srai	a5,a5,0x3
    80001a36:	000a3703          	ld	a4,0(s4)
    80001a3a:	02e787b3          	mul	a5,a5,a4
    80001a3e:	2785                	addiw	a5,a5,1
    80001a40:	00d7979b          	slliw	a5,a5,0xd
    80001a44:	40f907b3          	sub	a5,s2,a5
    80001a48:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a4a:	1a848493          	addi	s1,s1,424
    80001a4e:	fd349be3          	bne	s1,s3,80001a24 <procinit+0x6e>
  }
}
    80001a52:	70e2                	ld	ra,56(sp)
    80001a54:	7442                	ld	s0,48(sp)
    80001a56:	74a2                	ld	s1,40(sp)
    80001a58:	7902                	ld	s2,32(sp)
    80001a5a:	69e2                	ld	s3,24(sp)
    80001a5c:	6a42                	ld	s4,16(sp)
    80001a5e:	6aa2                	ld	s5,8(sp)
    80001a60:	6b02                	ld	s6,0(sp)
    80001a62:	6121                	addi	sp,sp,64
    80001a64:	8082                	ret

0000000080001a66 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a66:	1141                	addi	sp,sp,-16
    80001a68:	e422                	sd	s0,8(sp)
    80001a6a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a6c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a6e:	2501                	sext.w	a0,a0
    80001a70:	6422                	ld	s0,8(sp)
    80001a72:	0141                	addi	sp,sp,16
    80001a74:	8082                	ret

0000000080001a76 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a76:	1141                	addi	sp,sp,-16
    80001a78:	e422                	sd	s0,8(sp)
    80001a7a:	0800                	addi	s0,sp,16
    80001a7c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a7e:	2781                	sext.w	a5,a5
    80001a80:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a82:	00010517          	auipc	a0,0x10
    80001a86:	84e50513          	addi	a0,a0,-1970 # 800112d0 <cpus>
    80001a8a:	953e                	add	a0,a0,a5
    80001a8c:	6422                	ld	s0,8(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret

0000000080001a92 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	1000                	addi	s0,sp,32
  push_off();
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	0fc080e7          	jalr	252(ra) # 80000b98 <push_off>
    80001aa4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aa6:	2781                	sext.w	a5,a5
    80001aa8:	079e                	slli	a5,a5,0x7
    80001aaa:	0000f717          	auipc	a4,0xf
    80001aae:	7f670713          	addi	a4,a4,2038 # 800112a0 <pid_lock>
    80001ab2:	97ba                	add	a5,a5,a4
    80001ab4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	182080e7          	jalr	386(ra) # 80000c38 <pop_off>
  return p;
}
    80001abe:	8526                	mv	a0,s1
    80001ac0:	60e2                	ld	ra,24(sp)
    80001ac2:	6442                	ld	s0,16(sp)
    80001ac4:	64a2                	ld	s1,8(sp)
    80001ac6:	6105                	addi	sp,sp,32
    80001ac8:	8082                	ret

0000000080001aca <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001aca:	1141                	addi	sp,sp,-16
    80001acc:	e406                	sd	ra,8(sp)
    80001ace:	e022                	sd	s0,0(sp)
    80001ad0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	fc0080e7          	jalr	-64(ra) # 80001a92 <myproc>
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>

  if (first)
    80001ae2:	00007797          	auipc	a5,0x7
    80001ae6:	e8e7a783          	lw	a5,-370(a5) # 80008970 <first.1764>
    80001aea:	eb89                	bnez	a5,80001afc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aec:	00001097          	auipc	ra,0x1
    80001af0:	0b6080e7          	jalr	182(ra) # 80002ba2 <usertrapret>
}
    80001af4:	60a2                	ld	ra,8(sp)
    80001af6:	6402                	ld	s0,0(sp)
    80001af8:	0141                	addi	sp,sp,16
    80001afa:	8082                	ret
    first = 0;
    80001afc:	00007797          	auipc	a5,0x7
    80001b00:	e607aa23          	sw	zero,-396(a5) # 80008970 <first.1764>
    fsinit(ROOTDEV);
    80001b04:	4505                	li	a0,1
    80001b06:	00002097          	auipc	ra,0x2
    80001b0a:	05e080e7          	jalr	94(ra) # 80003b64 <fsinit>
    80001b0e:	bff9                	j	80001aec <forkret+0x22>

0000000080001b10 <allocpid>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b1c:	0000f917          	auipc	s2,0xf
    80001b20:	78490913          	addi	s2,s2,1924 # 800112a0 <pid_lock>
    80001b24:	854a                	mv	a0,s2
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	0be080e7          	jalr	190(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	e4678793          	addi	a5,a5,-442 # 80008974 <nextpid>
    80001b36:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b38:	0014871b          	addiw	a4,s1,1
    80001b3c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b3e:	854a                	mv	a0,s2
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	158080e7          	jalr	344(ra) # 80000c98 <release>
}
    80001b48:	8526                	mv	a0,s1
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret

0000000080001b56 <proc_pagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	7de080e7          	jalr	2014(ra) # 80001342 <uvmcreate>
    80001b6c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b6e:	c121                	beqz	a0,80001bae <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b70:	4729                	li	a4,10
    80001b72:	00005697          	auipc	a3,0x5
    80001b76:	48e68693          	addi	a3,a3,1166 # 80007000 <_trampoline>
    80001b7a:	6605                	lui	a2,0x1
    80001b7c:	040005b7          	lui	a1,0x4000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b2                	slli	a1,a1,0xc
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	534080e7          	jalr	1332(ra) # 800010b8 <mappages>
    80001b8c:	02054863          	bltz	a0,80001bbc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b90:	4719                	li	a4,6
    80001b92:	05893683          	ld	a3,88(s2)
    80001b96:	6605                	lui	a2,0x1
    80001b98:	020005b7          	lui	a1,0x2000
    80001b9c:	15fd                	addi	a1,a1,-1
    80001b9e:	05b6                	slli	a1,a1,0xd
    80001ba0:	8526                	mv	a0,s1
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	516080e7          	jalr	1302(ra) # 800010b8 <mappages>
    80001baa:	02054163          	bltz	a0,80001bcc <proc_pagetable+0x76>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret
    uvmfree(pagetable, 0);
    80001bbc:	4581                	li	a1,0
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	00000097          	auipc	ra,0x0
    80001bc4:	97e080e7          	jalr	-1666(ra) # 8000153e <uvmfree>
    return 0;
    80001bc8:	4481                	li	s1,0
    80001bca:	b7d5                	j	80001bae <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bcc:	4681                	li	a3,0
    80001bce:	4605                	li	a2,1
    80001bd0:	040005b7          	lui	a1,0x4000
    80001bd4:	15fd                	addi	a1,a1,-1
    80001bd6:	05b2                	slli	a1,a1,0xc
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	6a4080e7          	jalr	1700(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001be2:	4581                	li	a1,0
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	958080e7          	jalr	-1704(ra) # 8000153e <uvmfree>
    return 0;
    80001bee:	4481                	li	s1,0
    80001bf0:	bf7d                	j	80001bae <proc_pagetable+0x58>

0000000080001bf2 <proc_freepagetable>:
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	e04a                	sd	s2,0(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
    80001c00:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c02:	4681                	li	a3,0
    80001c04:	4605                	li	a2,1
    80001c06:	040005b7          	lui	a1,0x4000
    80001c0a:	15fd                	addi	a1,a1,-1
    80001c0c:	05b2                	slli	a1,a1,0xc
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	670080e7          	jalr	1648(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c16:	4681                	li	a3,0
    80001c18:	4605                	li	a2,1
    80001c1a:	020005b7          	lui	a1,0x2000
    80001c1e:	15fd                	addi	a1,a1,-1
    80001c20:	05b6                	slli	a1,a1,0xd
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	65a080e7          	jalr	1626(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c2c:	85ca                	mv	a1,s2
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	90e080e7          	jalr	-1778(ra) # 8000153e <uvmfree>
}
    80001c38:	60e2                	ld	ra,24(sp)
    80001c3a:	6442                	ld	s0,16(sp)
    80001c3c:	64a2                	ld	s1,8(sp)
    80001c3e:	6902                	ld	s2,0(sp)
    80001c40:	6105                	addi	sp,sp,32
    80001c42:	8082                	ret

0000000080001c44 <freeproc>:
{
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	1000                	addi	s0,sp,32
    80001c4e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c50:	6d28                	ld	a0,88(a0)
    80001c52:	c509                	beqz	a0,80001c5c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	da4080e7          	jalr	-604(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c5c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c60:	68a8                	ld	a0,80(s1)
    80001c62:	c511                	beqz	a0,80001c6e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c64:	64ac                	ld	a1,72(s1)
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	f8c080e7          	jalr	-116(ra) # 80001bf2 <proc_freepagetable>
  p->pagetable = 0;
    80001c6e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c72:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c76:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c7a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c7e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c82:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c86:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c8a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c8e:	0004ac23          	sw	zero,24(s1)
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret

0000000080001c9c <allocproc>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	e04a                	sd	s2,0(sp)
    80001ca6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ca8:	00010497          	auipc	s1,0x10
    80001cac:	45048493          	addi	s1,s1,1104 # 800120f8 <proc>
    80001cb0:	00017917          	auipc	s2,0x17
    80001cb4:	e4890913          	addi	s2,s2,-440 # 80018af8 <tickslock>
    acquire(&p->lock);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	f2a080e7          	jalr	-214(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001cc2:	4c9c                	lw	a5,24(s1)
    80001cc4:	cf81                	beqz	a5,80001cdc <allocproc+0x40>
      release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	fd0080e7          	jalr	-48(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cd0:	1a848493          	addi	s1,s1,424
    80001cd4:	ff2492e3          	bne	s1,s2,80001cb8 <allocproc+0x1c>
  return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	a841                	j	80001d6a <allocproc+0xce>
  p->pid = allocpid();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	e34080e7          	jalr	-460(ra) # 80001b10 <allocpid>
    80001ce4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ce6:	4785                	li	a5,1
    80001ce8:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	e0a080e7          	jalr	-502(ra) # 80000af4 <kalloc>
    80001cf2:	892a                	mv	s2,a0
    80001cf4:	eca8                	sd	a0,88(s1)
    80001cf6:	c149                	beqz	a0,80001d78 <allocproc+0xdc>
  p->pagetable = proc_pagetable(p);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	e5c080e7          	jalr	-420(ra) # 80001b56 <proc_pagetable>
    80001d02:	892a                	mv	s2,a0
    80001d04:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d06:	c549                	beqz	a0,80001d90 <allocproc+0xf4>
  memset(&p->context, 0, sizeof(p->context));
    80001d08:	07000613          	li	a2,112
    80001d0c:	4581                	li	a1,0
    80001d0e:	06048513          	addi	a0,s1,96
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	fce080e7          	jalr	-50(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d1a:	00000797          	auipc	a5,0x0
    80001d1e:	db078793          	addi	a5,a5,-592 # 80001aca <forkret>
    80001d22:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d24:	60bc                	ld	a5,64(s1)
    80001d26:	6705                	lui	a4,0x1
    80001d28:	97ba                	add	a5,a5,a4
    80001d2a:	f4bc                	sd	a5,104(s1)
  p->traceflag = 0;
    80001d2c:	1604a423          	sw	zero,360(s1)
  p->syscallno = 0;
    80001d30:	1604b823          	sd	zero,368(s1)
  p->ctime = ticks;
    80001d34:	00007797          	auipc	a5,0x7
    80001d38:	2fc7a783          	lw	a5,764(a5) # 80009030 <ticks>
    80001d3c:	16f4ac23          	sw	a5,376(s1)
  p->runtime = 0;
    80001d40:	1604ae23          	sw	zero,380(s1)
  p->endtime = 0;
    80001d44:	1804a023          	sw	zero,384(s1)
  p->staticpriority = 60;
    80001d48:	03c00793          	li	a5,60
    80001d4c:	18f4ac23          	sw	a5,408(s1)
  p->schedcount = 0;
    80001d50:	1804aa23          	sw	zero,404(s1)
  p->niceness = 5;
    80001d54:	4795                	li	a5,5
    80001d56:	18f4ae23          	sw	a5,412(s1)
  p->lastsleeptime = 0;
    80001d5a:	1804a423          	sw	zero,392(s1)
  p->lastruntime = 0;
    80001d5e:	1804a823          	sw	zero,400(s1)
  p->sleepstart = 0;
    80001d62:	1804a623          	sw	zero,396(s1)
  p->queno = 0;
    80001d66:	1a04a223          	sw	zero,420(s1)
}
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret
    freeproc(p);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	eca080e7          	jalr	-310(ra) # 80001c44 <freeproc>
    release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f14080e7          	jalr	-236(ra) # 80000c98 <release>
    return 0;
    80001d8c:	84ca                	mv	s1,s2
    80001d8e:	bff1                	j	80001d6a <allocproc+0xce>
    freeproc(p);
    80001d90:	8526                	mv	a0,s1
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	eb2080e7          	jalr	-334(ra) # 80001c44 <freeproc>
    release(&p->lock);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	efc080e7          	jalr	-260(ra) # 80000c98 <release>
    return 0;
    80001da4:	84ca                	mv	s1,s2
    80001da6:	b7d1                	j	80001d6a <allocproc+0xce>

0000000080001da8 <userinit>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	eea080e7          	jalr	-278(ra) # 80001c9c <allocproc>
    80001dba:	84aa                	mv	s1,a0
  initproc = p;
    80001dbc:	00007797          	auipc	a5,0x7
    80001dc0:	26a7b623          	sd	a0,620(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dc4:	03400613          	li	a2,52
    80001dc8:	00007597          	auipc	a1,0x7
    80001dcc:	bb858593          	addi	a1,a1,-1096 # 80008980 <initcode>
    80001dd0:	6928                	ld	a0,80(a0)
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	59e080e7          	jalr	1438(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001dda:	6785                	lui	a5,0x1
    80001ddc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dde:	6cb8                	ld	a4,88(s1)
    80001de0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001de4:	6cb8                	ld	a4,88(s1)
    80001de6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001de8:	4641                	li	a2,16
    80001dea:	00006597          	auipc	a1,0x6
    80001dee:	41658593          	addi	a1,a1,1046 # 80008200 <digits+0x1c0>
    80001df2:	15848513          	addi	a0,s1,344
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	03c080e7          	jalr	60(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001dfe:	00006517          	auipc	a0,0x6
    80001e02:	41250513          	addi	a0,a0,1042 # 80008210 <digits+0x1d0>
    80001e06:	00002097          	auipc	ra,0x2
    80001e0a:	78c080e7          	jalr	1932(ra) # 80004592 <namei>
    80001e0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e12:	478d                	li	a5,3
    80001e14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e16:	8526                	mv	a0,s1
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
}
    80001e20:	60e2                	ld	ra,24(sp)
    80001e22:	6442                	ld	s0,16(sp)
    80001e24:	64a2                	ld	s1,8(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret

0000000080001e2a <growproc>:
{
    80001e2a:	1101                	addi	sp,sp,-32
    80001e2c:	ec06                	sd	ra,24(sp)
    80001e2e:	e822                	sd	s0,16(sp)
    80001e30:	e426                	sd	s1,8(sp)
    80001e32:	e04a                	sd	s2,0(sp)
    80001e34:	1000                	addi	s0,sp,32
    80001e36:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	c5a080e7          	jalr	-934(ra) # 80001a92 <myproc>
    80001e40:	892a                	mv	s2,a0
  sz = p->sz;
    80001e42:	652c                	ld	a1,72(a0)
    80001e44:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001e48:	00904f63          	bgtz	s1,80001e66 <growproc+0x3c>
  else if (n < 0)
    80001e4c:	0204cc63          	bltz	s1,80001e84 <growproc+0x5a>
  p->sz = sz;
    80001e50:	1602                	slli	a2,a2,0x20
    80001e52:	9201                	srli	a2,a2,0x20
    80001e54:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e58:	4501                	li	a0,0
}
    80001e5a:	60e2                	ld	ra,24(sp)
    80001e5c:	6442                	ld	s0,16(sp)
    80001e5e:	64a2                	ld	s1,8(sp)
    80001e60:	6902                	ld	s2,0(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001e66:	9e25                	addw	a2,a2,s1
    80001e68:	1602                	slli	a2,a2,0x20
    80001e6a:	9201                	srli	a2,a2,0x20
    80001e6c:	1582                	slli	a1,a1,0x20
    80001e6e:	9181                	srli	a1,a1,0x20
    80001e70:	6928                	ld	a0,80(a0)
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	5b8080e7          	jalr	1464(ra) # 8000142a <uvmalloc>
    80001e7a:	0005061b          	sext.w	a2,a0
    80001e7e:	fa69                	bnez	a2,80001e50 <growproc+0x26>
      return -1;
    80001e80:	557d                	li	a0,-1
    80001e82:	bfe1                	j	80001e5a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e84:	9e25                	addw	a2,a2,s1
    80001e86:	1602                	slli	a2,a2,0x20
    80001e88:	9201                	srli	a2,a2,0x20
    80001e8a:	1582                	slli	a1,a1,0x20
    80001e8c:	9181                	srli	a1,a1,0x20
    80001e8e:	6928                	ld	a0,80(a0)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	552080e7          	jalr	1362(ra) # 800013e2 <uvmdealloc>
    80001e98:	0005061b          	sext.w	a2,a0
    80001e9c:	bf55                	j	80001e50 <growproc+0x26>

0000000080001e9e <fork>:
{
    80001e9e:	7179                	addi	sp,sp,-48
    80001ea0:	f406                	sd	ra,40(sp)
    80001ea2:	f022                	sd	s0,32(sp)
    80001ea4:	ec26                	sd	s1,24(sp)
    80001ea6:	e84a                	sd	s2,16(sp)
    80001ea8:	e44e                	sd	s3,8(sp)
    80001eaa:	e052                	sd	s4,0(sp)
    80001eac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	be4080e7          	jalr	-1052(ra) # 80001a92 <myproc>
    80001eb6:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	de4080e7          	jalr	-540(ra) # 80001c9c <allocproc>
    80001ec0:	12050363          	beqz	a0,80001fe6 <fork+0x148>
    80001ec4:	89aa                	mv	s3,a0
  np->syscallno = p->syscallno;
    80001ec6:	17093783          	ld	a5,368(s2)
    80001eca:	16f53823          	sd	a5,368(a0)
  np->traceflag = p->traceflag;
    80001ece:	16892783          	lw	a5,360(s2)
    80001ed2:	16f52423          	sw	a5,360(a0)
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ed6:	04893603          	ld	a2,72(s2)
    80001eda:	692c                	ld	a1,80(a0)
    80001edc:	05093503          	ld	a0,80(s2)
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	696080e7          	jalr	1686(ra) # 80001576 <uvmcopy>
    80001ee8:	04054663          	bltz	a0,80001f34 <fork+0x96>
  np->sz = p->sz;
    80001eec:	04893783          	ld	a5,72(s2)
    80001ef0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ef4:	05893683          	ld	a3,88(s2)
    80001ef8:	87b6                	mv	a5,a3
    80001efa:	0589b703          	ld	a4,88(s3)
    80001efe:	12068693          	addi	a3,a3,288
    80001f02:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f06:	6788                	ld	a0,8(a5)
    80001f08:	6b8c                	ld	a1,16(a5)
    80001f0a:	6f90                	ld	a2,24(a5)
    80001f0c:	01073023          	sd	a6,0(a4)
    80001f10:	e708                	sd	a0,8(a4)
    80001f12:	eb0c                	sd	a1,16(a4)
    80001f14:	ef10                	sd	a2,24(a4)
    80001f16:	02078793          	addi	a5,a5,32
    80001f1a:	02070713          	addi	a4,a4,32
    80001f1e:	fed792e3          	bne	a5,a3,80001f02 <fork+0x64>
  np->trapframe->a0 = 0;
    80001f22:	0589b783          	ld	a5,88(s3)
    80001f26:	0607b823          	sd	zero,112(a5)
    80001f2a:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001f2e:	15000a13          	li	s4,336
    80001f32:	a03d                	j	80001f60 <fork+0xc2>
    freeproc(np);
    80001f34:	854e                	mv	a0,s3
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	d0e080e7          	jalr	-754(ra) # 80001c44 <freeproc>
    release(&np->lock);
    80001f3e:	854e                	mv	a0,s3
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
    return -1;
    80001f48:	5a7d                	li	s4,-1
    80001f4a:	a069                	j	80001fd4 <fork+0x136>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f4c:	00003097          	auipc	ra,0x3
    80001f50:	cdc080e7          	jalr	-804(ra) # 80004c28 <filedup>
    80001f54:	009987b3          	add	a5,s3,s1
    80001f58:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001f5a:	04a1                	addi	s1,s1,8
    80001f5c:	01448763          	beq	s1,s4,80001f6a <fork+0xcc>
    if (p->ofile[i])
    80001f60:	009907b3          	add	a5,s2,s1
    80001f64:	6388                	ld	a0,0(a5)
    80001f66:	f17d                	bnez	a0,80001f4c <fork+0xae>
    80001f68:	bfcd                	j	80001f5a <fork+0xbc>
  np->cwd = idup(p->cwd);
    80001f6a:	15093503          	ld	a0,336(s2)
    80001f6e:	00002097          	auipc	ra,0x2
    80001f72:	e30080e7          	jalr	-464(ra) # 80003d9e <idup>
    80001f76:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f7a:	4641                	li	a2,16
    80001f7c:	15890593          	addi	a1,s2,344
    80001f80:	15898513          	addi	a0,s3,344
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	eae080e7          	jalr	-338(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f8c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f90:	854e                	mv	a0,s3
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	d06080e7          	jalr	-762(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f9a:	0000f497          	auipc	s1,0xf
    80001f9e:	31e48493          	addi	s1,s1,798 # 800112b8 <wait_lock>
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	c40080e7          	jalr	-960(ra) # 80000be4 <acquire>
  np->parent = p;
    80001fac:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001fba:	854e                	mv	a0,s3
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	c28080e7          	jalr	-984(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fc4:	478d                	li	a5,3
    80001fc6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fca:	854e                	mv	a0,s3
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	ccc080e7          	jalr	-820(ra) # 80000c98 <release>
}
    80001fd4:	8552                	mv	a0,s4
    80001fd6:	70a2                	ld	ra,40(sp)
    80001fd8:	7402                	ld	s0,32(sp)
    80001fda:	64e2                	ld	s1,24(sp)
    80001fdc:	6942                	ld	s2,16(sp)
    80001fde:	69a2                	ld	s3,8(sp)
    80001fe0:	6a02                	ld	s4,0(sp)
    80001fe2:	6145                	addi	sp,sp,48
    80001fe4:	8082                	ret
    return -1;
    80001fe6:	5a7d                	li	s4,-1
    80001fe8:	b7f5                	j	80001fd4 <fork+0x136>

0000000080001fea <UpdateTime>:
{
    80001fea:	7179                	addi	sp,sp,-48
    80001fec:	f406                	sd	ra,40(sp)
    80001fee:	f022                	sd	s0,32(sp)
    80001ff0:	ec26                	sd	s1,24(sp)
    80001ff2:	e84a                	sd	s2,16(sp)
    80001ff4:	e44e                	sd	s3,8(sp)
    80001ff6:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001ff8:	00010497          	auipc	s1,0x10
    80001ffc:	10048493          	addi	s1,s1,256 # 800120f8 <proc>
    if (p->state == RUNNING)
    80002000:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002002:	00017917          	auipc	s2,0x17
    80002006:	af690913          	addi	s2,s2,-1290 # 80018af8 <tickslock>
    8000200a:	a811                	j	8000201e <UpdateTime+0x34>
    release(&p->lock);
    8000200c:	8526                	mv	a0,s1
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	c8a080e7          	jalr	-886(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002016:	1a848493          	addi	s1,s1,424
    8000201a:	03248563          	beq	s1,s2,80002044 <UpdateTime+0x5a>
    acquire(&p->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	bc4080e7          	jalr	-1084(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80002028:	4c9c                	lw	a5,24(s1)
    8000202a:	ff3791e3          	bne	a5,s3,8000200c <UpdateTime+0x22>
      p->runtime++;
    8000202e:	17c4a783          	lw	a5,380(s1)
    80002032:	2785                	addiw	a5,a5,1
    80002034:	16f4ae23          	sw	a5,380(s1)
      p->lastruntime++;
    80002038:	1904a783          	lw	a5,400(s1)
    8000203c:	2785                	addiw	a5,a5,1
    8000203e:	18f4a823          	sw	a5,400(s1)
    80002042:	b7e9                	j	8000200c <UpdateTime+0x22>
}
    80002044:	70a2                	ld	ra,40(sp)
    80002046:	7402                	ld	s0,32(sp)
    80002048:	64e2                	ld	s1,24(sp)
    8000204a:	6942                	ld	s2,16(sp)
    8000204c:	69a2                	ld	s3,8(sp)
    8000204e:	6145                	addi	sp,sp,48
    80002050:	8082                	ret

0000000080002052 <calculatedp>:
{
    80002052:	1141                	addi	sp,sp,-16
    80002054:	e422                	sd	s0,8(sp)
    80002056:	0800                	addi	s0,sp,16
  if ((p->lastsleeptime + p->lastruntime) != 0)
    80002058:	18852703          	lw	a4,392(a0)
    8000205c:	19052783          	lw	a5,400(a0)
    80002060:	9fb9                	addw	a5,a5,a4
    80002062:	0007869b          	sext.w	a3,a5
    80002066:	ca91                	beqz	a3,8000207a <calculatedp+0x28>
    p->niceness = (int)((p->lastsleeptime / (p->lastsleeptime + p->lastruntime)) * 10);
    80002068:	02f757bb          	divuw	a5,a4,a5
    8000206c:	0027971b          	slliw	a4,a5,0x2
    80002070:	9fb9                	addw	a5,a5,a4
    80002072:	0017979b          	slliw	a5,a5,0x1
    80002076:	18f52e23          	sw	a5,412(a0)
  int temp = p->staticpriority - p->niceness + 5;
    8000207a:	19852783          	lw	a5,408(a0)
    8000207e:	2795                	addiw	a5,a5,5
    80002080:	19c52503          	lw	a0,412(a0)
    80002084:	40a7853b          	subw	a0,a5,a0
    80002088:	0005079b          	sext.w	a5,a0
    8000208c:	fff7c793          	not	a5,a5
    80002090:	97fd                	srai	a5,a5,0x3f
    80002092:	8d7d                	and	a0,a0,a5
    80002094:	0005071b          	sext.w	a4,a0
    80002098:	06400793          	li	a5,100
    8000209c:	00e7d463          	bge	a5,a4,800020a4 <calculatedp+0x52>
    800020a0:	06400513          	li	a0,100
}
    800020a4:	2501                	sext.w	a0,a0
    800020a6:	6422                	ld	s0,8(sp)
    800020a8:	0141                	addi	sp,sp,16
    800020aa:	8082                	ret

00000000800020ac <UpdateQueue>:
{
    800020ac:	7159                	addi	sp,sp,-112
    800020ae:	f486                	sd	ra,104(sp)
    800020b0:	f0a2                	sd	s0,96(sp)
    800020b2:	eca6                	sd	s1,88(sp)
    800020b4:	e8ca                	sd	s2,80(sp)
    800020b6:	e4ce                	sd	s3,72(sp)
    800020b8:	e0d2                	sd	s4,64(sp)
    800020ba:	fc56                	sd	s5,56(sp)
    800020bc:	f85a                	sd	s6,48(sp)
    800020be:	f45e                	sd	s7,40(sp)
    800020c0:	1880                	addi	s0,sp,112
  int timeslice[] = {1, 2, 4, 8, 16};
    800020c2:	4785                	li	a5,1
    800020c4:	f8f42c23          	sw	a5,-104(s0)
    800020c8:	4789                	li	a5,2
    800020ca:	f8f42e23          	sw	a5,-100(s0)
    800020ce:	4791                	li	a5,4
    800020d0:	faf42023          	sw	a5,-96(s0)
    800020d4:	47a1                	li	a5,8
    800020d6:	faf42223          	sw	a5,-92(s0)
    800020da:	47c1                	li	a5,16
    800020dc:	faf42423          	sw	a5,-88(s0)
  for (int i = 0; i < 5; i++)
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	5f048493          	addi	s1,s1,1520 # 800116d0 <quelist>
    800020e8:	f9840993          	addi	s3,s0,-104
    800020ec:	00010a97          	auipc	s5,0x10
    800020f0:	00ca8a93          	addi	s5,s5,12 # 800120f8 <proc>
    if (t->lastidx == -1)
    800020f4:	5a7d                	li	s4,-1
    printf("HELLO\n");
    800020f6:	00006b17          	auipc	s6,0x6
    800020fa:	122b0b13          	addi	s6,s6,290 # 80008218 <digits+0x1d8>
    800020fe:	a09d                	j	80002164 <UpdateQueue+0xb8>
      printf("HELLO\n");
    80002100:	00006517          	auipc	a0,0x6
    80002104:	11850513          	addi	a0,a0,280 # 80008218 <digits+0x1d8>
    80002108:	ffffe097          	auipc	ra,0xffffe
    8000210c:	480080e7          	jalr	1152(ra) # 80000588 <printf>
      p->lastruntime = 0;
    80002110:	18092823          	sw	zero,400(s2)
      pop(p->queno, p);
    80002114:	85ca                	mv	a1,s2
    80002116:	1a492503          	lw	a0,420(s2)
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	792080e7          	jalr	1938(ra) # 800018ac <pop>
      if (p->queno < 4)
    80002122:	1a492503          	lw	a0,420(s2)
    80002126:	478d                	li	a5,3
    80002128:	00a7ee63          	bltu	a5,a0,80002144 <UpdateQueue+0x98>
        push(p->queno + 1, p);
    8000212c:	85ca                	mv	a1,s2
    8000212e:	2505                	addiw	a0,a0,1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	740080e7          	jalr	1856(ra) # 80001870 <push>
        release(&p->lock);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	b5e080e7          	jalr	-1186(ra) # 80000c98 <release>
        return p;
    80002142:	a8b1                	j	8000219e <UpdateQueue+0xf2>
      push(p->queno,p);
    80002144:	85ca                	mv	a1,s2
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	72a080e7          	jalr	1834(ra) # 80001870 <push>
      release(&p->lock);
    8000214e:	854a                	mv	a0,s2
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b48080e7          	jalr	-1208(ra) # 80000c98 <release>
      return p;
    80002158:	a099                	j	8000219e <UpdateQueue+0xf2>
  for (int i = 0; i < 5; i++)
    8000215a:	20848493          	addi	s1,s1,520
    8000215e:	0991                	addi	s3,s3,4
    80002160:	03548e63          	beq	s1,s5,8000219c <UpdateQueue+0xf0>
    if (t->lastidx == -1)
    80002164:	2004a783          	lw	a5,512(s1)
    80002168:	ff4789e3          	beq	a5,s4,8000215a <UpdateQueue+0xae>
    p = t->proclist[0];
    8000216c:	0004b903          	ld	s2,0(s1)
    printf("HELLO\n");
    80002170:	855a                	mv	a0,s6
    80002172:	ffffe097          	auipc	ra,0xffffe
    80002176:	416080e7          	jalr	1046(ra) # 80000588 <printf>
    acquire(&p->lock);
    8000217a:	854a                	mv	a0,s2
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
    if (p->lastruntime >= timeslice[i])
    80002184:	19092703          	lw	a4,400(s2)
    80002188:	0009a783          	lw	a5,0(s3)
    8000218c:	f6f77ae3          	bgeu	a4,a5,80002100 <UpdateQueue+0x54>
    release(&p->lock);
    80002190:	854a                	mv	a0,s2
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
    8000219a:	b7c1                	j	8000215a <UpdateQueue+0xae>
  return 0;
    8000219c:	4901                	li	s2,0
}
    8000219e:	854a                	mv	a0,s2
    800021a0:	70a6                	ld	ra,104(sp)
    800021a2:	7406                	ld	s0,96(sp)
    800021a4:	64e6                	ld	s1,88(sp)
    800021a6:	6946                	ld	s2,80(sp)
    800021a8:	69a6                	ld	s3,72(sp)
    800021aa:	6a06                	ld	s4,64(sp)
    800021ac:	7ae2                	ld	s5,56(sp)
    800021ae:	7b42                	ld	s6,48(sp)
    800021b0:	7ba2                	ld	s7,40(sp)
    800021b2:	6165                	addi	sp,sp,112
    800021b4:	8082                	ret

00000000800021b6 <scheduler>:
{
    800021b6:	7139                	addi	sp,sp,-64
    800021b8:	fc06                	sd	ra,56(sp)
    800021ba:	f822                	sd	s0,48(sp)
    800021bc:	f426                	sd	s1,40(sp)
    800021be:	f04a                	sd	s2,32(sp)
    800021c0:	ec4e                	sd	s3,24(sp)
    800021c2:	e852                	sd	s4,16(sp)
    800021c4:	e456                	sd	s5,8(sp)
    800021c6:	e05a                	sd	s6,0(sp)
    800021c8:	0080                	addi	s0,sp,64
    800021ca:	8792                	mv	a5,tp
  int id = r_tp();
    800021cc:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021ce:	00779a93          	slli	s5,a5,0x7
    800021d2:	0000f717          	auipc	a4,0xf
    800021d6:	0ce70713          	addi	a4,a4,206 # 800112a0 <pid_lock>
    800021da:	9756                	add	a4,a4,s5
    800021dc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021e0:	0000f717          	auipc	a4,0xf
    800021e4:	0f870713          	addi	a4,a4,248 # 800112d8 <cpus+0x8>
    800021e8:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800021ea:	498d                	li	s3,3
        p->state = RUNNING;
    800021ec:	4b11                	li	s6,4
        c->proc = p;
    800021ee:	079e                	slli	a5,a5,0x7
    800021f0:	0000fa17          	auipc	s4,0xf
    800021f4:	0b0a0a13          	addi	s4,s4,176 # 800112a0 <pid_lock>
    800021f8:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021fa:	00017917          	auipc	s2,0x17
    800021fe:	8fe90913          	addi	s2,s2,-1794 # 80018af8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002202:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002206:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000220a:	10079073          	csrw	sstatus,a5
    8000220e:	00010497          	auipc	s1,0x10
    80002212:	eea48493          	addi	s1,s1,-278 # 800120f8 <proc>
    80002216:	a03d                	j	80002244 <scheduler+0x8e>
        p->state = RUNNING;
    80002218:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000221c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002220:	06048593          	addi	a1,s1,96
    80002224:	8556                	mv	a0,s5
    80002226:	00001097          	auipc	ra,0x1
    8000222a:	8d2080e7          	jalr	-1838(ra) # 80002af8 <swtch>
        c->proc = 0;
    8000222e:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000223c:	1a848493          	addi	s1,s1,424
    80002240:	fd2481e3          	beq	s1,s2,80002202 <scheduler+0x4c>
      acquire(&p->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	99e080e7          	jalr	-1634(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    8000224e:	4c9c                	lw	a5,24(s1)
    80002250:	ff3791e3          	bne	a5,s3,80002232 <scheduler+0x7c>
    80002254:	b7d1                	j	80002218 <scheduler+0x62>

0000000080002256 <sched>:
{
    80002256:	7179                	addi	sp,sp,-48
    80002258:	f406                	sd	ra,40(sp)
    8000225a:	f022                	sd	s0,32(sp)
    8000225c:	ec26                	sd	s1,24(sp)
    8000225e:	e84a                	sd	s2,16(sp)
    80002260:	e44e                	sd	s3,8(sp)
    80002262:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002264:	00000097          	auipc	ra,0x0
    80002268:	82e080e7          	jalr	-2002(ra) # 80001a92 <myproc>
    8000226c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	8fc080e7          	jalr	-1796(ra) # 80000b6a <holding>
    80002276:	c93d                	beqz	a0,800022ec <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002278:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000227a:	2781                	sext.w	a5,a5
    8000227c:	079e                	slli	a5,a5,0x7
    8000227e:	0000f717          	auipc	a4,0xf
    80002282:	02270713          	addi	a4,a4,34 # 800112a0 <pid_lock>
    80002286:	97ba                	add	a5,a5,a4
    80002288:	0a87a703          	lw	a4,168(a5)
    8000228c:	4785                	li	a5,1
    8000228e:	06f71763          	bne	a4,a5,800022fc <sched+0xa6>
  if (p->state == RUNNING)
    80002292:	4c98                	lw	a4,24(s1)
    80002294:	4791                	li	a5,4
    80002296:	06f70b63          	beq	a4,a5,8000230c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000229a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000229e:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022a0:	efb5                	bnez	a5,8000231c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022a2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022a4:	0000f917          	auipc	s2,0xf
    800022a8:	ffc90913          	addi	s2,s2,-4 # 800112a0 <pid_lock>
    800022ac:	2781                	sext.w	a5,a5
    800022ae:	079e                	slli	a5,a5,0x7
    800022b0:	97ca                	add	a5,a5,s2
    800022b2:	0ac7a983          	lw	s3,172(a5)
    800022b6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022b8:	2781                	sext.w	a5,a5
    800022ba:	079e                	slli	a5,a5,0x7
    800022bc:	0000f597          	auipc	a1,0xf
    800022c0:	01c58593          	addi	a1,a1,28 # 800112d8 <cpus+0x8>
    800022c4:	95be                	add	a1,a1,a5
    800022c6:	06048513          	addi	a0,s1,96
    800022ca:	00001097          	auipc	ra,0x1
    800022ce:	82e080e7          	jalr	-2002(ra) # 80002af8 <swtch>
    800022d2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022d4:	2781                	sext.w	a5,a5
    800022d6:	079e                	slli	a5,a5,0x7
    800022d8:	97ca                	add	a5,a5,s2
    800022da:	0b37a623          	sw	s3,172(a5)
}
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6942                	ld	s2,16(sp)
    800022e6:	69a2                	ld	s3,8(sp)
    800022e8:	6145                	addi	sp,sp,48
    800022ea:	8082                	ret
    panic("sched p->lock");
    800022ec:	00006517          	auipc	a0,0x6
    800022f0:	f3450513          	addi	a0,a0,-204 # 80008220 <digits+0x1e0>
    800022f4:	ffffe097          	auipc	ra,0xffffe
    800022f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
    panic("sched locks");
    800022fc:	00006517          	auipc	a0,0x6
    80002300:	f3450513          	addi	a0,a0,-204 # 80008230 <digits+0x1f0>
    80002304:	ffffe097          	auipc	ra,0xffffe
    80002308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
    panic("sched running");
    8000230c:	00006517          	auipc	a0,0x6
    80002310:	f3450513          	addi	a0,a0,-204 # 80008240 <digits+0x200>
    80002314:	ffffe097          	auipc	ra,0xffffe
    80002318:	22a080e7          	jalr	554(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000231c:	00006517          	auipc	a0,0x6
    80002320:	f3450513          	addi	a0,a0,-204 # 80008250 <digits+0x210>
    80002324:	ffffe097          	auipc	ra,0xffffe
    80002328:	21a080e7          	jalr	538(ra) # 8000053e <panic>

000000008000232c <yield>:
{
    8000232c:	1101                	addi	sp,sp,-32
    8000232e:	ec06                	sd	ra,24(sp)
    80002330:	e822                	sd	s0,16(sp)
    80002332:	e426                	sd	s1,8(sp)
    80002334:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	75c080e7          	jalr	1884(ra) # 80001a92 <myproc>
    8000233e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	8a4080e7          	jalr	-1884(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002348:	478d                	li	a5,3
    8000234a:	cc9c                	sw	a5,24(s1)
  sched();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	f0a080e7          	jalr	-246(ra) # 80002256 <sched>
  release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
}
    8000235e:	60e2                	ld	ra,24(sp)
    80002360:	6442                	ld	s0,16(sp)
    80002362:	64a2                	ld	s1,8(sp)
    80002364:	6105                	addi	sp,sp,32
    80002366:	8082                	ret

0000000080002368 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002368:	7179                	addi	sp,sp,-48
    8000236a:	f406                	sd	ra,40(sp)
    8000236c:	f022                	sd	s0,32(sp)
    8000236e:	ec26                	sd	s1,24(sp)
    80002370:	e84a                	sd	s2,16(sp)
    80002372:	e44e                	sd	s3,8(sp)
    80002374:	1800                	addi	s0,sp,48
    80002376:	89aa                	mv	s3,a0
    80002378:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	718080e7          	jalr	1816(ra) # 80001a92 <myproc>
    80002382:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	860080e7          	jalr	-1952(ra) # 80000be4 <acquire>
  release(lk);
    8000238c:	854a                	mv	a0,s2
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	90a080e7          	jalr	-1782(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002396:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000239a:	4789                	li	a5,2
    8000239c:	cc9c                	sw	a5,24(s1)
  p->sleepstart = ticks;
    8000239e:	00007797          	auipc	a5,0x7
    800023a2:	c927a783          	lw	a5,-878(a5) # 80009030 <ticks>
    800023a6:	18f4a623          	sw	a5,396(s1)
  #ifdef MLFQ
      pop(p->queno, p);
  #endif
  sched();
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	eac080e7          	jalr	-340(ra) # 80002256 <sched>

  // Tidy up.
  p->chan = 0;
    800023b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
  acquire(lk);
    800023c0:	854a                	mv	a0,s2
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6145                	addi	sp,sp,48
    800023d6:	8082                	ret

00000000800023d8 <wait>:
{
    800023d8:	715d                	addi	sp,sp,-80
    800023da:	e486                	sd	ra,72(sp)
    800023dc:	e0a2                	sd	s0,64(sp)
    800023de:	fc26                	sd	s1,56(sp)
    800023e0:	f84a                	sd	s2,48(sp)
    800023e2:	f44e                	sd	s3,40(sp)
    800023e4:	f052                	sd	s4,32(sp)
    800023e6:	ec56                	sd	s5,24(sp)
    800023e8:	e85a                	sd	s6,16(sp)
    800023ea:	e45e                	sd	s7,8(sp)
    800023ec:	e062                	sd	s8,0(sp)
    800023ee:	0880                	addi	s0,sp,80
    800023f0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	6a0080e7          	jalr	1696(ra) # 80001a92 <myproc>
    800023fa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023fc:	0000f517          	auipc	a0,0xf
    80002400:	ebc50513          	addi	a0,a0,-324 # 800112b8 <wait_lock>
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	7e0080e7          	jalr	2016(ra) # 80000be4 <acquire>
    havekids = 0;
    8000240c:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000240e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002410:	00016997          	auipc	s3,0x16
    80002414:	6e898993          	addi	s3,s3,1768 # 80018af8 <tickslock>
        havekids = 1;
    80002418:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000241a:	0000fc17          	auipc	s8,0xf
    8000241e:	e9ec0c13          	addi	s8,s8,-354 # 800112b8 <wait_lock>
    havekids = 0;
    80002422:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002424:	00010497          	auipc	s1,0x10
    80002428:	cd448493          	addi	s1,s1,-812 # 800120f8 <proc>
    8000242c:	a8ad                	j	800024a6 <wait+0xce>
          pid = np->pid;
    8000242e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002432:	000b0e63          	beqz	s6,8000244e <wait+0x76>
    80002436:	4691                	li	a3,4
    80002438:	02c48613          	addi	a2,s1,44
    8000243c:	85da                	mv	a1,s6
    8000243e:	05093503          	ld	a0,80(s2)
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	238080e7          	jalr	568(ra) # 8000167a <copyout>
    8000244a:	02054b63          	bltz	a0,80002480 <wait+0xa8>
          np->endtime = ticks;
    8000244e:	00007797          	auipc	a5,0x7
    80002452:	be27a783          	lw	a5,-1054(a5) # 80009030 <ticks>
    80002456:	18f4a023          	sw	a5,384(s1)
          freeproc(np);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	7e8080e7          	jalr	2024(ra) # 80001c44 <freeproc>
          release(&np->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	832080e7          	jalr	-1998(ra) # 80000c98 <release>
          release(&wait_lock);
    8000246e:	0000f517          	auipc	a0,0xf
    80002472:	e4a50513          	addi	a0,a0,-438 # 800112b8 <wait_lock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
          return pid;
    8000247e:	a09d                	j	800024e4 <wait+0x10c>
            release(&np->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
            release(&wait_lock);
    8000248a:	0000f517          	auipc	a0,0xf
    8000248e:	e2e50513          	addi	a0,a0,-466 # 800112b8 <wait_lock>
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
            return -1;
    8000249a:	59fd                	li	s3,-1
    8000249c:	a0a1                	j	800024e4 <wait+0x10c>
    for (np = proc; np < &proc[NPROC]; np++)
    8000249e:	1a848493          	addi	s1,s1,424
    800024a2:	03348463          	beq	s1,s3,800024ca <wait+0xf2>
      if (np->parent == p)
    800024a6:	7c9c                	ld	a5,56(s1)
    800024a8:	ff279be3          	bne	a5,s2,8000249e <wait+0xc6>
        acquire(&np->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800024b6:	4c9c                	lw	a5,24(s1)
    800024b8:	f7478be3          	beq	a5,s4,8000242e <wait+0x56>
        release(&np->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	7da080e7          	jalr	2010(ra) # 80000c98 <release>
        havekids = 1;
    800024c6:	8756                	mv	a4,s5
    800024c8:	bfd9                	j	8000249e <wait+0xc6>
    if (!havekids || p->killed)
    800024ca:	c701                	beqz	a4,800024d2 <wait+0xfa>
    800024cc:	02892783          	lw	a5,40(s2)
    800024d0:	c79d                	beqz	a5,800024fe <wait+0x126>
      release(&wait_lock);
    800024d2:	0000f517          	auipc	a0,0xf
    800024d6:	de650513          	addi	a0,a0,-538 # 800112b8 <wait_lock>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7be080e7          	jalr	1982(ra) # 80000c98 <release>
      return -1;
    800024e2:	59fd                	li	s3,-1
}
    800024e4:	854e                	mv	a0,s3
    800024e6:	60a6                	ld	ra,72(sp)
    800024e8:	6406                	ld	s0,64(sp)
    800024ea:	74e2                	ld	s1,56(sp)
    800024ec:	7942                	ld	s2,48(sp)
    800024ee:	79a2                	ld	s3,40(sp)
    800024f0:	7a02                	ld	s4,32(sp)
    800024f2:	6ae2                	ld	s5,24(sp)
    800024f4:	6b42                	ld	s6,16(sp)
    800024f6:	6ba2                	ld	s7,8(sp)
    800024f8:	6c02                	ld	s8,0(sp)
    800024fa:	6161                	addi	sp,sp,80
    800024fc:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800024fe:	85e2                	mv	a1,s8
    80002500:	854a                	mv	a0,s2
    80002502:	00000097          	auipc	ra,0x0
    80002506:	e66080e7          	jalr	-410(ra) # 80002368 <sleep>
    havekids = 0;
    8000250a:	bf21                	j	80002422 <wait+0x4a>

000000008000250c <waitx>:
{
    8000250c:	711d                	addi	sp,sp,-96
    8000250e:	ec86                	sd	ra,88(sp)
    80002510:	e8a2                	sd	s0,80(sp)
    80002512:	e4a6                	sd	s1,72(sp)
    80002514:	e0ca                	sd	s2,64(sp)
    80002516:	fc4e                	sd	s3,56(sp)
    80002518:	f852                	sd	s4,48(sp)
    8000251a:	f456                	sd	s5,40(sp)
    8000251c:	f05a                	sd	s6,32(sp)
    8000251e:	ec5e                	sd	s7,24(sp)
    80002520:	e862                	sd	s8,16(sp)
    80002522:	e466                	sd	s9,8(sp)
    80002524:	e06a                	sd	s10,0(sp)
    80002526:	1080                	addi	s0,sp,96
    80002528:	8b2a                	mv	s6,a0
    8000252a:	8c2e                	mv	s8,a1
    8000252c:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	564080e7          	jalr	1380(ra) # 80001a92 <myproc>
    80002536:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002538:	0000f517          	auipc	a0,0xf
    8000253c:	d8050513          	addi	a0,a0,-640 # 800112b8 <wait_lock>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	6a4080e7          	jalr	1700(ra) # 80000be4 <acquire>
    havekids = 0;
    80002548:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000254a:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000254c:	00016997          	auipc	s3,0x16
    80002550:	5ac98993          	addi	s3,s3,1452 # 80018af8 <tickslock>
        havekids = 1;
    80002554:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002556:	0000fd17          	auipc	s10,0xf
    8000255a:	d62d0d13          	addi	s10,s10,-670 # 800112b8 <wait_lock>
    havekids = 0;
    8000255e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002560:	00010497          	auipc	s1,0x10
    80002564:	b9848493          	addi	s1,s1,-1128 # 800120f8 <proc>
    80002568:	a059                	j	800025ee <waitx+0xe2>
          pid = np->pid;
    8000256a:	0304a983          	lw	s3,48(s1)
          *rtime = np->runtime;
    8000256e:	17c4a703          	lw	a4,380(s1)
    80002572:	00ec2023          	sw	a4,0(s8)
          *wtime = np->endtime - np->ctime - np->runtime;
    80002576:	1784a783          	lw	a5,376(s1)
    8000257a:	9f3d                	addw	a4,a4,a5
    8000257c:	1804a783          	lw	a5,384(s1)
    80002580:	9f99                	subw	a5,a5,a4
    80002582:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd8000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002586:	000b0e63          	beqz	s6,800025a2 <waitx+0x96>
    8000258a:	4691                	li	a3,4
    8000258c:	02c48613          	addi	a2,s1,44
    80002590:	85da                	mv	a1,s6
    80002592:	05093503          	ld	a0,80(s2)
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	0e4080e7          	jalr	228(ra) # 8000167a <copyout>
    8000259e:	02054563          	bltz	a0,800025c8 <waitx+0xbc>
          freeproc(np);
    800025a2:	8526                	mv	a0,s1
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	6a0080e7          	jalr	1696(ra) # 80001c44 <freeproc>
          release(&np->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
          release(&wait_lock);
    800025b6:	0000f517          	auipc	a0,0xf
    800025ba:	d0250513          	addi	a0,a0,-766 # 800112b8 <wait_lock>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	6da080e7          	jalr	1754(ra) # 80000c98 <release>
          return pid;
    800025c6:	a09d                	j	8000262c <waitx+0x120>
            release(&np->lock);
    800025c8:	8526                	mv	a0,s1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	6ce080e7          	jalr	1742(ra) # 80000c98 <release>
            release(&wait_lock);
    800025d2:	0000f517          	auipc	a0,0xf
    800025d6:	ce650513          	addi	a0,a0,-794 # 800112b8 <wait_lock>
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
            return -1;
    800025e2:	59fd                	li	s3,-1
    800025e4:	a0a1                	j	8000262c <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800025e6:	1a848493          	addi	s1,s1,424
    800025ea:	03348463          	beq	s1,s3,80002612 <waitx+0x106>
      if (np->parent == p)
    800025ee:	7c9c                	ld	a5,56(s1)
    800025f0:	ff279be3          	bne	a5,s2,800025e6 <waitx+0xda>
        acquire(&np->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	5ee080e7          	jalr	1518(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800025fe:	4c9c                	lw	a5,24(s1)
    80002600:	f74785e3          	beq	a5,s4,8000256a <waitx+0x5e>
        release(&np->lock);
    80002604:	8526                	mv	a0,s1
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	692080e7          	jalr	1682(ra) # 80000c98 <release>
        havekids = 1;
    8000260e:	8756                	mv	a4,s5
    80002610:	bfd9                	j	800025e6 <waitx+0xda>
    if (!havekids || p->killed)
    80002612:	c701                	beqz	a4,8000261a <waitx+0x10e>
    80002614:	02892783          	lw	a5,40(s2)
    80002618:	cb8d                	beqz	a5,8000264a <waitx+0x13e>
      release(&wait_lock);
    8000261a:	0000f517          	auipc	a0,0xf
    8000261e:	c9e50513          	addi	a0,a0,-866 # 800112b8 <wait_lock>
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	676080e7          	jalr	1654(ra) # 80000c98 <release>
      return -1;
    8000262a:	59fd                	li	s3,-1
}
    8000262c:	854e                	mv	a0,s3
    8000262e:	60e6                	ld	ra,88(sp)
    80002630:	6446                	ld	s0,80(sp)
    80002632:	64a6                	ld	s1,72(sp)
    80002634:	6906                	ld	s2,64(sp)
    80002636:	79e2                	ld	s3,56(sp)
    80002638:	7a42                	ld	s4,48(sp)
    8000263a:	7aa2                	ld	s5,40(sp)
    8000263c:	7b02                	ld	s6,32(sp)
    8000263e:	6be2                	ld	s7,24(sp)
    80002640:	6c42                	ld	s8,16(sp)
    80002642:	6ca2                	ld	s9,8(sp)
    80002644:	6d02                	ld	s10,0(sp)
    80002646:	6125                	addi	sp,sp,96
    80002648:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000264a:	85ea                	mv	a1,s10
    8000264c:	854a                	mv	a0,s2
    8000264e:	00000097          	auipc	ra,0x0
    80002652:	d1a080e7          	jalr	-742(ra) # 80002368 <sleep>
    havekids = 0;
    80002656:	b721                	j	8000255e <waitx+0x52>

0000000080002658 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002658:	7139                	addi	sp,sp,-64
    8000265a:	fc06                	sd	ra,56(sp)
    8000265c:	f822                	sd	s0,48(sp)
    8000265e:	f426                	sd	s1,40(sp)
    80002660:	f04a                	sd	s2,32(sp)
    80002662:	ec4e                	sd	s3,24(sp)
    80002664:	e852                	sd	s4,16(sp)
    80002666:	e456                	sd	s5,8(sp)
    80002668:	e05a                	sd	s6,0(sp)
    8000266a:	0080                	addi	s0,sp,64
    8000266c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000266e:	00010497          	auipc	s1,0x10
    80002672:	a8a48493          	addi	s1,s1,-1398 # 800120f8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002676:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002678:	4a8d                	li	s5,3
        if (p->sleepstart != 0)
        {
          p->lastsleeptime = ticks - p->sleepstart;
    8000267a:	00007b17          	auipc	s6,0x7
    8000267e:	9b6b0b13          	addi	s6,s6,-1610 # 80009030 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002682:	00016917          	auipc	s2,0x16
    80002686:	47690913          	addi	s2,s2,1142 # 80018af8 <tickslock>
    8000268a:	a811                	j	8000269e <wakeup+0x46>
        }
      }
      #ifdef MLFQ
          push(p->queno, p);
      #endif
      release(&p->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	60a080e7          	jalr	1546(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002696:	1a848493          	addi	s1,s1,424
    8000269a:	05248463          	beq	s1,s2,800026e2 <wakeup+0x8a>
    if (p != myproc())
    8000269e:	fffff097          	auipc	ra,0xfffff
    800026a2:	3f4080e7          	jalr	1012(ra) # 80001a92 <myproc>
    800026a6:	fea488e3          	beq	s1,a0,80002696 <wakeup+0x3e>
      acquire(&p->lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800026b4:	4c9c                	lw	a5,24(s1)
    800026b6:	fd379be3          	bne	a5,s3,8000268c <wakeup+0x34>
    800026ba:	709c                	ld	a5,32(s1)
    800026bc:	fd4798e3          	bne	a5,s4,8000268c <wakeup+0x34>
        p->state = RUNNABLE;
    800026c0:	0154ac23          	sw	s5,24(s1)
        if (p->sleepstart != 0)
    800026c4:	18c4a783          	lw	a5,396(s1)
    800026c8:	d3f1                	beqz	a5,8000268c <wakeup+0x34>
          p->lastsleeptime = ticks - p->sleepstart;
    800026ca:	000b2703          	lw	a4,0(s6)
    800026ce:	40f707bb          	subw	a5,a4,a5
    800026d2:	18f4a423          	sw	a5,392(s1)
          p->totalsleeptime += p->lastsleeptime;
    800026d6:	1844a703          	lw	a4,388(s1)
    800026da:	9fb9                	addw	a5,a5,a4
    800026dc:	18f4a223          	sw	a5,388(s1)
    800026e0:	b775                	j	8000268c <wakeup+0x34>
    }
  }
}
    800026e2:	70e2                	ld	ra,56(sp)
    800026e4:	7442                	ld	s0,48(sp)
    800026e6:	74a2                	ld	s1,40(sp)
    800026e8:	7902                	ld	s2,32(sp)
    800026ea:	69e2                	ld	s3,24(sp)
    800026ec:	6a42                	ld	s4,16(sp)
    800026ee:	6aa2                	ld	s5,8(sp)
    800026f0:	6b02                	ld	s6,0(sp)
    800026f2:	6121                	addi	sp,sp,64
    800026f4:	8082                	ret

00000000800026f6 <reparent>:
{
    800026f6:	7179                	addi	sp,sp,-48
    800026f8:	f406                	sd	ra,40(sp)
    800026fa:	f022                	sd	s0,32(sp)
    800026fc:	ec26                	sd	s1,24(sp)
    800026fe:	e84a                	sd	s2,16(sp)
    80002700:	e44e                	sd	s3,8(sp)
    80002702:	e052                	sd	s4,0(sp)
    80002704:	1800                	addi	s0,sp,48
    80002706:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002708:	00010497          	auipc	s1,0x10
    8000270c:	9f048493          	addi	s1,s1,-1552 # 800120f8 <proc>
      pp->parent = initproc;
    80002710:	00007a17          	auipc	s4,0x7
    80002714:	918a0a13          	addi	s4,s4,-1768 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002718:	00016997          	auipc	s3,0x16
    8000271c:	3e098993          	addi	s3,s3,992 # 80018af8 <tickslock>
    80002720:	a029                	j	8000272a <reparent+0x34>
    80002722:	1a848493          	addi	s1,s1,424
    80002726:	01348d63          	beq	s1,s3,80002740 <reparent+0x4a>
    if (pp->parent == p)
    8000272a:	7c9c                	ld	a5,56(s1)
    8000272c:	ff279be3          	bne	a5,s2,80002722 <reparent+0x2c>
      pp->parent = initproc;
    80002730:	000a3503          	ld	a0,0(s4)
    80002734:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002736:	00000097          	auipc	ra,0x0
    8000273a:	f22080e7          	jalr	-222(ra) # 80002658 <wakeup>
    8000273e:	b7d5                	j	80002722 <reparent+0x2c>
}
    80002740:	70a2                	ld	ra,40(sp)
    80002742:	7402                	ld	s0,32(sp)
    80002744:	64e2                	ld	s1,24(sp)
    80002746:	6942                	ld	s2,16(sp)
    80002748:	69a2                	ld	s3,8(sp)
    8000274a:	6a02                	ld	s4,0(sp)
    8000274c:	6145                	addi	sp,sp,48
    8000274e:	8082                	ret

0000000080002750 <exit>:
{
    80002750:	7179                	addi	sp,sp,-48
    80002752:	f406                	sd	ra,40(sp)
    80002754:	f022                	sd	s0,32(sp)
    80002756:	ec26                	sd	s1,24(sp)
    80002758:	e84a                	sd	s2,16(sp)
    8000275a:	e44e                	sd	s3,8(sp)
    8000275c:	e052                	sd	s4,0(sp)
    8000275e:	1800                	addi	s0,sp,48
    80002760:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	330080e7          	jalr	816(ra) # 80001a92 <myproc>
    8000276a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000276c:	00007797          	auipc	a5,0x7
    80002770:	8bc7b783          	ld	a5,-1860(a5) # 80009028 <initproc>
    80002774:	0d050493          	addi	s1,a0,208
    80002778:	15050913          	addi	s2,a0,336
    8000277c:	02a79363          	bne	a5,a0,800027a2 <exit+0x52>
    panic("init exiting");
    80002780:	00006517          	auipc	a0,0x6
    80002784:	ae850513          	addi	a0,a0,-1304 # 80008268 <digits+0x228>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>
      fileclose(f);
    80002790:	00002097          	auipc	ra,0x2
    80002794:	4ea080e7          	jalr	1258(ra) # 80004c7a <fileclose>
      p->ofile[fd] = 0;
    80002798:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000279c:	04a1                	addi	s1,s1,8
    8000279e:	01248563          	beq	s1,s2,800027a8 <exit+0x58>
    if (p->ofile[fd])
    800027a2:	6088                	ld	a0,0(s1)
    800027a4:	f575                	bnez	a0,80002790 <exit+0x40>
    800027a6:	bfdd                	j	8000279c <exit+0x4c>
  begin_op();
    800027a8:	00002097          	auipc	ra,0x2
    800027ac:	006080e7          	jalr	6(ra) # 800047ae <begin_op>
  iput(p->cwd);
    800027b0:	1509b503          	ld	a0,336(s3)
    800027b4:	00001097          	auipc	ra,0x1
    800027b8:	7e2080e7          	jalr	2018(ra) # 80003f96 <iput>
  end_op();
    800027bc:	00002097          	auipc	ra,0x2
    800027c0:	072080e7          	jalr	114(ra) # 8000482e <end_op>
  p->cwd = 0;
    800027c4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800027c8:	0000f497          	auipc	s1,0xf
    800027cc:	af048493          	addi	s1,s1,-1296 # 800112b8 <wait_lock>
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	412080e7          	jalr	1042(ra) # 80000be4 <acquire>
  reparent(p);
    800027da:	854e                	mv	a0,s3
    800027dc:	00000097          	auipc	ra,0x0
    800027e0:	f1a080e7          	jalr	-230(ra) # 800026f6 <reparent>
  wakeup(p->parent);
    800027e4:	0389b503          	ld	a0,56(s3)
    800027e8:	00000097          	auipc	ra,0x0
    800027ec:	e70080e7          	jalr	-400(ra) # 80002658 <wakeup>
  acquire(&p->lock);
    800027f0:	854e                	mv	a0,s3
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	3f2080e7          	jalr	1010(ra) # 80000be4 <acquire>
  p->xstate = status;
    800027fa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027fe:	4795                	li	a5,5
    80002800:	00f9ac23          	sw	a5,24(s3)
  p->endtime = ticks;
    80002804:	00007797          	auipc	a5,0x7
    80002808:	82c7a783          	lw	a5,-2004(a5) # 80009030 <ticks>
    8000280c:	18f9a023          	sw	a5,384(s3)
  release(&wait_lock);
    80002810:	8526                	mv	a0,s1
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
  sched();
    8000281a:	00000097          	auipc	ra,0x0
    8000281e:	a3c080e7          	jalr	-1476(ra) # 80002256 <sched>
  panic("zombie exit");
    80002822:	00006517          	auipc	a0,0x6
    80002826:	a5650513          	addi	a0,a0,-1450 # 80008278 <digits+0x238>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080002832 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002832:	7179                	addi	sp,sp,-48
    80002834:	f406                	sd	ra,40(sp)
    80002836:	f022                	sd	s0,32(sp)
    80002838:	ec26                	sd	s1,24(sp)
    8000283a:	e84a                	sd	s2,16(sp)
    8000283c:	e44e                	sd	s3,8(sp)
    8000283e:	1800                	addi	s0,sp,48
    80002840:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002842:	00010497          	auipc	s1,0x10
    80002846:	8b648493          	addi	s1,s1,-1866 # 800120f8 <proc>
    8000284a:	00016997          	auipc	s3,0x16
    8000284e:	2ae98993          	addi	s3,s3,686 # 80018af8 <tickslock>
  {
    acquire(&p->lock);
    80002852:	8526                	mv	a0,s1
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	390080e7          	jalr	912(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000285c:	589c                	lw	a5,48(s1)
    8000285e:	01278d63          	beq	a5,s2,80002878 <kill+0x46>
        p->lastsleeptime = ticks - p->sleepstart;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	434080e7          	jalr	1076(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000286c:	1a848493          	addi	s1,s1,424
    80002870:	ff3491e3          	bne	s1,s3,80002852 <kill+0x20>
  }
  return -1;
    80002874:	557d                	li	a0,-1
    80002876:	a829                	j	80002890 <kill+0x5e>
      p->killed = 1;
    80002878:	4785                	li	a5,1
    8000287a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000287c:	4c98                	lw	a4,24(s1)
    8000287e:	4789                	li	a5,2
    80002880:	00f70f63          	beq	a4,a5,8000289e <kill+0x6c>
      release(&p->lock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	412080e7          	jalr	1042(ra) # 80000c98 <release>
      return 0;
    8000288e:	4501                	li	a0,0
}
    80002890:	70a2                	ld	ra,40(sp)
    80002892:	7402                	ld	s0,32(sp)
    80002894:	64e2                	ld	s1,24(sp)
    80002896:	6942                	ld	s2,16(sp)
    80002898:	69a2                	ld	s3,8(sp)
    8000289a:	6145                	addi	sp,sp,48
    8000289c:	8082                	ret
        p->state = RUNNABLE;
    8000289e:	478d                	li	a5,3
    800028a0:	cc9c                	sw	a5,24(s1)
        p->lastsleeptime = ticks - p->sleepstart;
    800028a2:	18c4a703          	lw	a4,396(s1)
    800028a6:	00006797          	auipc	a5,0x6
    800028aa:	78a7a783          	lw	a5,1930(a5) # 80009030 <ticks>
    800028ae:	9f99                	subw	a5,a5,a4
    800028b0:	18f4a423          	sw	a5,392(s1)
    800028b4:	bfc1                	j	80002884 <kill+0x52>

00000000800028b6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028b6:	7179                	addi	sp,sp,-48
    800028b8:	f406                	sd	ra,40(sp)
    800028ba:	f022                	sd	s0,32(sp)
    800028bc:	ec26                	sd	s1,24(sp)
    800028be:	e84a                	sd	s2,16(sp)
    800028c0:	e44e                	sd	s3,8(sp)
    800028c2:	e052                	sd	s4,0(sp)
    800028c4:	1800                	addi	s0,sp,48
    800028c6:	84aa                	mv	s1,a0
    800028c8:	892e                	mv	s2,a1
    800028ca:	89b2                	mv	s3,a2
    800028cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	1c4080e7          	jalr	452(ra) # 80001a92 <myproc>
  if (user_dst)
    800028d6:	c08d                	beqz	s1,800028f8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800028d8:	86d2                	mv	a3,s4
    800028da:	864e                	mv	a2,s3
    800028dc:	85ca                	mv	a1,s2
    800028de:	6928                	ld	a0,80(a0)
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	d9a080e7          	jalr	-614(ra) # 8000167a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028e8:	70a2                	ld	ra,40(sp)
    800028ea:	7402                	ld	s0,32(sp)
    800028ec:	64e2                	ld	s1,24(sp)
    800028ee:	6942                	ld	s2,16(sp)
    800028f0:	69a2                	ld	s3,8(sp)
    800028f2:	6a02                	ld	s4,0(sp)
    800028f4:	6145                	addi	sp,sp,48
    800028f6:	8082                	ret
    memmove((char *)dst, src, len);
    800028f8:	000a061b          	sext.w	a2,s4
    800028fc:	85ce                	mv	a1,s3
    800028fe:	854a                	mv	a0,s2
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	440080e7          	jalr	1088(ra) # 80000d40 <memmove>
    return 0;
    80002908:	8526                	mv	a0,s1
    8000290a:	bff9                	j	800028e8 <either_copyout+0x32>

000000008000290c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000290c:	7179                	addi	sp,sp,-48
    8000290e:	f406                	sd	ra,40(sp)
    80002910:	f022                	sd	s0,32(sp)
    80002912:	ec26                	sd	s1,24(sp)
    80002914:	e84a                	sd	s2,16(sp)
    80002916:	e44e                	sd	s3,8(sp)
    80002918:	e052                	sd	s4,0(sp)
    8000291a:	1800                	addi	s0,sp,48
    8000291c:	892a                	mv	s2,a0
    8000291e:	84ae                	mv	s1,a1
    80002920:	89b2                	mv	s3,a2
    80002922:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	16e080e7          	jalr	366(ra) # 80001a92 <myproc>
  if (user_src)
    8000292c:	c08d                	beqz	s1,8000294e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000292e:	86d2                	mv	a3,s4
    80002930:	864e                	mv	a2,s3
    80002932:	85ca                	mv	a1,s2
    80002934:	6928                	ld	a0,80(a0)
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	dd0080e7          	jalr	-560(ra) # 80001706 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000293e:	70a2                	ld	ra,40(sp)
    80002940:	7402                	ld	s0,32(sp)
    80002942:	64e2                	ld	s1,24(sp)
    80002944:	6942                	ld	s2,16(sp)
    80002946:	69a2                	ld	s3,8(sp)
    80002948:	6a02                	ld	s4,0(sp)
    8000294a:	6145                	addi	sp,sp,48
    8000294c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000294e:	000a061b          	sext.w	a2,s4
    80002952:	85ce                	mv	a1,s3
    80002954:	854a                	mv	a0,s2
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	3ea080e7          	jalr	1002(ra) # 80000d40 <memmove>
    return 0;
    8000295e:	8526                	mv	a0,s1
    80002960:	bff9                	j	8000293e <either_copyin+0x32>

0000000080002962 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002962:	715d                	addi	sp,sp,-80
    80002964:	e486                	sd	ra,72(sp)
    80002966:	e0a2                	sd	s0,64(sp)
    80002968:	fc26                	sd	s1,56(sp)
    8000296a:	f84a                	sd	s2,48(sp)
    8000296c:	f44e                	sd	s3,40(sp)
    8000296e:	f052                	sd	s4,32(sp)
    80002970:	ec56                	sd	s5,24(sp)
    80002972:	e85a                	sd	s6,16(sp)
    80002974:	e45e                	sd	s7,8(sp)
    80002976:	0880                	addi	s0,sp,80
    printf("%d     %d     %s   %d    %d    %d\n", p->pid, p->dynamicpriority, state, p->runtime, p->totalsleeptime, p->schedcount);
    //release(&p->lock);
  }
  return;
#endif
printf("\n");
    80002978:	00005517          	auipc	a0,0x5
    8000297c:	75050513          	addi	a0,a0,1872 # 800080c8 <digits+0x88>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c08080e7          	jalr	-1016(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002988:	00010497          	auipc	s1,0x10
    8000298c:	8c848493          	addi	s1,s1,-1848 # 80012250 <proc+0x158>
    80002990:	00016917          	auipc	s2,0x16
    80002994:	2c090913          	addi	s2,s2,704 # 80018c50 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002998:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000299a:	00006997          	auipc	s3,0x6
    8000299e:	8ee98993          	addi	s3,s3,-1810 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800029a2:	00006a97          	auipc	s5,0x6
    800029a6:	8eea8a93          	addi	s5,s5,-1810 # 80008290 <digits+0x250>
    printf("\n");
    800029aa:	00005a17          	auipc	s4,0x5
    800029ae:	71ea0a13          	addi	s4,s4,1822 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029b2:	00006b97          	auipc	s7,0x6
    800029b6:	916b8b93          	addi	s7,s7,-1770 # 800082c8 <states.1801>
    800029ba:	a00d                	j	800029dc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800029bc:	ed86a583          	lw	a1,-296(a3)
    800029c0:	8556                	mv	a0,s5
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	bc6080e7          	jalr	-1082(ra) # 80000588 <printf>
    printf("\n");
    800029ca:	8552                	mv	a0,s4
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	bbc080e7          	jalr	-1092(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029d4:	1a848493          	addi	s1,s1,424
    800029d8:	03248163          	beq	s1,s2,800029fa <procdump+0x98>
    if (p->state == UNUSED)
    800029dc:	86a6                	mv	a3,s1
    800029de:	ec04a783          	lw	a5,-320(s1)
    800029e2:	dbed                	beqz	a5,800029d4 <procdump+0x72>
      state = "???";
    800029e4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029e6:	fcfb6be3          	bltu	s6,a5,800029bc <procdump+0x5a>
    800029ea:	1782                	slli	a5,a5,0x20
    800029ec:	9381                	srli	a5,a5,0x20
    800029ee:	078e                	slli	a5,a5,0x3
    800029f0:	97de                	add	a5,a5,s7
    800029f2:	6390                	ld	a2,0(a5)
    800029f4:	f661                	bnez	a2,800029bc <procdump+0x5a>
      state = "???";
    800029f6:	864e                	mv	a2,s3
    800029f8:	b7d1                	j	800029bc <procdump+0x5a>
  }
}
    800029fa:	60a6                	ld	ra,72(sp)
    800029fc:	6406                	ld	s0,64(sp)
    800029fe:	74e2                	ld	s1,56(sp)
    80002a00:	7942                	ld	s2,48(sp)
    80002a02:	79a2                	ld	s3,40(sp)
    80002a04:	7a02                	ld	s4,32(sp)
    80002a06:	6ae2                	ld	s5,24(sp)
    80002a08:	6b42                	ld	s6,16(sp)
    80002a0a:	6ba2                	ld	s7,8(sp)
    80002a0c:	6161                	addi	sp,sp,80
    80002a0e:	8082                	ret

0000000080002a10 <trace>:

int trace(uint64 mask)
{
    80002a10:	1101                	addi	sp,sp,-32
    80002a12:	ec06                	sd	ra,24(sp)
    80002a14:	e822                	sd	s0,16(sp)
    80002a16:	e426                	sd	s1,8(sp)
    80002a18:	e04a                	sd	s2,0(sp)
    80002a1a:	1000                	addi	s0,sp,32
    80002a1c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	074080e7          	jalr	116(ra) # 80001a92 <myproc>
    80002a26:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	1bc080e7          	jalr	444(ra) # 80000be4 <acquire>
  p->syscallno = mask;
    80002a30:	1724b823          	sd	s2,368(s1)
  p->traceflag = 1;
    80002a34:	4785                	li	a5,1
    80002a36:	16f4a423          	sw	a5,360(s1)
  release(&p->lock);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	25c080e7          	jalr	604(ra) # 80000c98 <release>
  return 0;
}
    80002a44:	4501                	li	a0,0
    80002a46:	60e2                	ld	ra,24(sp)
    80002a48:	6442                	ld	s0,16(sp)
    80002a4a:	64a2                	ld	s1,8(sp)
    80002a4c:	6902                	ld	s2,0(sp)
    80002a4e:	6105                	addi	sp,sp,32
    80002a50:	8082                	ret

0000000080002a52 <set_priority>:

int set_priority(uint64 new_priority, uint64 pid)
{
    80002a52:	7179                	addi	sp,sp,-48
    80002a54:	f406                	sd	ra,40(sp)
    80002a56:	f022                	sd	s0,32(sp)
    80002a58:	ec26                	sd	s1,24(sp)
    80002a5a:	e84a                	sd	s2,16(sp)
    80002a5c:	e44e                	sd	s3,8(sp)
    80002a5e:	e052                	sd	s4,0(sp)
    80002a60:	1800                	addi	s0,sp,48
    80002a62:	8a2a                	mv	s4,a0
    80002a64:	892e                	mv	s2,a1
  struct proc *p;
  struct proc *q = 0;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a66:	0000f497          	auipc	s1,0xf
    80002a6a:	69248493          	addi	s1,s1,1682 # 800120f8 <proc>
    80002a6e:	00016997          	auipc	s3,0x16
    80002a72:	08a98993          	addi	s3,s3,138 # 80018af8 <tickslock>
  {
    acquire(&p->lock);
    80002a76:	8526                	mv	a0,s1
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	16c080e7          	jalr	364(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002a80:	589c                	lw	a5,48(s1)
    80002a82:	01278d63          	beq	a5,s2,80002a9c <set_priority+0x4a>
    {
      q = p;
      release(&p->lock);
      break;
    }
    release(&p->lock);
    80002a86:	8526                	mv	a0,s1
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a90:	1a848493          	addi	s1,s1,424
    80002a94:	ff3491e3          	bne	s1,s3,80002a76 <set_priority+0x24>
  }
  if (q == 0)
    return -1;
    80002a98:	59fd                	li	s3,-1
    80002a9a:	a089                	j	80002adc <set_priority+0x8a>
      release(&p->lock);
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	1fa080e7          	jalr	506(ra) # 80000c98 <release>
  acquire(&q->lock);
    80002aa6:	8526                	mv	a0,s1
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	13c080e7          	jalr	316(ra) # 80000be4 <acquire>
  int oldpriority = q->staticpriority;
    80002ab0:	1984a983          	lw	s3,408(s1)
  q->staticpriority = new_priority;
    80002ab4:	1944ac23          	sw	s4,408(s1)
  q->niceness = 5;
    80002ab8:	4795                	li	a5,5
    80002aba:	18f4ae23          	sw	a5,412(s1)
  int olddp = q->dynamicpriority;
    80002abe:	1a04aa03          	lw	s4,416(s1)
  int newdp = calculatedp(q);
    80002ac2:	8526                	mv	a0,s1
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	58e080e7          	jalr	1422(ra) # 80002052 <calculatedp>
    80002acc:	892a                	mv	s2,a0
  //printf("old: %d new: %d\n",olddp,newdp);
  release(&q->lock);
    80002ace:	8526                	mv	a0,s1
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	1c8080e7          	jalr	456(ra) # 80000c98 <release>
  if (newdp < olddp)
    80002ad8:	01494b63          	blt	s2,s4,80002aee <set_priority+0x9c>
  {
    yield();
  }
  return oldpriority;
    80002adc:	854e                	mv	a0,s3
    80002ade:	70a2                	ld	ra,40(sp)
    80002ae0:	7402                	ld	s0,32(sp)
    80002ae2:	64e2                	ld	s1,24(sp)
    80002ae4:	6942                	ld	s2,16(sp)
    80002ae6:	69a2                	ld	s3,8(sp)
    80002ae8:	6a02                	ld	s4,0(sp)
    80002aea:	6145                	addi	sp,sp,48
    80002aec:	8082                	ret
    yield();
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	83e080e7          	jalr	-1986(ra) # 8000232c <yield>
    80002af6:	b7dd                	j	80002adc <set_priority+0x8a>

0000000080002af8 <swtch>:
    80002af8:	00153023          	sd	ra,0(a0)
    80002afc:	00253423          	sd	sp,8(a0)
    80002b00:	e900                	sd	s0,16(a0)
    80002b02:	ed04                	sd	s1,24(a0)
    80002b04:	03253023          	sd	s2,32(a0)
    80002b08:	03353423          	sd	s3,40(a0)
    80002b0c:	03453823          	sd	s4,48(a0)
    80002b10:	03553c23          	sd	s5,56(a0)
    80002b14:	05653023          	sd	s6,64(a0)
    80002b18:	05753423          	sd	s7,72(a0)
    80002b1c:	05853823          	sd	s8,80(a0)
    80002b20:	05953c23          	sd	s9,88(a0)
    80002b24:	07a53023          	sd	s10,96(a0)
    80002b28:	07b53423          	sd	s11,104(a0)
    80002b2c:	0005b083          	ld	ra,0(a1)
    80002b30:	0085b103          	ld	sp,8(a1)
    80002b34:	6980                	ld	s0,16(a1)
    80002b36:	6d84                	ld	s1,24(a1)
    80002b38:	0205b903          	ld	s2,32(a1)
    80002b3c:	0285b983          	ld	s3,40(a1)
    80002b40:	0305ba03          	ld	s4,48(a1)
    80002b44:	0385ba83          	ld	s5,56(a1)
    80002b48:	0405bb03          	ld	s6,64(a1)
    80002b4c:	0485bb83          	ld	s7,72(a1)
    80002b50:	0505bc03          	ld	s8,80(a1)
    80002b54:	0585bc83          	ld	s9,88(a1)
    80002b58:	0605bd03          	ld	s10,96(a1)
    80002b5c:	0685bd83          	ld	s11,104(a1)
    80002b60:	8082                	ret

0000000080002b62 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b62:	1141                	addi	sp,sp,-16
    80002b64:	e406                	sd	ra,8(sp)
    80002b66:	e022                	sd	s0,0(sp)
    80002b68:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b6a:	00005597          	auipc	a1,0x5
    80002b6e:	78e58593          	addi	a1,a1,1934 # 800082f8 <states.1801+0x30>
    80002b72:	00016517          	auipc	a0,0x16
    80002b76:	f8650513          	addi	a0,a0,-122 # 80018af8 <tickslock>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	fda080e7          	jalr	-38(ra) # 80000b54 <initlock>
}
    80002b82:	60a2                	ld	ra,8(sp)
    80002b84:	6402                	ld	s0,0(sp)
    80002b86:	0141                	addi	sp,sp,16
    80002b88:	8082                	ret

0000000080002b8a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b8a:	1141                	addi	sp,sp,-16
    80002b8c:	e422                	sd	s0,8(sp)
    80002b8e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b90:	00003797          	auipc	a5,0x3
    80002b94:	70078793          	addi	a5,a5,1792 # 80006290 <kernelvec>
    80002b98:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b9c:	6422                	ld	s0,8(sp)
    80002b9e:	0141                	addi	sp,sp,16
    80002ba0:	8082                	ret

0000000080002ba2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ba2:	1141                	addi	sp,sp,-16
    80002ba4:	e406                	sd	ra,8(sp)
    80002ba6:	e022                	sd	s0,0(sp)
    80002ba8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	ee8080e7          	jalr	-280(ra) # 80001a92 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bb6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bbc:	00004617          	auipc	a2,0x4
    80002bc0:	44460613          	addi	a2,a2,1092 # 80007000 <_trampoline>
    80002bc4:	00004697          	auipc	a3,0x4
    80002bc8:	43c68693          	addi	a3,a3,1084 # 80007000 <_trampoline>
    80002bcc:	8e91                	sub	a3,a3,a2
    80002bce:	040007b7          	lui	a5,0x4000
    80002bd2:	17fd                	addi	a5,a5,-1
    80002bd4:	07b2                	slli	a5,a5,0xc
    80002bd6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bd8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bdc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bde:	180026f3          	csrr	a3,satp
    80002be2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002be4:	6d38                	ld	a4,88(a0)
    80002be6:	6134                	ld	a3,64(a0)
    80002be8:	6585                	lui	a1,0x1
    80002bea:	96ae                	add	a3,a3,a1
    80002bec:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bee:	6d38                	ld	a4,88(a0)
    80002bf0:	00000697          	auipc	a3,0x0
    80002bf4:	14668693          	addi	a3,a3,326 # 80002d36 <usertrap>
    80002bf8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bfa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bfc:	8692                	mv	a3,tp
    80002bfe:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c00:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c04:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c08:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c10:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c12:	6f18                	ld	a4,24(a4)
    80002c14:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c18:	692c                	ld	a1,80(a0)
    80002c1a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c1c:	00004717          	auipc	a4,0x4
    80002c20:	47470713          	addi	a4,a4,1140 # 80007090 <userret>
    80002c24:	8f11                	sub	a4,a4,a2
    80002c26:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c28:	577d                	li	a4,-1
    80002c2a:	177e                	slli	a4,a4,0x3f
    80002c2c:	8dd9                	or	a1,a1,a4
    80002c2e:	02000537          	lui	a0,0x2000
    80002c32:	157d                	addi	a0,a0,-1
    80002c34:	0536                	slli	a0,a0,0xd
    80002c36:	9782                	jalr	a5
}
    80002c38:	60a2                	ld	ra,8(sp)
    80002c3a:	6402                	ld	s0,0(sp)
    80002c3c:	0141                	addi	sp,sp,16
    80002c3e:	8082                	ret

0000000080002c40 <clockintr>:
  
}

void
clockintr()
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	e426                	sd	s1,8(sp)
    80002c48:	e04a                	sd	s2,0(sp)
    80002c4a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c4c:	00016917          	auipc	s2,0x16
    80002c50:	eac90913          	addi	s2,s2,-340 # 80018af8 <tickslock>
    80002c54:	854a                	mv	a0,s2
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	f8e080e7          	jalr	-114(ra) # 80000be4 <acquire>
  ticks++;
    80002c5e:	00006497          	auipc	s1,0x6
    80002c62:	3d248493          	addi	s1,s1,978 # 80009030 <ticks>
    80002c66:	409c                	lw	a5,0(s1)
    80002c68:	2785                	addiw	a5,a5,1
    80002c6a:	c09c                	sw	a5,0(s1)
  //struct proc *p = myproc();
  UpdateTime();
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	37e080e7          	jalr	894(ra) # 80001fea <UpdateTime>
    if(p != 0)
    {
      yield();
    }
  #endif
  wakeup(&ticks);
    80002c74:	8526                	mv	a0,s1
    80002c76:	00000097          	auipc	ra,0x0
    80002c7a:	9e2080e7          	jalr	-1566(ra) # 80002658 <wakeup>
  release(&tickslock);
    80002c7e:	854a                	mv	a0,s2
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	018080e7          	jalr	24(ra) # 80000c98 <release>
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6902                	ld	s2,0(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c9e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ca2:	00074d63          	bltz	a4,80002cbc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ca6:	57fd                	li	a5,-1
    80002ca8:	17fe                	slli	a5,a5,0x3f
    80002caa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cae:	06f70363          	beq	a4,a5,80002d14 <devintr+0x80>
  }
}
    80002cb2:	60e2                	ld	ra,24(sp)
    80002cb4:	6442                	ld	s0,16(sp)
    80002cb6:	64a2                	ld	s1,8(sp)
    80002cb8:	6105                	addi	sp,sp,32
    80002cba:	8082                	ret
     (scause & 0xff) == 9){
    80002cbc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cc0:	46a5                	li	a3,9
    80002cc2:	fed792e3          	bne	a5,a3,80002ca6 <devintr+0x12>
    int irq = plic_claim();
    80002cc6:	00003097          	auipc	ra,0x3
    80002cca:	6d2080e7          	jalr	1746(ra) # 80006398 <plic_claim>
    80002cce:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cd0:	47a9                	li	a5,10
    80002cd2:	02f50763          	beq	a0,a5,80002d00 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cd6:	4785                	li	a5,1
    80002cd8:	02f50963          	beq	a0,a5,80002d0a <devintr+0x76>
    return 1;
    80002cdc:	4505                	li	a0,1
    } else if(irq){
    80002cde:	d8f1                	beqz	s1,80002cb2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ce0:	85a6                	mv	a1,s1
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	61e50513          	addi	a0,a0,1566 # 80008300 <states.1801+0x38>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	89e080e7          	jalr	-1890(ra) # 80000588 <printf>
      plic_complete(irq);
    80002cf2:	8526                	mv	a0,s1
    80002cf4:	00003097          	auipc	ra,0x3
    80002cf8:	6c8080e7          	jalr	1736(ra) # 800063bc <plic_complete>
    return 1;
    80002cfc:	4505                	li	a0,1
    80002cfe:	bf55                	j	80002cb2 <devintr+0x1e>
      uartintr();
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	ca8080e7          	jalr	-856(ra) # 800009a8 <uartintr>
    80002d08:	b7ed                	j	80002cf2 <devintr+0x5e>
      virtio_disk_intr();
    80002d0a:	00004097          	auipc	ra,0x4
    80002d0e:	b92080e7          	jalr	-1134(ra) # 8000689c <virtio_disk_intr>
    80002d12:	b7c5                	j	80002cf2 <devintr+0x5e>
    if(cpuid() == 0){
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	d52080e7          	jalr	-686(ra) # 80001a66 <cpuid>
    80002d1c:	c901                	beqz	a0,80002d2c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d1e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d24:	14479073          	csrw	sip,a5
    return 2;
    80002d28:	4509                	li	a0,2
    80002d2a:	b761                	j	80002cb2 <devintr+0x1e>
      clockintr();
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	f14080e7          	jalr	-236(ra) # 80002c40 <clockintr>
    80002d34:	b7ed                	j	80002d1e <devintr+0x8a>

0000000080002d36 <usertrap>:
{
    80002d36:	1101                	addi	sp,sp,-32
    80002d38:	ec06                	sd	ra,24(sp)
    80002d3a:	e822                	sd	s0,16(sp)
    80002d3c:	e426                	sd	s1,8(sp)
    80002d3e:	e04a                	sd	s2,0(sp)
    80002d40:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d42:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d46:	1007f793          	andi	a5,a5,256
    80002d4a:	e3ad                	bnez	a5,80002dac <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d4c:	00003797          	auipc	a5,0x3
    80002d50:	54478793          	addi	a5,a5,1348 # 80006290 <kernelvec>
    80002d54:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	d3a080e7          	jalr	-710(ra) # 80001a92 <myproc>
    80002d60:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d62:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d64:	14102773          	csrr	a4,sepc
    80002d68:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d6a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d6e:	47a1                	li	a5,8
    80002d70:	04f71c63          	bne	a4,a5,80002dc8 <usertrap+0x92>
    if(p->killed)
    80002d74:	551c                	lw	a5,40(a0)
    80002d76:	e3b9                	bnez	a5,80002dbc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d78:	6cb8                	ld	a4,88(s1)
    80002d7a:	6f1c                	ld	a5,24(a4)
    80002d7c:	0791                	addi	a5,a5,4
    80002d7e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d88:	10079073          	csrw	sstatus,a5
    syscall();
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	2f0080e7          	jalr	752(ra) # 8000307c <syscall>
  if(p->killed)
    80002d94:	549c                	lw	a5,40(s1)
    80002d96:	ebc1                	bnez	a5,80002e26 <usertrap+0xf0>
  usertrapret();
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	e0a080e7          	jalr	-502(ra) # 80002ba2 <usertrapret>
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6902                	ld	s2,0(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret
    panic("usertrap: not from user mode");
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	57450513          	addi	a0,a0,1396 # 80008320 <states.1801+0x58>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	78a080e7          	jalr	1930(ra) # 8000053e <panic>
      exit(-1);
    80002dbc:	557d                	li	a0,-1
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	992080e7          	jalr	-1646(ra) # 80002750 <exit>
    80002dc6:	bf4d                	j	80002d78 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	ecc080e7          	jalr	-308(ra) # 80002c94 <devintr>
    80002dd0:	892a                	mv	s2,a0
    80002dd2:	c501                	beqz	a0,80002dda <usertrap+0xa4>
  if(p->killed)
    80002dd4:	549c                	lw	a5,40(s1)
    80002dd6:	c3a1                	beqz	a5,80002e16 <usertrap+0xe0>
    80002dd8:	a815                	j	80002e0c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dda:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dde:	5890                	lw	a2,48(s1)
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	56050513          	addi	a0,a0,1376 # 80008340 <states.1801+0x78>
    80002de8:	ffffd097          	auipc	ra,0xffffd
    80002dec:	7a0080e7          	jalr	1952(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002df4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002df8:	00005517          	auipc	a0,0x5
    80002dfc:	57850513          	addi	a0,a0,1400 # 80008370 <states.1801+0xa8>
    80002e00:	ffffd097          	auipc	ra,0xffffd
    80002e04:	788080e7          	jalr	1928(ra) # 80000588 <printf>
    p->killed = 1;
    80002e08:	4785                	li	a5,1
    80002e0a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e0c:	557d                	li	a0,-1
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	942080e7          	jalr	-1726(ra) # 80002750 <exit>
    if(which_dev == 2)
    80002e16:	4789                	li	a5,2
    80002e18:	f8f910e3          	bne	s2,a5,80002d98 <usertrap+0x62>
      yield();
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	510080e7          	jalr	1296(ra) # 8000232c <yield>
    80002e24:	bf95                	j	80002d98 <usertrap+0x62>
  int which_dev = 0;
    80002e26:	4901                	li	s2,0
    80002e28:	b7d5                	j	80002e0c <usertrap+0xd6>

0000000080002e2a <kerneltrap>:
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	e84a                	sd	s2,16(sp)
    80002e34:	e44e                	sd	s3,8(sp)
    80002e36:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e38:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e3c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e40:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e44:	1004f793          	andi	a5,s1,256
    80002e48:	cb85                	beqz	a5,80002e78 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e4a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e4e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e50:	ef85                	bnez	a5,80002e88 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	e42080e7          	jalr	-446(ra) # 80002c94 <devintr>
    80002e5a:	cd1d                	beqz	a0,80002e98 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e5c:	4789                	li	a5,2
    80002e5e:	06f50a63          	beq	a0,a5,80002ed2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e62:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e66:	10049073          	csrw	sstatus,s1
}
    80002e6a:	70a2                	ld	ra,40(sp)
    80002e6c:	7402                	ld	s0,32(sp)
    80002e6e:	64e2                	ld	s1,24(sp)
    80002e70:	6942                	ld	s2,16(sp)
    80002e72:	69a2                	ld	s3,8(sp)
    80002e74:	6145                	addi	sp,sp,48
    80002e76:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	51850513          	addi	a0,a0,1304 # 80008390 <states.1801+0xc8>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	6be080e7          	jalr	1726(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e88:	00005517          	auipc	a0,0x5
    80002e8c:	53050513          	addi	a0,a0,1328 # 800083b8 <states.1801+0xf0>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	6ae080e7          	jalr	1710(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e98:	85ce                	mv	a1,s3
    80002e9a:	00005517          	auipc	a0,0x5
    80002e9e:	53e50513          	addi	a0,a0,1342 # 800083d8 <states.1801+0x110>
    80002ea2:	ffffd097          	auipc	ra,0xffffd
    80002ea6:	6e6080e7          	jalr	1766(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eaa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eae:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eb2:	00005517          	auipc	a0,0x5
    80002eb6:	53650513          	addi	a0,a0,1334 # 800083e8 <states.1801+0x120>
    80002eba:	ffffd097          	auipc	ra,0xffffd
    80002ebe:	6ce080e7          	jalr	1742(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	53e50513          	addi	a0,a0,1342 # 80008400 <states.1801+0x138>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	674080e7          	jalr	1652(ra) # 8000053e <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	bc0080e7          	jalr	-1088(ra) # 80001a92 <myproc>
    80002eda:	d541                	beqz	a0,80002e62 <kerneltrap+0x38>
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	bb6080e7          	jalr	-1098(ra) # 80001a92 <myproc>
    80002ee4:	4d18                	lw	a4,24(a0)
    80002ee6:	4791                	li	a5,4
    80002ee8:	f6f71de3          	bne	a4,a5,80002e62 <kerneltrap+0x38>
        yield();
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	440080e7          	jalr	1088(ra) # 8000232c <yield>
    80002ef4:	b7bd                	j	80002e62 <kerneltrap+0x38>

0000000080002ef6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ef6:	1101                	addi	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	e426                	sd	s1,8(sp)
    80002efe:	1000                	addi	s0,sp,32
    80002f00:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	b90080e7          	jalr	-1136(ra) # 80001a92 <myproc>
  switch (n) {
    80002f0a:	4795                	li	a5,5
    80002f0c:	0497e163          	bltu	a5,s1,80002f4e <argraw+0x58>
    80002f10:	048a                	slli	s1,s1,0x2
    80002f12:	00005717          	auipc	a4,0x5
    80002f16:	66670713          	addi	a4,a4,1638 # 80008578 <states.1801+0x2b0>
    80002f1a:	94ba                	add	s1,s1,a4
    80002f1c:	409c                	lw	a5,0(s1)
    80002f1e:	97ba                	add	a5,a5,a4
    80002f20:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f22:	6d3c                	ld	a5,88(a0)
    80002f24:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	64a2                	ld	s1,8(sp)
    80002f2c:	6105                	addi	sp,sp,32
    80002f2e:	8082                	ret
    return p->trapframe->a1;
    80002f30:	6d3c                	ld	a5,88(a0)
    80002f32:	7fa8                	ld	a0,120(a5)
    80002f34:	bfcd                	j	80002f26 <argraw+0x30>
    return p->trapframe->a2;
    80002f36:	6d3c                	ld	a5,88(a0)
    80002f38:	63c8                	ld	a0,128(a5)
    80002f3a:	b7f5                	j	80002f26 <argraw+0x30>
    return p->trapframe->a3;
    80002f3c:	6d3c                	ld	a5,88(a0)
    80002f3e:	67c8                	ld	a0,136(a5)
    80002f40:	b7dd                	j	80002f26 <argraw+0x30>
    return p->trapframe->a4;
    80002f42:	6d3c                	ld	a5,88(a0)
    80002f44:	6bc8                	ld	a0,144(a5)
    80002f46:	b7c5                	j	80002f26 <argraw+0x30>
    return p->trapframe->a5;
    80002f48:	6d3c                	ld	a5,88(a0)
    80002f4a:	6fc8                	ld	a0,152(a5)
    80002f4c:	bfe9                	j	80002f26 <argraw+0x30>
  panic("argraw");
    80002f4e:	00005517          	auipc	a0,0x5
    80002f52:	4c250513          	addi	a0,a0,1218 # 80008410 <states.1801+0x148>
    80002f56:	ffffd097          	auipc	ra,0xffffd
    80002f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>

0000000080002f5e <fetchaddr>:
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	e04a                	sd	s2,0(sp)
    80002f68:	1000                	addi	s0,sp,32
    80002f6a:	84aa                	mv	s1,a0
    80002f6c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	b24080e7          	jalr	-1244(ra) # 80001a92 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f76:	653c                	ld	a5,72(a0)
    80002f78:	02f4f863          	bgeu	s1,a5,80002fa8 <fetchaddr+0x4a>
    80002f7c:	00848713          	addi	a4,s1,8
    80002f80:	02e7e663          	bltu	a5,a4,80002fac <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f84:	46a1                	li	a3,8
    80002f86:	8626                	mv	a2,s1
    80002f88:	85ca                	mv	a1,s2
    80002f8a:	6928                	ld	a0,80(a0)
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	77a080e7          	jalr	1914(ra) # 80001706 <copyin>
    80002f94:	00a03533          	snez	a0,a0
    80002f98:	40a00533          	neg	a0,a0
}
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	64a2                	ld	s1,8(sp)
    80002fa2:	6902                	ld	s2,0(sp)
    80002fa4:	6105                	addi	sp,sp,32
    80002fa6:	8082                	ret
    return -1;
    80002fa8:	557d                	li	a0,-1
    80002faa:	bfcd                	j	80002f9c <fetchaddr+0x3e>
    80002fac:	557d                	li	a0,-1
    80002fae:	b7fd                	j	80002f9c <fetchaddr+0x3e>

0000000080002fb0 <fetchstr>:
{
    80002fb0:	7179                	addi	sp,sp,-48
    80002fb2:	f406                	sd	ra,40(sp)
    80002fb4:	f022                	sd	s0,32(sp)
    80002fb6:	ec26                	sd	s1,24(sp)
    80002fb8:	e84a                	sd	s2,16(sp)
    80002fba:	e44e                	sd	s3,8(sp)
    80002fbc:	1800                	addi	s0,sp,48
    80002fbe:	892a                	mv	s2,a0
    80002fc0:	84ae                	mv	s1,a1
    80002fc2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	ace080e7          	jalr	-1330(ra) # 80001a92 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fcc:	86ce                	mv	a3,s3
    80002fce:	864a                	mv	a2,s2
    80002fd0:	85a6                	mv	a1,s1
    80002fd2:	6928                	ld	a0,80(a0)
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	7be080e7          	jalr	1982(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002fdc:	00054763          	bltz	a0,80002fea <fetchstr+0x3a>
  return strlen(buf);
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	e82080e7          	jalr	-382(ra) # 80000e64 <strlen>
}
    80002fea:	70a2                	ld	ra,40(sp)
    80002fec:	7402                	ld	s0,32(sp)
    80002fee:	64e2                	ld	s1,24(sp)
    80002ff0:	6942                	ld	s2,16(sp)
    80002ff2:	69a2                	ld	s3,8(sp)
    80002ff4:	6145                	addi	sp,sp,48
    80002ff6:	8082                	ret

0000000080002ff8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	1000                	addi	s0,sp,32
    80003002:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003004:	00000097          	auipc	ra,0x0
    80003008:	ef2080e7          	jalr	-270(ra) # 80002ef6 <argraw>
    8000300c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000300e:	4501                	li	a0,0
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	e426                	sd	s1,8(sp)
    80003022:	1000                	addi	s0,sp,32
    80003024:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	ed0080e7          	jalr	-304(ra) # 80002ef6 <argraw>
    8000302e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003030:	4501                	li	a0,0
    80003032:	60e2                	ld	ra,24(sp)
    80003034:	6442                	ld	s0,16(sp)
    80003036:	64a2                	ld	s1,8(sp)
    80003038:	6105                	addi	sp,sp,32
    8000303a:	8082                	ret

000000008000303c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000303c:	7179                	addi	sp,sp,-48
    8000303e:	f406                	sd	ra,40(sp)
    80003040:	f022                	sd	s0,32(sp)
    80003042:	ec26                	sd	s1,24(sp)
    80003044:	e84a                	sd	s2,16(sp)
    80003046:	1800                	addi	s0,sp,48
    80003048:	84ae                	mv	s1,a1
    8000304a:	8932                	mv	s2,a2
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    8000304c:	fd840593          	addi	a1,s0,-40
    80003050:	00000097          	auipc	ra,0x0
    80003054:	fca080e7          	jalr	-54(ra) # 8000301a <argaddr>
    80003058:	02054063          	bltz	a0,80003078 <argstr+0x3c>
    return -1;
  return fetchstr(addr, buf, max);
    8000305c:	864a                	mv	a2,s2
    8000305e:	85a6                	mv	a1,s1
    80003060:	fd843503          	ld	a0,-40(s0)
    80003064:	00000097          	auipc	ra,0x0
    80003068:	f4c080e7          	jalr	-180(ra) # 80002fb0 <fetchstr>
}
    8000306c:	70a2                	ld	ra,40(sp)
    8000306e:	7402                	ld	s0,32(sp)
    80003070:	64e2                	ld	s1,24(sp)
    80003072:	6942                	ld	s2,16(sp)
    80003074:	6145                	addi	sp,sp,48
    80003076:	8082                	ret
    return -1;
    80003078:	557d                	li	a0,-1
    8000307a:	bfcd                	j	8000306c <argstr+0x30>

000000008000307c <syscall>:
  2,  // set_priority
};

void
syscall(void)
{
    8000307c:	715d                	addi	sp,sp,-80
    8000307e:	e486                	sd	ra,72(sp)
    80003080:	e0a2                	sd	s0,64(sp)
    80003082:	fc26                	sd	s1,56(sp)
    80003084:	f84a                	sd	s2,48(sp)
    80003086:	f44e                	sd	s3,40(sp)
    80003088:	f052                	sd	s4,32(sp)
    8000308a:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	a06080e7          	jalr	-1530(ra) # 80001a92 <myproc>
    80003094:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003096:	6d3c                	ld	a5,88(a0)
    80003098:	77dc                	ld	a5,168(a5)
    8000309a:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000309e:	37fd                	addiw	a5,a5,-1
    800030a0:	475d                	li	a4,23
    800030a2:	14f76763          	bltu	a4,a5,800031f0 <syscall+0x174>
    800030a6:	00391713          	slli	a4,s2,0x3
    800030aa:	00005797          	auipc	a5,0x5
    800030ae:	4e678793          	addi	a5,a5,1254 # 80008590 <syscalls>
    800030b2:	97ba                	add	a5,a5,a4
    800030b4:	0007b983          	ld	s3,0(a5)
    800030b8:	12098c63          	beqz	s3,800031f0 <syscall+0x174>
    uint64 addr1;
    argaddr(0,&addr1);
    800030bc:	fb840593          	addi	a1,s0,-72
    800030c0:	4501                	li	a0,0
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	f58080e7          	jalr	-168(ra) # 8000301a <argaddr>
    p->trapframe->a0 = syscalls[num]();
    800030ca:	0584ba03          	ld	s4,88(s1)
    800030ce:	9982                	jalr	s3
    800030d0:	06aa3823          	sd	a0,112(s4)
    //num = num - 1;
    if((p->syscallno & ((uint64)1 << num)) && p->traceflag)
    800030d4:	1704b783          	ld	a5,368(s1)
    800030d8:	0127d7b3          	srl	a5,a5,s2
    800030dc:	8b85                	andi	a5,a5,1
    800030de:	12078863          	beqz	a5,8000320e <syscall+0x192>
    800030e2:	1684a783          	lw	a5,360(s1)
    800030e6:	12078463          	beqz	a5,8000320e <syscall+0x192>
    {
      //printf("%d %d\n",p->syscallno,num);
      uint64 addr2, addr3;
      
      int argcnt = argno[num-1];
    800030ea:	397d                	addiw	s2,s2,-1
    800030ec:	00291713          	slli	a4,s2,0x2
    800030f0:	00006797          	auipc	a5,0x6
    800030f4:	8c878793          	addi	a5,a5,-1848 # 800089b8 <argno>
    800030f8:	97ba                	add	a5,a5,a4
    800030fa:	439c                	lw	a5,0(a5)
      //printf("argcnt = %d array = %d\n",argcnt,argno[num-1]);
      if(argcnt == 0)
    800030fc:	c3bd                	beqz	a5,80003162 <syscall+0xe6>
      {
        printf("%d: syscall %s --> %d\n",p->pid,syscallnames[num-1],p->trapframe->a0);
        return;
      }
      if(argcnt == 1)
    800030fe:	4705                	li	a4,1
    80003100:	08e78563          	beq	a5,a4,8000318a <syscall+0x10e>
      {
        printf("%d: syscall %s (%d)--> %d\n",p->pid,syscallnames[num-1],addr1,p->trapframe->a0);
        return;
      }
      if(argcnt == 2)
    80003104:	4709                	li	a4,2
    80003106:	0ae78763          	beq	a5,a4,800031b4 <syscall+0x138>
      {
        argaddr(1,&addr2);
        printf("%d: syscall %s (%d %d)--> %d\n",p->pid,syscallnames[num-1],addr1,addr2,p->trapframe->a0);
        return;
      }
      if(argcnt == 3)
    8000310a:	470d                	li	a4,3
    8000310c:	10e79163          	bne	a5,a4,8000320e <syscall+0x192>
      {
        argaddr(1,&addr2);
    80003110:	fc040593          	addi	a1,s0,-64
    80003114:	4505                	li	a0,1
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	f04080e7          	jalr	-252(ra) # 8000301a <argaddr>
        argaddr(2,&addr3);
    8000311e:	fc840593          	addi	a1,s0,-56
    80003122:	4509                	li	a0,2
    80003124:	00000097          	auipc	ra,0x0
    80003128:	ef6080e7          	jalr	-266(ra) # 8000301a <argaddr>
        printf("%d: syscall %s (%d %d %d)--> %d\n",p->pid,syscallnames[num-1],addr1,addr2,addr3,p->trapframe->a0);
    8000312c:	6cb8                	ld	a4,88(s1)
    8000312e:	090e                	slli	s2,s2,0x3
    80003130:	00006797          	auipc	a5,0x6
    80003134:	88878793          	addi	a5,a5,-1912 # 800089b8 <argno>
    80003138:	993e                	add	s2,s2,a5
    8000313a:	07073803          	ld	a6,112(a4)
    8000313e:	fc843783          	ld	a5,-56(s0)
    80003142:	fc043703          	ld	a4,-64(s0)
    80003146:	fb843683          	ld	a3,-72(s0)
    8000314a:	06093603          	ld	a2,96(s2)
    8000314e:	588c                	lw	a1,48(s1)
    80003150:	00005517          	auipc	a0,0x5
    80003154:	32050513          	addi	a0,a0,800 # 80008470 <states.1801+0x1a8>
    80003158:	ffffd097          	auipc	ra,0xffffd
    8000315c:	430080e7          	jalr	1072(ra) # 80000588 <printf>
        return;
    80003160:	a07d                	j	8000320e <syscall+0x192>
        printf("%d: syscall %s --> %d\n",p->pid,syscallnames[num-1],p->trapframe->a0);
    80003162:	6cb8                	ld	a4,88(s1)
    80003164:	090e                	slli	s2,s2,0x3
    80003166:	00006797          	auipc	a5,0x6
    8000316a:	85278793          	addi	a5,a5,-1966 # 800089b8 <argno>
    8000316e:	993e                	add	s2,s2,a5
    80003170:	7b34                	ld	a3,112(a4)
    80003172:	06093603          	ld	a2,96(s2)
    80003176:	588c                	lw	a1,48(s1)
    80003178:	00005517          	auipc	a0,0x5
    8000317c:	2a050513          	addi	a0,a0,672 # 80008418 <states.1801+0x150>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	408080e7          	jalr	1032(ra) # 80000588 <printf>
        return;
    80003188:	a059                	j	8000320e <syscall+0x192>
        printf("%d: syscall %s (%d)--> %d\n",p->pid,syscallnames[num-1],addr1,p->trapframe->a0);
    8000318a:	6cb8                	ld	a4,88(s1)
    8000318c:	090e                	slli	s2,s2,0x3
    8000318e:	00006797          	auipc	a5,0x6
    80003192:	82a78793          	addi	a5,a5,-2006 # 800089b8 <argno>
    80003196:	97ca                	add	a5,a5,s2
    80003198:	7b38                	ld	a4,112(a4)
    8000319a:	fb843683          	ld	a3,-72(s0)
    8000319e:	73b0                	ld	a2,96(a5)
    800031a0:	588c                	lw	a1,48(s1)
    800031a2:	00005517          	auipc	a0,0x5
    800031a6:	28e50513          	addi	a0,a0,654 # 80008430 <states.1801+0x168>
    800031aa:	ffffd097          	auipc	ra,0xffffd
    800031ae:	3de080e7          	jalr	990(ra) # 80000588 <printf>
        return;
    800031b2:	a8b1                	j	8000320e <syscall+0x192>
        argaddr(1,&addr2);
    800031b4:	fc040593          	addi	a1,s0,-64
    800031b8:	4505                	li	a0,1
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	e60080e7          	jalr	-416(ra) # 8000301a <argaddr>
        printf("%d: syscall %s (%d %d)--> %d\n",p->pid,syscallnames[num-1],addr1,addr2,p->trapframe->a0);
    800031c2:	6cbc                	ld	a5,88(s1)
    800031c4:	090e                	slli	s2,s2,0x3
    800031c6:	00005617          	auipc	a2,0x5
    800031ca:	7f260613          	addi	a2,a2,2034 # 800089b8 <argno>
    800031ce:	964a                	add	a2,a2,s2
    800031d0:	7bbc                	ld	a5,112(a5)
    800031d2:	fc043703          	ld	a4,-64(s0)
    800031d6:	fb843683          	ld	a3,-72(s0)
    800031da:	7230                	ld	a2,96(a2)
    800031dc:	588c                	lw	a1,48(s1)
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	27250513          	addi	a0,a0,626 # 80008450 <states.1801+0x188>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	3a2080e7          	jalr	930(ra) # 80000588 <printf>
        return;
    800031ee:	a005                	j	8000320e <syscall+0x192>
      }
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031f0:	86ca                	mv	a3,s2
    800031f2:	15848613          	addi	a2,s1,344
    800031f6:	588c                	lw	a1,48(s1)
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	2a050513          	addi	a0,a0,672 # 80008498 <states.1801+0x1d0>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	388080e7          	jalr	904(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003208:	6cbc                	ld	a5,88(s1)
    8000320a:	577d                	li	a4,-1
    8000320c:	fbb8                	sd	a4,112(a5)
  }
}
    8000320e:	60a6                	ld	ra,72(sp)
    80003210:	6406                	ld	s0,64(sp)
    80003212:	74e2                	ld	s1,56(sp)
    80003214:	7942                	ld	s2,48(sp)
    80003216:	79a2                	ld	s3,40(sp)
    80003218:	7a02                	ld	s4,32(sp)
    8000321a:	6161                	addi	sp,sp,80
    8000321c:	8082                	ret

000000008000321e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003226:	fec40593          	addi	a1,s0,-20
    8000322a:	4501                	li	a0,0
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	dcc080e7          	jalr	-564(ra) # 80002ff8 <argint>
    return -1;
    80003234:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003236:	00054963          	bltz	a0,80003248 <sys_exit+0x2a>
  exit(n);
    8000323a:	fec42503          	lw	a0,-20(s0)
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	512080e7          	jalr	1298(ra) # 80002750 <exit>
  return 0;  // not reached
    80003246:	4781                	li	a5,0
}
    80003248:	853e                	mv	a0,a5
    8000324a:	60e2                	ld	ra,24(sp)
    8000324c:	6442                	ld	s0,16(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret

0000000080003252 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003252:	1141                	addi	sp,sp,-16
    80003254:	e406                	sd	ra,8(sp)
    80003256:	e022                	sd	s0,0(sp)
    80003258:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000325a:	fffff097          	auipc	ra,0xfffff
    8000325e:	838080e7          	jalr	-1992(ra) # 80001a92 <myproc>
}
    80003262:	5908                	lw	a0,48(a0)
    80003264:	60a2                	ld	ra,8(sp)
    80003266:	6402                	ld	s0,0(sp)
    80003268:	0141                	addi	sp,sp,16
    8000326a:	8082                	ret

000000008000326c <sys_fork>:

uint64
sys_fork(void)
{
    8000326c:	1141                	addi	sp,sp,-16
    8000326e:	e406                	sd	ra,8(sp)
    80003270:	e022                	sd	s0,0(sp)
    80003272:	0800                	addi	s0,sp,16
  return fork();
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	c2a080e7          	jalr	-982(ra) # 80001e9e <fork>
}
    8000327c:	60a2                	ld	ra,8(sp)
    8000327e:	6402                	ld	s0,0(sp)
    80003280:	0141                	addi	sp,sp,16
    80003282:	8082                	ret

0000000080003284 <sys_wait>:

uint64
sys_wait(void)
{
    80003284:	1101                	addi	sp,sp,-32
    80003286:	ec06                	sd	ra,24(sp)
    80003288:	e822                	sd	s0,16(sp)
    8000328a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000328c:	fe840593          	addi	a1,s0,-24
    80003290:	4501                	li	a0,0
    80003292:	00000097          	auipc	ra,0x0
    80003296:	d88080e7          	jalr	-632(ra) # 8000301a <argaddr>
    8000329a:	87aa                	mv	a5,a0
    return -1;
    8000329c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000329e:	0007c863          	bltz	a5,800032ae <sys_wait+0x2a>
  return wait(p);
    800032a2:	fe843503          	ld	a0,-24(s0)
    800032a6:	fffff097          	auipc	ra,0xfffff
    800032aa:	132080e7          	jalr	306(ra) # 800023d8 <wait>
}
    800032ae:	60e2                	ld	ra,24(sp)
    800032b0:	6442                	ld	s0,16(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret

00000000800032b6 <sys_waitx>:

uint64
sys_waitx(void)
{
    800032b6:	7139                	addi	sp,sp,-64
    800032b8:	fc06                	sd	ra,56(sp)
    800032ba:	f822                	sd	s0,48(sp)
    800032bc:	f426                	sd	s1,40(sp)
    800032be:	f04a                	sd	s2,32(sp)
    800032c0:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    800032c2:	fd840593          	addi	a1,s0,-40
    800032c6:	4501                	li	a0,0
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	d52080e7          	jalr	-686(ra) # 8000301a <argaddr>
    return -1;
    800032d0:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800032d2:	08054063          	bltz	a0,80003352 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0)
    800032d6:	fd040593          	addi	a1,s0,-48
    800032da:	4505                	li	a0,1
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	d3e080e7          	jalr	-706(ra) # 8000301a <argaddr>
    return -1;
    800032e4:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0)
    800032e6:	06054663          	bltz	a0,80003352 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    800032ea:	fc840593          	addi	a1,s0,-56
    800032ee:	4509                	li	a0,2
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	d2a080e7          	jalr	-726(ra) # 8000301a <argaddr>
    return -1;
    800032f8:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800032fa:	04054c63          	bltz	a0,80003352 <sys_waitx+0x9c>
  int ret = waitx(addr,&wtime,&rtime);
    800032fe:	fc040613          	addi	a2,s0,-64
    80003302:	fc440593          	addi	a1,s0,-60
    80003306:	fd843503          	ld	a0,-40(s0)
    8000330a:	fffff097          	auipc	ra,0xfffff
    8000330e:	202080e7          	jalr	514(ra) # 8000250c <waitx>
    80003312:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	77e080e7          	jalr	1918(ra) # 80001a92 <myproc>
    8000331c:	84aa                	mv	s1,a0
  if(copyout(p->pagetable,addr1,(char*)&wtime,sizeof(int))< 0)
    8000331e:	4691                	li	a3,4
    80003320:	fc440613          	addi	a2,s0,-60
    80003324:	fd043583          	ld	a1,-48(s0)
    80003328:	6928                	ld	a0,80(a0)
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	350080e7          	jalr	848(ra) # 8000167a <copyout>
    return -1;
    80003332:	57fd                	li	a5,-1
  if(copyout(p->pagetable,addr1,(char*)&wtime,sizeof(int))< 0)
    80003334:	00054f63          	bltz	a0,80003352 <sys_waitx+0x9c>
  if(copyout(p->pagetable,addr2,(char*)&rtime,sizeof(int))< 0)
    80003338:	4691                	li	a3,4
    8000333a:	fc040613          	addi	a2,s0,-64
    8000333e:	fc843583          	ld	a1,-56(s0)
    80003342:	68a8                	ld	a0,80(s1)
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	336080e7          	jalr	822(ra) # 8000167a <copyout>
    8000334c:	00054a63          	bltz	a0,80003360 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003350:	87ca                	mv	a5,s2
}
    80003352:	853e                	mv	a0,a5
    80003354:	70e2                	ld	ra,56(sp)
    80003356:	7442                	ld	s0,48(sp)
    80003358:	74a2                	ld	s1,40(sp)
    8000335a:	7902                	ld	s2,32(sp)
    8000335c:	6121                	addi	sp,sp,64
    8000335e:	8082                	ret
    return -1;
    80003360:	57fd                	li	a5,-1
    80003362:	bfc5                	j	80003352 <sys_waitx+0x9c>

0000000080003364 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003364:	7179                	addi	sp,sp,-48
    80003366:	f406                	sd	ra,40(sp)
    80003368:	f022                	sd	s0,32(sp)
    8000336a:	ec26                	sd	s1,24(sp)
    8000336c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000336e:	fdc40593          	addi	a1,s0,-36
    80003372:	4501                	li	a0,0
    80003374:	00000097          	auipc	ra,0x0
    80003378:	c84080e7          	jalr	-892(ra) # 80002ff8 <argint>
    8000337c:	87aa                	mv	a5,a0
    return -1;
    8000337e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003380:	0207c063          	bltz	a5,800033a0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	70e080e7          	jalr	1806(ra) # 80001a92 <myproc>
    8000338c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000338e:	fdc42503          	lw	a0,-36(s0)
    80003392:	fffff097          	auipc	ra,0xfffff
    80003396:	a98080e7          	jalr	-1384(ra) # 80001e2a <growproc>
    8000339a:	00054863          	bltz	a0,800033aa <sys_sbrk+0x46>
    return -1;
  return addr;
    8000339e:	8526                	mv	a0,s1
}
    800033a0:	70a2                	ld	ra,40(sp)
    800033a2:	7402                	ld	s0,32(sp)
    800033a4:	64e2                	ld	s1,24(sp)
    800033a6:	6145                	addi	sp,sp,48
    800033a8:	8082                	ret
    return -1;
    800033aa:	557d                	li	a0,-1
    800033ac:	bfd5                	j	800033a0 <sys_sbrk+0x3c>

00000000800033ae <sys_sleep>:

uint64
sys_sleep(void)
{
    800033ae:	7139                	addi	sp,sp,-64
    800033b0:	fc06                	sd	ra,56(sp)
    800033b2:	f822                	sd	s0,48(sp)
    800033b4:	f426                	sd	s1,40(sp)
    800033b6:	f04a                	sd	s2,32(sp)
    800033b8:	ec4e                	sd	s3,24(sp)
    800033ba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033bc:	fcc40593          	addi	a1,s0,-52
    800033c0:	4501                	li	a0,0
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	c36080e7          	jalr	-970(ra) # 80002ff8 <argint>
    return -1;
    800033ca:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033cc:	06054563          	bltz	a0,80003436 <sys_sleep+0x88>
  acquire(&tickslock);
    800033d0:	00015517          	auipc	a0,0x15
    800033d4:	72850513          	addi	a0,a0,1832 # 80018af8 <tickslock>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	80c080e7          	jalr	-2036(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800033e0:	00006917          	auipc	s2,0x6
    800033e4:	c5092903          	lw	s2,-944(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800033e8:	fcc42783          	lw	a5,-52(s0)
    800033ec:	cf85                	beqz	a5,80003424 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033ee:	00015997          	auipc	s3,0x15
    800033f2:	70a98993          	addi	s3,s3,1802 # 80018af8 <tickslock>
    800033f6:	00006497          	auipc	s1,0x6
    800033fa:	c3a48493          	addi	s1,s1,-966 # 80009030 <ticks>
    if(myproc()->killed){
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	694080e7          	jalr	1684(ra) # 80001a92 <myproc>
    80003406:	551c                	lw	a5,40(a0)
    80003408:	ef9d                	bnez	a5,80003446 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000340a:	85ce                	mv	a1,s3
    8000340c:	8526                	mv	a0,s1
    8000340e:	fffff097          	auipc	ra,0xfffff
    80003412:	f5a080e7          	jalr	-166(ra) # 80002368 <sleep>
  while(ticks - ticks0 < n){
    80003416:	409c                	lw	a5,0(s1)
    80003418:	412787bb          	subw	a5,a5,s2
    8000341c:	fcc42703          	lw	a4,-52(s0)
    80003420:	fce7efe3          	bltu	a5,a4,800033fe <sys_sleep+0x50>
  }
  release(&tickslock);
    80003424:	00015517          	auipc	a0,0x15
    80003428:	6d450513          	addi	a0,a0,1748 # 80018af8 <tickslock>
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
  return 0;
    80003434:	4781                	li	a5,0
}
    80003436:	853e                	mv	a0,a5
    80003438:	70e2                	ld	ra,56(sp)
    8000343a:	7442                	ld	s0,48(sp)
    8000343c:	74a2                	ld	s1,40(sp)
    8000343e:	7902                	ld	s2,32(sp)
    80003440:	69e2                	ld	s3,24(sp)
    80003442:	6121                	addi	sp,sp,64
    80003444:	8082                	ret
      release(&tickslock);
    80003446:	00015517          	auipc	a0,0x15
    8000344a:	6b250513          	addi	a0,a0,1714 # 80018af8 <tickslock>
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
      return -1;
    80003456:	57fd                	li	a5,-1
    80003458:	bff9                	j	80003436 <sys_sleep+0x88>

000000008000345a <sys_kill>:

uint64
sys_kill(void)
{
    8000345a:	1101                	addi	sp,sp,-32
    8000345c:	ec06                	sd	ra,24(sp)
    8000345e:	e822                	sd	s0,16(sp)
    80003460:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003462:	fec40593          	addi	a1,s0,-20
    80003466:	4501                	li	a0,0
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	b90080e7          	jalr	-1136(ra) # 80002ff8 <argint>
    80003470:	87aa                	mv	a5,a0
    return -1;
    80003472:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003474:	0007c863          	bltz	a5,80003484 <sys_kill+0x2a>
  return kill(pid);
    80003478:	fec42503          	lw	a0,-20(s0)
    8000347c:	fffff097          	auipc	ra,0xfffff
    80003480:	3b6080e7          	jalr	950(ra) # 80002832 <kill>
}
    80003484:	60e2                	ld	ra,24(sp)
    80003486:	6442                	ld	s0,16(sp)
    80003488:	6105                	addi	sp,sp,32
    8000348a:	8082                	ret

000000008000348c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000348c:	1101                	addi	sp,sp,-32
    8000348e:	ec06                	sd	ra,24(sp)
    80003490:	e822                	sd	s0,16(sp)
    80003492:	e426                	sd	s1,8(sp)
    80003494:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003496:	00015517          	auipc	a0,0x15
    8000349a:	66250513          	addi	a0,a0,1634 # 80018af8 <tickslock>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	746080e7          	jalr	1862(ra) # 80000be4 <acquire>
  xticks = ticks;
    800034a6:	00006497          	auipc	s1,0x6
    800034aa:	b8a4a483          	lw	s1,-1142(s1) # 80009030 <ticks>
  release(&tickslock);
    800034ae:	00015517          	auipc	a0,0x15
    800034b2:	64a50513          	addi	a0,a0,1610 # 80018af8 <tickslock>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	7e2080e7          	jalr	2018(ra) # 80000c98 <release>
  return xticks;
}
    800034be:	02049513          	slli	a0,s1,0x20
    800034c2:	9101                	srli	a0,a0,0x20
    800034c4:	60e2                	ld	ra,24(sp)
    800034c6:	6442                	ld	s0,16(sp)
    800034c8:	64a2                	ld	s1,8(sp)
    800034ca:	6105                	addi	sp,sp,32
    800034cc:	8082                	ret

00000000800034ce <sys_trace>:

uint64
sys_trace(void)
{
    800034ce:	1101                	addi	sp,sp,-32
    800034d0:	ec06                	sd	ra,24(sp)
    800034d2:	e822                	sd	s0,16(sp)
    800034d4:	1000                	addi	s0,sp,32
  uint64 mask;
  if(argaddr(0,&mask) < 0)
    800034d6:	fe840593          	addi	a1,s0,-24
    800034da:	4501                	li	a0,0
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	b3e080e7          	jalr	-1218(ra) # 8000301a <argaddr>
    800034e4:	87aa                	mv	a5,a0
    return -1;
    800034e6:	557d                	li	a0,-1
  if(argaddr(0,&mask) < 0)
    800034e8:	0007c863          	bltz	a5,800034f8 <sys_trace+0x2a>
  
  return trace(mask);
    800034ec:	fe843503          	ld	a0,-24(s0)
    800034f0:	fffff097          	auipc	ra,0xfffff
    800034f4:	520080e7          	jalr	1312(ra) # 80002a10 <trace>
}
    800034f8:	60e2                	ld	ra,24(sp)
    800034fa:	6442                	ld	s0,16(sp)
    800034fc:	6105                	addi	sp,sp,32
    800034fe:	8082                	ret

0000000080003500 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003500:	1101                	addi	sp,sp,-32
    80003502:	ec06                	sd	ra,24(sp)
    80003504:	e822                	sd	s0,16(sp)
    80003506:	1000                	addi	s0,sp,32
  uint64 arg1,arg2;
  if(argaddr(0,&arg1)<0)
    80003508:	fe840593          	addi	a1,s0,-24
    8000350c:	4501                	li	a0,0
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	b0c080e7          	jalr	-1268(ra) # 8000301a <argaddr>
    return -1;
    80003516:	57fd                	li	a5,-1
  if(argaddr(0,&arg1)<0)
    80003518:	02054563          	bltz	a0,80003542 <sys_set_priority+0x42>
  if(argaddr(1,&arg2)<0)
    8000351c:	fe040593          	addi	a1,s0,-32
    80003520:	4505                	li	a0,1
    80003522:	00000097          	auipc	ra,0x0
    80003526:	af8080e7          	jalr	-1288(ra) # 8000301a <argaddr>
    return -1;
    8000352a:	57fd                	li	a5,-1
  if(argaddr(1,&arg2)<0)
    8000352c:	00054b63          	bltz	a0,80003542 <sys_set_priority+0x42>
  
  return set_priority(arg1,arg2);
    80003530:	fe043583          	ld	a1,-32(s0)
    80003534:	fe843503          	ld	a0,-24(s0)
    80003538:	fffff097          	auipc	ra,0xfffff
    8000353c:	51a080e7          	jalr	1306(ra) # 80002a52 <set_priority>
    80003540:	87aa                	mv	a5,a0
    80003542:	853e                	mv	a0,a5
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret

000000008000354c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000354c:	7179                	addi	sp,sp,-48
    8000354e:	f406                	sd	ra,40(sp)
    80003550:	f022                	sd	s0,32(sp)
    80003552:	ec26                	sd	s1,24(sp)
    80003554:	e84a                	sd	s2,16(sp)
    80003556:	e44e                	sd	s3,8(sp)
    80003558:	e052                	sd	s4,0(sp)
    8000355a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000355c:	00005597          	auipc	a1,0x5
    80003560:	0fc58593          	addi	a1,a1,252 # 80008658 <syscalls+0xc8>
    80003564:	00015517          	auipc	a0,0x15
    80003568:	5ac50513          	addi	a0,a0,1452 # 80018b10 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	5e8080e7          	jalr	1512(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003574:	0001d797          	auipc	a5,0x1d
    80003578:	59c78793          	addi	a5,a5,1436 # 80020b10 <bcache+0x8000>
    8000357c:	0001d717          	auipc	a4,0x1d
    80003580:	7fc70713          	addi	a4,a4,2044 # 80020d78 <bcache+0x8268>
    80003584:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003588:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000358c:	00015497          	auipc	s1,0x15
    80003590:	59c48493          	addi	s1,s1,1436 # 80018b28 <bcache+0x18>
    b->next = bcache.head.next;
    80003594:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003596:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003598:	00005a17          	auipc	s4,0x5
    8000359c:	0c8a0a13          	addi	s4,s4,200 # 80008660 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035a0:	2b893783          	ld	a5,696(s2)
    800035a4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035a6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035aa:	85d2                	mv	a1,s4
    800035ac:	01048513          	addi	a0,s1,16
    800035b0:	00001097          	auipc	ra,0x1
    800035b4:	4bc080e7          	jalr	1212(ra) # 80004a6c <initsleeplock>
    bcache.head.next->prev = b;
    800035b8:	2b893783          	ld	a5,696(s2)
    800035bc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035be:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035c2:	45848493          	addi	s1,s1,1112
    800035c6:	fd349de3          	bne	s1,s3,800035a0 <binit+0x54>
  }
}
    800035ca:	70a2                	ld	ra,40(sp)
    800035cc:	7402                	ld	s0,32(sp)
    800035ce:	64e2                	ld	s1,24(sp)
    800035d0:	6942                	ld	s2,16(sp)
    800035d2:	69a2                	ld	s3,8(sp)
    800035d4:	6a02                	ld	s4,0(sp)
    800035d6:	6145                	addi	sp,sp,48
    800035d8:	8082                	ret

00000000800035da <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	1800                	addi	s0,sp,48
    800035e8:	89aa                	mv	s3,a0
    800035ea:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035ec:	00015517          	auipc	a0,0x15
    800035f0:	52450513          	addi	a0,a0,1316 # 80018b10 <bcache>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035fc:	0001d497          	auipc	s1,0x1d
    80003600:	7cc4b483          	ld	s1,1996(s1) # 80020dc8 <bcache+0x82b8>
    80003604:	0001d797          	auipc	a5,0x1d
    80003608:	77478793          	addi	a5,a5,1908 # 80020d78 <bcache+0x8268>
    8000360c:	02f48f63          	beq	s1,a5,8000364a <bread+0x70>
    80003610:	873e                	mv	a4,a5
    80003612:	a021                	j	8000361a <bread+0x40>
    80003614:	68a4                	ld	s1,80(s1)
    80003616:	02e48a63          	beq	s1,a4,8000364a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000361a:	449c                	lw	a5,8(s1)
    8000361c:	ff379ce3          	bne	a5,s3,80003614 <bread+0x3a>
    80003620:	44dc                	lw	a5,12(s1)
    80003622:	ff2799e3          	bne	a5,s2,80003614 <bread+0x3a>
      b->refcnt++;
    80003626:	40bc                	lw	a5,64(s1)
    80003628:	2785                	addiw	a5,a5,1
    8000362a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000362c:	00015517          	auipc	a0,0x15
    80003630:	4e450513          	addi	a0,a0,1252 # 80018b10 <bcache>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	664080e7          	jalr	1636(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000363c:	01048513          	addi	a0,s1,16
    80003640:	00001097          	auipc	ra,0x1
    80003644:	466080e7          	jalr	1126(ra) # 80004aa6 <acquiresleep>
      return b;
    80003648:	a8b9                	j	800036a6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000364a:	0001d497          	auipc	s1,0x1d
    8000364e:	7764b483          	ld	s1,1910(s1) # 80020dc0 <bcache+0x82b0>
    80003652:	0001d797          	auipc	a5,0x1d
    80003656:	72678793          	addi	a5,a5,1830 # 80020d78 <bcache+0x8268>
    8000365a:	00f48863          	beq	s1,a5,8000366a <bread+0x90>
    8000365e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003660:	40bc                	lw	a5,64(s1)
    80003662:	cf81                	beqz	a5,8000367a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003664:	64a4                	ld	s1,72(s1)
    80003666:	fee49de3          	bne	s1,a4,80003660 <bread+0x86>
  panic("bget: no buffers");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	ffe50513          	addi	a0,a0,-2 # 80008668 <syscalls+0xd8>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>
      b->dev = dev;
    8000367a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000367e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003682:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003686:	4785                	li	a5,1
    80003688:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000368a:	00015517          	auipc	a0,0x15
    8000368e:	48650513          	addi	a0,a0,1158 # 80018b10 <bcache>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	606080e7          	jalr	1542(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000369a:	01048513          	addi	a0,s1,16
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	408080e7          	jalr	1032(ra) # 80004aa6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036a6:	409c                	lw	a5,0(s1)
    800036a8:	cb89                	beqz	a5,800036ba <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036aa:	8526                	mv	a0,s1
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret
    virtio_disk_rw(b, 0);
    800036ba:	4581                	li	a1,0
    800036bc:	8526                	mv	a0,s1
    800036be:	00003097          	auipc	ra,0x3
    800036c2:	f08080e7          	jalr	-248(ra) # 800065c6 <virtio_disk_rw>
    b->valid = 1;
    800036c6:	4785                	li	a5,1
    800036c8:	c09c                	sw	a5,0(s1)
  return b;
    800036ca:	b7c5                	j	800036aa <bread+0xd0>

00000000800036cc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036d8:	0541                	addi	a0,a0,16
    800036da:	00001097          	auipc	ra,0x1
    800036de:	466080e7          	jalr	1126(ra) # 80004b40 <holdingsleep>
    800036e2:	cd01                	beqz	a0,800036fa <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036e4:	4585                	li	a1,1
    800036e6:	8526                	mv	a0,s1
    800036e8:	00003097          	auipc	ra,0x3
    800036ec:	ede080e7          	jalr	-290(ra) # 800065c6 <virtio_disk_rw>
}
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	64a2                	ld	s1,8(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret
    panic("bwrite");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	f8650513          	addi	a0,a0,-122 # 80008680 <syscalls+0xf0>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e3c080e7          	jalr	-452(ra) # 8000053e <panic>

000000008000370a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	e04a                	sd	s2,0(sp)
    80003714:	1000                	addi	s0,sp,32
    80003716:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003718:	01050913          	addi	s2,a0,16
    8000371c:	854a                	mv	a0,s2
    8000371e:	00001097          	auipc	ra,0x1
    80003722:	422080e7          	jalr	1058(ra) # 80004b40 <holdingsleep>
    80003726:	c92d                	beqz	a0,80003798 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	3d2080e7          	jalr	978(ra) # 80004afc <releasesleep>

  acquire(&bcache.lock);
    80003732:	00015517          	auipc	a0,0x15
    80003736:	3de50513          	addi	a0,a0,990 # 80018b10 <bcache>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	4aa080e7          	jalr	1194(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003742:	40bc                	lw	a5,64(s1)
    80003744:	37fd                	addiw	a5,a5,-1
    80003746:	0007871b          	sext.w	a4,a5
    8000374a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000374c:	eb05                	bnez	a4,8000377c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000374e:	68bc                	ld	a5,80(s1)
    80003750:	64b8                	ld	a4,72(s1)
    80003752:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003754:	64bc                	ld	a5,72(s1)
    80003756:	68b8                	ld	a4,80(s1)
    80003758:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000375a:	0001d797          	auipc	a5,0x1d
    8000375e:	3b678793          	addi	a5,a5,950 # 80020b10 <bcache+0x8000>
    80003762:	2b87b703          	ld	a4,696(a5)
    80003766:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003768:	0001d717          	auipc	a4,0x1d
    8000376c:	61070713          	addi	a4,a4,1552 # 80020d78 <bcache+0x8268>
    80003770:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003772:	2b87b703          	ld	a4,696(a5)
    80003776:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003778:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000377c:	00015517          	auipc	a0,0x15
    80003780:	39450513          	addi	a0,a0,916 # 80018b10 <bcache>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	514080e7          	jalr	1300(ra) # 80000c98 <release>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6902                	ld	s2,0(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret
    panic("brelse");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	ef050513          	addi	a0,a0,-272 # 80008688 <syscalls+0xf8>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>

00000000800037a8 <bpin>:

void
bpin(struct buf *b) {
    800037a8:	1101                	addi	sp,sp,-32
    800037aa:	ec06                	sd	ra,24(sp)
    800037ac:	e822                	sd	s0,16(sp)
    800037ae:	e426                	sd	s1,8(sp)
    800037b0:	1000                	addi	s0,sp,32
    800037b2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b4:	00015517          	auipc	a0,0x15
    800037b8:	35c50513          	addi	a0,a0,860 # 80018b10 <bcache>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037c4:	40bc                	lw	a5,64(s1)
    800037c6:	2785                	addiw	a5,a5,1
    800037c8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037ca:	00015517          	auipc	a0,0x15
    800037ce:	34650513          	addi	a0,a0,838 # 80018b10 <bcache>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6105                	addi	sp,sp,32
    800037e2:	8082                	ret

00000000800037e4 <bunpin>:

void
bunpin(struct buf *b) {
    800037e4:	1101                	addi	sp,sp,-32
    800037e6:	ec06                	sd	ra,24(sp)
    800037e8:	e822                	sd	s0,16(sp)
    800037ea:	e426                	sd	s1,8(sp)
    800037ec:	1000                	addi	s0,sp,32
    800037ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037f0:	00015517          	auipc	a0,0x15
    800037f4:	32050513          	addi	a0,a0,800 # 80018b10 <bcache>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	3ec080e7          	jalr	1004(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003800:	40bc                	lw	a5,64(s1)
    80003802:	37fd                	addiw	a5,a5,-1
    80003804:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003806:	00015517          	auipc	a0,0x15
    8000380a:	30a50513          	addi	a0,a0,778 # 80018b10 <bcache>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
}
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	64a2                	ld	s1,8(sp)
    8000381c:	6105                	addi	sp,sp,32
    8000381e:	8082                	ret

0000000080003820 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003820:	1101                	addi	sp,sp,-32
    80003822:	ec06                	sd	ra,24(sp)
    80003824:	e822                	sd	s0,16(sp)
    80003826:	e426                	sd	s1,8(sp)
    80003828:	e04a                	sd	s2,0(sp)
    8000382a:	1000                	addi	s0,sp,32
    8000382c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000382e:	00d5d59b          	srliw	a1,a1,0xd
    80003832:	0001e797          	auipc	a5,0x1e
    80003836:	9ba7a783          	lw	a5,-1606(a5) # 800211ec <sb+0x1c>
    8000383a:	9dbd                	addw	a1,a1,a5
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	d9e080e7          	jalr	-610(ra) # 800035da <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003844:	0074f713          	andi	a4,s1,7
    80003848:	4785                	li	a5,1
    8000384a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000384e:	14ce                	slli	s1,s1,0x33
    80003850:	90d9                	srli	s1,s1,0x36
    80003852:	00950733          	add	a4,a0,s1
    80003856:	05874703          	lbu	a4,88(a4)
    8000385a:	00e7f6b3          	and	a3,a5,a4
    8000385e:	c69d                	beqz	a3,8000388c <bfree+0x6c>
    80003860:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003862:	94aa                	add	s1,s1,a0
    80003864:	fff7c793          	not	a5,a5
    80003868:	8ff9                	and	a5,a5,a4
    8000386a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	118080e7          	jalr	280(ra) # 80004986 <log_write>
  brelse(bp);
    80003876:	854a                	mv	a0,s2
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	e92080e7          	jalr	-366(ra) # 8000370a <brelse>
}
    80003880:	60e2                	ld	ra,24(sp)
    80003882:	6442                	ld	s0,16(sp)
    80003884:	64a2                	ld	s1,8(sp)
    80003886:	6902                	ld	s2,0(sp)
    80003888:	6105                	addi	sp,sp,32
    8000388a:	8082                	ret
    panic("freeing free block");
    8000388c:	00005517          	auipc	a0,0x5
    80003890:	e0450513          	addi	a0,a0,-508 # 80008690 <syscalls+0x100>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>

000000008000389c <balloc>:
{
    8000389c:	711d                	addi	sp,sp,-96
    8000389e:	ec86                	sd	ra,88(sp)
    800038a0:	e8a2                	sd	s0,80(sp)
    800038a2:	e4a6                	sd	s1,72(sp)
    800038a4:	e0ca                	sd	s2,64(sp)
    800038a6:	fc4e                	sd	s3,56(sp)
    800038a8:	f852                	sd	s4,48(sp)
    800038aa:	f456                	sd	s5,40(sp)
    800038ac:	f05a                	sd	s6,32(sp)
    800038ae:	ec5e                	sd	s7,24(sp)
    800038b0:	e862                	sd	s8,16(sp)
    800038b2:	e466                	sd	s9,8(sp)
    800038b4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038b6:	0001e797          	auipc	a5,0x1e
    800038ba:	91e7a783          	lw	a5,-1762(a5) # 800211d4 <sb+0x4>
    800038be:	cbd1                	beqz	a5,80003952 <balloc+0xb6>
    800038c0:	8baa                	mv	s7,a0
    800038c2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038c4:	0001eb17          	auipc	s6,0x1e
    800038c8:	90cb0b13          	addi	s6,s6,-1780 # 800211d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038cc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038ce:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038d2:	6c89                	lui	s9,0x2
    800038d4:	a831                	j	800038f0 <balloc+0x54>
    brelse(bp);
    800038d6:	854a                	mv	a0,s2
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	e32080e7          	jalr	-462(ra) # 8000370a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038e0:	015c87bb          	addw	a5,s9,s5
    800038e4:	00078a9b          	sext.w	s5,a5
    800038e8:	004b2703          	lw	a4,4(s6)
    800038ec:	06eaf363          	bgeu	s5,a4,80003952 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038f0:	41fad79b          	sraiw	a5,s5,0x1f
    800038f4:	0137d79b          	srliw	a5,a5,0x13
    800038f8:	015787bb          	addw	a5,a5,s5
    800038fc:	40d7d79b          	sraiw	a5,a5,0xd
    80003900:	01cb2583          	lw	a1,28(s6)
    80003904:	9dbd                	addw	a1,a1,a5
    80003906:	855e                	mv	a0,s7
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	cd2080e7          	jalr	-814(ra) # 800035da <bread>
    80003910:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003912:	004b2503          	lw	a0,4(s6)
    80003916:	000a849b          	sext.w	s1,s5
    8000391a:	8662                	mv	a2,s8
    8000391c:	faa4fde3          	bgeu	s1,a0,800038d6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003920:	41f6579b          	sraiw	a5,a2,0x1f
    80003924:	01d7d69b          	srliw	a3,a5,0x1d
    80003928:	00c6873b          	addw	a4,a3,a2
    8000392c:	00777793          	andi	a5,a4,7
    80003930:	9f95                	subw	a5,a5,a3
    80003932:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003936:	4037571b          	sraiw	a4,a4,0x3
    8000393a:	00e906b3          	add	a3,s2,a4
    8000393e:	0586c683          	lbu	a3,88(a3)
    80003942:	00d7f5b3          	and	a1,a5,a3
    80003946:	cd91                	beqz	a1,80003962 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003948:	2605                	addiw	a2,a2,1
    8000394a:	2485                	addiw	s1,s1,1
    8000394c:	fd4618e3          	bne	a2,s4,8000391c <balloc+0x80>
    80003950:	b759                	j	800038d6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	d5650513          	addi	a0,a0,-682 # 800086a8 <syscalls+0x118>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003962:	974a                	add	a4,a4,s2
    80003964:	8fd5                	or	a5,a5,a3
    80003966:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000396a:	854a                	mv	a0,s2
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	01a080e7          	jalr	26(ra) # 80004986 <log_write>
        brelse(bp);
    80003974:	854a                	mv	a0,s2
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	d94080e7          	jalr	-620(ra) # 8000370a <brelse>
  bp = bread(dev, bno);
    8000397e:	85a6                	mv	a1,s1
    80003980:	855e                	mv	a0,s7
    80003982:	00000097          	auipc	ra,0x0
    80003986:	c58080e7          	jalr	-936(ra) # 800035da <bread>
    8000398a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000398c:	40000613          	li	a2,1024
    80003990:	4581                	li	a1,0
    80003992:	05850513          	addi	a0,a0,88
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	34a080e7          	jalr	842(ra) # 80000ce0 <memset>
  log_write(bp);
    8000399e:	854a                	mv	a0,s2
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	fe6080e7          	jalr	-26(ra) # 80004986 <log_write>
  brelse(bp);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	d60080e7          	jalr	-672(ra) # 8000370a <brelse>
}
    800039b2:	8526                	mv	a0,s1
    800039b4:	60e6                	ld	ra,88(sp)
    800039b6:	6446                	ld	s0,80(sp)
    800039b8:	64a6                	ld	s1,72(sp)
    800039ba:	6906                	ld	s2,64(sp)
    800039bc:	79e2                	ld	s3,56(sp)
    800039be:	7a42                	ld	s4,48(sp)
    800039c0:	7aa2                	ld	s5,40(sp)
    800039c2:	7b02                	ld	s6,32(sp)
    800039c4:	6be2                	ld	s7,24(sp)
    800039c6:	6c42                	ld	s8,16(sp)
    800039c8:	6ca2                	ld	s9,8(sp)
    800039ca:	6125                	addi	sp,sp,96
    800039cc:	8082                	ret

00000000800039ce <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039ce:	7179                	addi	sp,sp,-48
    800039d0:	f406                	sd	ra,40(sp)
    800039d2:	f022                	sd	s0,32(sp)
    800039d4:	ec26                	sd	s1,24(sp)
    800039d6:	e84a                	sd	s2,16(sp)
    800039d8:	e44e                	sd	s3,8(sp)
    800039da:	e052                	sd	s4,0(sp)
    800039dc:	1800                	addi	s0,sp,48
    800039de:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039e0:	47ad                	li	a5,11
    800039e2:	04b7fe63          	bgeu	a5,a1,80003a3e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039e6:	ff45849b          	addiw	s1,a1,-12
    800039ea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039ee:	0ff00793          	li	a5,255
    800039f2:	0ae7e363          	bltu	a5,a4,80003a98 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800039f6:	08052583          	lw	a1,128(a0)
    800039fa:	c5ad                	beqz	a1,80003a64 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800039fc:	00092503          	lw	a0,0(s2)
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	bda080e7          	jalr	-1062(ra) # 800035da <bread>
    80003a08:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a0a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a0e:	02049593          	slli	a1,s1,0x20
    80003a12:	9181                	srli	a1,a1,0x20
    80003a14:	058a                	slli	a1,a1,0x2
    80003a16:	00b784b3          	add	s1,a5,a1
    80003a1a:	0004a983          	lw	s3,0(s1)
    80003a1e:	04098d63          	beqz	s3,80003a78 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a22:	8552                	mv	a0,s4
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	ce6080e7          	jalr	-794(ra) # 8000370a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a2c:	854e                	mv	a0,s3
    80003a2e:	70a2                	ld	ra,40(sp)
    80003a30:	7402                	ld	s0,32(sp)
    80003a32:	64e2                	ld	s1,24(sp)
    80003a34:	6942                	ld	s2,16(sp)
    80003a36:	69a2                	ld	s3,8(sp)
    80003a38:	6a02                	ld	s4,0(sp)
    80003a3a:	6145                	addi	sp,sp,48
    80003a3c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a3e:	02059493          	slli	s1,a1,0x20
    80003a42:	9081                	srli	s1,s1,0x20
    80003a44:	048a                	slli	s1,s1,0x2
    80003a46:	94aa                	add	s1,s1,a0
    80003a48:	0504a983          	lw	s3,80(s1)
    80003a4c:	fe0990e3          	bnez	s3,80003a2c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a50:	4108                	lw	a0,0(a0)
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	e4a080e7          	jalr	-438(ra) # 8000389c <balloc>
    80003a5a:	0005099b          	sext.w	s3,a0
    80003a5e:	0534a823          	sw	s3,80(s1)
    80003a62:	b7e9                	j	80003a2c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a64:	4108                	lw	a0,0(a0)
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	e36080e7          	jalr	-458(ra) # 8000389c <balloc>
    80003a6e:	0005059b          	sext.w	a1,a0
    80003a72:	08b92023          	sw	a1,128(s2)
    80003a76:	b759                	j	800039fc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a78:	00092503          	lw	a0,0(s2)
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	e20080e7          	jalr	-480(ra) # 8000389c <balloc>
    80003a84:	0005099b          	sext.w	s3,a0
    80003a88:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a8c:	8552                	mv	a0,s4
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	ef8080e7          	jalr	-264(ra) # 80004986 <log_write>
    80003a96:	b771                	j	80003a22 <bmap+0x54>
  panic("bmap: out of range");
    80003a98:	00005517          	auipc	a0,0x5
    80003a9c:	c2850513          	addi	a0,a0,-984 # 800086c0 <syscalls+0x130>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	a9e080e7          	jalr	-1378(ra) # 8000053e <panic>

0000000080003aa8 <iget>:
{
    80003aa8:	7179                	addi	sp,sp,-48
    80003aaa:	f406                	sd	ra,40(sp)
    80003aac:	f022                	sd	s0,32(sp)
    80003aae:	ec26                	sd	s1,24(sp)
    80003ab0:	e84a                	sd	s2,16(sp)
    80003ab2:	e44e                	sd	s3,8(sp)
    80003ab4:	e052                	sd	s4,0(sp)
    80003ab6:	1800                	addi	s0,sp,48
    80003ab8:	89aa                	mv	s3,a0
    80003aba:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003abc:	0001d517          	auipc	a0,0x1d
    80003ac0:	73450513          	addi	a0,a0,1844 # 800211f0 <itable>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	120080e7          	jalr	288(ra) # 80000be4 <acquire>
  empty = 0;
    80003acc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ace:	0001d497          	auipc	s1,0x1d
    80003ad2:	73a48493          	addi	s1,s1,1850 # 80021208 <itable+0x18>
    80003ad6:	0001f697          	auipc	a3,0x1f
    80003ada:	1c268693          	addi	a3,a3,450 # 80022c98 <log>
    80003ade:	a039                	j	80003aec <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ae0:	02090b63          	beqz	s2,80003b16 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ae4:	08848493          	addi	s1,s1,136
    80003ae8:	02d48a63          	beq	s1,a3,80003b1c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003aec:	449c                	lw	a5,8(s1)
    80003aee:	fef059e3          	blez	a5,80003ae0 <iget+0x38>
    80003af2:	4098                	lw	a4,0(s1)
    80003af4:	ff3716e3          	bne	a4,s3,80003ae0 <iget+0x38>
    80003af8:	40d8                	lw	a4,4(s1)
    80003afa:	ff4713e3          	bne	a4,s4,80003ae0 <iget+0x38>
      ip->ref++;
    80003afe:	2785                	addiw	a5,a5,1
    80003b00:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b02:	0001d517          	auipc	a0,0x1d
    80003b06:	6ee50513          	addi	a0,a0,1774 # 800211f0 <itable>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	18e080e7          	jalr	398(ra) # 80000c98 <release>
      return ip;
    80003b12:	8926                	mv	s2,s1
    80003b14:	a03d                	j	80003b42 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b16:	f7f9                	bnez	a5,80003ae4 <iget+0x3c>
    80003b18:	8926                	mv	s2,s1
    80003b1a:	b7e9                	j	80003ae4 <iget+0x3c>
  if(empty == 0)
    80003b1c:	02090c63          	beqz	s2,80003b54 <iget+0xac>
  ip->dev = dev;
    80003b20:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b24:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b28:	4785                	li	a5,1
    80003b2a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b2e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b32:	0001d517          	auipc	a0,0x1d
    80003b36:	6be50513          	addi	a0,a0,1726 # 800211f0 <itable>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	15e080e7          	jalr	350(ra) # 80000c98 <release>
}
    80003b42:	854a                	mv	a0,s2
    80003b44:	70a2                	ld	ra,40(sp)
    80003b46:	7402                	ld	s0,32(sp)
    80003b48:	64e2                	ld	s1,24(sp)
    80003b4a:	6942                	ld	s2,16(sp)
    80003b4c:	69a2                	ld	s3,8(sp)
    80003b4e:	6a02                	ld	s4,0(sp)
    80003b50:	6145                	addi	sp,sp,48
    80003b52:	8082                	ret
    panic("iget: no inodes");
    80003b54:	00005517          	auipc	a0,0x5
    80003b58:	b8450513          	addi	a0,a0,-1148 # 800086d8 <syscalls+0x148>
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	9e2080e7          	jalr	-1566(ra) # 8000053e <panic>

0000000080003b64 <fsinit>:
fsinit(int dev) {
    80003b64:	7179                	addi	sp,sp,-48
    80003b66:	f406                	sd	ra,40(sp)
    80003b68:	f022                	sd	s0,32(sp)
    80003b6a:	ec26                	sd	s1,24(sp)
    80003b6c:	e84a                	sd	s2,16(sp)
    80003b6e:	e44e                	sd	s3,8(sp)
    80003b70:	1800                	addi	s0,sp,48
    80003b72:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b74:	4585                	li	a1,1
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	a64080e7          	jalr	-1436(ra) # 800035da <bread>
    80003b7e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b80:	0001d997          	auipc	s3,0x1d
    80003b84:	65098993          	addi	s3,s3,1616 # 800211d0 <sb>
    80003b88:	02000613          	li	a2,32
    80003b8c:	05850593          	addi	a1,a0,88
    80003b90:	854e                	mv	a0,s3
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	1ae080e7          	jalr	430(ra) # 80000d40 <memmove>
  brelse(bp);
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	b6e080e7          	jalr	-1170(ra) # 8000370a <brelse>
  if(sb.magic != FSMAGIC)
    80003ba4:	0009a703          	lw	a4,0(s3)
    80003ba8:	102037b7          	lui	a5,0x10203
    80003bac:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bb0:	02f71263          	bne	a4,a5,80003bd4 <fsinit+0x70>
  initlog(dev, &sb);
    80003bb4:	0001d597          	auipc	a1,0x1d
    80003bb8:	61c58593          	addi	a1,a1,1564 # 800211d0 <sb>
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	00001097          	auipc	ra,0x1
    80003bc2:	b4c080e7          	jalr	-1204(ra) # 8000470a <initlog>
}
    80003bc6:	70a2                	ld	ra,40(sp)
    80003bc8:	7402                	ld	s0,32(sp)
    80003bca:	64e2                	ld	s1,24(sp)
    80003bcc:	6942                	ld	s2,16(sp)
    80003bce:	69a2                	ld	s3,8(sp)
    80003bd0:	6145                	addi	sp,sp,48
    80003bd2:	8082                	ret
    panic("invalid file system");
    80003bd4:	00005517          	auipc	a0,0x5
    80003bd8:	b1450513          	addi	a0,a0,-1260 # 800086e8 <syscalls+0x158>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	962080e7          	jalr	-1694(ra) # 8000053e <panic>

0000000080003be4 <iinit>:
{
    80003be4:	7179                	addi	sp,sp,-48
    80003be6:	f406                	sd	ra,40(sp)
    80003be8:	f022                	sd	s0,32(sp)
    80003bea:	ec26                	sd	s1,24(sp)
    80003bec:	e84a                	sd	s2,16(sp)
    80003bee:	e44e                	sd	s3,8(sp)
    80003bf0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bf2:	00005597          	auipc	a1,0x5
    80003bf6:	b0e58593          	addi	a1,a1,-1266 # 80008700 <syscalls+0x170>
    80003bfa:	0001d517          	auipc	a0,0x1d
    80003bfe:	5f650513          	addi	a0,a0,1526 # 800211f0 <itable>
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	f52080e7          	jalr	-174(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c0a:	0001d497          	auipc	s1,0x1d
    80003c0e:	60e48493          	addi	s1,s1,1550 # 80021218 <itable+0x28>
    80003c12:	0001f997          	auipc	s3,0x1f
    80003c16:	09698993          	addi	s3,s3,150 # 80022ca8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c1a:	00005917          	auipc	s2,0x5
    80003c1e:	aee90913          	addi	s2,s2,-1298 # 80008708 <syscalls+0x178>
    80003c22:	85ca                	mv	a1,s2
    80003c24:	8526                	mv	a0,s1
    80003c26:	00001097          	auipc	ra,0x1
    80003c2a:	e46080e7          	jalr	-442(ra) # 80004a6c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c2e:	08848493          	addi	s1,s1,136
    80003c32:	ff3498e3          	bne	s1,s3,80003c22 <iinit+0x3e>
}
    80003c36:	70a2                	ld	ra,40(sp)
    80003c38:	7402                	ld	s0,32(sp)
    80003c3a:	64e2                	ld	s1,24(sp)
    80003c3c:	6942                	ld	s2,16(sp)
    80003c3e:	69a2                	ld	s3,8(sp)
    80003c40:	6145                	addi	sp,sp,48
    80003c42:	8082                	ret

0000000080003c44 <ialloc>:
{
    80003c44:	715d                	addi	sp,sp,-80
    80003c46:	e486                	sd	ra,72(sp)
    80003c48:	e0a2                	sd	s0,64(sp)
    80003c4a:	fc26                	sd	s1,56(sp)
    80003c4c:	f84a                	sd	s2,48(sp)
    80003c4e:	f44e                	sd	s3,40(sp)
    80003c50:	f052                	sd	s4,32(sp)
    80003c52:	ec56                	sd	s5,24(sp)
    80003c54:	e85a                	sd	s6,16(sp)
    80003c56:	e45e                	sd	s7,8(sp)
    80003c58:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c5a:	0001d717          	auipc	a4,0x1d
    80003c5e:	58272703          	lw	a4,1410(a4) # 800211dc <sb+0xc>
    80003c62:	4785                	li	a5,1
    80003c64:	04e7fa63          	bgeu	a5,a4,80003cb8 <ialloc+0x74>
    80003c68:	8aaa                	mv	s5,a0
    80003c6a:	8bae                	mv	s7,a1
    80003c6c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c6e:	0001da17          	auipc	s4,0x1d
    80003c72:	562a0a13          	addi	s4,s4,1378 # 800211d0 <sb>
    80003c76:	00048b1b          	sext.w	s6,s1
    80003c7a:	0044d593          	srli	a1,s1,0x4
    80003c7e:	018a2783          	lw	a5,24(s4)
    80003c82:	9dbd                	addw	a1,a1,a5
    80003c84:	8556                	mv	a0,s5
    80003c86:	00000097          	auipc	ra,0x0
    80003c8a:	954080e7          	jalr	-1708(ra) # 800035da <bread>
    80003c8e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c90:	05850993          	addi	s3,a0,88
    80003c94:	00f4f793          	andi	a5,s1,15
    80003c98:	079a                	slli	a5,a5,0x6
    80003c9a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c9c:	00099783          	lh	a5,0(s3)
    80003ca0:	c785                	beqz	a5,80003cc8 <ialloc+0x84>
    brelse(bp);
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	a68080e7          	jalr	-1432(ra) # 8000370a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003caa:	0485                	addi	s1,s1,1
    80003cac:	00ca2703          	lw	a4,12(s4)
    80003cb0:	0004879b          	sext.w	a5,s1
    80003cb4:	fce7e1e3          	bltu	a5,a4,80003c76 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cb8:	00005517          	auipc	a0,0x5
    80003cbc:	a5850513          	addi	a0,a0,-1448 # 80008710 <syscalls+0x180>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	87e080e7          	jalr	-1922(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cc8:	04000613          	li	a2,64
    80003ccc:	4581                	li	a1,0
    80003cce:	854e                	mv	a0,s3
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	010080e7          	jalr	16(ra) # 80000ce0 <memset>
      dip->type = type;
    80003cd8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00001097          	auipc	ra,0x1
    80003ce2:	ca8080e7          	jalr	-856(ra) # 80004986 <log_write>
      brelse(bp);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	a22080e7          	jalr	-1502(ra) # 8000370a <brelse>
      return iget(dev, inum);
    80003cf0:	85da                	mv	a1,s6
    80003cf2:	8556                	mv	a0,s5
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	db4080e7          	jalr	-588(ra) # 80003aa8 <iget>
}
    80003cfc:	60a6                	ld	ra,72(sp)
    80003cfe:	6406                	ld	s0,64(sp)
    80003d00:	74e2                	ld	s1,56(sp)
    80003d02:	7942                	ld	s2,48(sp)
    80003d04:	79a2                	ld	s3,40(sp)
    80003d06:	7a02                	ld	s4,32(sp)
    80003d08:	6ae2                	ld	s5,24(sp)
    80003d0a:	6b42                	ld	s6,16(sp)
    80003d0c:	6ba2                	ld	s7,8(sp)
    80003d0e:	6161                	addi	sp,sp,80
    80003d10:	8082                	ret

0000000080003d12 <iupdate>:
{
    80003d12:	1101                	addi	sp,sp,-32
    80003d14:	ec06                	sd	ra,24(sp)
    80003d16:	e822                	sd	s0,16(sp)
    80003d18:	e426                	sd	s1,8(sp)
    80003d1a:	e04a                	sd	s2,0(sp)
    80003d1c:	1000                	addi	s0,sp,32
    80003d1e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d20:	415c                	lw	a5,4(a0)
    80003d22:	0047d79b          	srliw	a5,a5,0x4
    80003d26:	0001d597          	auipc	a1,0x1d
    80003d2a:	4c25a583          	lw	a1,1218(a1) # 800211e8 <sb+0x18>
    80003d2e:	9dbd                	addw	a1,a1,a5
    80003d30:	4108                	lw	a0,0(a0)
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	8a8080e7          	jalr	-1880(ra) # 800035da <bread>
    80003d3a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d3c:	05850793          	addi	a5,a0,88
    80003d40:	40c8                	lw	a0,4(s1)
    80003d42:	893d                	andi	a0,a0,15
    80003d44:	051a                	slli	a0,a0,0x6
    80003d46:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d48:	04449703          	lh	a4,68(s1)
    80003d4c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d50:	04649703          	lh	a4,70(s1)
    80003d54:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d58:	04849703          	lh	a4,72(s1)
    80003d5c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d60:	04a49703          	lh	a4,74(s1)
    80003d64:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d68:	44f8                	lw	a4,76(s1)
    80003d6a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d6c:	03400613          	li	a2,52
    80003d70:	05048593          	addi	a1,s1,80
    80003d74:	0531                	addi	a0,a0,12
    80003d76:	ffffd097          	auipc	ra,0xffffd
    80003d7a:	fca080e7          	jalr	-54(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d7e:	854a                	mv	a0,s2
    80003d80:	00001097          	auipc	ra,0x1
    80003d84:	c06080e7          	jalr	-1018(ra) # 80004986 <log_write>
  brelse(bp);
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	980080e7          	jalr	-1664(ra) # 8000370a <brelse>
}
    80003d92:	60e2                	ld	ra,24(sp)
    80003d94:	6442                	ld	s0,16(sp)
    80003d96:	64a2                	ld	s1,8(sp)
    80003d98:	6902                	ld	s2,0(sp)
    80003d9a:	6105                	addi	sp,sp,32
    80003d9c:	8082                	ret

0000000080003d9e <idup>:
{
    80003d9e:	1101                	addi	sp,sp,-32
    80003da0:	ec06                	sd	ra,24(sp)
    80003da2:	e822                	sd	s0,16(sp)
    80003da4:	e426                	sd	s1,8(sp)
    80003da6:	1000                	addi	s0,sp,32
    80003da8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003daa:	0001d517          	auipc	a0,0x1d
    80003dae:	44650513          	addi	a0,a0,1094 # 800211f0 <itable>
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	e32080e7          	jalr	-462(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dba:	449c                	lw	a5,8(s1)
    80003dbc:	2785                	addiw	a5,a5,1
    80003dbe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dc0:	0001d517          	auipc	a0,0x1d
    80003dc4:	43050513          	addi	a0,a0,1072 # 800211f0 <itable>
    80003dc8:	ffffd097          	auipc	ra,0xffffd
    80003dcc:	ed0080e7          	jalr	-304(ra) # 80000c98 <release>
}
    80003dd0:	8526                	mv	a0,s1
    80003dd2:	60e2                	ld	ra,24(sp)
    80003dd4:	6442                	ld	s0,16(sp)
    80003dd6:	64a2                	ld	s1,8(sp)
    80003dd8:	6105                	addi	sp,sp,32
    80003dda:	8082                	ret

0000000080003ddc <ilock>:
{
    80003ddc:	1101                	addi	sp,sp,-32
    80003dde:	ec06                	sd	ra,24(sp)
    80003de0:	e822                	sd	s0,16(sp)
    80003de2:	e426                	sd	s1,8(sp)
    80003de4:	e04a                	sd	s2,0(sp)
    80003de6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003de8:	c115                	beqz	a0,80003e0c <ilock+0x30>
    80003dea:	84aa                	mv	s1,a0
    80003dec:	451c                	lw	a5,8(a0)
    80003dee:	00f05f63          	blez	a5,80003e0c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003df2:	0541                	addi	a0,a0,16
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	cb2080e7          	jalr	-846(ra) # 80004aa6 <acquiresleep>
  if(ip->valid == 0){
    80003dfc:	40bc                	lw	a5,64(s1)
    80003dfe:	cf99                	beqz	a5,80003e1c <ilock+0x40>
}
    80003e00:	60e2                	ld	ra,24(sp)
    80003e02:	6442                	ld	s0,16(sp)
    80003e04:	64a2                	ld	s1,8(sp)
    80003e06:	6902                	ld	s2,0(sp)
    80003e08:	6105                	addi	sp,sp,32
    80003e0a:	8082                	ret
    panic("ilock");
    80003e0c:	00005517          	auipc	a0,0x5
    80003e10:	91c50513          	addi	a0,a0,-1764 # 80008728 <syscalls+0x198>
    80003e14:	ffffc097          	auipc	ra,0xffffc
    80003e18:	72a080e7          	jalr	1834(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e1c:	40dc                	lw	a5,4(s1)
    80003e1e:	0047d79b          	srliw	a5,a5,0x4
    80003e22:	0001d597          	auipc	a1,0x1d
    80003e26:	3c65a583          	lw	a1,966(a1) # 800211e8 <sb+0x18>
    80003e2a:	9dbd                	addw	a1,a1,a5
    80003e2c:	4088                	lw	a0,0(s1)
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	7ac080e7          	jalr	1964(ra) # 800035da <bread>
    80003e36:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e38:	05850593          	addi	a1,a0,88
    80003e3c:	40dc                	lw	a5,4(s1)
    80003e3e:	8bbd                	andi	a5,a5,15
    80003e40:	079a                	slli	a5,a5,0x6
    80003e42:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e44:	00059783          	lh	a5,0(a1)
    80003e48:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e4c:	00259783          	lh	a5,2(a1)
    80003e50:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e54:	00459783          	lh	a5,4(a1)
    80003e58:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e5c:	00659783          	lh	a5,6(a1)
    80003e60:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e64:	459c                	lw	a5,8(a1)
    80003e66:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e68:	03400613          	li	a2,52
    80003e6c:	05b1                	addi	a1,a1,12
    80003e6e:	05048513          	addi	a0,s1,80
    80003e72:	ffffd097          	auipc	ra,0xffffd
    80003e76:	ece080e7          	jalr	-306(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	88e080e7          	jalr	-1906(ra) # 8000370a <brelse>
    ip->valid = 1;
    80003e84:	4785                	li	a5,1
    80003e86:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e88:	04449783          	lh	a5,68(s1)
    80003e8c:	fbb5                	bnez	a5,80003e00 <ilock+0x24>
      panic("ilock: no type");
    80003e8e:	00005517          	auipc	a0,0x5
    80003e92:	8a250513          	addi	a0,a0,-1886 # 80008730 <syscalls+0x1a0>
    80003e96:	ffffc097          	auipc	ra,0xffffc
    80003e9a:	6a8080e7          	jalr	1704(ra) # 8000053e <panic>

0000000080003e9e <iunlock>:
{
    80003e9e:	1101                	addi	sp,sp,-32
    80003ea0:	ec06                	sd	ra,24(sp)
    80003ea2:	e822                	sd	s0,16(sp)
    80003ea4:	e426                	sd	s1,8(sp)
    80003ea6:	e04a                	sd	s2,0(sp)
    80003ea8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eaa:	c905                	beqz	a0,80003eda <iunlock+0x3c>
    80003eac:	84aa                	mv	s1,a0
    80003eae:	01050913          	addi	s2,a0,16
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	00001097          	auipc	ra,0x1
    80003eb8:	c8c080e7          	jalr	-884(ra) # 80004b40 <holdingsleep>
    80003ebc:	cd19                	beqz	a0,80003eda <iunlock+0x3c>
    80003ebe:	449c                	lw	a5,8(s1)
    80003ec0:	00f05d63          	blez	a5,80003eda <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00001097          	auipc	ra,0x1
    80003eca:	c36080e7          	jalr	-970(ra) # 80004afc <releasesleep>
}
    80003ece:	60e2                	ld	ra,24(sp)
    80003ed0:	6442                	ld	s0,16(sp)
    80003ed2:	64a2                	ld	s1,8(sp)
    80003ed4:	6902                	ld	s2,0(sp)
    80003ed6:	6105                	addi	sp,sp,32
    80003ed8:	8082                	ret
    panic("iunlock");
    80003eda:	00005517          	auipc	a0,0x5
    80003ede:	86650513          	addi	a0,a0,-1946 # 80008740 <syscalls+0x1b0>
    80003ee2:	ffffc097          	auipc	ra,0xffffc
    80003ee6:	65c080e7          	jalr	1628(ra) # 8000053e <panic>

0000000080003eea <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003eea:	7179                	addi	sp,sp,-48
    80003eec:	f406                	sd	ra,40(sp)
    80003eee:	f022                	sd	s0,32(sp)
    80003ef0:	ec26                	sd	s1,24(sp)
    80003ef2:	e84a                	sd	s2,16(sp)
    80003ef4:	e44e                	sd	s3,8(sp)
    80003ef6:	e052                	sd	s4,0(sp)
    80003ef8:	1800                	addi	s0,sp,48
    80003efa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003efc:	05050493          	addi	s1,a0,80
    80003f00:	08050913          	addi	s2,a0,128
    80003f04:	a021                	j	80003f0c <itrunc+0x22>
    80003f06:	0491                	addi	s1,s1,4
    80003f08:	01248d63          	beq	s1,s2,80003f22 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f0c:	408c                	lw	a1,0(s1)
    80003f0e:	dde5                	beqz	a1,80003f06 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f10:	0009a503          	lw	a0,0(s3)
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	90c080e7          	jalr	-1780(ra) # 80003820 <bfree>
      ip->addrs[i] = 0;
    80003f1c:	0004a023          	sw	zero,0(s1)
    80003f20:	b7dd                	j	80003f06 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f22:	0809a583          	lw	a1,128(s3)
    80003f26:	e185                	bnez	a1,80003f46 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f28:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	de4080e7          	jalr	-540(ra) # 80003d12 <iupdate>
}
    80003f36:	70a2                	ld	ra,40(sp)
    80003f38:	7402                	ld	s0,32(sp)
    80003f3a:	64e2                	ld	s1,24(sp)
    80003f3c:	6942                	ld	s2,16(sp)
    80003f3e:	69a2                	ld	s3,8(sp)
    80003f40:	6a02                	ld	s4,0(sp)
    80003f42:	6145                	addi	sp,sp,48
    80003f44:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f46:	0009a503          	lw	a0,0(s3)
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	690080e7          	jalr	1680(ra) # 800035da <bread>
    80003f52:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f54:	05850493          	addi	s1,a0,88
    80003f58:	45850913          	addi	s2,a0,1112
    80003f5c:	a811                	j	80003f70 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f5e:	0009a503          	lw	a0,0(s3)
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	8be080e7          	jalr	-1858(ra) # 80003820 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f6a:	0491                	addi	s1,s1,4
    80003f6c:	01248563          	beq	s1,s2,80003f76 <itrunc+0x8c>
      if(a[j])
    80003f70:	408c                	lw	a1,0(s1)
    80003f72:	dde5                	beqz	a1,80003f6a <itrunc+0x80>
    80003f74:	b7ed                	j	80003f5e <itrunc+0x74>
    brelse(bp);
    80003f76:	8552                	mv	a0,s4
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	792080e7          	jalr	1938(ra) # 8000370a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f80:	0809a583          	lw	a1,128(s3)
    80003f84:	0009a503          	lw	a0,0(s3)
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	898080e7          	jalr	-1896(ra) # 80003820 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f90:	0809a023          	sw	zero,128(s3)
    80003f94:	bf51                	j	80003f28 <itrunc+0x3e>

0000000080003f96 <iput>:
{
    80003f96:	1101                	addi	sp,sp,-32
    80003f98:	ec06                	sd	ra,24(sp)
    80003f9a:	e822                	sd	s0,16(sp)
    80003f9c:	e426                	sd	s1,8(sp)
    80003f9e:	e04a                	sd	s2,0(sp)
    80003fa0:	1000                	addi	s0,sp,32
    80003fa2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fa4:	0001d517          	auipc	a0,0x1d
    80003fa8:	24c50513          	addi	a0,a0,588 # 800211f0 <itable>
    80003fac:	ffffd097          	auipc	ra,0xffffd
    80003fb0:	c38080e7          	jalr	-968(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fb4:	4498                	lw	a4,8(s1)
    80003fb6:	4785                	li	a5,1
    80003fb8:	02f70363          	beq	a4,a5,80003fde <iput+0x48>
  ip->ref--;
    80003fbc:	449c                	lw	a5,8(s1)
    80003fbe:	37fd                	addiw	a5,a5,-1
    80003fc0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fc2:	0001d517          	auipc	a0,0x1d
    80003fc6:	22e50513          	addi	a0,a0,558 # 800211f0 <itable>
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	cce080e7          	jalr	-818(ra) # 80000c98 <release>
}
    80003fd2:	60e2                	ld	ra,24(sp)
    80003fd4:	6442                	ld	s0,16(sp)
    80003fd6:	64a2                	ld	s1,8(sp)
    80003fd8:	6902                	ld	s2,0(sp)
    80003fda:	6105                	addi	sp,sp,32
    80003fdc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fde:	40bc                	lw	a5,64(s1)
    80003fe0:	dff1                	beqz	a5,80003fbc <iput+0x26>
    80003fe2:	04a49783          	lh	a5,74(s1)
    80003fe6:	fbf9                	bnez	a5,80003fbc <iput+0x26>
    acquiresleep(&ip->lock);
    80003fe8:	01048913          	addi	s2,s1,16
    80003fec:	854a                	mv	a0,s2
    80003fee:	00001097          	auipc	ra,0x1
    80003ff2:	ab8080e7          	jalr	-1352(ra) # 80004aa6 <acquiresleep>
    release(&itable.lock);
    80003ff6:	0001d517          	auipc	a0,0x1d
    80003ffa:	1fa50513          	addi	a0,a0,506 # 800211f0 <itable>
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	c9a080e7          	jalr	-870(ra) # 80000c98 <release>
    itrunc(ip);
    80004006:	8526                	mv	a0,s1
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	ee2080e7          	jalr	-286(ra) # 80003eea <itrunc>
    ip->type = 0;
    80004010:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004014:	8526                	mv	a0,s1
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	cfc080e7          	jalr	-772(ra) # 80003d12 <iupdate>
    ip->valid = 0;
    8000401e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004022:	854a                	mv	a0,s2
    80004024:	00001097          	auipc	ra,0x1
    80004028:	ad8080e7          	jalr	-1320(ra) # 80004afc <releasesleep>
    acquire(&itable.lock);
    8000402c:	0001d517          	auipc	a0,0x1d
    80004030:	1c450513          	addi	a0,a0,452 # 800211f0 <itable>
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	bb0080e7          	jalr	-1104(ra) # 80000be4 <acquire>
    8000403c:	b741                	j	80003fbc <iput+0x26>

000000008000403e <iunlockput>:
{
    8000403e:	1101                	addi	sp,sp,-32
    80004040:	ec06                	sd	ra,24(sp)
    80004042:	e822                	sd	s0,16(sp)
    80004044:	e426                	sd	s1,8(sp)
    80004046:	1000                	addi	s0,sp,32
    80004048:	84aa                	mv	s1,a0
  iunlock(ip);
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	e54080e7          	jalr	-428(ra) # 80003e9e <iunlock>
  iput(ip);
    80004052:	8526                	mv	a0,s1
    80004054:	00000097          	auipc	ra,0x0
    80004058:	f42080e7          	jalr	-190(ra) # 80003f96 <iput>
}
    8000405c:	60e2                	ld	ra,24(sp)
    8000405e:	6442                	ld	s0,16(sp)
    80004060:	64a2                	ld	s1,8(sp)
    80004062:	6105                	addi	sp,sp,32
    80004064:	8082                	ret

0000000080004066 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004066:	1141                	addi	sp,sp,-16
    80004068:	e422                	sd	s0,8(sp)
    8000406a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000406c:	411c                	lw	a5,0(a0)
    8000406e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004070:	415c                	lw	a5,4(a0)
    80004072:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004074:	04451783          	lh	a5,68(a0)
    80004078:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000407c:	04a51783          	lh	a5,74(a0)
    80004080:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004084:	04c56783          	lwu	a5,76(a0)
    80004088:	e99c                	sd	a5,16(a1)
}
    8000408a:	6422                	ld	s0,8(sp)
    8000408c:	0141                	addi	sp,sp,16
    8000408e:	8082                	ret

0000000080004090 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004090:	457c                	lw	a5,76(a0)
    80004092:	0ed7e963          	bltu	a5,a3,80004184 <readi+0xf4>
{
    80004096:	7159                	addi	sp,sp,-112
    80004098:	f486                	sd	ra,104(sp)
    8000409a:	f0a2                	sd	s0,96(sp)
    8000409c:	eca6                	sd	s1,88(sp)
    8000409e:	e8ca                	sd	s2,80(sp)
    800040a0:	e4ce                	sd	s3,72(sp)
    800040a2:	e0d2                	sd	s4,64(sp)
    800040a4:	fc56                	sd	s5,56(sp)
    800040a6:	f85a                	sd	s6,48(sp)
    800040a8:	f45e                	sd	s7,40(sp)
    800040aa:	f062                	sd	s8,32(sp)
    800040ac:	ec66                	sd	s9,24(sp)
    800040ae:	e86a                	sd	s10,16(sp)
    800040b0:	e46e                	sd	s11,8(sp)
    800040b2:	1880                	addi	s0,sp,112
    800040b4:	8baa                	mv	s7,a0
    800040b6:	8c2e                	mv	s8,a1
    800040b8:	8ab2                	mv	s5,a2
    800040ba:	84b6                	mv	s1,a3
    800040bc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040be:	9f35                	addw	a4,a4,a3
    return 0;
    800040c0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040c2:	0ad76063          	bltu	a4,a3,80004162 <readi+0xd2>
  if(off + n > ip->size)
    800040c6:	00e7f463          	bgeu	a5,a4,800040ce <readi+0x3e>
    n = ip->size - off;
    800040ca:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040ce:	0a0b0963          	beqz	s6,80004180 <readi+0xf0>
    800040d2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040d8:	5cfd                	li	s9,-1
    800040da:	a82d                	j	80004114 <readi+0x84>
    800040dc:	020a1d93          	slli	s11,s4,0x20
    800040e0:	020ddd93          	srli	s11,s11,0x20
    800040e4:	05890613          	addi	a2,s2,88
    800040e8:	86ee                	mv	a3,s11
    800040ea:	963a                	add	a2,a2,a4
    800040ec:	85d6                	mv	a1,s5
    800040ee:	8562                	mv	a0,s8
    800040f0:	ffffe097          	auipc	ra,0xffffe
    800040f4:	7c6080e7          	jalr	1990(ra) # 800028b6 <either_copyout>
    800040f8:	05950d63          	beq	a0,s9,80004152 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040fc:	854a                	mv	a0,s2
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	60c080e7          	jalr	1548(ra) # 8000370a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004106:	013a09bb          	addw	s3,s4,s3
    8000410a:	009a04bb          	addw	s1,s4,s1
    8000410e:	9aee                	add	s5,s5,s11
    80004110:	0569f763          	bgeu	s3,s6,8000415e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004114:	000ba903          	lw	s2,0(s7)
    80004118:	00a4d59b          	srliw	a1,s1,0xa
    8000411c:	855e                	mv	a0,s7
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	8b0080e7          	jalr	-1872(ra) # 800039ce <bmap>
    80004126:	0005059b          	sext.w	a1,a0
    8000412a:	854a                	mv	a0,s2
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	4ae080e7          	jalr	1198(ra) # 800035da <bread>
    80004134:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004136:	3ff4f713          	andi	a4,s1,1023
    8000413a:	40ed07bb          	subw	a5,s10,a4
    8000413e:	413b06bb          	subw	a3,s6,s3
    80004142:	8a3e                	mv	s4,a5
    80004144:	2781                	sext.w	a5,a5
    80004146:	0006861b          	sext.w	a2,a3
    8000414a:	f8f679e3          	bgeu	a2,a5,800040dc <readi+0x4c>
    8000414e:	8a36                	mv	s4,a3
    80004150:	b771                	j	800040dc <readi+0x4c>
      brelse(bp);
    80004152:	854a                	mv	a0,s2
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	5b6080e7          	jalr	1462(ra) # 8000370a <brelse>
      tot = -1;
    8000415c:	59fd                	li	s3,-1
  }
  return tot;
    8000415e:	0009851b          	sext.w	a0,s3
}
    80004162:	70a6                	ld	ra,104(sp)
    80004164:	7406                	ld	s0,96(sp)
    80004166:	64e6                	ld	s1,88(sp)
    80004168:	6946                	ld	s2,80(sp)
    8000416a:	69a6                	ld	s3,72(sp)
    8000416c:	6a06                	ld	s4,64(sp)
    8000416e:	7ae2                	ld	s5,56(sp)
    80004170:	7b42                	ld	s6,48(sp)
    80004172:	7ba2                	ld	s7,40(sp)
    80004174:	7c02                	ld	s8,32(sp)
    80004176:	6ce2                	ld	s9,24(sp)
    80004178:	6d42                	ld	s10,16(sp)
    8000417a:	6da2                	ld	s11,8(sp)
    8000417c:	6165                	addi	sp,sp,112
    8000417e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004180:	89da                	mv	s3,s6
    80004182:	bff1                	j	8000415e <readi+0xce>
    return 0;
    80004184:	4501                	li	a0,0
}
    80004186:	8082                	ret

0000000080004188 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004188:	457c                	lw	a5,76(a0)
    8000418a:	10d7e863          	bltu	a5,a3,8000429a <writei+0x112>
{
    8000418e:	7159                	addi	sp,sp,-112
    80004190:	f486                	sd	ra,104(sp)
    80004192:	f0a2                	sd	s0,96(sp)
    80004194:	eca6                	sd	s1,88(sp)
    80004196:	e8ca                	sd	s2,80(sp)
    80004198:	e4ce                	sd	s3,72(sp)
    8000419a:	e0d2                	sd	s4,64(sp)
    8000419c:	fc56                	sd	s5,56(sp)
    8000419e:	f85a                	sd	s6,48(sp)
    800041a0:	f45e                	sd	s7,40(sp)
    800041a2:	f062                	sd	s8,32(sp)
    800041a4:	ec66                	sd	s9,24(sp)
    800041a6:	e86a                	sd	s10,16(sp)
    800041a8:	e46e                	sd	s11,8(sp)
    800041aa:	1880                	addi	s0,sp,112
    800041ac:	8b2a                	mv	s6,a0
    800041ae:	8c2e                	mv	s8,a1
    800041b0:	8ab2                	mv	s5,a2
    800041b2:	8936                	mv	s2,a3
    800041b4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041b6:	00e687bb          	addw	a5,a3,a4
    800041ba:	0ed7e263          	bltu	a5,a3,8000429e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041be:	00043737          	lui	a4,0x43
    800041c2:	0ef76063          	bltu	a4,a5,800042a2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041c6:	0c0b8863          	beqz	s7,80004296 <writei+0x10e>
    800041ca:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041cc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041d0:	5cfd                	li	s9,-1
    800041d2:	a091                	j	80004216 <writei+0x8e>
    800041d4:	02099d93          	slli	s11,s3,0x20
    800041d8:	020ddd93          	srli	s11,s11,0x20
    800041dc:	05848513          	addi	a0,s1,88
    800041e0:	86ee                	mv	a3,s11
    800041e2:	8656                	mv	a2,s5
    800041e4:	85e2                	mv	a1,s8
    800041e6:	953a                	add	a0,a0,a4
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	724080e7          	jalr	1828(ra) # 8000290c <either_copyin>
    800041f0:	07950263          	beq	a0,s9,80004254 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041f4:	8526                	mv	a0,s1
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	790080e7          	jalr	1936(ra) # 80004986 <log_write>
    brelse(bp);
    800041fe:	8526                	mv	a0,s1
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	50a080e7          	jalr	1290(ra) # 8000370a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004208:	01498a3b          	addw	s4,s3,s4
    8000420c:	0129893b          	addw	s2,s3,s2
    80004210:	9aee                	add	s5,s5,s11
    80004212:	057a7663          	bgeu	s4,s7,8000425e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004216:	000b2483          	lw	s1,0(s6)
    8000421a:	00a9559b          	srliw	a1,s2,0xa
    8000421e:	855a                	mv	a0,s6
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	7ae080e7          	jalr	1966(ra) # 800039ce <bmap>
    80004228:	0005059b          	sext.w	a1,a0
    8000422c:	8526                	mv	a0,s1
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	3ac080e7          	jalr	940(ra) # 800035da <bread>
    80004236:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004238:	3ff97713          	andi	a4,s2,1023
    8000423c:	40ed07bb          	subw	a5,s10,a4
    80004240:	414b86bb          	subw	a3,s7,s4
    80004244:	89be                	mv	s3,a5
    80004246:	2781                	sext.w	a5,a5
    80004248:	0006861b          	sext.w	a2,a3
    8000424c:	f8f674e3          	bgeu	a2,a5,800041d4 <writei+0x4c>
    80004250:	89b6                	mv	s3,a3
    80004252:	b749                	j	800041d4 <writei+0x4c>
      brelse(bp);
    80004254:	8526                	mv	a0,s1
    80004256:	fffff097          	auipc	ra,0xfffff
    8000425a:	4b4080e7          	jalr	1204(ra) # 8000370a <brelse>
  }

  if(off > ip->size)
    8000425e:	04cb2783          	lw	a5,76(s6)
    80004262:	0127f463          	bgeu	a5,s2,8000426a <writei+0xe2>
    ip->size = off;
    80004266:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000426a:	855a                	mv	a0,s6
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	aa6080e7          	jalr	-1370(ra) # 80003d12 <iupdate>

  return tot;
    80004274:	000a051b          	sext.w	a0,s4
}
    80004278:	70a6                	ld	ra,104(sp)
    8000427a:	7406                	ld	s0,96(sp)
    8000427c:	64e6                	ld	s1,88(sp)
    8000427e:	6946                	ld	s2,80(sp)
    80004280:	69a6                	ld	s3,72(sp)
    80004282:	6a06                	ld	s4,64(sp)
    80004284:	7ae2                	ld	s5,56(sp)
    80004286:	7b42                	ld	s6,48(sp)
    80004288:	7ba2                	ld	s7,40(sp)
    8000428a:	7c02                	ld	s8,32(sp)
    8000428c:	6ce2                	ld	s9,24(sp)
    8000428e:	6d42                	ld	s10,16(sp)
    80004290:	6da2                	ld	s11,8(sp)
    80004292:	6165                	addi	sp,sp,112
    80004294:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004296:	8a5e                	mv	s4,s7
    80004298:	bfc9                	j	8000426a <writei+0xe2>
    return -1;
    8000429a:	557d                	li	a0,-1
}
    8000429c:	8082                	ret
    return -1;
    8000429e:	557d                	li	a0,-1
    800042a0:	bfe1                	j	80004278 <writei+0xf0>
    return -1;
    800042a2:	557d                	li	a0,-1
    800042a4:	bfd1                	j	80004278 <writei+0xf0>

00000000800042a6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042a6:	1141                	addi	sp,sp,-16
    800042a8:	e406                	sd	ra,8(sp)
    800042aa:	e022                	sd	s0,0(sp)
    800042ac:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042ae:	4639                	li	a2,14
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	b08080e7          	jalr	-1272(ra) # 80000db8 <strncmp>
}
    800042b8:	60a2                	ld	ra,8(sp)
    800042ba:	6402                	ld	s0,0(sp)
    800042bc:	0141                	addi	sp,sp,16
    800042be:	8082                	ret

00000000800042c0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042c0:	7139                	addi	sp,sp,-64
    800042c2:	fc06                	sd	ra,56(sp)
    800042c4:	f822                	sd	s0,48(sp)
    800042c6:	f426                	sd	s1,40(sp)
    800042c8:	f04a                	sd	s2,32(sp)
    800042ca:	ec4e                	sd	s3,24(sp)
    800042cc:	e852                	sd	s4,16(sp)
    800042ce:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042d0:	04451703          	lh	a4,68(a0)
    800042d4:	4785                	li	a5,1
    800042d6:	00f71a63          	bne	a4,a5,800042ea <dirlookup+0x2a>
    800042da:	892a                	mv	s2,a0
    800042dc:	89ae                	mv	s3,a1
    800042de:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e0:	457c                	lw	a5,76(a0)
    800042e2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042e4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e6:	e79d                	bnez	a5,80004314 <dirlookup+0x54>
    800042e8:	a8a5                	j	80004360 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042ea:	00004517          	auipc	a0,0x4
    800042ee:	45e50513          	addi	a0,a0,1118 # 80008748 <syscalls+0x1b8>
    800042f2:	ffffc097          	auipc	ra,0xffffc
    800042f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
      panic("dirlookup read");
    800042fa:	00004517          	auipc	a0,0x4
    800042fe:	46650513          	addi	a0,a0,1126 # 80008760 <syscalls+0x1d0>
    80004302:	ffffc097          	auipc	ra,0xffffc
    80004306:	23c080e7          	jalr	572(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430a:	24c1                	addiw	s1,s1,16
    8000430c:	04c92783          	lw	a5,76(s2)
    80004310:	04f4f763          	bgeu	s1,a5,8000435e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004314:	4741                	li	a4,16
    80004316:	86a6                	mv	a3,s1
    80004318:	fc040613          	addi	a2,s0,-64
    8000431c:	4581                	li	a1,0
    8000431e:	854a                	mv	a0,s2
    80004320:	00000097          	auipc	ra,0x0
    80004324:	d70080e7          	jalr	-656(ra) # 80004090 <readi>
    80004328:	47c1                	li	a5,16
    8000432a:	fcf518e3          	bne	a0,a5,800042fa <dirlookup+0x3a>
    if(de.inum == 0)
    8000432e:	fc045783          	lhu	a5,-64(s0)
    80004332:	dfe1                	beqz	a5,8000430a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004334:	fc240593          	addi	a1,s0,-62
    80004338:	854e                	mv	a0,s3
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	f6c080e7          	jalr	-148(ra) # 800042a6 <namecmp>
    80004342:	f561                	bnez	a0,8000430a <dirlookup+0x4a>
      if(poff)
    80004344:	000a0463          	beqz	s4,8000434c <dirlookup+0x8c>
        *poff = off;
    80004348:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000434c:	fc045583          	lhu	a1,-64(s0)
    80004350:	00092503          	lw	a0,0(s2)
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	754080e7          	jalr	1876(ra) # 80003aa8 <iget>
    8000435c:	a011                	j	80004360 <dirlookup+0xa0>
  return 0;
    8000435e:	4501                	li	a0,0
}
    80004360:	70e2                	ld	ra,56(sp)
    80004362:	7442                	ld	s0,48(sp)
    80004364:	74a2                	ld	s1,40(sp)
    80004366:	7902                	ld	s2,32(sp)
    80004368:	69e2                	ld	s3,24(sp)
    8000436a:	6a42                	ld	s4,16(sp)
    8000436c:	6121                	addi	sp,sp,64
    8000436e:	8082                	ret

0000000080004370 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004370:	711d                	addi	sp,sp,-96
    80004372:	ec86                	sd	ra,88(sp)
    80004374:	e8a2                	sd	s0,80(sp)
    80004376:	e4a6                	sd	s1,72(sp)
    80004378:	e0ca                	sd	s2,64(sp)
    8000437a:	fc4e                	sd	s3,56(sp)
    8000437c:	f852                	sd	s4,48(sp)
    8000437e:	f456                	sd	s5,40(sp)
    80004380:	f05a                	sd	s6,32(sp)
    80004382:	ec5e                	sd	s7,24(sp)
    80004384:	e862                	sd	s8,16(sp)
    80004386:	e466                	sd	s9,8(sp)
    80004388:	1080                	addi	s0,sp,96
    8000438a:	84aa                	mv	s1,a0
    8000438c:	8b2e                	mv	s6,a1
    8000438e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004390:	00054703          	lbu	a4,0(a0)
    80004394:	02f00793          	li	a5,47
    80004398:	02f70363          	beq	a4,a5,800043be <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	6f6080e7          	jalr	1782(ra) # 80001a92 <myproc>
    800043a4:	15053503          	ld	a0,336(a0)
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	9f6080e7          	jalr	-1546(ra) # 80003d9e <idup>
    800043b0:	89aa                	mv	s3,a0
  while(*path == '/')
    800043b2:	02f00913          	li	s2,47
  len = path - s;
    800043b6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043b8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043ba:	4c05                	li	s8,1
    800043bc:	a865                	j	80004474 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043be:	4585                	li	a1,1
    800043c0:	4505                	li	a0,1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	6e6080e7          	jalr	1766(ra) # 80003aa8 <iget>
    800043ca:	89aa                	mv	s3,a0
    800043cc:	b7dd                	j	800043b2 <namex+0x42>
      iunlockput(ip);
    800043ce:	854e                	mv	a0,s3
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	c6e080e7          	jalr	-914(ra) # 8000403e <iunlockput>
      return 0;
    800043d8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043da:	854e                	mv	a0,s3
    800043dc:	60e6                	ld	ra,88(sp)
    800043de:	6446                	ld	s0,80(sp)
    800043e0:	64a6                	ld	s1,72(sp)
    800043e2:	6906                	ld	s2,64(sp)
    800043e4:	79e2                	ld	s3,56(sp)
    800043e6:	7a42                	ld	s4,48(sp)
    800043e8:	7aa2                	ld	s5,40(sp)
    800043ea:	7b02                	ld	s6,32(sp)
    800043ec:	6be2                	ld	s7,24(sp)
    800043ee:	6c42                	ld	s8,16(sp)
    800043f0:	6ca2                	ld	s9,8(sp)
    800043f2:	6125                	addi	sp,sp,96
    800043f4:	8082                	ret
      iunlock(ip);
    800043f6:	854e                	mv	a0,s3
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	aa6080e7          	jalr	-1370(ra) # 80003e9e <iunlock>
      return ip;
    80004400:	bfe9                	j	800043da <namex+0x6a>
      iunlockput(ip);
    80004402:	854e                	mv	a0,s3
    80004404:	00000097          	auipc	ra,0x0
    80004408:	c3a080e7          	jalr	-966(ra) # 8000403e <iunlockput>
      return 0;
    8000440c:	89d2                	mv	s3,s4
    8000440e:	b7f1                	j	800043da <namex+0x6a>
  len = path - s;
    80004410:	40b48633          	sub	a2,s1,a1
    80004414:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004418:	094cd463          	bge	s9,s4,800044a0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000441c:	4639                	li	a2,14
    8000441e:	8556                	mv	a0,s5
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	920080e7          	jalr	-1760(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004428:	0004c783          	lbu	a5,0(s1)
    8000442c:	01279763          	bne	a5,s2,8000443a <namex+0xca>
    path++;
    80004430:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004432:	0004c783          	lbu	a5,0(s1)
    80004436:	ff278de3          	beq	a5,s2,80004430 <namex+0xc0>
    ilock(ip);
    8000443a:	854e                	mv	a0,s3
    8000443c:	00000097          	auipc	ra,0x0
    80004440:	9a0080e7          	jalr	-1632(ra) # 80003ddc <ilock>
    if(ip->type != T_DIR){
    80004444:	04499783          	lh	a5,68(s3)
    80004448:	f98793e3          	bne	a5,s8,800043ce <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000444c:	000b0563          	beqz	s6,80004456 <namex+0xe6>
    80004450:	0004c783          	lbu	a5,0(s1)
    80004454:	d3cd                	beqz	a5,800043f6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004456:	865e                	mv	a2,s7
    80004458:	85d6                	mv	a1,s5
    8000445a:	854e                	mv	a0,s3
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	e64080e7          	jalr	-412(ra) # 800042c0 <dirlookup>
    80004464:	8a2a                	mv	s4,a0
    80004466:	dd51                	beqz	a0,80004402 <namex+0x92>
    iunlockput(ip);
    80004468:	854e                	mv	a0,s3
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	bd4080e7          	jalr	-1068(ra) # 8000403e <iunlockput>
    ip = next;
    80004472:	89d2                	mv	s3,s4
  while(*path == '/')
    80004474:	0004c783          	lbu	a5,0(s1)
    80004478:	05279763          	bne	a5,s2,800044c6 <namex+0x156>
    path++;
    8000447c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000447e:	0004c783          	lbu	a5,0(s1)
    80004482:	ff278de3          	beq	a5,s2,8000447c <namex+0x10c>
  if(*path == 0)
    80004486:	c79d                	beqz	a5,800044b4 <namex+0x144>
    path++;
    80004488:	85a6                	mv	a1,s1
  len = path - s;
    8000448a:	8a5e                	mv	s4,s7
    8000448c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000448e:	01278963          	beq	a5,s2,800044a0 <namex+0x130>
    80004492:	dfbd                	beqz	a5,80004410 <namex+0xa0>
    path++;
    80004494:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004496:	0004c783          	lbu	a5,0(s1)
    8000449a:	ff279ce3          	bne	a5,s2,80004492 <namex+0x122>
    8000449e:	bf8d                	j	80004410 <namex+0xa0>
    memmove(name, s, len);
    800044a0:	2601                	sext.w	a2,a2
    800044a2:	8556                	mv	a0,s5
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	89c080e7          	jalr	-1892(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044ac:	9a56                	add	s4,s4,s5
    800044ae:	000a0023          	sb	zero,0(s4)
    800044b2:	bf9d                	j	80004428 <namex+0xb8>
  if(nameiparent){
    800044b4:	f20b03e3          	beqz	s6,800043da <namex+0x6a>
    iput(ip);
    800044b8:	854e                	mv	a0,s3
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	adc080e7          	jalr	-1316(ra) # 80003f96 <iput>
    return 0;
    800044c2:	4981                	li	s3,0
    800044c4:	bf19                	j	800043da <namex+0x6a>
  if(*path == 0)
    800044c6:	d7fd                	beqz	a5,800044b4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044c8:	0004c783          	lbu	a5,0(s1)
    800044cc:	85a6                	mv	a1,s1
    800044ce:	b7d1                	j	80004492 <namex+0x122>

00000000800044d0 <dirlink>:
{
    800044d0:	7139                	addi	sp,sp,-64
    800044d2:	fc06                	sd	ra,56(sp)
    800044d4:	f822                	sd	s0,48(sp)
    800044d6:	f426                	sd	s1,40(sp)
    800044d8:	f04a                	sd	s2,32(sp)
    800044da:	ec4e                	sd	s3,24(sp)
    800044dc:	e852                	sd	s4,16(sp)
    800044de:	0080                	addi	s0,sp,64
    800044e0:	892a                	mv	s2,a0
    800044e2:	8a2e                	mv	s4,a1
    800044e4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044e6:	4601                	li	a2,0
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	dd8080e7          	jalr	-552(ra) # 800042c0 <dirlookup>
    800044f0:	e93d                	bnez	a0,80004566 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f2:	04c92483          	lw	s1,76(s2)
    800044f6:	c49d                	beqz	s1,80004524 <dirlink+0x54>
    800044f8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044fa:	4741                	li	a4,16
    800044fc:	86a6                	mv	a3,s1
    800044fe:	fc040613          	addi	a2,s0,-64
    80004502:	4581                	li	a1,0
    80004504:	854a                	mv	a0,s2
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	b8a080e7          	jalr	-1142(ra) # 80004090 <readi>
    8000450e:	47c1                	li	a5,16
    80004510:	06f51163          	bne	a0,a5,80004572 <dirlink+0xa2>
    if(de.inum == 0)
    80004514:	fc045783          	lhu	a5,-64(s0)
    80004518:	c791                	beqz	a5,80004524 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000451a:	24c1                	addiw	s1,s1,16
    8000451c:	04c92783          	lw	a5,76(s2)
    80004520:	fcf4ede3          	bltu	s1,a5,800044fa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004524:	4639                	li	a2,14
    80004526:	85d2                	mv	a1,s4
    80004528:	fc240513          	addi	a0,s0,-62
    8000452c:	ffffd097          	auipc	ra,0xffffd
    80004530:	8c8080e7          	jalr	-1848(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004534:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004538:	4741                	li	a4,16
    8000453a:	86a6                	mv	a3,s1
    8000453c:	fc040613          	addi	a2,s0,-64
    80004540:	4581                	li	a1,0
    80004542:	854a                	mv	a0,s2
    80004544:	00000097          	auipc	ra,0x0
    80004548:	c44080e7          	jalr	-956(ra) # 80004188 <writei>
    8000454c:	872a                	mv	a4,a0
    8000454e:	47c1                	li	a5,16
  return 0;
    80004550:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004552:	02f71863          	bne	a4,a5,80004582 <dirlink+0xb2>
}
    80004556:	70e2                	ld	ra,56(sp)
    80004558:	7442                	ld	s0,48(sp)
    8000455a:	74a2                	ld	s1,40(sp)
    8000455c:	7902                	ld	s2,32(sp)
    8000455e:	69e2                	ld	s3,24(sp)
    80004560:	6a42                	ld	s4,16(sp)
    80004562:	6121                	addi	sp,sp,64
    80004564:	8082                	ret
    iput(ip);
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	a30080e7          	jalr	-1488(ra) # 80003f96 <iput>
    return -1;
    8000456e:	557d                	li	a0,-1
    80004570:	b7dd                	j	80004556 <dirlink+0x86>
      panic("dirlink read");
    80004572:	00004517          	auipc	a0,0x4
    80004576:	1fe50513          	addi	a0,a0,510 # 80008770 <syscalls+0x1e0>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>
    panic("dirlink");
    80004582:	00004517          	auipc	a0,0x4
    80004586:	2f650513          	addi	a0,a0,758 # 80008878 <syscalls+0x2e8>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>

0000000080004592 <namei>:

struct inode*
namei(char *path)
{
    80004592:	1101                	addi	sp,sp,-32
    80004594:	ec06                	sd	ra,24(sp)
    80004596:	e822                	sd	s0,16(sp)
    80004598:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000459a:	fe040613          	addi	a2,s0,-32
    8000459e:	4581                	li	a1,0
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	dd0080e7          	jalr	-560(ra) # 80004370 <namex>
}
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	6105                	addi	sp,sp,32
    800045ae:	8082                	ret

00000000800045b0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045b0:	1141                	addi	sp,sp,-16
    800045b2:	e406                	sd	ra,8(sp)
    800045b4:	e022                	sd	s0,0(sp)
    800045b6:	0800                	addi	s0,sp,16
    800045b8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045ba:	4585                	li	a1,1
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	db4080e7          	jalr	-588(ra) # 80004370 <namex>
}
    800045c4:	60a2                	ld	ra,8(sp)
    800045c6:	6402                	ld	s0,0(sp)
    800045c8:	0141                	addi	sp,sp,16
    800045ca:	8082                	ret

00000000800045cc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	e04a                	sd	s2,0(sp)
    800045d6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045d8:	0001e917          	auipc	s2,0x1e
    800045dc:	6c090913          	addi	s2,s2,1728 # 80022c98 <log>
    800045e0:	01892583          	lw	a1,24(s2)
    800045e4:	02892503          	lw	a0,40(s2)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	ff2080e7          	jalr	-14(ra) # 800035da <bread>
    800045f0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045f2:	02c92683          	lw	a3,44(s2)
    800045f6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045f8:	02d05763          	blez	a3,80004626 <write_head+0x5a>
    800045fc:	0001e797          	auipc	a5,0x1e
    80004600:	6cc78793          	addi	a5,a5,1740 # 80022cc8 <log+0x30>
    80004604:	05c50713          	addi	a4,a0,92
    80004608:	36fd                	addiw	a3,a3,-1
    8000460a:	1682                	slli	a3,a3,0x20
    8000460c:	9281                	srli	a3,a3,0x20
    8000460e:	068a                	slli	a3,a3,0x2
    80004610:	0001e617          	auipc	a2,0x1e
    80004614:	6bc60613          	addi	a2,a2,1724 # 80022ccc <log+0x34>
    80004618:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000461a:	4390                	lw	a2,0(a5)
    8000461c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000461e:	0791                	addi	a5,a5,4
    80004620:	0711                	addi	a4,a4,4
    80004622:	fed79ce3          	bne	a5,a3,8000461a <write_head+0x4e>
  }
  bwrite(buf);
    80004626:	8526                	mv	a0,s1
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	0a4080e7          	jalr	164(ra) # 800036cc <bwrite>
  brelse(buf);
    80004630:	8526                	mv	a0,s1
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	0d8080e7          	jalr	216(ra) # 8000370a <brelse>
}
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6902                	ld	s2,0(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004646:	0001e797          	auipc	a5,0x1e
    8000464a:	67e7a783          	lw	a5,1662(a5) # 80022cc4 <log+0x2c>
    8000464e:	0af05d63          	blez	a5,80004708 <install_trans+0xc2>
{
    80004652:	7139                	addi	sp,sp,-64
    80004654:	fc06                	sd	ra,56(sp)
    80004656:	f822                	sd	s0,48(sp)
    80004658:	f426                	sd	s1,40(sp)
    8000465a:	f04a                	sd	s2,32(sp)
    8000465c:	ec4e                	sd	s3,24(sp)
    8000465e:	e852                	sd	s4,16(sp)
    80004660:	e456                	sd	s5,8(sp)
    80004662:	e05a                	sd	s6,0(sp)
    80004664:	0080                	addi	s0,sp,64
    80004666:	8b2a                	mv	s6,a0
    80004668:	0001ea97          	auipc	s5,0x1e
    8000466c:	660a8a93          	addi	s5,s5,1632 # 80022cc8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004670:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004672:	0001e997          	auipc	s3,0x1e
    80004676:	62698993          	addi	s3,s3,1574 # 80022c98 <log>
    8000467a:	a035                	j	800046a6 <install_trans+0x60>
      bunpin(dbuf);
    8000467c:	8526                	mv	a0,s1
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	166080e7          	jalr	358(ra) # 800037e4 <bunpin>
    brelse(lbuf);
    80004686:	854a                	mv	a0,s2
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	082080e7          	jalr	130(ra) # 8000370a <brelse>
    brelse(dbuf);
    80004690:	8526                	mv	a0,s1
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	078080e7          	jalr	120(ra) # 8000370a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469a:	2a05                	addiw	s4,s4,1
    8000469c:	0a91                	addi	s5,s5,4
    8000469e:	02c9a783          	lw	a5,44(s3)
    800046a2:	04fa5963          	bge	s4,a5,800046f4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046a6:	0189a583          	lw	a1,24(s3)
    800046aa:	014585bb          	addw	a1,a1,s4
    800046ae:	2585                	addiw	a1,a1,1
    800046b0:	0289a503          	lw	a0,40(s3)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	f26080e7          	jalr	-218(ra) # 800035da <bread>
    800046bc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046be:	000aa583          	lw	a1,0(s5)
    800046c2:	0289a503          	lw	a0,40(s3)
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	f14080e7          	jalr	-236(ra) # 800035da <bread>
    800046ce:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046d0:	40000613          	li	a2,1024
    800046d4:	05890593          	addi	a1,s2,88
    800046d8:	05850513          	addi	a0,a0,88
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	664080e7          	jalr	1636(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046e4:	8526                	mv	a0,s1
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	fe6080e7          	jalr	-26(ra) # 800036cc <bwrite>
    if(recovering == 0)
    800046ee:	f80b1ce3          	bnez	s6,80004686 <install_trans+0x40>
    800046f2:	b769                	j	8000467c <install_trans+0x36>
}
    800046f4:	70e2                	ld	ra,56(sp)
    800046f6:	7442                	ld	s0,48(sp)
    800046f8:	74a2                	ld	s1,40(sp)
    800046fa:	7902                	ld	s2,32(sp)
    800046fc:	69e2                	ld	s3,24(sp)
    800046fe:	6a42                	ld	s4,16(sp)
    80004700:	6aa2                	ld	s5,8(sp)
    80004702:	6b02                	ld	s6,0(sp)
    80004704:	6121                	addi	sp,sp,64
    80004706:	8082                	ret
    80004708:	8082                	ret

000000008000470a <initlog>:
{
    8000470a:	7179                	addi	sp,sp,-48
    8000470c:	f406                	sd	ra,40(sp)
    8000470e:	f022                	sd	s0,32(sp)
    80004710:	ec26                	sd	s1,24(sp)
    80004712:	e84a                	sd	s2,16(sp)
    80004714:	e44e                	sd	s3,8(sp)
    80004716:	1800                	addi	s0,sp,48
    80004718:	892a                	mv	s2,a0
    8000471a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000471c:	0001e497          	auipc	s1,0x1e
    80004720:	57c48493          	addi	s1,s1,1404 # 80022c98 <log>
    80004724:	00004597          	auipc	a1,0x4
    80004728:	05c58593          	addi	a1,a1,92 # 80008780 <syscalls+0x1f0>
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	426080e7          	jalr	1062(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004736:	0149a583          	lw	a1,20(s3)
    8000473a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000473c:	0109a783          	lw	a5,16(s3)
    80004740:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004742:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004746:	854a                	mv	a0,s2
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	e92080e7          	jalr	-366(ra) # 800035da <bread>
  log.lh.n = lh->n;
    80004750:	4d3c                	lw	a5,88(a0)
    80004752:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004754:	02f05563          	blez	a5,8000477e <initlog+0x74>
    80004758:	05c50713          	addi	a4,a0,92
    8000475c:	0001e697          	auipc	a3,0x1e
    80004760:	56c68693          	addi	a3,a3,1388 # 80022cc8 <log+0x30>
    80004764:	37fd                	addiw	a5,a5,-1
    80004766:	1782                	slli	a5,a5,0x20
    80004768:	9381                	srli	a5,a5,0x20
    8000476a:	078a                	slli	a5,a5,0x2
    8000476c:	06050613          	addi	a2,a0,96
    80004770:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004772:	4310                	lw	a2,0(a4)
    80004774:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004776:	0711                	addi	a4,a4,4
    80004778:	0691                	addi	a3,a3,4
    8000477a:	fef71ce3          	bne	a4,a5,80004772 <initlog+0x68>
  brelse(buf);
    8000477e:	fffff097          	auipc	ra,0xfffff
    80004782:	f8c080e7          	jalr	-116(ra) # 8000370a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004786:	4505                	li	a0,1
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	ebe080e7          	jalr	-322(ra) # 80004646 <install_trans>
  log.lh.n = 0;
    80004790:	0001e797          	auipc	a5,0x1e
    80004794:	5207aa23          	sw	zero,1332(a5) # 80022cc4 <log+0x2c>
  write_head(); // clear the log
    80004798:	00000097          	auipc	ra,0x0
    8000479c:	e34080e7          	jalr	-460(ra) # 800045cc <write_head>
}
    800047a0:	70a2                	ld	ra,40(sp)
    800047a2:	7402                	ld	s0,32(sp)
    800047a4:	64e2                	ld	s1,24(sp)
    800047a6:	6942                	ld	s2,16(sp)
    800047a8:	69a2                	ld	s3,8(sp)
    800047aa:	6145                	addi	sp,sp,48
    800047ac:	8082                	ret

00000000800047ae <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047ae:	1101                	addi	sp,sp,-32
    800047b0:	ec06                	sd	ra,24(sp)
    800047b2:	e822                	sd	s0,16(sp)
    800047b4:	e426                	sd	s1,8(sp)
    800047b6:	e04a                	sd	s2,0(sp)
    800047b8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ba:	0001e517          	auipc	a0,0x1e
    800047be:	4de50513          	addi	a0,a0,1246 # 80022c98 <log>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	422080e7          	jalr	1058(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047ca:	0001e497          	auipc	s1,0x1e
    800047ce:	4ce48493          	addi	s1,s1,1230 # 80022c98 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047d2:	4979                	li	s2,30
    800047d4:	a039                	j	800047e2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047d6:	85a6                	mv	a1,s1
    800047d8:	8526                	mv	a0,s1
    800047da:	ffffe097          	auipc	ra,0xffffe
    800047de:	b8e080e7          	jalr	-1138(ra) # 80002368 <sleep>
    if(log.committing){
    800047e2:	50dc                	lw	a5,36(s1)
    800047e4:	fbed                	bnez	a5,800047d6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047e6:	509c                	lw	a5,32(s1)
    800047e8:	0017871b          	addiw	a4,a5,1
    800047ec:	0007069b          	sext.w	a3,a4
    800047f0:	0027179b          	slliw	a5,a4,0x2
    800047f4:	9fb9                	addw	a5,a5,a4
    800047f6:	0017979b          	slliw	a5,a5,0x1
    800047fa:	54d8                	lw	a4,44(s1)
    800047fc:	9fb9                	addw	a5,a5,a4
    800047fe:	00f95963          	bge	s2,a5,80004810 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004802:	85a6                	mv	a1,s1
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	b62080e7          	jalr	-1182(ra) # 80002368 <sleep>
    8000480e:	bfd1                	j	800047e2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004810:	0001e517          	auipc	a0,0x1e
    80004814:	48850513          	addi	a0,a0,1160 # 80022c98 <log>
    80004818:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	47e080e7          	jalr	1150(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004822:	60e2                	ld	ra,24(sp)
    80004824:	6442                	ld	s0,16(sp)
    80004826:	64a2                	ld	s1,8(sp)
    80004828:	6902                	ld	s2,0(sp)
    8000482a:	6105                	addi	sp,sp,32
    8000482c:	8082                	ret

000000008000482e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000482e:	7139                	addi	sp,sp,-64
    80004830:	fc06                	sd	ra,56(sp)
    80004832:	f822                	sd	s0,48(sp)
    80004834:	f426                	sd	s1,40(sp)
    80004836:	f04a                	sd	s2,32(sp)
    80004838:	ec4e                	sd	s3,24(sp)
    8000483a:	e852                	sd	s4,16(sp)
    8000483c:	e456                	sd	s5,8(sp)
    8000483e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004840:	0001e497          	auipc	s1,0x1e
    80004844:	45848493          	addi	s1,s1,1112 # 80022c98 <log>
    80004848:	8526                	mv	a0,s1
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	39a080e7          	jalr	922(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004852:	509c                	lw	a5,32(s1)
    80004854:	37fd                	addiw	a5,a5,-1
    80004856:	0007891b          	sext.w	s2,a5
    8000485a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000485c:	50dc                	lw	a5,36(s1)
    8000485e:	efb9                	bnez	a5,800048bc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004860:	06091663          	bnez	s2,800048cc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004864:	0001e497          	auipc	s1,0x1e
    80004868:	43448493          	addi	s1,s1,1076 # 80022c98 <log>
    8000486c:	4785                	li	a5,1
    8000486e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004870:	8526                	mv	a0,s1
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000487a:	54dc                	lw	a5,44(s1)
    8000487c:	06f04763          	bgtz	a5,800048ea <end_op+0xbc>
    acquire(&log.lock);
    80004880:	0001e497          	auipc	s1,0x1e
    80004884:	41848493          	addi	s1,s1,1048 # 80022c98 <log>
    80004888:	8526                	mv	a0,s1
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	35a080e7          	jalr	858(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004892:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004896:	8526                	mv	a0,s1
    80004898:	ffffe097          	auipc	ra,0xffffe
    8000489c:	dc0080e7          	jalr	-576(ra) # 80002658 <wakeup>
    release(&log.lock);
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	3f6080e7          	jalr	1014(ra) # 80000c98 <release>
}
    800048aa:	70e2                	ld	ra,56(sp)
    800048ac:	7442                	ld	s0,48(sp)
    800048ae:	74a2                	ld	s1,40(sp)
    800048b0:	7902                	ld	s2,32(sp)
    800048b2:	69e2                	ld	s3,24(sp)
    800048b4:	6a42                	ld	s4,16(sp)
    800048b6:	6aa2                	ld	s5,8(sp)
    800048b8:	6121                	addi	sp,sp,64
    800048ba:	8082                	ret
    panic("log.committing");
    800048bc:	00004517          	auipc	a0,0x4
    800048c0:	ecc50513          	addi	a0,a0,-308 # 80008788 <syscalls+0x1f8>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>
    wakeup(&log);
    800048cc:	0001e497          	auipc	s1,0x1e
    800048d0:	3cc48493          	addi	s1,s1,972 # 80022c98 <log>
    800048d4:	8526                	mv	a0,s1
    800048d6:	ffffe097          	auipc	ra,0xffffe
    800048da:	d82080e7          	jalr	-638(ra) # 80002658 <wakeup>
  release(&log.lock);
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	3b8080e7          	jalr	952(ra) # 80000c98 <release>
  if(do_commit){
    800048e8:	b7c9                	j	800048aa <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048ea:	0001ea97          	auipc	s5,0x1e
    800048ee:	3dea8a93          	addi	s5,s5,990 # 80022cc8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048f2:	0001ea17          	auipc	s4,0x1e
    800048f6:	3a6a0a13          	addi	s4,s4,934 # 80022c98 <log>
    800048fa:	018a2583          	lw	a1,24(s4)
    800048fe:	012585bb          	addw	a1,a1,s2
    80004902:	2585                	addiw	a1,a1,1
    80004904:	028a2503          	lw	a0,40(s4)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	cd2080e7          	jalr	-814(ra) # 800035da <bread>
    80004910:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004912:	000aa583          	lw	a1,0(s5)
    80004916:	028a2503          	lw	a0,40(s4)
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	cc0080e7          	jalr	-832(ra) # 800035da <bread>
    80004922:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004924:	40000613          	li	a2,1024
    80004928:	05850593          	addi	a1,a0,88
    8000492c:	05848513          	addi	a0,s1,88
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	410080e7          	jalr	1040(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004938:	8526                	mv	a0,s1
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	d92080e7          	jalr	-622(ra) # 800036cc <bwrite>
    brelse(from);
    80004942:	854e                	mv	a0,s3
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	dc6080e7          	jalr	-570(ra) # 8000370a <brelse>
    brelse(to);
    8000494c:	8526                	mv	a0,s1
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	dbc080e7          	jalr	-580(ra) # 8000370a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004956:	2905                	addiw	s2,s2,1
    80004958:	0a91                	addi	s5,s5,4
    8000495a:	02ca2783          	lw	a5,44(s4)
    8000495e:	f8f94ee3          	blt	s2,a5,800048fa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004962:	00000097          	auipc	ra,0x0
    80004966:	c6a080e7          	jalr	-918(ra) # 800045cc <write_head>
    install_trans(0); // Now install writes to home locations
    8000496a:	4501                	li	a0,0
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	cda080e7          	jalr	-806(ra) # 80004646 <install_trans>
    log.lh.n = 0;
    80004974:	0001e797          	auipc	a5,0x1e
    80004978:	3407a823          	sw	zero,848(a5) # 80022cc4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	c50080e7          	jalr	-944(ra) # 800045cc <write_head>
    80004984:	bdf5                	j	80004880 <end_op+0x52>

0000000080004986 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004986:	1101                	addi	sp,sp,-32
    80004988:	ec06                	sd	ra,24(sp)
    8000498a:	e822                	sd	s0,16(sp)
    8000498c:	e426                	sd	s1,8(sp)
    8000498e:	e04a                	sd	s2,0(sp)
    80004990:	1000                	addi	s0,sp,32
    80004992:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004994:	0001e917          	auipc	s2,0x1e
    80004998:	30490913          	addi	s2,s2,772 # 80022c98 <log>
    8000499c:	854a                	mv	a0,s2
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	246080e7          	jalr	582(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049a6:	02c92603          	lw	a2,44(s2)
    800049aa:	47f5                	li	a5,29
    800049ac:	06c7c563          	blt	a5,a2,80004a16 <log_write+0x90>
    800049b0:	0001e797          	auipc	a5,0x1e
    800049b4:	3047a783          	lw	a5,772(a5) # 80022cb4 <log+0x1c>
    800049b8:	37fd                	addiw	a5,a5,-1
    800049ba:	04f65e63          	bge	a2,a5,80004a16 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049be:	0001e797          	auipc	a5,0x1e
    800049c2:	2fa7a783          	lw	a5,762(a5) # 80022cb8 <log+0x20>
    800049c6:	06f05063          	blez	a5,80004a26 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049ca:	4781                	li	a5,0
    800049cc:	06c05563          	blez	a2,80004a36 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049d0:	44cc                	lw	a1,12(s1)
    800049d2:	0001e717          	auipc	a4,0x1e
    800049d6:	2f670713          	addi	a4,a4,758 # 80022cc8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049da:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049dc:	4314                	lw	a3,0(a4)
    800049de:	04b68c63          	beq	a3,a1,80004a36 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049e2:	2785                	addiw	a5,a5,1
    800049e4:	0711                	addi	a4,a4,4
    800049e6:	fef61be3          	bne	a2,a5,800049dc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049ea:	0621                	addi	a2,a2,8
    800049ec:	060a                	slli	a2,a2,0x2
    800049ee:	0001e797          	auipc	a5,0x1e
    800049f2:	2aa78793          	addi	a5,a5,682 # 80022c98 <log>
    800049f6:	963e                	add	a2,a2,a5
    800049f8:	44dc                	lw	a5,12(s1)
    800049fa:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049fc:	8526                	mv	a0,s1
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	daa080e7          	jalr	-598(ra) # 800037a8 <bpin>
    log.lh.n++;
    80004a06:	0001e717          	auipc	a4,0x1e
    80004a0a:	29270713          	addi	a4,a4,658 # 80022c98 <log>
    80004a0e:	575c                	lw	a5,44(a4)
    80004a10:	2785                	addiw	a5,a5,1
    80004a12:	d75c                	sw	a5,44(a4)
    80004a14:	a835                	j	80004a50 <log_write+0xca>
    panic("too big a transaction");
    80004a16:	00004517          	auipc	a0,0x4
    80004a1a:	d8250513          	addi	a0,a0,-638 # 80008798 <syscalls+0x208>
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	b20080e7          	jalr	-1248(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a26:	00004517          	auipc	a0,0x4
    80004a2a:	d8a50513          	addi	a0,a0,-630 # 800087b0 <syscalls+0x220>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	b10080e7          	jalr	-1264(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a36:	00878713          	addi	a4,a5,8
    80004a3a:	00271693          	slli	a3,a4,0x2
    80004a3e:	0001e717          	auipc	a4,0x1e
    80004a42:	25a70713          	addi	a4,a4,602 # 80022c98 <log>
    80004a46:	9736                	add	a4,a4,a3
    80004a48:	44d4                	lw	a3,12(s1)
    80004a4a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a4c:	faf608e3          	beq	a2,a5,800049fc <log_write+0x76>
  }
  release(&log.lock);
    80004a50:	0001e517          	auipc	a0,0x1e
    80004a54:	24850513          	addi	a0,a0,584 # 80022c98 <log>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	240080e7          	jalr	576(ra) # 80000c98 <release>
}
    80004a60:	60e2                	ld	ra,24(sp)
    80004a62:	6442                	ld	s0,16(sp)
    80004a64:	64a2                	ld	s1,8(sp)
    80004a66:	6902                	ld	s2,0(sp)
    80004a68:	6105                	addi	sp,sp,32
    80004a6a:	8082                	ret

0000000080004a6c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a6c:	1101                	addi	sp,sp,-32
    80004a6e:	ec06                	sd	ra,24(sp)
    80004a70:	e822                	sd	s0,16(sp)
    80004a72:	e426                	sd	s1,8(sp)
    80004a74:	e04a                	sd	s2,0(sp)
    80004a76:	1000                	addi	s0,sp,32
    80004a78:	84aa                	mv	s1,a0
    80004a7a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a7c:	00004597          	auipc	a1,0x4
    80004a80:	d5458593          	addi	a1,a1,-684 # 800087d0 <syscalls+0x240>
    80004a84:	0521                	addi	a0,a0,8
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	0ce080e7          	jalr	206(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a8e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a92:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a96:	0204a423          	sw	zero,40(s1)
}
    80004a9a:	60e2                	ld	ra,24(sp)
    80004a9c:	6442                	ld	s0,16(sp)
    80004a9e:	64a2                	ld	s1,8(sp)
    80004aa0:	6902                	ld	s2,0(sp)
    80004aa2:	6105                	addi	sp,sp,32
    80004aa4:	8082                	ret

0000000080004aa6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004aa6:	1101                	addi	sp,sp,-32
    80004aa8:	ec06                	sd	ra,24(sp)
    80004aaa:	e822                	sd	s0,16(sp)
    80004aac:	e426                	sd	s1,8(sp)
    80004aae:	e04a                	sd	s2,0(sp)
    80004ab0:	1000                	addi	s0,sp,32
    80004ab2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ab4:	00850913          	addi	s2,a0,8
    80004ab8:	854a                	mv	a0,s2
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	12a080e7          	jalr	298(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004ac2:	409c                	lw	a5,0(s1)
    80004ac4:	cb89                	beqz	a5,80004ad6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ac6:	85ca                	mv	a1,s2
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffe097          	auipc	ra,0xffffe
    80004ace:	89e080e7          	jalr	-1890(ra) # 80002368 <sleep>
  while (lk->locked) {
    80004ad2:	409c                	lw	a5,0(s1)
    80004ad4:	fbed                	bnez	a5,80004ac6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ad6:	4785                	li	a5,1
    80004ad8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	fb8080e7          	jalr	-72(ra) # 80001a92 <myproc>
    80004ae2:	591c                	lw	a5,48(a0)
    80004ae4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ae6:	854a                	mv	a0,s2
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>
}
    80004af0:	60e2                	ld	ra,24(sp)
    80004af2:	6442                	ld	s0,16(sp)
    80004af4:	64a2                	ld	s1,8(sp)
    80004af6:	6902                	ld	s2,0(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret

0000000080004afc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004afc:	1101                	addi	sp,sp,-32
    80004afe:	ec06                	sd	ra,24(sp)
    80004b00:	e822                	sd	s0,16(sp)
    80004b02:	e426                	sd	s1,8(sp)
    80004b04:	e04a                	sd	s2,0(sp)
    80004b06:	1000                	addi	s0,sp,32
    80004b08:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b0a:	00850913          	addi	s2,a0,8
    80004b0e:	854a                	mv	a0,s2
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b18:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b1c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffe097          	auipc	ra,0xffffe
    80004b26:	b36080e7          	jalr	-1226(ra) # 80002658 <wakeup>
  release(&lk->lk);
    80004b2a:	854a                	mv	a0,s2
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16c080e7          	jalr	364(ra) # 80000c98 <release>
}
    80004b34:	60e2                	ld	ra,24(sp)
    80004b36:	6442                	ld	s0,16(sp)
    80004b38:	64a2                	ld	s1,8(sp)
    80004b3a:	6902                	ld	s2,0(sp)
    80004b3c:	6105                	addi	sp,sp,32
    80004b3e:	8082                	ret

0000000080004b40 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b40:	7179                	addi	sp,sp,-48
    80004b42:	f406                	sd	ra,40(sp)
    80004b44:	f022                	sd	s0,32(sp)
    80004b46:	ec26                	sd	s1,24(sp)
    80004b48:	e84a                	sd	s2,16(sp)
    80004b4a:	e44e                	sd	s3,8(sp)
    80004b4c:	1800                	addi	s0,sp,48
    80004b4e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b50:	00850913          	addi	s2,a0,8
    80004b54:	854a                	mv	a0,s2
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	08e080e7          	jalr	142(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b5e:	409c                	lw	a5,0(s1)
    80004b60:	ef99                	bnez	a5,80004b7e <holdingsleep+0x3e>
    80004b62:	4481                	li	s1,0
  release(&lk->lk);
    80004b64:	854a                	mv	a0,s2
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
  return r;
}
    80004b6e:	8526                	mv	a0,s1
    80004b70:	70a2                	ld	ra,40(sp)
    80004b72:	7402                	ld	s0,32(sp)
    80004b74:	64e2                	ld	s1,24(sp)
    80004b76:	6942                	ld	s2,16(sp)
    80004b78:	69a2                	ld	s3,8(sp)
    80004b7a:	6145                	addi	sp,sp,48
    80004b7c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b7e:	0284a983          	lw	s3,40(s1)
    80004b82:	ffffd097          	auipc	ra,0xffffd
    80004b86:	f10080e7          	jalr	-240(ra) # 80001a92 <myproc>
    80004b8a:	5904                	lw	s1,48(a0)
    80004b8c:	413484b3          	sub	s1,s1,s3
    80004b90:	0014b493          	seqz	s1,s1
    80004b94:	bfc1                	j	80004b64 <holdingsleep+0x24>

0000000080004b96 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b96:	1141                	addi	sp,sp,-16
    80004b98:	e406                	sd	ra,8(sp)
    80004b9a:	e022                	sd	s0,0(sp)
    80004b9c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b9e:	00004597          	auipc	a1,0x4
    80004ba2:	c4258593          	addi	a1,a1,-958 # 800087e0 <syscalls+0x250>
    80004ba6:	0001e517          	auipc	a0,0x1e
    80004baa:	23a50513          	addi	a0,a0,570 # 80022de0 <ftable>
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	fa6080e7          	jalr	-90(ra) # 80000b54 <initlock>
}
    80004bb6:	60a2                	ld	ra,8(sp)
    80004bb8:	6402                	ld	s0,0(sp)
    80004bba:	0141                	addi	sp,sp,16
    80004bbc:	8082                	ret

0000000080004bbe <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bbe:	1101                	addi	sp,sp,-32
    80004bc0:	ec06                	sd	ra,24(sp)
    80004bc2:	e822                	sd	s0,16(sp)
    80004bc4:	e426                	sd	s1,8(sp)
    80004bc6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bc8:	0001e517          	auipc	a0,0x1e
    80004bcc:	21850513          	addi	a0,a0,536 # 80022de0 <ftable>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	014080e7          	jalr	20(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bd8:	0001e497          	auipc	s1,0x1e
    80004bdc:	22048493          	addi	s1,s1,544 # 80022df8 <ftable+0x18>
    80004be0:	0001f717          	auipc	a4,0x1f
    80004be4:	1b870713          	addi	a4,a4,440 # 80023d98 <ftable+0xfb8>
    if(f->ref == 0){
    80004be8:	40dc                	lw	a5,4(s1)
    80004bea:	cf99                	beqz	a5,80004c08 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bec:	02848493          	addi	s1,s1,40
    80004bf0:	fee49ce3          	bne	s1,a4,80004be8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bf4:	0001e517          	auipc	a0,0x1e
    80004bf8:	1ec50513          	addi	a0,a0,492 # 80022de0 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	09c080e7          	jalr	156(ra) # 80000c98 <release>
  return 0;
    80004c04:	4481                	li	s1,0
    80004c06:	a819                	j	80004c1c <filealloc+0x5e>
      f->ref = 1;
    80004c08:	4785                	li	a5,1
    80004c0a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c0c:	0001e517          	auipc	a0,0x1e
    80004c10:	1d450513          	addi	a0,a0,468 # 80022de0 <ftable>
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	084080e7          	jalr	132(ra) # 80000c98 <release>
}
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	60e2                	ld	ra,24(sp)
    80004c20:	6442                	ld	s0,16(sp)
    80004c22:	64a2                	ld	s1,8(sp)
    80004c24:	6105                	addi	sp,sp,32
    80004c26:	8082                	ret

0000000080004c28 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c28:	1101                	addi	sp,sp,-32
    80004c2a:	ec06                	sd	ra,24(sp)
    80004c2c:	e822                	sd	s0,16(sp)
    80004c2e:	e426                	sd	s1,8(sp)
    80004c30:	1000                	addi	s0,sp,32
    80004c32:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c34:	0001e517          	auipc	a0,0x1e
    80004c38:	1ac50513          	addi	a0,a0,428 # 80022de0 <ftable>
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	fa8080e7          	jalr	-88(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c44:	40dc                	lw	a5,4(s1)
    80004c46:	02f05263          	blez	a5,80004c6a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c4a:	2785                	addiw	a5,a5,1
    80004c4c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c4e:	0001e517          	auipc	a0,0x1e
    80004c52:	19250513          	addi	a0,a0,402 # 80022de0 <ftable>
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>
  return f;
}
    80004c5e:	8526                	mv	a0,s1
    80004c60:	60e2                	ld	ra,24(sp)
    80004c62:	6442                	ld	s0,16(sp)
    80004c64:	64a2                	ld	s1,8(sp)
    80004c66:	6105                	addi	sp,sp,32
    80004c68:	8082                	ret
    panic("filedup");
    80004c6a:	00004517          	auipc	a0,0x4
    80004c6e:	b7e50513          	addi	a0,a0,-1154 # 800087e8 <syscalls+0x258>
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>

0000000080004c7a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c7a:	7139                	addi	sp,sp,-64
    80004c7c:	fc06                	sd	ra,56(sp)
    80004c7e:	f822                	sd	s0,48(sp)
    80004c80:	f426                	sd	s1,40(sp)
    80004c82:	f04a                	sd	s2,32(sp)
    80004c84:	ec4e                	sd	s3,24(sp)
    80004c86:	e852                	sd	s4,16(sp)
    80004c88:	e456                	sd	s5,8(sp)
    80004c8a:	0080                	addi	s0,sp,64
    80004c8c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c8e:	0001e517          	auipc	a0,0x1e
    80004c92:	15250513          	addi	a0,a0,338 # 80022de0 <ftable>
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	f4e080e7          	jalr	-178(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c9e:	40dc                	lw	a5,4(s1)
    80004ca0:	06f05163          	blez	a5,80004d02 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ca4:	37fd                	addiw	a5,a5,-1
    80004ca6:	0007871b          	sext.w	a4,a5
    80004caa:	c0dc                	sw	a5,4(s1)
    80004cac:	06e04363          	bgtz	a4,80004d12 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cb0:	0004a903          	lw	s2,0(s1)
    80004cb4:	0094ca83          	lbu	s5,9(s1)
    80004cb8:	0104ba03          	ld	s4,16(s1)
    80004cbc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cc0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cc4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cc8:	0001e517          	auipc	a0,0x1e
    80004ccc:	11850513          	addi	a0,a0,280 # 80022de0 <ftable>
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	fc8080e7          	jalr	-56(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004cd8:	4785                	li	a5,1
    80004cda:	04f90d63          	beq	s2,a5,80004d34 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cde:	3979                	addiw	s2,s2,-2
    80004ce0:	4785                	li	a5,1
    80004ce2:	0527e063          	bltu	a5,s2,80004d22 <fileclose+0xa8>
    begin_op();
    80004ce6:	00000097          	auipc	ra,0x0
    80004cea:	ac8080e7          	jalr	-1336(ra) # 800047ae <begin_op>
    iput(ff.ip);
    80004cee:	854e                	mv	a0,s3
    80004cf0:	fffff097          	auipc	ra,0xfffff
    80004cf4:	2a6080e7          	jalr	678(ra) # 80003f96 <iput>
    end_op();
    80004cf8:	00000097          	auipc	ra,0x0
    80004cfc:	b36080e7          	jalr	-1226(ra) # 8000482e <end_op>
    80004d00:	a00d                	j	80004d22 <fileclose+0xa8>
    panic("fileclose");
    80004d02:	00004517          	auipc	a0,0x4
    80004d06:	aee50513          	addi	a0,a0,-1298 # 800087f0 <syscalls+0x260>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	834080e7          	jalr	-1996(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d12:	0001e517          	auipc	a0,0x1e
    80004d16:	0ce50513          	addi	a0,a0,206 # 80022de0 <ftable>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	f7e080e7          	jalr	-130(ra) # 80000c98 <release>
  }
}
    80004d22:	70e2                	ld	ra,56(sp)
    80004d24:	7442                	ld	s0,48(sp)
    80004d26:	74a2                	ld	s1,40(sp)
    80004d28:	7902                	ld	s2,32(sp)
    80004d2a:	69e2                	ld	s3,24(sp)
    80004d2c:	6a42                	ld	s4,16(sp)
    80004d2e:	6aa2                	ld	s5,8(sp)
    80004d30:	6121                	addi	sp,sp,64
    80004d32:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d34:	85d6                	mv	a1,s5
    80004d36:	8552                	mv	a0,s4
    80004d38:	00000097          	auipc	ra,0x0
    80004d3c:	34c080e7          	jalr	844(ra) # 80005084 <pipeclose>
    80004d40:	b7cd                	j	80004d22 <fileclose+0xa8>

0000000080004d42 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d42:	715d                	addi	sp,sp,-80
    80004d44:	e486                	sd	ra,72(sp)
    80004d46:	e0a2                	sd	s0,64(sp)
    80004d48:	fc26                	sd	s1,56(sp)
    80004d4a:	f84a                	sd	s2,48(sp)
    80004d4c:	f44e                	sd	s3,40(sp)
    80004d4e:	0880                	addi	s0,sp,80
    80004d50:	84aa                	mv	s1,a0
    80004d52:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	d3e080e7          	jalr	-706(ra) # 80001a92 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d5c:	409c                	lw	a5,0(s1)
    80004d5e:	37f9                	addiw	a5,a5,-2
    80004d60:	4705                	li	a4,1
    80004d62:	04f76763          	bltu	a4,a5,80004db0 <filestat+0x6e>
    80004d66:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d68:	6c88                	ld	a0,24(s1)
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	072080e7          	jalr	114(ra) # 80003ddc <ilock>
    stati(f->ip, &st);
    80004d72:	fb840593          	addi	a1,s0,-72
    80004d76:	6c88                	ld	a0,24(s1)
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	2ee080e7          	jalr	750(ra) # 80004066 <stati>
    iunlock(f->ip);
    80004d80:	6c88                	ld	a0,24(s1)
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	11c080e7          	jalr	284(ra) # 80003e9e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d8a:	46e1                	li	a3,24
    80004d8c:	fb840613          	addi	a2,s0,-72
    80004d90:	85ce                	mv	a1,s3
    80004d92:	05093503          	ld	a0,80(s2)
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	8e4080e7          	jalr	-1820(ra) # 8000167a <copyout>
    80004d9e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004da2:	60a6                	ld	ra,72(sp)
    80004da4:	6406                	ld	s0,64(sp)
    80004da6:	74e2                	ld	s1,56(sp)
    80004da8:	7942                	ld	s2,48(sp)
    80004daa:	79a2                	ld	s3,40(sp)
    80004dac:	6161                	addi	sp,sp,80
    80004dae:	8082                	ret
  return -1;
    80004db0:	557d                	li	a0,-1
    80004db2:	bfc5                	j	80004da2 <filestat+0x60>

0000000080004db4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004db4:	7179                	addi	sp,sp,-48
    80004db6:	f406                	sd	ra,40(sp)
    80004db8:	f022                	sd	s0,32(sp)
    80004dba:	ec26                	sd	s1,24(sp)
    80004dbc:	e84a                	sd	s2,16(sp)
    80004dbe:	e44e                	sd	s3,8(sp)
    80004dc0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dc2:	00854783          	lbu	a5,8(a0)
    80004dc6:	c3d5                	beqz	a5,80004e6a <fileread+0xb6>
    80004dc8:	84aa                	mv	s1,a0
    80004dca:	89ae                	mv	s3,a1
    80004dcc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dce:	411c                	lw	a5,0(a0)
    80004dd0:	4705                	li	a4,1
    80004dd2:	04e78963          	beq	a5,a4,80004e24 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dd6:	470d                	li	a4,3
    80004dd8:	04e78d63          	beq	a5,a4,80004e32 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ddc:	4709                	li	a4,2
    80004dde:	06e79e63          	bne	a5,a4,80004e5a <fileread+0xa6>
    ilock(f->ip);
    80004de2:	6d08                	ld	a0,24(a0)
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	ff8080e7          	jalr	-8(ra) # 80003ddc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dec:	874a                	mv	a4,s2
    80004dee:	5094                	lw	a3,32(s1)
    80004df0:	864e                	mv	a2,s3
    80004df2:	4585                	li	a1,1
    80004df4:	6c88                	ld	a0,24(s1)
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	29a080e7          	jalr	666(ra) # 80004090 <readi>
    80004dfe:	892a                	mv	s2,a0
    80004e00:	00a05563          	blez	a0,80004e0a <fileread+0x56>
      f->off += r;
    80004e04:	509c                	lw	a5,32(s1)
    80004e06:	9fa9                	addw	a5,a5,a0
    80004e08:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e0a:	6c88                	ld	a0,24(s1)
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	092080e7          	jalr	146(ra) # 80003e9e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e14:	854a                	mv	a0,s2
    80004e16:	70a2                	ld	ra,40(sp)
    80004e18:	7402                	ld	s0,32(sp)
    80004e1a:	64e2                	ld	s1,24(sp)
    80004e1c:	6942                	ld	s2,16(sp)
    80004e1e:	69a2                	ld	s3,8(sp)
    80004e20:	6145                	addi	sp,sp,48
    80004e22:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e24:	6908                	ld	a0,16(a0)
    80004e26:	00000097          	auipc	ra,0x0
    80004e2a:	3c8080e7          	jalr	968(ra) # 800051ee <piperead>
    80004e2e:	892a                	mv	s2,a0
    80004e30:	b7d5                	j	80004e14 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e32:	02451783          	lh	a5,36(a0)
    80004e36:	03079693          	slli	a3,a5,0x30
    80004e3a:	92c1                	srli	a3,a3,0x30
    80004e3c:	4725                	li	a4,9
    80004e3e:	02d76863          	bltu	a4,a3,80004e6e <fileread+0xba>
    80004e42:	0792                	slli	a5,a5,0x4
    80004e44:	0001e717          	auipc	a4,0x1e
    80004e48:	efc70713          	addi	a4,a4,-260 # 80022d40 <devsw>
    80004e4c:	97ba                	add	a5,a5,a4
    80004e4e:	639c                	ld	a5,0(a5)
    80004e50:	c38d                	beqz	a5,80004e72 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e52:	4505                	li	a0,1
    80004e54:	9782                	jalr	a5
    80004e56:	892a                	mv	s2,a0
    80004e58:	bf75                	j	80004e14 <fileread+0x60>
    panic("fileread");
    80004e5a:	00004517          	auipc	a0,0x4
    80004e5e:	9a650513          	addi	a0,a0,-1626 # 80008800 <syscalls+0x270>
    80004e62:	ffffb097          	auipc	ra,0xffffb
    80004e66:	6dc080e7          	jalr	1756(ra) # 8000053e <panic>
    return -1;
    80004e6a:	597d                	li	s2,-1
    80004e6c:	b765                	j	80004e14 <fileread+0x60>
      return -1;
    80004e6e:	597d                	li	s2,-1
    80004e70:	b755                	j	80004e14 <fileread+0x60>
    80004e72:	597d                	li	s2,-1
    80004e74:	b745                	j	80004e14 <fileread+0x60>

0000000080004e76 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e76:	715d                	addi	sp,sp,-80
    80004e78:	e486                	sd	ra,72(sp)
    80004e7a:	e0a2                	sd	s0,64(sp)
    80004e7c:	fc26                	sd	s1,56(sp)
    80004e7e:	f84a                	sd	s2,48(sp)
    80004e80:	f44e                	sd	s3,40(sp)
    80004e82:	f052                	sd	s4,32(sp)
    80004e84:	ec56                	sd	s5,24(sp)
    80004e86:	e85a                	sd	s6,16(sp)
    80004e88:	e45e                	sd	s7,8(sp)
    80004e8a:	e062                	sd	s8,0(sp)
    80004e8c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e8e:	00954783          	lbu	a5,9(a0)
    80004e92:	10078663          	beqz	a5,80004f9e <filewrite+0x128>
    80004e96:	892a                	mv	s2,a0
    80004e98:	8aae                	mv	s5,a1
    80004e9a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e9c:	411c                	lw	a5,0(a0)
    80004e9e:	4705                	li	a4,1
    80004ea0:	02e78263          	beq	a5,a4,80004ec4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ea4:	470d                	li	a4,3
    80004ea6:	02e78663          	beq	a5,a4,80004ed2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eaa:	4709                	li	a4,2
    80004eac:	0ee79163          	bne	a5,a4,80004f8e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004eb0:	0ac05d63          	blez	a2,80004f6a <filewrite+0xf4>
    int i = 0;
    80004eb4:	4981                	li	s3,0
    80004eb6:	6b05                	lui	s6,0x1
    80004eb8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ebc:	6b85                	lui	s7,0x1
    80004ebe:	c00b8b9b          	addiw	s7,s7,-1024
    80004ec2:	a861                	j	80004f5a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ec4:	6908                	ld	a0,16(a0)
    80004ec6:	00000097          	auipc	ra,0x0
    80004eca:	22e080e7          	jalr	558(ra) # 800050f4 <pipewrite>
    80004ece:	8a2a                	mv	s4,a0
    80004ed0:	a045                	j	80004f70 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ed2:	02451783          	lh	a5,36(a0)
    80004ed6:	03079693          	slli	a3,a5,0x30
    80004eda:	92c1                	srli	a3,a3,0x30
    80004edc:	4725                	li	a4,9
    80004ede:	0cd76263          	bltu	a4,a3,80004fa2 <filewrite+0x12c>
    80004ee2:	0792                	slli	a5,a5,0x4
    80004ee4:	0001e717          	auipc	a4,0x1e
    80004ee8:	e5c70713          	addi	a4,a4,-420 # 80022d40 <devsw>
    80004eec:	97ba                	add	a5,a5,a4
    80004eee:	679c                	ld	a5,8(a5)
    80004ef0:	cbdd                	beqz	a5,80004fa6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ef2:	4505                	li	a0,1
    80004ef4:	9782                	jalr	a5
    80004ef6:	8a2a                	mv	s4,a0
    80004ef8:	a8a5                	j	80004f70 <filewrite+0xfa>
    80004efa:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004efe:	00000097          	auipc	ra,0x0
    80004f02:	8b0080e7          	jalr	-1872(ra) # 800047ae <begin_op>
      ilock(f->ip);
    80004f06:	01893503          	ld	a0,24(s2)
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	ed2080e7          	jalr	-302(ra) # 80003ddc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f12:	8762                	mv	a4,s8
    80004f14:	02092683          	lw	a3,32(s2)
    80004f18:	01598633          	add	a2,s3,s5
    80004f1c:	4585                	li	a1,1
    80004f1e:	01893503          	ld	a0,24(s2)
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	266080e7          	jalr	614(ra) # 80004188 <writei>
    80004f2a:	84aa                	mv	s1,a0
    80004f2c:	00a05763          	blez	a0,80004f3a <filewrite+0xc4>
        f->off += r;
    80004f30:	02092783          	lw	a5,32(s2)
    80004f34:	9fa9                	addw	a5,a5,a0
    80004f36:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f3a:	01893503          	ld	a0,24(s2)
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	f60080e7          	jalr	-160(ra) # 80003e9e <iunlock>
      end_op();
    80004f46:	00000097          	auipc	ra,0x0
    80004f4a:	8e8080e7          	jalr	-1816(ra) # 8000482e <end_op>

      if(r != n1){
    80004f4e:	009c1f63          	bne	s8,s1,80004f6c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f52:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f56:	0149db63          	bge	s3,s4,80004f6c <filewrite+0xf6>
      int n1 = n - i;
    80004f5a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f5e:	84be                	mv	s1,a5
    80004f60:	2781                	sext.w	a5,a5
    80004f62:	f8fb5ce3          	bge	s6,a5,80004efa <filewrite+0x84>
    80004f66:	84de                	mv	s1,s7
    80004f68:	bf49                	j	80004efa <filewrite+0x84>
    int i = 0;
    80004f6a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f6c:	013a1f63          	bne	s4,s3,80004f8a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f70:	8552                	mv	a0,s4
    80004f72:	60a6                	ld	ra,72(sp)
    80004f74:	6406                	ld	s0,64(sp)
    80004f76:	74e2                	ld	s1,56(sp)
    80004f78:	7942                	ld	s2,48(sp)
    80004f7a:	79a2                	ld	s3,40(sp)
    80004f7c:	7a02                	ld	s4,32(sp)
    80004f7e:	6ae2                	ld	s5,24(sp)
    80004f80:	6b42                	ld	s6,16(sp)
    80004f82:	6ba2                	ld	s7,8(sp)
    80004f84:	6c02                	ld	s8,0(sp)
    80004f86:	6161                	addi	sp,sp,80
    80004f88:	8082                	ret
    ret = (i == n ? n : -1);
    80004f8a:	5a7d                	li	s4,-1
    80004f8c:	b7d5                	j	80004f70 <filewrite+0xfa>
    panic("filewrite");
    80004f8e:	00004517          	auipc	a0,0x4
    80004f92:	88250513          	addi	a0,a0,-1918 # 80008810 <syscalls+0x280>
    80004f96:	ffffb097          	auipc	ra,0xffffb
    80004f9a:	5a8080e7          	jalr	1448(ra) # 8000053e <panic>
    return -1;
    80004f9e:	5a7d                	li	s4,-1
    80004fa0:	bfc1                	j	80004f70 <filewrite+0xfa>
      return -1;
    80004fa2:	5a7d                	li	s4,-1
    80004fa4:	b7f1                	j	80004f70 <filewrite+0xfa>
    80004fa6:	5a7d                	li	s4,-1
    80004fa8:	b7e1                	j	80004f70 <filewrite+0xfa>

0000000080004faa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004faa:	7179                	addi	sp,sp,-48
    80004fac:	f406                	sd	ra,40(sp)
    80004fae:	f022                	sd	s0,32(sp)
    80004fb0:	ec26                	sd	s1,24(sp)
    80004fb2:	e84a                	sd	s2,16(sp)
    80004fb4:	e44e                	sd	s3,8(sp)
    80004fb6:	e052                	sd	s4,0(sp)
    80004fb8:	1800                	addi	s0,sp,48
    80004fba:	84aa                	mv	s1,a0
    80004fbc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fbe:	0005b023          	sd	zero,0(a1)
    80004fc2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fc6:	00000097          	auipc	ra,0x0
    80004fca:	bf8080e7          	jalr	-1032(ra) # 80004bbe <filealloc>
    80004fce:	e088                	sd	a0,0(s1)
    80004fd0:	c551                	beqz	a0,8000505c <pipealloc+0xb2>
    80004fd2:	00000097          	auipc	ra,0x0
    80004fd6:	bec080e7          	jalr	-1044(ra) # 80004bbe <filealloc>
    80004fda:	00aa3023          	sd	a0,0(s4)
    80004fde:	c92d                	beqz	a0,80005050 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	b14080e7          	jalr	-1260(ra) # 80000af4 <kalloc>
    80004fe8:	892a                	mv	s2,a0
    80004fea:	c125                	beqz	a0,8000504a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fec:	4985                	li	s3,1
    80004fee:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ff2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ff6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ffa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ffe:	00003597          	auipc	a1,0x3
    80005002:	4d258593          	addi	a1,a1,1234 # 800084d0 <states.1801+0x208>
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	b4e080e7          	jalr	-1202(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000500e:	609c                	ld	a5,0(s1)
    80005010:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005014:	609c                	ld	a5,0(s1)
    80005016:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000501a:	609c                	ld	a5,0(s1)
    8000501c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005020:	609c                	ld	a5,0(s1)
    80005022:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005026:	000a3783          	ld	a5,0(s4)
    8000502a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000502e:	000a3783          	ld	a5,0(s4)
    80005032:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005036:	000a3783          	ld	a5,0(s4)
    8000503a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000503e:	000a3783          	ld	a5,0(s4)
    80005042:	0127b823          	sd	s2,16(a5)
  return 0;
    80005046:	4501                	li	a0,0
    80005048:	a025                	j	80005070 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000504a:	6088                	ld	a0,0(s1)
    8000504c:	e501                	bnez	a0,80005054 <pipealloc+0xaa>
    8000504e:	a039                	j	8000505c <pipealloc+0xb2>
    80005050:	6088                	ld	a0,0(s1)
    80005052:	c51d                	beqz	a0,80005080 <pipealloc+0xd6>
    fileclose(*f0);
    80005054:	00000097          	auipc	ra,0x0
    80005058:	c26080e7          	jalr	-986(ra) # 80004c7a <fileclose>
  if(*f1)
    8000505c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005060:	557d                	li	a0,-1
  if(*f1)
    80005062:	c799                	beqz	a5,80005070 <pipealloc+0xc6>
    fileclose(*f1);
    80005064:	853e                	mv	a0,a5
    80005066:	00000097          	auipc	ra,0x0
    8000506a:	c14080e7          	jalr	-1004(ra) # 80004c7a <fileclose>
  return -1;
    8000506e:	557d                	li	a0,-1
}
    80005070:	70a2                	ld	ra,40(sp)
    80005072:	7402                	ld	s0,32(sp)
    80005074:	64e2                	ld	s1,24(sp)
    80005076:	6942                	ld	s2,16(sp)
    80005078:	69a2                	ld	s3,8(sp)
    8000507a:	6a02                	ld	s4,0(sp)
    8000507c:	6145                	addi	sp,sp,48
    8000507e:	8082                	ret
  return -1;
    80005080:	557d                	li	a0,-1
    80005082:	b7fd                	j	80005070 <pipealloc+0xc6>

0000000080005084 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005084:	1101                	addi	sp,sp,-32
    80005086:	ec06                	sd	ra,24(sp)
    80005088:	e822                	sd	s0,16(sp)
    8000508a:	e426                	sd	s1,8(sp)
    8000508c:	e04a                	sd	s2,0(sp)
    8000508e:	1000                	addi	s0,sp,32
    80005090:	84aa                	mv	s1,a0
    80005092:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	b50080e7          	jalr	-1200(ra) # 80000be4 <acquire>
  if(writable){
    8000509c:	02090d63          	beqz	s2,800050d6 <pipeclose+0x52>
    pi->writeopen = 0;
    800050a0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050a4:	21848513          	addi	a0,s1,536
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	5b0080e7          	jalr	1456(ra) # 80002658 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050b0:	2204b783          	ld	a5,544(s1)
    800050b4:	eb95                	bnez	a5,800050e8 <pipeclose+0x64>
    release(&pi->lock);
    800050b6:	8526                	mv	a0,s1
    800050b8:	ffffc097          	auipc	ra,0xffffc
    800050bc:	be0080e7          	jalr	-1056(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050c0:	8526                	mv	a0,s1
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	936080e7          	jalr	-1738(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050ca:	60e2                	ld	ra,24(sp)
    800050cc:	6442                	ld	s0,16(sp)
    800050ce:	64a2                	ld	s1,8(sp)
    800050d0:	6902                	ld	s2,0(sp)
    800050d2:	6105                	addi	sp,sp,32
    800050d4:	8082                	ret
    pi->readopen = 0;
    800050d6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050da:	21c48513          	addi	a0,s1,540
    800050de:	ffffd097          	auipc	ra,0xffffd
    800050e2:	57a080e7          	jalr	1402(ra) # 80002658 <wakeup>
    800050e6:	b7e9                	j	800050b0 <pipeclose+0x2c>
    release(&pi->lock);
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	bae080e7          	jalr	-1106(ra) # 80000c98 <release>
}
    800050f2:	bfe1                	j	800050ca <pipeclose+0x46>

00000000800050f4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050f4:	7159                	addi	sp,sp,-112
    800050f6:	f486                	sd	ra,104(sp)
    800050f8:	f0a2                	sd	s0,96(sp)
    800050fa:	eca6                	sd	s1,88(sp)
    800050fc:	e8ca                	sd	s2,80(sp)
    800050fe:	e4ce                	sd	s3,72(sp)
    80005100:	e0d2                	sd	s4,64(sp)
    80005102:	fc56                	sd	s5,56(sp)
    80005104:	f85a                	sd	s6,48(sp)
    80005106:	f45e                	sd	s7,40(sp)
    80005108:	f062                	sd	s8,32(sp)
    8000510a:	ec66                	sd	s9,24(sp)
    8000510c:	1880                	addi	s0,sp,112
    8000510e:	84aa                	mv	s1,a0
    80005110:	8aae                	mv	s5,a1
    80005112:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005114:	ffffd097          	auipc	ra,0xffffd
    80005118:	97e080e7          	jalr	-1666(ra) # 80001a92 <myproc>
    8000511c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000511e:	8526                	mv	a0,s1
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	ac4080e7          	jalr	-1340(ra) # 80000be4 <acquire>
  while(i < n){
    80005128:	0d405163          	blez	s4,800051ea <pipewrite+0xf6>
    8000512c:	8ba6                	mv	s7,s1
  int i = 0;
    8000512e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005130:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005132:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005136:	21c48c13          	addi	s8,s1,540
    8000513a:	a08d                	j	8000519c <pipewrite+0xa8>
      release(&pi->lock);
    8000513c:	8526                	mv	a0,s1
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	b5a080e7          	jalr	-1190(ra) # 80000c98 <release>
      return -1;
    80005146:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005148:	854a                	mv	a0,s2
    8000514a:	70a6                	ld	ra,104(sp)
    8000514c:	7406                	ld	s0,96(sp)
    8000514e:	64e6                	ld	s1,88(sp)
    80005150:	6946                	ld	s2,80(sp)
    80005152:	69a6                	ld	s3,72(sp)
    80005154:	6a06                	ld	s4,64(sp)
    80005156:	7ae2                	ld	s5,56(sp)
    80005158:	7b42                	ld	s6,48(sp)
    8000515a:	7ba2                	ld	s7,40(sp)
    8000515c:	7c02                	ld	s8,32(sp)
    8000515e:	6ce2                	ld	s9,24(sp)
    80005160:	6165                	addi	sp,sp,112
    80005162:	8082                	ret
      wakeup(&pi->nread);
    80005164:	8566                	mv	a0,s9
    80005166:	ffffd097          	auipc	ra,0xffffd
    8000516a:	4f2080e7          	jalr	1266(ra) # 80002658 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000516e:	85de                	mv	a1,s7
    80005170:	8562                	mv	a0,s8
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	1f6080e7          	jalr	502(ra) # 80002368 <sleep>
    8000517a:	a839                	j	80005198 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000517c:	21c4a783          	lw	a5,540(s1)
    80005180:	0017871b          	addiw	a4,a5,1
    80005184:	20e4ae23          	sw	a4,540(s1)
    80005188:	1ff7f793          	andi	a5,a5,511
    8000518c:	97a6                	add	a5,a5,s1
    8000518e:	f9f44703          	lbu	a4,-97(s0)
    80005192:	00e78c23          	sb	a4,24(a5)
      i++;
    80005196:	2905                	addiw	s2,s2,1
  while(i < n){
    80005198:	03495d63          	bge	s2,s4,800051d2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000519c:	2204a783          	lw	a5,544(s1)
    800051a0:	dfd1                	beqz	a5,8000513c <pipewrite+0x48>
    800051a2:	0289a783          	lw	a5,40(s3)
    800051a6:	fbd9                	bnez	a5,8000513c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051a8:	2184a783          	lw	a5,536(s1)
    800051ac:	21c4a703          	lw	a4,540(s1)
    800051b0:	2007879b          	addiw	a5,a5,512
    800051b4:	faf708e3          	beq	a4,a5,80005164 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051b8:	4685                	li	a3,1
    800051ba:	01590633          	add	a2,s2,s5
    800051be:	f9f40593          	addi	a1,s0,-97
    800051c2:	0509b503          	ld	a0,80(s3)
    800051c6:	ffffc097          	auipc	ra,0xffffc
    800051ca:	540080e7          	jalr	1344(ra) # 80001706 <copyin>
    800051ce:	fb6517e3          	bne	a0,s6,8000517c <pipewrite+0x88>
  wakeup(&pi->nread);
    800051d2:	21848513          	addi	a0,s1,536
    800051d6:	ffffd097          	auipc	ra,0xffffd
    800051da:	482080e7          	jalr	1154(ra) # 80002658 <wakeup>
  release(&pi->lock);
    800051de:	8526                	mv	a0,s1
    800051e0:	ffffc097          	auipc	ra,0xffffc
    800051e4:	ab8080e7          	jalr	-1352(ra) # 80000c98 <release>
  return i;
    800051e8:	b785                	j	80005148 <pipewrite+0x54>
  int i = 0;
    800051ea:	4901                	li	s2,0
    800051ec:	b7dd                	j	800051d2 <pipewrite+0xde>

00000000800051ee <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051ee:	715d                	addi	sp,sp,-80
    800051f0:	e486                	sd	ra,72(sp)
    800051f2:	e0a2                	sd	s0,64(sp)
    800051f4:	fc26                	sd	s1,56(sp)
    800051f6:	f84a                	sd	s2,48(sp)
    800051f8:	f44e                	sd	s3,40(sp)
    800051fa:	f052                	sd	s4,32(sp)
    800051fc:	ec56                	sd	s5,24(sp)
    800051fe:	e85a                	sd	s6,16(sp)
    80005200:	0880                	addi	s0,sp,80
    80005202:	84aa                	mv	s1,a0
    80005204:	892e                	mv	s2,a1
    80005206:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005208:	ffffd097          	auipc	ra,0xffffd
    8000520c:	88a080e7          	jalr	-1910(ra) # 80001a92 <myproc>
    80005210:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005212:	8b26                	mv	s6,s1
    80005214:	8526                	mv	a0,s1
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000521e:	2184a703          	lw	a4,536(s1)
    80005222:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005226:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000522a:	02f71463          	bne	a4,a5,80005252 <piperead+0x64>
    8000522e:	2244a783          	lw	a5,548(s1)
    80005232:	c385                	beqz	a5,80005252 <piperead+0x64>
    if(pr->killed){
    80005234:	028a2783          	lw	a5,40(s4)
    80005238:	ebc1                	bnez	a5,800052c8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000523a:	85da                	mv	a1,s6
    8000523c:	854e                	mv	a0,s3
    8000523e:	ffffd097          	auipc	ra,0xffffd
    80005242:	12a080e7          	jalr	298(ra) # 80002368 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005246:	2184a703          	lw	a4,536(s1)
    8000524a:	21c4a783          	lw	a5,540(s1)
    8000524e:	fef700e3          	beq	a4,a5,8000522e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005252:	09505263          	blez	s5,800052d6 <piperead+0xe8>
    80005256:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005258:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000525a:	2184a783          	lw	a5,536(s1)
    8000525e:	21c4a703          	lw	a4,540(s1)
    80005262:	02f70d63          	beq	a4,a5,8000529c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005266:	0017871b          	addiw	a4,a5,1
    8000526a:	20e4ac23          	sw	a4,536(s1)
    8000526e:	1ff7f793          	andi	a5,a5,511
    80005272:	97a6                	add	a5,a5,s1
    80005274:	0187c783          	lbu	a5,24(a5)
    80005278:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000527c:	4685                	li	a3,1
    8000527e:	fbf40613          	addi	a2,s0,-65
    80005282:	85ca                	mv	a1,s2
    80005284:	050a3503          	ld	a0,80(s4)
    80005288:	ffffc097          	auipc	ra,0xffffc
    8000528c:	3f2080e7          	jalr	1010(ra) # 8000167a <copyout>
    80005290:	01650663          	beq	a0,s6,8000529c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005294:	2985                	addiw	s3,s3,1
    80005296:	0905                	addi	s2,s2,1
    80005298:	fd3a91e3          	bne	s5,s3,8000525a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000529c:	21c48513          	addi	a0,s1,540
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	3b8080e7          	jalr	952(ra) # 80002658 <wakeup>
  release(&pi->lock);
    800052a8:	8526                	mv	a0,s1
    800052aa:	ffffc097          	auipc	ra,0xffffc
    800052ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
  return i;
}
    800052b2:	854e                	mv	a0,s3
    800052b4:	60a6                	ld	ra,72(sp)
    800052b6:	6406                	ld	s0,64(sp)
    800052b8:	74e2                	ld	s1,56(sp)
    800052ba:	7942                	ld	s2,48(sp)
    800052bc:	79a2                	ld	s3,40(sp)
    800052be:	7a02                	ld	s4,32(sp)
    800052c0:	6ae2                	ld	s5,24(sp)
    800052c2:	6b42                	ld	s6,16(sp)
    800052c4:	6161                	addi	sp,sp,80
    800052c6:	8082                	ret
      release(&pi->lock);
    800052c8:	8526                	mv	a0,s1
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
      return -1;
    800052d2:	59fd                	li	s3,-1
    800052d4:	bff9                	j	800052b2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052d6:	4981                	li	s3,0
    800052d8:	b7d1                	j	8000529c <piperead+0xae>

00000000800052da <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052da:	df010113          	addi	sp,sp,-528
    800052de:	20113423          	sd	ra,520(sp)
    800052e2:	20813023          	sd	s0,512(sp)
    800052e6:	ffa6                	sd	s1,504(sp)
    800052e8:	fbca                	sd	s2,496(sp)
    800052ea:	f7ce                	sd	s3,488(sp)
    800052ec:	f3d2                	sd	s4,480(sp)
    800052ee:	efd6                	sd	s5,472(sp)
    800052f0:	ebda                	sd	s6,464(sp)
    800052f2:	e7de                	sd	s7,456(sp)
    800052f4:	e3e2                	sd	s8,448(sp)
    800052f6:	ff66                	sd	s9,440(sp)
    800052f8:	fb6a                	sd	s10,432(sp)
    800052fa:	f76e                	sd	s11,424(sp)
    800052fc:	0c00                	addi	s0,sp,528
    800052fe:	84aa                	mv	s1,a0
    80005300:	dea43c23          	sd	a0,-520(s0)
    80005304:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005308:	ffffc097          	auipc	ra,0xffffc
    8000530c:	78a080e7          	jalr	1930(ra) # 80001a92 <myproc>
    80005310:	892a                	mv	s2,a0

  begin_op();
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	49c080e7          	jalr	1180(ra) # 800047ae <begin_op>

  if((ip = namei(path)) == 0){
    8000531a:	8526                	mv	a0,s1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	276080e7          	jalr	630(ra) # 80004592 <namei>
    80005324:	c92d                	beqz	a0,80005396 <exec+0xbc>
    80005326:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	ab4080e7          	jalr	-1356(ra) # 80003ddc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005330:	04000713          	li	a4,64
    80005334:	4681                	li	a3,0
    80005336:	e5040613          	addi	a2,s0,-432
    8000533a:	4581                	li	a1,0
    8000533c:	8526                	mv	a0,s1
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	d52080e7          	jalr	-686(ra) # 80004090 <readi>
    80005346:	04000793          	li	a5,64
    8000534a:	00f51a63          	bne	a0,a5,8000535e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000534e:	e5042703          	lw	a4,-432(s0)
    80005352:	464c47b7          	lui	a5,0x464c4
    80005356:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000535a:	04f70463          	beq	a4,a5,800053a2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000535e:	8526                	mv	a0,s1
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	cde080e7          	jalr	-802(ra) # 8000403e <iunlockput>
    end_op();
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	4c6080e7          	jalr	1222(ra) # 8000482e <end_op>
  }
  return -1;
    80005370:	557d                	li	a0,-1
}
    80005372:	20813083          	ld	ra,520(sp)
    80005376:	20013403          	ld	s0,512(sp)
    8000537a:	74fe                	ld	s1,504(sp)
    8000537c:	795e                	ld	s2,496(sp)
    8000537e:	79be                	ld	s3,488(sp)
    80005380:	7a1e                	ld	s4,480(sp)
    80005382:	6afe                	ld	s5,472(sp)
    80005384:	6b5e                	ld	s6,464(sp)
    80005386:	6bbe                	ld	s7,456(sp)
    80005388:	6c1e                	ld	s8,448(sp)
    8000538a:	7cfa                	ld	s9,440(sp)
    8000538c:	7d5a                	ld	s10,432(sp)
    8000538e:	7dba                	ld	s11,424(sp)
    80005390:	21010113          	addi	sp,sp,528
    80005394:	8082                	ret
    end_op();
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	498080e7          	jalr	1176(ra) # 8000482e <end_op>
    return -1;
    8000539e:	557d                	li	a0,-1
    800053a0:	bfc9                	j	80005372 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053a2:	854a                	mv	a0,s2
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	7b2080e7          	jalr	1970(ra) # 80001b56 <proc_pagetable>
    800053ac:	8baa                	mv	s7,a0
    800053ae:	d945                	beqz	a0,8000535e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053b0:	e7042983          	lw	s3,-400(s0)
    800053b4:	e8845783          	lhu	a5,-376(s0)
    800053b8:	c7ad                	beqz	a5,80005422 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ba:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053bc:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053be:	6c85                	lui	s9,0x1
    800053c0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053c4:	def43823          	sd	a5,-528(s0)
    800053c8:	a42d                	j	800055f2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053ca:	00003517          	auipc	a0,0x3
    800053ce:	45650513          	addi	a0,a0,1110 # 80008820 <syscalls+0x290>
    800053d2:	ffffb097          	auipc	ra,0xffffb
    800053d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053da:	8756                	mv	a4,s5
    800053dc:	012d86bb          	addw	a3,s11,s2
    800053e0:	4581                	li	a1,0
    800053e2:	8526                	mv	a0,s1
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	cac080e7          	jalr	-852(ra) # 80004090 <readi>
    800053ec:	2501                	sext.w	a0,a0
    800053ee:	1aaa9963          	bne	s5,a0,800055a0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053f2:	6785                	lui	a5,0x1
    800053f4:	0127893b          	addw	s2,a5,s2
    800053f8:	77fd                	lui	a5,0xfffff
    800053fa:	01478a3b          	addw	s4,a5,s4
    800053fe:	1f897163          	bgeu	s2,s8,800055e0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005402:	02091593          	slli	a1,s2,0x20
    80005406:	9181                	srli	a1,a1,0x20
    80005408:	95ea                	add	a1,a1,s10
    8000540a:	855e                	mv	a0,s7
    8000540c:	ffffc097          	auipc	ra,0xffffc
    80005410:	c6a080e7          	jalr	-918(ra) # 80001076 <walkaddr>
    80005414:	862a                	mv	a2,a0
    if(pa == 0)
    80005416:	d955                	beqz	a0,800053ca <exec+0xf0>
      n = PGSIZE;
    80005418:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000541a:	fd9a70e3          	bgeu	s4,s9,800053da <exec+0x100>
      n = sz - i;
    8000541e:	8ad2                	mv	s5,s4
    80005420:	bf6d                	j	800053da <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005422:	4901                	li	s2,0
  iunlockput(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	c18080e7          	jalr	-1000(ra) # 8000403e <iunlockput>
  end_op();
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	400080e7          	jalr	1024(ra) # 8000482e <end_op>
  p = myproc();
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	65c080e7          	jalr	1628(ra) # 80001a92 <myproc>
    8000543e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005440:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005444:	6785                	lui	a5,0x1
    80005446:	17fd                	addi	a5,a5,-1
    80005448:	993e                	add	s2,s2,a5
    8000544a:	757d                	lui	a0,0xfffff
    8000544c:	00a977b3          	and	a5,s2,a0
    80005450:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005454:	6609                	lui	a2,0x2
    80005456:	963e                	add	a2,a2,a5
    80005458:	85be                	mv	a1,a5
    8000545a:	855e                	mv	a0,s7
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	fce080e7          	jalr	-50(ra) # 8000142a <uvmalloc>
    80005464:	8b2a                	mv	s6,a0
  ip = 0;
    80005466:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005468:	12050c63          	beqz	a0,800055a0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000546c:	75f9                	lui	a1,0xffffe
    8000546e:	95aa                	add	a1,a1,a0
    80005470:	855e                	mv	a0,s7
    80005472:	ffffc097          	auipc	ra,0xffffc
    80005476:	1d6080e7          	jalr	470(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    8000547a:	7c7d                	lui	s8,0xfffff
    8000547c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000547e:	e0043783          	ld	a5,-512(s0)
    80005482:	6388                	ld	a0,0(a5)
    80005484:	c535                	beqz	a0,800054f0 <exec+0x216>
    80005486:	e9040993          	addi	s3,s0,-368
    8000548a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000548e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005490:	ffffc097          	auipc	ra,0xffffc
    80005494:	9d4080e7          	jalr	-1580(ra) # 80000e64 <strlen>
    80005498:	2505                	addiw	a0,a0,1
    8000549a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000549e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054a2:	13896363          	bltu	s2,s8,800055c8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054a6:	e0043d83          	ld	s11,-512(s0)
    800054aa:	000dba03          	ld	s4,0(s11)
    800054ae:	8552                	mv	a0,s4
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	9b4080e7          	jalr	-1612(ra) # 80000e64 <strlen>
    800054b8:	0015069b          	addiw	a3,a0,1
    800054bc:	8652                	mv	a2,s4
    800054be:	85ca                	mv	a1,s2
    800054c0:	855e                	mv	a0,s7
    800054c2:	ffffc097          	auipc	ra,0xffffc
    800054c6:	1b8080e7          	jalr	440(ra) # 8000167a <copyout>
    800054ca:	10054363          	bltz	a0,800055d0 <exec+0x2f6>
    ustack[argc] = sp;
    800054ce:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054d2:	0485                	addi	s1,s1,1
    800054d4:	008d8793          	addi	a5,s11,8
    800054d8:	e0f43023          	sd	a5,-512(s0)
    800054dc:	008db503          	ld	a0,8(s11)
    800054e0:	c911                	beqz	a0,800054f4 <exec+0x21a>
    if(argc >= MAXARG)
    800054e2:	09a1                	addi	s3,s3,8
    800054e4:	fb3c96e3          	bne	s9,s3,80005490 <exec+0x1b6>
  sz = sz1;
    800054e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054ec:	4481                	li	s1,0
    800054ee:	a84d                	j	800055a0 <exec+0x2c6>
  sp = sz;
    800054f0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054f2:	4481                	li	s1,0
  ustack[argc] = 0;
    800054f4:	00349793          	slli	a5,s1,0x3
    800054f8:	f9040713          	addi	a4,s0,-112
    800054fc:	97ba                	add	a5,a5,a4
    800054fe:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005502:	00148693          	addi	a3,s1,1
    80005506:	068e                	slli	a3,a3,0x3
    80005508:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000550c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005510:	01897663          	bgeu	s2,s8,8000551c <exec+0x242>
  sz = sz1;
    80005514:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005518:	4481                	li	s1,0
    8000551a:	a059                	j	800055a0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000551c:	e9040613          	addi	a2,s0,-368
    80005520:	85ca                	mv	a1,s2
    80005522:	855e                	mv	a0,s7
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	156080e7          	jalr	342(ra) # 8000167a <copyout>
    8000552c:	0a054663          	bltz	a0,800055d8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005530:	058ab783          	ld	a5,88(s5)
    80005534:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005538:	df843783          	ld	a5,-520(s0)
    8000553c:	0007c703          	lbu	a4,0(a5)
    80005540:	cf11                	beqz	a4,8000555c <exec+0x282>
    80005542:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005544:	02f00693          	li	a3,47
    80005548:	a039                	j	80005556 <exec+0x27c>
      last = s+1;
    8000554a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000554e:	0785                	addi	a5,a5,1
    80005550:	fff7c703          	lbu	a4,-1(a5)
    80005554:	c701                	beqz	a4,8000555c <exec+0x282>
    if(*s == '/')
    80005556:	fed71ce3          	bne	a4,a3,8000554e <exec+0x274>
    8000555a:	bfc5                	j	8000554a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000555c:	4641                	li	a2,16
    8000555e:	df843583          	ld	a1,-520(s0)
    80005562:	158a8513          	addi	a0,s5,344
    80005566:	ffffc097          	auipc	ra,0xffffc
    8000556a:	8cc080e7          	jalr	-1844(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000556e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005572:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005576:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000557a:	058ab783          	ld	a5,88(s5)
    8000557e:	e6843703          	ld	a4,-408(s0)
    80005582:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005584:	058ab783          	ld	a5,88(s5)
    80005588:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000558c:	85ea                	mv	a1,s10
    8000558e:	ffffc097          	auipc	ra,0xffffc
    80005592:	664080e7          	jalr	1636(ra) # 80001bf2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005596:	0004851b          	sext.w	a0,s1
    8000559a:	bbe1                	j	80005372 <exec+0x98>
    8000559c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055a0:	e0843583          	ld	a1,-504(s0)
    800055a4:	855e                	mv	a0,s7
    800055a6:	ffffc097          	auipc	ra,0xffffc
    800055aa:	64c080e7          	jalr	1612(ra) # 80001bf2 <proc_freepagetable>
  if(ip){
    800055ae:	da0498e3          	bnez	s1,8000535e <exec+0x84>
  return -1;
    800055b2:	557d                	li	a0,-1
    800055b4:	bb7d                	j	80005372 <exec+0x98>
    800055b6:	e1243423          	sd	s2,-504(s0)
    800055ba:	b7dd                	j	800055a0 <exec+0x2c6>
    800055bc:	e1243423          	sd	s2,-504(s0)
    800055c0:	b7c5                	j	800055a0 <exec+0x2c6>
    800055c2:	e1243423          	sd	s2,-504(s0)
    800055c6:	bfe9                	j	800055a0 <exec+0x2c6>
  sz = sz1;
    800055c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055cc:	4481                	li	s1,0
    800055ce:	bfc9                	j	800055a0 <exec+0x2c6>
  sz = sz1;
    800055d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d4:	4481                	li	s1,0
    800055d6:	b7e9                	j	800055a0 <exec+0x2c6>
  sz = sz1;
    800055d8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055dc:	4481                	li	s1,0
    800055de:	b7c9                	j	800055a0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055e0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055e4:	2b05                	addiw	s6,s6,1
    800055e6:	0389899b          	addiw	s3,s3,56
    800055ea:	e8845783          	lhu	a5,-376(s0)
    800055ee:	e2fb5be3          	bge	s6,a5,80005424 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055f2:	2981                	sext.w	s3,s3
    800055f4:	03800713          	li	a4,56
    800055f8:	86ce                	mv	a3,s3
    800055fa:	e1840613          	addi	a2,s0,-488
    800055fe:	4581                	li	a1,0
    80005600:	8526                	mv	a0,s1
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	a8e080e7          	jalr	-1394(ra) # 80004090 <readi>
    8000560a:	03800793          	li	a5,56
    8000560e:	f8f517e3          	bne	a0,a5,8000559c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005612:	e1842783          	lw	a5,-488(s0)
    80005616:	4705                	li	a4,1
    80005618:	fce796e3          	bne	a5,a4,800055e4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000561c:	e4043603          	ld	a2,-448(s0)
    80005620:	e3843783          	ld	a5,-456(s0)
    80005624:	f8f669e3          	bltu	a2,a5,800055b6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005628:	e2843783          	ld	a5,-472(s0)
    8000562c:	963e                	add	a2,a2,a5
    8000562e:	f8f667e3          	bltu	a2,a5,800055bc <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005632:	85ca                	mv	a1,s2
    80005634:	855e                	mv	a0,s7
    80005636:	ffffc097          	auipc	ra,0xffffc
    8000563a:	df4080e7          	jalr	-524(ra) # 8000142a <uvmalloc>
    8000563e:	e0a43423          	sd	a0,-504(s0)
    80005642:	d141                	beqz	a0,800055c2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005644:	e2843d03          	ld	s10,-472(s0)
    80005648:	df043783          	ld	a5,-528(s0)
    8000564c:	00fd77b3          	and	a5,s10,a5
    80005650:	fba1                	bnez	a5,800055a0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005652:	e2042d83          	lw	s11,-480(s0)
    80005656:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000565a:	f80c03e3          	beqz	s8,800055e0 <exec+0x306>
    8000565e:	8a62                	mv	s4,s8
    80005660:	4901                	li	s2,0
    80005662:	b345                	j	80005402 <exec+0x128>

0000000080005664 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005664:	7179                	addi	sp,sp,-48
    80005666:	f406                	sd	ra,40(sp)
    80005668:	f022                	sd	s0,32(sp)
    8000566a:	ec26                	sd	s1,24(sp)
    8000566c:	e84a                	sd	s2,16(sp)
    8000566e:	1800                	addi	s0,sp,48
    80005670:	892e                	mv	s2,a1
    80005672:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005674:	fdc40593          	addi	a1,s0,-36
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	980080e7          	jalr	-1664(ra) # 80002ff8 <argint>
    80005680:	04054063          	bltz	a0,800056c0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005684:	fdc42703          	lw	a4,-36(s0)
    80005688:	47bd                	li	a5,15
    8000568a:	02e7ed63          	bltu	a5,a4,800056c4 <argfd+0x60>
    8000568e:	ffffc097          	auipc	ra,0xffffc
    80005692:	404080e7          	jalr	1028(ra) # 80001a92 <myproc>
    80005696:	fdc42703          	lw	a4,-36(s0)
    8000569a:	01a70793          	addi	a5,a4,26
    8000569e:	078e                	slli	a5,a5,0x3
    800056a0:	953e                	add	a0,a0,a5
    800056a2:	611c                	ld	a5,0(a0)
    800056a4:	c395                	beqz	a5,800056c8 <argfd+0x64>
    return -1;
  if(pfd)
    800056a6:	00090463          	beqz	s2,800056ae <argfd+0x4a>
    *pfd = fd;
    800056aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056ae:	4501                	li	a0,0
  if(pf)
    800056b0:	c091                	beqz	s1,800056b4 <argfd+0x50>
    *pf = f;
    800056b2:	e09c                	sd	a5,0(s1)
}
    800056b4:	70a2                	ld	ra,40(sp)
    800056b6:	7402                	ld	s0,32(sp)
    800056b8:	64e2                	ld	s1,24(sp)
    800056ba:	6942                	ld	s2,16(sp)
    800056bc:	6145                	addi	sp,sp,48
    800056be:	8082                	ret
    return -1;
    800056c0:	557d                	li	a0,-1
    800056c2:	bfcd                	j	800056b4 <argfd+0x50>
    return -1;
    800056c4:	557d                	li	a0,-1
    800056c6:	b7fd                	j	800056b4 <argfd+0x50>
    800056c8:	557d                	li	a0,-1
    800056ca:	b7ed                	j	800056b4 <argfd+0x50>

00000000800056cc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056cc:	1101                	addi	sp,sp,-32
    800056ce:	ec06                	sd	ra,24(sp)
    800056d0:	e822                	sd	s0,16(sp)
    800056d2:	e426                	sd	s1,8(sp)
    800056d4:	1000                	addi	s0,sp,32
    800056d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056d8:	ffffc097          	auipc	ra,0xffffc
    800056dc:	3ba080e7          	jalr	954(ra) # 80001a92 <myproc>
    800056e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056e2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    800056e6:	4501                	li	a0,0
    800056e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056ea:	6398                	ld	a4,0(a5)
    800056ec:	cb19                	beqz	a4,80005702 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056ee:	2505                	addiw	a0,a0,1
    800056f0:	07a1                	addi	a5,a5,8
    800056f2:	fed51ce3          	bne	a0,a3,800056ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056f6:	557d                	li	a0,-1
}
    800056f8:	60e2                	ld	ra,24(sp)
    800056fa:	6442                	ld	s0,16(sp)
    800056fc:	64a2                	ld	s1,8(sp)
    800056fe:	6105                	addi	sp,sp,32
    80005700:	8082                	ret
      p->ofile[fd] = f;
    80005702:	01a50793          	addi	a5,a0,26
    80005706:	078e                	slli	a5,a5,0x3
    80005708:	963e                	add	a2,a2,a5
    8000570a:	e204                	sd	s1,0(a2)
      return fd;
    8000570c:	b7f5                	j	800056f8 <fdalloc+0x2c>

000000008000570e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000570e:	715d                	addi	sp,sp,-80
    80005710:	e486                	sd	ra,72(sp)
    80005712:	e0a2                	sd	s0,64(sp)
    80005714:	fc26                	sd	s1,56(sp)
    80005716:	f84a                	sd	s2,48(sp)
    80005718:	f44e                	sd	s3,40(sp)
    8000571a:	f052                	sd	s4,32(sp)
    8000571c:	ec56                	sd	s5,24(sp)
    8000571e:	0880                	addi	s0,sp,80
    80005720:	89ae                	mv	s3,a1
    80005722:	8ab2                	mv	s5,a2
    80005724:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005726:	fb040593          	addi	a1,s0,-80
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	e86080e7          	jalr	-378(ra) # 800045b0 <nameiparent>
    80005732:	892a                	mv	s2,a0
    80005734:	12050f63          	beqz	a0,80005872 <create+0x164>
    return 0;

  ilock(dp);
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	6a4080e7          	jalr	1700(ra) # 80003ddc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005740:	4601                	li	a2,0
    80005742:	fb040593          	addi	a1,s0,-80
    80005746:	854a                	mv	a0,s2
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	b78080e7          	jalr	-1160(ra) # 800042c0 <dirlookup>
    80005750:	84aa                	mv	s1,a0
    80005752:	c921                	beqz	a0,800057a2 <create+0x94>
    iunlockput(dp);
    80005754:	854a                	mv	a0,s2
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	8e8080e7          	jalr	-1816(ra) # 8000403e <iunlockput>
    ilock(ip);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	67c080e7          	jalr	1660(ra) # 80003ddc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005768:	2981                	sext.w	s3,s3
    8000576a:	4789                	li	a5,2
    8000576c:	02f99463          	bne	s3,a5,80005794 <create+0x86>
    80005770:	0444d783          	lhu	a5,68(s1)
    80005774:	37f9                	addiw	a5,a5,-2
    80005776:	17c2                	slli	a5,a5,0x30
    80005778:	93c1                	srli	a5,a5,0x30
    8000577a:	4705                	li	a4,1
    8000577c:	00f76c63          	bltu	a4,a5,80005794 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005780:	8526                	mv	a0,s1
    80005782:	60a6                	ld	ra,72(sp)
    80005784:	6406                	ld	s0,64(sp)
    80005786:	74e2                	ld	s1,56(sp)
    80005788:	7942                	ld	s2,48(sp)
    8000578a:	79a2                	ld	s3,40(sp)
    8000578c:	7a02                	ld	s4,32(sp)
    8000578e:	6ae2                	ld	s5,24(sp)
    80005790:	6161                	addi	sp,sp,80
    80005792:	8082                	ret
    iunlockput(ip);
    80005794:	8526                	mv	a0,s1
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	8a8080e7          	jalr	-1880(ra) # 8000403e <iunlockput>
    return 0;
    8000579e:	4481                	li	s1,0
    800057a0:	b7c5                	j	80005780 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057a2:	85ce                	mv	a1,s3
    800057a4:	00092503          	lw	a0,0(s2)
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	49c080e7          	jalr	1180(ra) # 80003c44 <ialloc>
    800057b0:	84aa                	mv	s1,a0
    800057b2:	c529                	beqz	a0,800057fc <create+0xee>
  ilock(ip);
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	628080e7          	jalr	1576(ra) # 80003ddc <ilock>
  ip->major = major;
    800057bc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057c0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057c4:	4785                	li	a5,1
    800057c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	546080e7          	jalr	1350(ra) # 80003d12 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057d4:	2981                	sext.w	s3,s3
    800057d6:	4785                	li	a5,1
    800057d8:	02f98a63          	beq	s3,a5,8000580c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057dc:	40d0                	lw	a2,4(s1)
    800057de:	fb040593          	addi	a1,s0,-80
    800057e2:	854a                	mv	a0,s2
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	cec080e7          	jalr	-788(ra) # 800044d0 <dirlink>
    800057ec:	06054b63          	bltz	a0,80005862 <create+0x154>
  iunlockput(dp);
    800057f0:	854a                	mv	a0,s2
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	84c080e7          	jalr	-1972(ra) # 8000403e <iunlockput>
  return ip;
    800057fa:	b759                	j	80005780 <create+0x72>
    panic("create: ialloc");
    800057fc:	00003517          	auipc	a0,0x3
    80005800:	04450513          	addi	a0,a0,68 # 80008840 <syscalls+0x2b0>
    80005804:	ffffb097          	auipc	ra,0xffffb
    80005808:	d3a080e7          	jalr	-710(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000580c:	04a95783          	lhu	a5,74(s2)
    80005810:	2785                	addiw	a5,a5,1
    80005812:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	4fa080e7          	jalr	1274(ra) # 80003d12 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005820:	40d0                	lw	a2,4(s1)
    80005822:	00003597          	auipc	a1,0x3
    80005826:	02e58593          	addi	a1,a1,46 # 80008850 <syscalls+0x2c0>
    8000582a:	8526                	mv	a0,s1
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	ca4080e7          	jalr	-860(ra) # 800044d0 <dirlink>
    80005834:	00054f63          	bltz	a0,80005852 <create+0x144>
    80005838:	00492603          	lw	a2,4(s2)
    8000583c:	00003597          	auipc	a1,0x3
    80005840:	01c58593          	addi	a1,a1,28 # 80008858 <syscalls+0x2c8>
    80005844:	8526                	mv	a0,s1
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	c8a080e7          	jalr	-886(ra) # 800044d0 <dirlink>
    8000584e:	f80557e3          	bgez	a0,800057dc <create+0xce>
      panic("create dots");
    80005852:	00003517          	auipc	a0,0x3
    80005856:	00e50513          	addi	a0,a0,14 # 80008860 <syscalls+0x2d0>
    8000585a:	ffffb097          	auipc	ra,0xffffb
    8000585e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005862:	00003517          	auipc	a0,0x3
    80005866:	00e50513          	addi	a0,a0,14 # 80008870 <syscalls+0x2e0>
    8000586a:	ffffb097          	auipc	ra,0xffffb
    8000586e:	cd4080e7          	jalr	-812(ra) # 8000053e <panic>
    return 0;
    80005872:	84aa                	mv	s1,a0
    80005874:	b731                	j	80005780 <create+0x72>

0000000080005876 <sys_dup>:
{
    80005876:	7179                	addi	sp,sp,-48
    80005878:	f406                	sd	ra,40(sp)
    8000587a:	f022                	sd	s0,32(sp)
    8000587c:	ec26                	sd	s1,24(sp)
    8000587e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005880:	fd840613          	addi	a2,s0,-40
    80005884:	4581                	li	a1,0
    80005886:	4501                	li	a0,0
    80005888:	00000097          	auipc	ra,0x0
    8000588c:	ddc080e7          	jalr	-548(ra) # 80005664 <argfd>
    return -1;
    80005890:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005892:	02054363          	bltz	a0,800058b8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005896:	fd843503          	ld	a0,-40(s0)
    8000589a:	00000097          	auipc	ra,0x0
    8000589e:	e32080e7          	jalr	-462(ra) # 800056cc <fdalloc>
    800058a2:	84aa                	mv	s1,a0
    return -1;
    800058a4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058a6:	00054963          	bltz	a0,800058b8 <sys_dup+0x42>
  filedup(f);
    800058aa:	fd843503          	ld	a0,-40(s0)
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	37a080e7          	jalr	890(ra) # 80004c28 <filedup>
  return fd;
    800058b6:	87a6                	mv	a5,s1
}
    800058b8:	853e                	mv	a0,a5
    800058ba:	70a2                	ld	ra,40(sp)
    800058bc:	7402                	ld	s0,32(sp)
    800058be:	64e2                	ld	s1,24(sp)
    800058c0:	6145                	addi	sp,sp,48
    800058c2:	8082                	ret

00000000800058c4 <sys_read>:
{
    800058c4:	7179                	addi	sp,sp,-48
    800058c6:	f406                	sd	ra,40(sp)
    800058c8:	f022                	sd	s0,32(sp)
    800058ca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058cc:	fe840613          	addi	a2,s0,-24
    800058d0:	4581                	li	a1,0
    800058d2:	4501                	li	a0,0
    800058d4:	00000097          	auipc	ra,0x0
    800058d8:	d90080e7          	jalr	-624(ra) # 80005664 <argfd>
    return -1;
    800058dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058de:	04054163          	bltz	a0,80005920 <sys_read+0x5c>
    800058e2:	fe440593          	addi	a1,s0,-28
    800058e6:	4509                	li	a0,2
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	710080e7          	jalr	1808(ra) # 80002ff8 <argint>
    return -1;
    800058f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058f2:	02054763          	bltz	a0,80005920 <sys_read+0x5c>
    800058f6:	fd840593          	addi	a1,s0,-40
    800058fa:	4505                	li	a0,1
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	71e080e7          	jalr	1822(ra) # 8000301a <argaddr>
    return -1;
    80005904:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005906:	00054d63          	bltz	a0,80005920 <sys_read+0x5c>
  return fileread(f, p, n);
    8000590a:	fe442603          	lw	a2,-28(s0)
    8000590e:	fd843583          	ld	a1,-40(s0)
    80005912:	fe843503          	ld	a0,-24(s0)
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	49e080e7          	jalr	1182(ra) # 80004db4 <fileread>
    8000591e:	87aa                	mv	a5,a0
}
    80005920:	853e                	mv	a0,a5
    80005922:	70a2                	ld	ra,40(sp)
    80005924:	7402                	ld	s0,32(sp)
    80005926:	6145                	addi	sp,sp,48
    80005928:	8082                	ret

000000008000592a <sys_write>:
{
    8000592a:	7179                	addi	sp,sp,-48
    8000592c:	f406                	sd	ra,40(sp)
    8000592e:	f022                	sd	s0,32(sp)
    80005930:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005932:	fe840613          	addi	a2,s0,-24
    80005936:	4581                	li	a1,0
    80005938:	4501                	li	a0,0
    8000593a:	00000097          	auipc	ra,0x0
    8000593e:	d2a080e7          	jalr	-726(ra) # 80005664 <argfd>
    return -1;
    80005942:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005944:	04054163          	bltz	a0,80005986 <sys_write+0x5c>
    80005948:	fe440593          	addi	a1,s0,-28
    8000594c:	4509                	li	a0,2
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	6aa080e7          	jalr	1706(ra) # 80002ff8 <argint>
    return -1;
    80005956:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005958:	02054763          	bltz	a0,80005986 <sys_write+0x5c>
    8000595c:	fd840593          	addi	a1,s0,-40
    80005960:	4505                	li	a0,1
    80005962:	ffffd097          	auipc	ra,0xffffd
    80005966:	6b8080e7          	jalr	1720(ra) # 8000301a <argaddr>
    return -1;
    8000596a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000596c:	00054d63          	bltz	a0,80005986 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005970:	fe442603          	lw	a2,-28(s0)
    80005974:	fd843583          	ld	a1,-40(s0)
    80005978:	fe843503          	ld	a0,-24(s0)
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	4fa080e7          	jalr	1274(ra) # 80004e76 <filewrite>
    80005984:	87aa                	mv	a5,a0
}
    80005986:	853e                	mv	a0,a5
    80005988:	70a2                	ld	ra,40(sp)
    8000598a:	7402                	ld	s0,32(sp)
    8000598c:	6145                	addi	sp,sp,48
    8000598e:	8082                	ret

0000000080005990 <sys_close>:
{
    80005990:	1101                	addi	sp,sp,-32
    80005992:	ec06                	sd	ra,24(sp)
    80005994:	e822                	sd	s0,16(sp)
    80005996:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005998:	fe040613          	addi	a2,s0,-32
    8000599c:	fec40593          	addi	a1,s0,-20
    800059a0:	4501                	li	a0,0
    800059a2:	00000097          	auipc	ra,0x0
    800059a6:	cc2080e7          	jalr	-830(ra) # 80005664 <argfd>
    return -1;
    800059aa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059ac:	02054463          	bltz	a0,800059d4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059b0:	ffffc097          	auipc	ra,0xffffc
    800059b4:	0e2080e7          	jalr	226(ra) # 80001a92 <myproc>
    800059b8:	fec42783          	lw	a5,-20(s0)
    800059bc:	07e9                	addi	a5,a5,26
    800059be:	078e                	slli	a5,a5,0x3
    800059c0:	97aa                	add	a5,a5,a0
    800059c2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059c6:	fe043503          	ld	a0,-32(s0)
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	2b0080e7          	jalr	688(ra) # 80004c7a <fileclose>
  return 0;
    800059d2:	4781                	li	a5,0
}
    800059d4:	853e                	mv	a0,a5
    800059d6:	60e2                	ld	ra,24(sp)
    800059d8:	6442                	ld	s0,16(sp)
    800059da:	6105                	addi	sp,sp,32
    800059dc:	8082                	ret

00000000800059de <sys_fstat>:
{
    800059de:	1101                	addi	sp,sp,-32
    800059e0:	ec06                	sd	ra,24(sp)
    800059e2:	e822                	sd	s0,16(sp)
    800059e4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059e6:	fe840613          	addi	a2,s0,-24
    800059ea:	4581                	li	a1,0
    800059ec:	4501                	li	a0,0
    800059ee:	00000097          	auipc	ra,0x0
    800059f2:	c76080e7          	jalr	-906(ra) # 80005664 <argfd>
    return -1;
    800059f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059f8:	02054563          	bltz	a0,80005a22 <sys_fstat+0x44>
    800059fc:	fe040593          	addi	a1,s0,-32
    80005a00:	4505                	li	a0,1
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	618080e7          	jalr	1560(ra) # 8000301a <argaddr>
    return -1;
    80005a0a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a0c:	00054b63          	bltz	a0,80005a22 <sys_fstat+0x44>
  return filestat(f, st);
    80005a10:	fe043583          	ld	a1,-32(s0)
    80005a14:	fe843503          	ld	a0,-24(s0)
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	32a080e7          	jalr	810(ra) # 80004d42 <filestat>
    80005a20:	87aa                	mv	a5,a0
}
    80005a22:	853e                	mv	a0,a5
    80005a24:	60e2                	ld	ra,24(sp)
    80005a26:	6442                	ld	s0,16(sp)
    80005a28:	6105                	addi	sp,sp,32
    80005a2a:	8082                	ret

0000000080005a2c <sys_link>:
{
    80005a2c:	7169                	addi	sp,sp,-304
    80005a2e:	f606                	sd	ra,296(sp)
    80005a30:	f222                	sd	s0,288(sp)
    80005a32:	ee26                	sd	s1,280(sp)
    80005a34:	ea4a                	sd	s2,272(sp)
    80005a36:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a38:	08000613          	li	a2,128
    80005a3c:	ed040593          	addi	a1,s0,-304
    80005a40:	4501                	li	a0,0
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	5fa080e7          	jalr	1530(ra) # 8000303c <argstr>
    return -1;
    80005a4a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a4c:	10054e63          	bltz	a0,80005b68 <sys_link+0x13c>
    80005a50:	08000613          	li	a2,128
    80005a54:	f5040593          	addi	a1,s0,-176
    80005a58:	4505                	li	a0,1
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	5e2080e7          	jalr	1506(ra) # 8000303c <argstr>
    return -1;
    80005a62:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a64:	10054263          	bltz	a0,80005b68 <sys_link+0x13c>
  begin_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	d46080e7          	jalr	-698(ra) # 800047ae <begin_op>
  if((ip = namei(old)) == 0){
    80005a70:	ed040513          	addi	a0,s0,-304
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	b1e080e7          	jalr	-1250(ra) # 80004592 <namei>
    80005a7c:	84aa                	mv	s1,a0
    80005a7e:	c551                	beqz	a0,80005b0a <sys_link+0xde>
  ilock(ip);
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	35c080e7          	jalr	860(ra) # 80003ddc <ilock>
  if(ip->type == T_DIR){
    80005a88:	04449703          	lh	a4,68(s1)
    80005a8c:	4785                	li	a5,1
    80005a8e:	08f70463          	beq	a4,a5,80005b16 <sys_link+0xea>
  ip->nlink++;
    80005a92:	04a4d783          	lhu	a5,74(s1)
    80005a96:	2785                	addiw	a5,a5,1
    80005a98:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	274080e7          	jalr	628(ra) # 80003d12 <iupdate>
  iunlock(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	3f6080e7          	jalr	1014(ra) # 80003e9e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ab0:	fd040593          	addi	a1,s0,-48
    80005ab4:	f5040513          	addi	a0,s0,-176
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	af8080e7          	jalr	-1288(ra) # 800045b0 <nameiparent>
    80005ac0:	892a                	mv	s2,a0
    80005ac2:	c935                	beqz	a0,80005b36 <sys_link+0x10a>
  ilock(dp);
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	318080e7          	jalr	792(ra) # 80003ddc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005acc:	00092703          	lw	a4,0(s2)
    80005ad0:	409c                	lw	a5,0(s1)
    80005ad2:	04f71d63          	bne	a4,a5,80005b2c <sys_link+0x100>
    80005ad6:	40d0                	lw	a2,4(s1)
    80005ad8:	fd040593          	addi	a1,s0,-48
    80005adc:	854a                	mv	a0,s2
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	9f2080e7          	jalr	-1550(ra) # 800044d0 <dirlink>
    80005ae6:	04054363          	bltz	a0,80005b2c <sys_link+0x100>
  iunlockput(dp);
    80005aea:	854a                	mv	a0,s2
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	552080e7          	jalr	1362(ra) # 8000403e <iunlockput>
  iput(ip);
    80005af4:	8526                	mv	a0,s1
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	4a0080e7          	jalr	1184(ra) # 80003f96 <iput>
  end_op();
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	d30080e7          	jalr	-720(ra) # 8000482e <end_op>
  return 0;
    80005b06:	4781                	li	a5,0
    80005b08:	a085                	j	80005b68 <sys_link+0x13c>
    end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	d24080e7          	jalr	-732(ra) # 8000482e <end_op>
    return -1;
    80005b12:	57fd                	li	a5,-1
    80005b14:	a891                	j	80005b68 <sys_link+0x13c>
    iunlockput(ip);
    80005b16:	8526                	mv	a0,s1
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	526080e7          	jalr	1318(ra) # 8000403e <iunlockput>
    end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	d0e080e7          	jalr	-754(ra) # 8000482e <end_op>
    return -1;
    80005b28:	57fd                	li	a5,-1
    80005b2a:	a83d                	j	80005b68 <sys_link+0x13c>
    iunlockput(dp);
    80005b2c:	854a                	mv	a0,s2
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	510080e7          	jalr	1296(ra) # 8000403e <iunlockput>
  ilock(ip);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	2a4080e7          	jalr	676(ra) # 80003ddc <ilock>
  ip->nlink--;
    80005b40:	04a4d783          	lhu	a5,74(s1)
    80005b44:	37fd                	addiw	a5,a5,-1
    80005b46:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b4a:	8526                	mv	a0,s1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	1c6080e7          	jalr	454(ra) # 80003d12 <iupdate>
  iunlockput(ip);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	4e8080e7          	jalr	1256(ra) # 8000403e <iunlockput>
  end_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	cd0080e7          	jalr	-816(ra) # 8000482e <end_op>
  return -1;
    80005b66:	57fd                	li	a5,-1
}
    80005b68:	853e                	mv	a0,a5
    80005b6a:	70b2                	ld	ra,296(sp)
    80005b6c:	7412                	ld	s0,288(sp)
    80005b6e:	64f2                	ld	s1,280(sp)
    80005b70:	6952                	ld	s2,272(sp)
    80005b72:	6155                	addi	sp,sp,304
    80005b74:	8082                	ret

0000000080005b76 <sys_unlink>:
{
    80005b76:	7151                	addi	sp,sp,-240
    80005b78:	f586                	sd	ra,232(sp)
    80005b7a:	f1a2                	sd	s0,224(sp)
    80005b7c:	eda6                	sd	s1,216(sp)
    80005b7e:	e9ca                	sd	s2,208(sp)
    80005b80:	e5ce                	sd	s3,200(sp)
    80005b82:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b84:	08000613          	li	a2,128
    80005b88:	f3040593          	addi	a1,s0,-208
    80005b8c:	4501                	li	a0,0
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	4ae080e7          	jalr	1198(ra) # 8000303c <argstr>
    80005b96:	18054163          	bltz	a0,80005d18 <sys_unlink+0x1a2>
  begin_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	c14080e7          	jalr	-1004(ra) # 800047ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ba2:	fb040593          	addi	a1,s0,-80
    80005ba6:	f3040513          	addi	a0,s0,-208
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	a06080e7          	jalr	-1530(ra) # 800045b0 <nameiparent>
    80005bb2:	84aa                	mv	s1,a0
    80005bb4:	c979                	beqz	a0,80005c8a <sys_unlink+0x114>
  ilock(dp);
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	226080e7          	jalr	550(ra) # 80003ddc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bbe:	00003597          	auipc	a1,0x3
    80005bc2:	c9258593          	addi	a1,a1,-878 # 80008850 <syscalls+0x2c0>
    80005bc6:	fb040513          	addi	a0,s0,-80
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	6dc080e7          	jalr	1756(ra) # 800042a6 <namecmp>
    80005bd2:	14050a63          	beqz	a0,80005d26 <sys_unlink+0x1b0>
    80005bd6:	00003597          	auipc	a1,0x3
    80005bda:	c8258593          	addi	a1,a1,-894 # 80008858 <syscalls+0x2c8>
    80005bde:	fb040513          	addi	a0,s0,-80
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	6c4080e7          	jalr	1732(ra) # 800042a6 <namecmp>
    80005bea:	12050e63          	beqz	a0,80005d26 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bee:	f2c40613          	addi	a2,s0,-212
    80005bf2:	fb040593          	addi	a1,s0,-80
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	6c8080e7          	jalr	1736(ra) # 800042c0 <dirlookup>
    80005c00:	892a                	mv	s2,a0
    80005c02:	12050263          	beqz	a0,80005d26 <sys_unlink+0x1b0>
  ilock(ip);
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	1d6080e7          	jalr	470(ra) # 80003ddc <ilock>
  if(ip->nlink < 1)
    80005c0e:	04a91783          	lh	a5,74(s2)
    80005c12:	08f05263          	blez	a5,80005c96 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c16:	04491703          	lh	a4,68(s2)
    80005c1a:	4785                	li	a5,1
    80005c1c:	08f70563          	beq	a4,a5,80005ca6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c20:	4641                	li	a2,16
    80005c22:	4581                	li	a1,0
    80005c24:	fc040513          	addi	a0,s0,-64
    80005c28:	ffffb097          	auipc	ra,0xffffb
    80005c2c:	0b8080e7          	jalr	184(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c30:	4741                	li	a4,16
    80005c32:	f2c42683          	lw	a3,-212(s0)
    80005c36:	fc040613          	addi	a2,s0,-64
    80005c3a:	4581                	li	a1,0
    80005c3c:	8526                	mv	a0,s1
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	54a080e7          	jalr	1354(ra) # 80004188 <writei>
    80005c46:	47c1                	li	a5,16
    80005c48:	0af51563          	bne	a0,a5,80005cf2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c4c:	04491703          	lh	a4,68(s2)
    80005c50:	4785                	li	a5,1
    80005c52:	0af70863          	beq	a4,a5,80005d02 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	3e6080e7          	jalr	998(ra) # 8000403e <iunlockput>
  ip->nlink--;
    80005c60:	04a95783          	lhu	a5,74(s2)
    80005c64:	37fd                	addiw	a5,a5,-1
    80005c66:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c6a:	854a                	mv	a0,s2
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	0a6080e7          	jalr	166(ra) # 80003d12 <iupdate>
  iunlockput(ip);
    80005c74:	854a                	mv	a0,s2
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	3c8080e7          	jalr	968(ra) # 8000403e <iunlockput>
  end_op();
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	bb0080e7          	jalr	-1104(ra) # 8000482e <end_op>
  return 0;
    80005c86:	4501                	li	a0,0
    80005c88:	a84d                	j	80005d3a <sys_unlink+0x1c4>
    end_op();
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	ba4080e7          	jalr	-1116(ra) # 8000482e <end_op>
    return -1;
    80005c92:	557d                	li	a0,-1
    80005c94:	a05d                	j	80005d3a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c96:	00003517          	auipc	a0,0x3
    80005c9a:	bea50513          	addi	a0,a0,-1046 # 80008880 <syscalls+0x2f0>
    80005c9e:	ffffb097          	auipc	ra,0xffffb
    80005ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ca6:	04c92703          	lw	a4,76(s2)
    80005caa:	02000793          	li	a5,32
    80005cae:	f6e7f9e3          	bgeu	a5,a4,80005c20 <sys_unlink+0xaa>
    80005cb2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cb6:	4741                	li	a4,16
    80005cb8:	86ce                	mv	a3,s3
    80005cba:	f1840613          	addi	a2,s0,-232
    80005cbe:	4581                	li	a1,0
    80005cc0:	854a                	mv	a0,s2
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	3ce080e7          	jalr	974(ra) # 80004090 <readi>
    80005cca:	47c1                	li	a5,16
    80005ccc:	00f51b63          	bne	a0,a5,80005ce2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cd0:	f1845783          	lhu	a5,-232(s0)
    80005cd4:	e7a1                	bnez	a5,80005d1c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cd6:	29c1                	addiw	s3,s3,16
    80005cd8:	04c92783          	lw	a5,76(s2)
    80005cdc:	fcf9ede3          	bltu	s3,a5,80005cb6 <sys_unlink+0x140>
    80005ce0:	b781                	j	80005c20 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ce2:	00003517          	auipc	a0,0x3
    80005ce6:	bb650513          	addi	a0,a0,-1098 # 80008898 <syscalls+0x308>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cf2:	00003517          	auipc	a0,0x3
    80005cf6:	bbe50513          	addi	a0,a0,-1090 # 800088b0 <syscalls+0x320>
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>
    dp->nlink--;
    80005d02:	04a4d783          	lhu	a5,74(s1)
    80005d06:	37fd                	addiw	a5,a5,-1
    80005d08:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d0c:	8526                	mv	a0,s1
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	004080e7          	jalr	4(ra) # 80003d12 <iupdate>
    80005d16:	b781                	j	80005c56 <sys_unlink+0xe0>
    return -1;
    80005d18:	557d                	li	a0,-1
    80005d1a:	a005                	j	80005d3a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d1c:	854a                	mv	a0,s2
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	320080e7          	jalr	800(ra) # 8000403e <iunlockput>
  iunlockput(dp);
    80005d26:	8526                	mv	a0,s1
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	316080e7          	jalr	790(ra) # 8000403e <iunlockput>
  end_op();
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	afe080e7          	jalr	-1282(ra) # 8000482e <end_op>
  return -1;
    80005d38:	557d                	li	a0,-1
}
    80005d3a:	70ae                	ld	ra,232(sp)
    80005d3c:	740e                	ld	s0,224(sp)
    80005d3e:	64ee                	ld	s1,216(sp)
    80005d40:	694e                	ld	s2,208(sp)
    80005d42:	69ae                	ld	s3,200(sp)
    80005d44:	616d                	addi	sp,sp,240
    80005d46:	8082                	ret

0000000080005d48 <sys_open>:

uint64
sys_open(void)
{
    80005d48:	7131                	addi	sp,sp,-192
    80005d4a:	fd06                	sd	ra,184(sp)
    80005d4c:	f922                	sd	s0,176(sp)
    80005d4e:	f526                	sd	s1,168(sp)
    80005d50:	f14a                	sd	s2,160(sp)
    80005d52:	ed4e                	sd	s3,152(sp)
    80005d54:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d56:	08000613          	li	a2,128
    80005d5a:	f5040593          	addi	a1,s0,-176
    80005d5e:	4501                	li	a0,0
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	2dc080e7          	jalr	732(ra) # 8000303c <argstr>
    return -1;
    80005d68:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d6a:	0c054163          	bltz	a0,80005e2c <sys_open+0xe4>
    80005d6e:	f4c40593          	addi	a1,s0,-180
    80005d72:	4505                	li	a0,1
    80005d74:	ffffd097          	auipc	ra,0xffffd
    80005d78:	284080e7          	jalr	644(ra) # 80002ff8 <argint>
    80005d7c:	0a054863          	bltz	a0,80005e2c <sys_open+0xe4>

  begin_op();
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	a2e080e7          	jalr	-1490(ra) # 800047ae <begin_op>

  if(omode & O_CREATE){
    80005d88:	f4c42783          	lw	a5,-180(s0)
    80005d8c:	2007f793          	andi	a5,a5,512
    80005d90:	cbdd                	beqz	a5,80005e46 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d92:	4681                	li	a3,0
    80005d94:	4601                	li	a2,0
    80005d96:	4589                	li	a1,2
    80005d98:	f5040513          	addi	a0,s0,-176
    80005d9c:	00000097          	auipc	ra,0x0
    80005da0:	972080e7          	jalr	-1678(ra) # 8000570e <create>
    80005da4:	892a                	mv	s2,a0
    if(ip == 0){
    80005da6:	c959                	beqz	a0,80005e3c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005da8:	04491703          	lh	a4,68(s2)
    80005dac:	478d                	li	a5,3
    80005dae:	00f71763          	bne	a4,a5,80005dbc <sys_open+0x74>
    80005db2:	04695703          	lhu	a4,70(s2)
    80005db6:	47a5                	li	a5,9
    80005db8:	0ce7ec63          	bltu	a5,a4,80005e90 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	e02080e7          	jalr	-510(ra) # 80004bbe <filealloc>
    80005dc4:	89aa                	mv	s3,a0
    80005dc6:	10050263          	beqz	a0,80005eca <sys_open+0x182>
    80005dca:	00000097          	auipc	ra,0x0
    80005dce:	902080e7          	jalr	-1790(ra) # 800056cc <fdalloc>
    80005dd2:	84aa                	mv	s1,a0
    80005dd4:	0e054663          	bltz	a0,80005ec0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dd8:	04491703          	lh	a4,68(s2)
    80005ddc:	478d                	li	a5,3
    80005dde:	0cf70463          	beq	a4,a5,80005ea6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005de2:	4789                	li	a5,2
    80005de4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005de8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dec:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005df0:	f4c42783          	lw	a5,-180(s0)
    80005df4:	0017c713          	xori	a4,a5,1
    80005df8:	8b05                	andi	a4,a4,1
    80005dfa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dfe:	0037f713          	andi	a4,a5,3
    80005e02:	00e03733          	snez	a4,a4
    80005e06:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e0a:	4007f793          	andi	a5,a5,1024
    80005e0e:	c791                	beqz	a5,80005e1a <sys_open+0xd2>
    80005e10:	04491703          	lh	a4,68(s2)
    80005e14:	4789                	li	a5,2
    80005e16:	08f70f63          	beq	a4,a5,80005eb4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e1a:	854a                	mv	a0,s2
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	082080e7          	jalr	130(ra) # 80003e9e <iunlock>
  end_op();
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	a0a080e7          	jalr	-1526(ra) # 8000482e <end_op>

  return fd;
}
    80005e2c:	8526                	mv	a0,s1
    80005e2e:	70ea                	ld	ra,184(sp)
    80005e30:	744a                	ld	s0,176(sp)
    80005e32:	74aa                	ld	s1,168(sp)
    80005e34:	790a                	ld	s2,160(sp)
    80005e36:	69ea                	ld	s3,152(sp)
    80005e38:	6129                	addi	sp,sp,192
    80005e3a:	8082                	ret
      end_op();
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	9f2080e7          	jalr	-1550(ra) # 8000482e <end_op>
      return -1;
    80005e44:	b7e5                	j	80005e2c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e46:	f5040513          	addi	a0,s0,-176
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	748080e7          	jalr	1864(ra) # 80004592 <namei>
    80005e52:	892a                	mv	s2,a0
    80005e54:	c905                	beqz	a0,80005e84 <sys_open+0x13c>
    ilock(ip);
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	f86080e7          	jalr	-122(ra) # 80003ddc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e5e:	04491703          	lh	a4,68(s2)
    80005e62:	4785                	li	a5,1
    80005e64:	f4f712e3          	bne	a4,a5,80005da8 <sys_open+0x60>
    80005e68:	f4c42783          	lw	a5,-180(s0)
    80005e6c:	dba1                	beqz	a5,80005dbc <sys_open+0x74>
      iunlockput(ip);
    80005e6e:	854a                	mv	a0,s2
    80005e70:	ffffe097          	auipc	ra,0xffffe
    80005e74:	1ce080e7          	jalr	462(ra) # 8000403e <iunlockput>
      end_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	9b6080e7          	jalr	-1610(ra) # 8000482e <end_op>
      return -1;
    80005e80:	54fd                	li	s1,-1
    80005e82:	b76d                	j	80005e2c <sys_open+0xe4>
      end_op();
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	9aa080e7          	jalr	-1622(ra) # 8000482e <end_op>
      return -1;
    80005e8c:	54fd                	li	s1,-1
    80005e8e:	bf79                	j	80005e2c <sys_open+0xe4>
    iunlockput(ip);
    80005e90:	854a                	mv	a0,s2
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	1ac080e7          	jalr	428(ra) # 8000403e <iunlockput>
    end_op();
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	994080e7          	jalr	-1644(ra) # 8000482e <end_op>
    return -1;
    80005ea2:	54fd                	li	s1,-1
    80005ea4:	b761                	j	80005e2c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ea6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eaa:	04691783          	lh	a5,70(s2)
    80005eae:	02f99223          	sh	a5,36(s3)
    80005eb2:	bf2d                	j	80005dec <sys_open+0xa4>
    itrunc(ip);
    80005eb4:	854a                	mv	a0,s2
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	034080e7          	jalr	52(ra) # 80003eea <itrunc>
    80005ebe:	bfb1                	j	80005e1a <sys_open+0xd2>
      fileclose(f);
    80005ec0:	854e                	mv	a0,s3
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	db8080e7          	jalr	-584(ra) # 80004c7a <fileclose>
    iunlockput(ip);
    80005eca:	854a                	mv	a0,s2
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	172080e7          	jalr	370(ra) # 8000403e <iunlockput>
    end_op();
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	95a080e7          	jalr	-1702(ra) # 8000482e <end_op>
    return -1;
    80005edc:	54fd                	li	s1,-1
    80005ede:	b7b9                	j	80005e2c <sys_open+0xe4>

0000000080005ee0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ee0:	7175                	addi	sp,sp,-144
    80005ee2:	e506                	sd	ra,136(sp)
    80005ee4:	e122                	sd	s0,128(sp)
    80005ee6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ee8:	fffff097          	auipc	ra,0xfffff
    80005eec:	8c6080e7          	jalr	-1850(ra) # 800047ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ef0:	08000613          	li	a2,128
    80005ef4:	f7040593          	addi	a1,s0,-144
    80005ef8:	4501                	li	a0,0
    80005efa:	ffffd097          	auipc	ra,0xffffd
    80005efe:	142080e7          	jalr	322(ra) # 8000303c <argstr>
    80005f02:	02054963          	bltz	a0,80005f34 <sys_mkdir+0x54>
    80005f06:	4681                	li	a3,0
    80005f08:	4601                	li	a2,0
    80005f0a:	4585                	li	a1,1
    80005f0c:	f7040513          	addi	a0,s0,-144
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	7fe080e7          	jalr	2046(ra) # 8000570e <create>
    80005f18:	cd11                	beqz	a0,80005f34 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	124080e7          	jalr	292(ra) # 8000403e <iunlockput>
  end_op();
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	90c080e7          	jalr	-1780(ra) # 8000482e <end_op>
  return 0;
    80005f2a:	4501                	li	a0,0
}
    80005f2c:	60aa                	ld	ra,136(sp)
    80005f2e:	640a                	ld	s0,128(sp)
    80005f30:	6149                	addi	sp,sp,144
    80005f32:	8082                	ret
    end_op();
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	8fa080e7          	jalr	-1798(ra) # 8000482e <end_op>
    return -1;
    80005f3c:	557d                	li	a0,-1
    80005f3e:	b7fd                	j	80005f2c <sys_mkdir+0x4c>

0000000080005f40 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f40:	7135                	addi	sp,sp,-160
    80005f42:	ed06                	sd	ra,152(sp)
    80005f44:	e922                	sd	s0,144(sp)
    80005f46:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	866080e7          	jalr	-1946(ra) # 800047ae <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f50:	08000613          	li	a2,128
    80005f54:	f7040593          	addi	a1,s0,-144
    80005f58:	4501                	li	a0,0
    80005f5a:	ffffd097          	auipc	ra,0xffffd
    80005f5e:	0e2080e7          	jalr	226(ra) # 8000303c <argstr>
    80005f62:	04054a63          	bltz	a0,80005fb6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f66:	f6c40593          	addi	a1,s0,-148
    80005f6a:	4505                	li	a0,1
    80005f6c:	ffffd097          	auipc	ra,0xffffd
    80005f70:	08c080e7          	jalr	140(ra) # 80002ff8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f74:	04054163          	bltz	a0,80005fb6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f78:	f6840593          	addi	a1,s0,-152
    80005f7c:	4509                	li	a0,2
    80005f7e:	ffffd097          	auipc	ra,0xffffd
    80005f82:	07a080e7          	jalr	122(ra) # 80002ff8 <argint>
     argint(1, &major) < 0 ||
    80005f86:	02054863          	bltz	a0,80005fb6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f8a:	f6841683          	lh	a3,-152(s0)
    80005f8e:	f6c41603          	lh	a2,-148(s0)
    80005f92:	458d                	li	a1,3
    80005f94:	f7040513          	addi	a0,s0,-144
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	776080e7          	jalr	1910(ra) # 8000570e <create>
     argint(2, &minor) < 0 ||
    80005fa0:	c919                	beqz	a0,80005fb6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	09c080e7          	jalr	156(ra) # 8000403e <iunlockput>
  end_op();
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	884080e7          	jalr	-1916(ra) # 8000482e <end_op>
  return 0;
    80005fb2:	4501                	li	a0,0
    80005fb4:	a031                	j	80005fc0 <sys_mknod+0x80>
    end_op();
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	878080e7          	jalr	-1928(ra) # 8000482e <end_op>
    return -1;
    80005fbe:	557d                	li	a0,-1
}
    80005fc0:	60ea                	ld	ra,152(sp)
    80005fc2:	644a                	ld	s0,144(sp)
    80005fc4:	610d                	addi	sp,sp,160
    80005fc6:	8082                	ret

0000000080005fc8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fc8:	7135                	addi	sp,sp,-160
    80005fca:	ed06                	sd	ra,152(sp)
    80005fcc:	e922                	sd	s0,144(sp)
    80005fce:	e526                	sd	s1,136(sp)
    80005fd0:	e14a                	sd	s2,128(sp)
    80005fd2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fd4:	ffffc097          	auipc	ra,0xffffc
    80005fd8:	abe080e7          	jalr	-1346(ra) # 80001a92 <myproc>
    80005fdc:	892a                	mv	s2,a0
  
  begin_op();
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	7d0080e7          	jalr	2000(ra) # 800047ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fe6:	08000613          	li	a2,128
    80005fea:	f6040593          	addi	a1,s0,-160
    80005fee:	4501                	li	a0,0
    80005ff0:	ffffd097          	auipc	ra,0xffffd
    80005ff4:	04c080e7          	jalr	76(ra) # 8000303c <argstr>
    80005ff8:	04054b63          	bltz	a0,8000604e <sys_chdir+0x86>
    80005ffc:	f6040513          	addi	a0,s0,-160
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	592080e7          	jalr	1426(ra) # 80004592 <namei>
    80006008:	84aa                	mv	s1,a0
    8000600a:	c131                	beqz	a0,8000604e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	dd0080e7          	jalr	-560(ra) # 80003ddc <ilock>
  if(ip->type != T_DIR){
    80006014:	04449703          	lh	a4,68(s1)
    80006018:	4785                	li	a5,1
    8000601a:	04f71063          	bne	a4,a5,8000605a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000601e:	8526                	mv	a0,s1
    80006020:	ffffe097          	auipc	ra,0xffffe
    80006024:	e7e080e7          	jalr	-386(ra) # 80003e9e <iunlock>
  iput(p->cwd);
    80006028:	15093503          	ld	a0,336(s2)
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	f6a080e7          	jalr	-150(ra) # 80003f96 <iput>
  end_op();
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	7fa080e7          	jalr	2042(ra) # 8000482e <end_op>
  p->cwd = ip;
    8000603c:	14993823          	sd	s1,336(s2)
  return 0;
    80006040:	4501                	li	a0,0
}
    80006042:	60ea                	ld	ra,152(sp)
    80006044:	644a                	ld	s0,144(sp)
    80006046:	64aa                	ld	s1,136(sp)
    80006048:	690a                	ld	s2,128(sp)
    8000604a:	610d                	addi	sp,sp,160
    8000604c:	8082                	ret
    end_op();
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	7e0080e7          	jalr	2016(ra) # 8000482e <end_op>
    return -1;
    80006056:	557d                	li	a0,-1
    80006058:	b7ed                	j	80006042 <sys_chdir+0x7a>
    iunlockput(ip);
    8000605a:	8526                	mv	a0,s1
    8000605c:	ffffe097          	auipc	ra,0xffffe
    80006060:	fe2080e7          	jalr	-30(ra) # 8000403e <iunlockput>
    end_op();
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	7ca080e7          	jalr	1994(ra) # 8000482e <end_op>
    return -1;
    8000606c:	557d                	li	a0,-1
    8000606e:	bfd1                	j	80006042 <sys_chdir+0x7a>

0000000080006070 <sys_exec>:

uint64
sys_exec(void)
{
    80006070:	7145                	addi	sp,sp,-464
    80006072:	e786                	sd	ra,456(sp)
    80006074:	e3a2                	sd	s0,448(sp)
    80006076:	ff26                	sd	s1,440(sp)
    80006078:	fb4a                	sd	s2,432(sp)
    8000607a:	f74e                	sd	s3,424(sp)
    8000607c:	f352                	sd	s4,416(sp)
    8000607e:	ef56                	sd	s5,408(sp)
    80006080:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006082:	08000613          	li	a2,128
    80006086:	f4040593          	addi	a1,s0,-192
    8000608a:	4501                	li	a0,0
    8000608c:	ffffd097          	auipc	ra,0xffffd
    80006090:	fb0080e7          	jalr	-80(ra) # 8000303c <argstr>
    return -1;
    80006094:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006096:	0c054a63          	bltz	a0,8000616a <sys_exec+0xfa>
    8000609a:	e3840593          	addi	a1,s0,-456
    8000609e:	4505                	li	a0,1
    800060a0:	ffffd097          	auipc	ra,0xffffd
    800060a4:	f7a080e7          	jalr	-134(ra) # 8000301a <argaddr>
    800060a8:	0c054163          	bltz	a0,8000616a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060ac:	10000613          	li	a2,256
    800060b0:	4581                	li	a1,0
    800060b2:	e4040513          	addi	a0,s0,-448
    800060b6:	ffffb097          	auipc	ra,0xffffb
    800060ba:	c2a080e7          	jalr	-982(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060be:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060c2:	89a6                	mv	s3,s1
    800060c4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060c6:	02000a13          	li	s4,32
    800060ca:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060ce:	00391513          	slli	a0,s2,0x3
    800060d2:	e3040593          	addi	a1,s0,-464
    800060d6:	e3843783          	ld	a5,-456(s0)
    800060da:	953e                	add	a0,a0,a5
    800060dc:	ffffd097          	auipc	ra,0xffffd
    800060e0:	e82080e7          	jalr	-382(ra) # 80002f5e <fetchaddr>
    800060e4:	02054a63          	bltz	a0,80006118 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060e8:	e3043783          	ld	a5,-464(s0)
    800060ec:	c3b9                	beqz	a5,80006132 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	a06080e7          	jalr	-1530(ra) # 80000af4 <kalloc>
    800060f6:	85aa                	mv	a1,a0
    800060f8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060fc:	cd11                	beqz	a0,80006118 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060fe:	6605                	lui	a2,0x1
    80006100:	e3043503          	ld	a0,-464(s0)
    80006104:	ffffd097          	auipc	ra,0xffffd
    80006108:	eac080e7          	jalr	-340(ra) # 80002fb0 <fetchstr>
    8000610c:	00054663          	bltz	a0,80006118 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006110:	0905                	addi	s2,s2,1
    80006112:	09a1                	addi	s3,s3,8
    80006114:	fb491be3          	bne	s2,s4,800060ca <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006118:	10048913          	addi	s2,s1,256
    8000611c:	6088                	ld	a0,0(s1)
    8000611e:	c529                	beqz	a0,80006168 <sys_exec+0xf8>
    kfree(argv[i]);
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	8d8080e7          	jalr	-1832(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006128:	04a1                	addi	s1,s1,8
    8000612a:	ff2499e3          	bne	s1,s2,8000611c <sys_exec+0xac>
  return -1;
    8000612e:	597d                	li	s2,-1
    80006130:	a82d                	j	8000616a <sys_exec+0xfa>
      argv[i] = 0;
    80006132:	0a8e                	slli	s5,s5,0x3
    80006134:	fc040793          	addi	a5,s0,-64
    80006138:	9abe                	add	s5,s5,a5
    8000613a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000613e:	e4040593          	addi	a1,s0,-448
    80006142:	f4040513          	addi	a0,s0,-192
    80006146:	fffff097          	auipc	ra,0xfffff
    8000614a:	194080e7          	jalr	404(ra) # 800052da <exec>
    8000614e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006150:	10048993          	addi	s3,s1,256
    80006154:	6088                	ld	a0,0(s1)
    80006156:	c911                	beqz	a0,8000616a <sys_exec+0xfa>
    kfree(argv[i]);
    80006158:	ffffb097          	auipc	ra,0xffffb
    8000615c:	8a0080e7          	jalr	-1888(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006160:	04a1                	addi	s1,s1,8
    80006162:	ff3499e3          	bne	s1,s3,80006154 <sys_exec+0xe4>
    80006166:	a011                	j	8000616a <sys_exec+0xfa>
  return -1;
    80006168:	597d                	li	s2,-1
}
    8000616a:	854a                	mv	a0,s2
    8000616c:	60be                	ld	ra,456(sp)
    8000616e:	641e                	ld	s0,448(sp)
    80006170:	74fa                	ld	s1,440(sp)
    80006172:	795a                	ld	s2,432(sp)
    80006174:	79ba                	ld	s3,424(sp)
    80006176:	7a1a                	ld	s4,416(sp)
    80006178:	6afa                	ld	s5,408(sp)
    8000617a:	6179                	addi	sp,sp,464
    8000617c:	8082                	ret

000000008000617e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000617e:	7139                	addi	sp,sp,-64
    80006180:	fc06                	sd	ra,56(sp)
    80006182:	f822                	sd	s0,48(sp)
    80006184:	f426                	sd	s1,40(sp)
    80006186:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	90a080e7          	jalr	-1782(ra) # 80001a92 <myproc>
    80006190:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006192:	fd840593          	addi	a1,s0,-40
    80006196:	4501                	li	a0,0
    80006198:	ffffd097          	auipc	ra,0xffffd
    8000619c:	e82080e7          	jalr	-382(ra) # 8000301a <argaddr>
    return -1;
    800061a0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061a2:	0e054063          	bltz	a0,80006282 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061a6:	fc840593          	addi	a1,s0,-56
    800061aa:	fd040513          	addi	a0,s0,-48
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	dfc080e7          	jalr	-516(ra) # 80004faa <pipealloc>
    return -1;
    800061b6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061b8:	0c054563          	bltz	a0,80006282 <sys_pipe+0x104>
  fd0 = -1;
    800061bc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061c0:	fd043503          	ld	a0,-48(s0)
    800061c4:	fffff097          	auipc	ra,0xfffff
    800061c8:	508080e7          	jalr	1288(ra) # 800056cc <fdalloc>
    800061cc:	fca42223          	sw	a0,-60(s0)
    800061d0:	08054c63          	bltz	a0,80006268 <sys_pipe+0xea>
    800061d4:	fc843503          	ld	a0,-56(s0)
    800061d8:	fffff097          	auipc	ra,0xfffff
    800061dc:	4f4080e7          	jalr	1268(ra) # 800056cc <fdalloc>
    800061e0:	fca42023          	sw	a0,-64(s0)
    800061e4:	06054863          	bltz	a0,80006254 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061e8:	4691                	li	a3,4
    800061ea:	fc440613          	addi	a2,s0,-60
    800061ee:	fd843583          	ld	a1,-40(s0)
    800061f2:	68a8                	ld	a0,80(s1)
    800061f4:	ffffb097          	auipc	ra,0xffffb
    800061f8:	486080e7          	jalr	1158(ra) # 8000167a <copyout>
    800061fc:	02054063          	bltz	a0,8000621c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006200:	4691                	li	a3,4
    80006202:	fc040613          	addi	a2,s0,-64
    80006206:	fd843583          	ld	a1,-40(s0)
    8000620a:	0591                	addi	a1,a1,4
    8000620c:	68a8                	ld	a0,80(s1)
    8000620e:	ffffb097          	auipc	ra,0xffffb
    80006212:	46c080e7          	jalr	1132(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006216:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006218:	06055563          	bgez	a0,80006282 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000621c:	fc442783          	lw	a5,-60(s0)
    80006220:	07e9                	addi	a5,a5,26
    80006222:	078e                	slli	a5,a5,0x3
    80006224:	97a6                	add	a5,a5,s1
    80006226:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000622a:	fc042503          	lw	a0,-64(s0)
    8000622e:	0569                	addi	a0,a0,26
    80006230:	050e                	slli	a0,a0,0x3
    80006232:	9526                	add	a0,a0,s1
    80006234:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006238:	fd043503          	ld	a0,-48(s0)
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	a3e080e7          	jalr	-1474(ra) # 80004c7a <fileclose>
    fileclose(wf);
    80006244:	fc843503          	ld	a0,-56(s0)
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	a32080e7          	jalr	-1486(ra) # 80004c7a <fileclose>
    return -1;
    80006250:	57fd                	li	a5,-1
    80006252:	a805                	j	80006282 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006254:	fc442783          	lw	a5,-60(s0)
    80006258:	0007c863          	bltz	a5,80006268 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000625c:	01a78513          	addi	a0,a5,26
    80006260:	050e                	slli	a0,a0,0x3
    80006262:	9526                	add	a0,a0,s1
    80006264:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006268:	fd043503          	ld	a0,-48(s0)
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	a0e080e7          	jalr	-1522(ra) # 80004c7a <fileclose>
    fileclose(wf);
    80006274:	fc843503          	ld	a0,-56(s0)
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	a02080e7          	jalr	-1534(ra) # 80004c7a <fileclose>
    return -1;
    80006280:	57fd                	li	a5,-1
}
    80006282:	853e                	mv	a0,a5
    80006284:	70e2                	ld	ra,56(sp)
    80006286:	7442                	ld	s0,48(sp)
    80006288:	74a2                	ld	s1,40(sp)
    8000628a:	6121                	addi	sp,sp,64
    8000628c:	8082                	ret
	...

0000000080006290 <kernelvec>:
    80006290:	7111                	addi	sp,sp,-256
    80006292:	e006                	sd	ra,0(sp)
    80006294:	e40a                	sd	sp,8(sp)
    80006296:	e80e                	sd	gp,16(sp)
    80006298:	ec12                	sd	tp,24(sp)
    8000629a:	f016                	sd	t0,32(sp)
    8000629c:	f41a                	sd	t1,40(sp)
    8000629e:	f81e                	sd	t2,48(sp)
    800062a0:	fc22                	sd	s0,56(sp)
    800062a2:	e0a6                	sd	s1,64(sp)
    800062a4:	e4aa                	sd	a0,72(sp)
    800062a6:	e8ae                	sd	a1,80(sp)
    800062a8:	ecb2                	sd	a2,88(sp)
    800062aa:	f0b6                	sd	a3,96(sp)
    800062ac:	f4ba                	sd	a4,104(sp)
    800062ae:	f8be                	sd	a5,112(sp)
    800062b0:	fcc2                	sd	a6,120(sp)
    800062b2:	e146                	sd	a7,128(sp)
    800062b4:	e54a                	sd	s2,136(sp)
    800062b6:	e94e                	sd	s3,144(sp)
    800062b8:	ed52                	sd	s4,152(sp)
    800062ba:	f156                	sd	s5,160(sp)
    800062bc:	f55a                	sd	s6,168(sp)
    800062be:	f95e                	sd	s7,176(sp)
    800062c0:	fd62                	sd	s8,184(sp)
    800062c2:	e1e6                	sd	s9,192(sp)
    800062c4:	e5ea                	sd	s10,200(sp)
    800062c6:	e9ee                	sd	s11,208(sp)
    800062c8:	edf2                	sd	t3,216(sp)
    800062ca:	f1f6                	sd	t4,224(sp)
    800062cc:	f5fa                	sd	t5,232(sp)
    800062ce:	f9fe                	sd	t6,240(sp)
    800062d0:	b5bfc0ef          	jal	ra,80002e2a <kerneltrap>
    800062d4:	6082                	ld	ra,0(sp)
    800062d6:	6122                	ld	sp,8(sp)
    800062d8:	61c2                	ld	gp,16(sp)
    800062da:	7282                	ld	t0,32(sp)
    800062dc:	7322                	ld	t1,40(sp)
    800062de:	73c2                	ld	t2,48(sp)
    800062e0:	7462                	ld	s0,56(sp)
    800062e2:	6486                	ld	s1,64(sp)
    800062e4:	6526                	ld	a0,72(sp)
    800062e6:	65c6                	ld	a1,80(sp)
    800062e8:	6666                	ld	a2,88(sp)
    800062ea:	7686                	ld	a3,96(sp)
    800062ec:	7726                	ld	a4,104(sp)
    800062ee:	77c6                	ld	a5,112(sp)
    800062f0:	7866                	ld	a6,120(sp)
    800062f2:	688a                	ld	a7,128(sp)
    800062f4:	692a                	ld	s2,136(sp)
    800062f6:	69ca                	ld	s3,144(sp)
    800062f8:	6a6a                	ld	s4,152(sp)
    800062fa:	7a8a                	ld	s5,160(sp)
    800062fc:	7b2a                	ld	s6,168(sp)
    800062fe:	7bca                	ld	s7,176(sp)
    80006300:	7c6a                	ld	s8,184(sp)
    80006302:	6c8e                	ld	s9,192(sp)
    80006304:	6d2e                	ld	s10,200(sp)
    80006306:	6dce                	ld	s11,208(sp)
    80006308:	6e6e                	ld	t3,216(sp)
    8000630a:	7e8e                	ld	t4,224(sp)
    8000630c:	7f2e                	ld	t5,232(sp)
    8000630e:	7fce                	ld	t6,240(sp)
    80006310:	6111                	addi	sp,sp,256
    80006312:	10200073          	sret
    80006316:	00000013          	nop
    8000631a:	00000013          	nop
    8000631e:	0001                	nop

0000000080006320 <timervec>:
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	e10c                	sd	a1,0(a0)
    80006326:	e510                	sd	a2,8(a0)
    80006328:	e914                	sd	a3,16(a0)
    8000632a:	6d0c                	ld	a1,24(a0)
    8000632c:	7110                	ld	a2,32(a0)
    8000632e:	6194                	ld	a3,0(a1)
    80006330:	96b2                	add	a3,a3,a2
    80006332:	e194                	sd	a3,0(a1)
    80006334:	4589                	li	a1,2
    80006336:	14459073          	csrw	sip,a1
    8000633a:	6914                	ld	a3,16(a0)
    8000633c:	6510                	ld	a2,8(a0)
    8000633e:	610c                	ld	a1,0(a0)
    80006340:	34051573          	csrrw	a0,mscratch,a0
    80006344:	30200073          	mret
	...

000000008000634a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000634a:	1141                	addi	sp,sp,-16
    8000634c:	e422                	sd	s0,8(sp)
    8000634e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006350:	0c0007b7          	lui	a5,0xc000
    80006354:	4705                	li	a4,1
    80006356:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006358:	c3d8                	sw	a4,4(a5)
}
    8000635a:	6422                	ld	s0,8(sp)
    8000635c:	0141                	addi	sp,sp,16
    8000635e:	8082                	ret

0000000080006360 <plicinithart>:

void
plicinithart(void)
{
    80006360:	1141                	addi	sp,sp,-16
    80006362:	e406                	sd	ra,8(sp)
    80006364:	e022                	sd	s0,0(sp)
    80006366:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006368:	ffffb097          	auipc	ra,0xffffb
    8000636c:	6fe080e7          	jalr	1790(ra) # 80001a66 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006370:	0085171b          	slliw	a4,a0,0x8
    80006374:	0c0027b7          	lui	a5,0xc002
    80006378:	97ba                	add	a5,a5,a4
    8000637a:	40200713          	li	a4,1026
    8000637e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006382:	00d5151b          	slliw	a0,a0,0xd
    80006386:	0c2017b7          	lui	a5,0xc201
    8000638a:	953e                	add	a0,a0,a5
    8000638c:	00052023          	sw	zero,0(a0)
}
    80006390:	60a2                	ld	ra,8(sp)
    80006392:	6402                	ld	s0,0(sp)
    80006394:	0141                	addi	sp,sp,16
    80006396:	8082                	ret

0000000080006398 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006398:	1141                	addi	sp,sp,-16
    8000639a:	e406                	sd	ra,8(sp)
    8000639c:	e022                	sd	s0,0(sp)
    8000639e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	6c6080e7          	jalr	1734(ra) # 80001a66 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063a8:	00d5179b          	slliw	a5,a0,0xd
    800063ac:	0c201537          	lui	a0,0xc201
    800063b0:	953e                	add	a0,a0,a5
  return irq;
}
    800063b2:	4148                	lw	a0,4(a0)
    800063b4:	60a2                	ld	ra,8(sp)
    800063b6:	6402                	ld	s0,0(sp)
    800063b8:	0141                	addi	sp,sp,16
    800063ba:	8082                	ret

00000000800063bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063bc:	1101                	addi	sp,sp,-32
    800063be:	ec06                	sd	ra,24(sp)
    800063c0:	e822                	sd	s0,16(sp)
    800063c2:	e426                	sd	s1,8(sp)
    800063c4:	1000                	addi	s0,sp,32
    800063c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063c8:	ffffb097          	auipc	ra,0xffffb
    800063cc:	69e080e7          	jalr	1694(ra) # 80001a66 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063d0:	00d5151b          	slliw	a0,a0,0xd
    800063d4:	0c2017b7          	lui	a5,0xc201
    800063d8:	97aa                	add	a5,a5,a0
    800063da:	c3c4                	sw	s1,4(a5)
}
    800063dc:	60e2                	ld	ra,24(sp)
    800063de:	6442                	ld	s0,16(sp)
    800063e0:	64a2                	ld	s1,8(sp)
    800063e2:	6105                	addi	sp,sp,32
    800063e4:	8082                	ret

00000000800063e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063e6:	1141                	addi	sp,sp,-16
    800063e8:	e406                	sd	ra,8(sp)
    800063ea:	e022                	sd	s0,0(sp)
    800063ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ee:	479d                	li	a5,7
    800063f0:	06a7c963          	blt	a5,a0,80006462 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800063f4:	0001e797          	auipc	a5,0x1e
    800063f8:	c0c78793          	addi	a5,a5,-1012 # 80024000 <disk>
    800063fc:	00a78733          	add	a4,a5,a0
    80006400:	6789                	lui	a5,0x2
    80006402:	97ba                	add	a5,a5,a4
    80006404:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006408:	e7ad                	bnez	a5,80006472 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000640a:	00451793          	slli	a5,a0,0x4
    8000640e:	00020717          	auipc	a4,0x20
    80006412:	bf270713          	addi	a4,a4,-1038 # 80026000 <disk+0x2000>
    80006416:	6314                	ld	a3,0(a4)
    80006418:	96be                	add	a3,a3,a5
    8000641a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000641e:	6314                	ld	a3,0(a4)
    80006420:	96be                	add	a3,a3,a5
    80006422:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000642e:	6318                	ld	a4,0(a4)
    80006430:	97ba                	add	a5,a5,a4
    80006432:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006436:	0001e797          	auipc	a5,0x1e
    8000643a:	bca78793          	addi	a5,a5,-1078 # 80024000 <disk>
    8000643e:	97aa                	add	a5,a5,a0
    80006440:	6509                	lui	a0,0x2
    80006442:	953e                	add	a0,a0,a5
    80006444:	4785                	li	a5,1
    80006446:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000644a:	00020517          	auipc	a0,0x20
    8000644e:	bce50513          	addi	a0,a0,-1074 # 80026018 <disk+0x2018>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	206080e7          	jalr	518(ra) # 80002658 <wakeup>
}
    8000645a:	60a2                	ld	ra,8(sp)
    8000645c:	6402                	ld	s0,0(sp)
    8000645e:	0141                	addi	sp,sp,16
    80006460:	8082                	ret
    panic("free_desc 1");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	45e50513          	addi	a0,a0,1118 # 800088c0 <syscalls+0x330>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	45e50513          	addi	a0,a0,1118 # 800088d0 <syscalls+0x340>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>

0000000080006482 <virtio_disk_init>:
{
    80006482:	1101                	addi	sp,sp,-32
    80006484:	ec06                	sd	ra,24(sp)
    80006486:	e822                	sd	s0,16(sp)
    80006488:	e426                	sd	s1,8(sp)
    8000648a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000648c:	00002597          	auipc	a1,0x2
    80006490:	45458593          	addi	a1,a1,1108 # 800088e0 <syscalls+0x350>
    80006494:	00020517          	auipc	a0,0x20
    80006498:	c9450513          	addi	a0,a0,-876 # 80026128 <disk+0x2128>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	6b8080e7          	jalr	1720(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a4:	100017b7          	lui	a5,0x10001
    800064a8:	4398                	lw	a4,0(a5)
    800064aa:	2701                	sext.w	a4,a4
    800064ac:	747277b7          	lui	a5,0x74727
    800064b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064b4:	0ef71163          	bne	a4,a5,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064b8:	100017b7          	lui	a5,0x10001
    800064bc:	43dc                	lw	a5,4(a5)
    800064be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064c0:	4705                	li	a4,1
    800064c2:	0ce79a63          	bne	a5,a4,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	479c                	lw	a5,8(a5)
    800064cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064ce:	4709                	li	a4,2
    800064d0:	0ce79363          	bne	a5,a4,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064d4:	100017b7          	lui	a5,0x10001
    800064d8:	47d8                	lw	a4,12(a5)
    800064da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064dc:	554d47b7          	lui	a5,0x554d4
    800064e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064e4:	0af71963          	bne	a4,a5,80006596 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e8:	100017b7          	lui	a5,0x10001
    800064ec:	4705                	li	a4,1
    800064ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f0:	470d                	li	a4,3
    800064f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064f6:	c7ffe737          	lui	a4,0xc7ffe
    800064fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800064fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006500:	2701                	sext.w	a4,a4
    80006502:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006504:	472d                	li	a4,11
    80006506:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006508:	473d                	li	a4,15
    8000650a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000650c:	6705                	lui	a4,0x1
    8000650e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006510:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006514:	5bdc                	lw	a5,52(a5)
    80006516:	2781                	sext.w	a5,a5
  if(max == 0)
    80006518:	c7d9                	beqz	a5,800065a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000651a:	471d                	li	a4,7
    8000651c:	08f77d63          	bgeu	a4,a5,800065b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006520:	100014b7          	lui	s1,0x10001
    80006524:	47a1                	li	a5,8
    80006526:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006528:	6609                	lui	a2,0x2
    8000652a:	4581                	li	a1,0
    8000652c:	0001e517          	auipc	a0,0x1e
    80006530:	ad450513          	addi	a0,a0,-1324 # 80024000 <disk>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	7ac080e7          	jalr	1964(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000653c:	0001e717          	auipc	a4,0x1e
    80006540:	ac470713          	addi	a4,a4,-1340 # 80024000 <disk>
    80006544:	00c75793          	srli	a5,a4,0xc
    80006548:	2781                	sext.w	a5,a5
    8000654a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000654c:	00020797          	auipc	a5,0x20
    80006550:	ab478793          	addi	a5,a5,-1356 # 80026000 <disk+0x2000>
    80006554:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006556:	0001e717          	auipc	a4,0x1e
    8000655a:	b2a70713          	addi	a4,a4,-1238 # 80024080 <disk+0x80>
    8000655e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006560:	0001f717          	auipc	a4,0x1f
    80006564:	aa070713          	addi	a4,a4,-1376 # 80025000 <disk+0x1000>
    80006568:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000656a:	4705                	li	a4,1
    8000656c:	00e78c23          	sb	a4,24(a5)
    80006570:	00e78ca3          	sb	a4,25(a5)
    80006574:	00e78d23          	sb	a4,26(a5)
    80006578:	00e78da3          	sb	a4,27(a5)
    8000657c:	00e78e23          	sb	a4,28(a5)
    80006580:	00e78ea3          	sb	a4,29(a5)
    80006584:	00e78f23          	sb	a4,30(a5)
    80006588:	00e78fa3          	sb	a4,31(a5)
}
    8000658c:	60e2                	ld	ra,24(sp)
    8000658e:	6442                	ld	s0,16(sp)
    80006590:	64a2                	ld	s1,8(sp)
    80006592:	6105                	addi	sp,sp,32
    80006594:	8082                	ret
    panic("could not find virtio disk");
    80006596:	00002517          	auipc	a0,0x2
    8000659a:	35a50513          	addi	a0,a0,858 # 800088f0 <syscalls+0x360>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	fa0080e7          	jalr	-96(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	36a50513          	addi	a0,a0,874 # 80008910 <syscalls+0x380>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	37a50513          	addi	a0,a0,890 # 80008930 <syscalls+0x3a0>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>

00000000800065c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065c6:	7159                	addi	sp,sp,-112
    800065c8:	f486                	sd	ra,104(sp)
    800065ca:	f0a2                	sd	s0,96(sp)
    800065cc:	eca6                	sd	s1,88(sp)
    800065ce:	e8ca                	sd	s2,80(sp)
    800065d0:	e4ce                	sd	s3,72(sp)
    800065d2:	e0d2                	sd	s4,64(sp)
    800065d4:	fc56                	sd	s5,56(sp)
    800065d6:	f85a                	sd	s6,48(sp)
    800065d8:	f45e                	sd	s7,40(sp)
    800065da:	f062                	sd	s8,32(sp)
    800065dc:	ec66                	sd	s9,24(sp)
    800065de:	e86a                	sd	s10,16(sp)
    800065e0:	1880                	addi	s0,sp,112
    800065e2:	892a                	mv	s2,a0
    800065e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065e6:	00c52c83          	lw	s9,12(a0)
    800065ea:	001c9c9b          	slliw	s9,s9,0x1
    800065ee:	1c82                	slli	s9,s9,0x20
    800065f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065f4:	00020517          	auipc	a0,0x20
    800065f8:	b3450513          	addi	a0,a0,-1228 # 80026128 <disk+0x2128>
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	5e8080e7          	jalr	1512(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006604:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006606:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006608:	0001eb97          	auipc	s7,0x1e
    8000660c:	9f8b8b93          	addi	s7,s7,-1544 # 80024000 <disk>
    80006610:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006612:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006614:	8a4e                	mv	s4,s3
    80006616:	a051                	j	8000669a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006618:	00fb86b3          	add	a3,s7,a5
    8000661c:	96da                	add	a3,a3,s6
    8000661e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006622:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006624:	0207c563          	bltz	a5,8000664e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006628:	2485                	addiw	s1,s1,1
    8000662a:	0711                	addi	a4,a4,4
    8000662c:	25548063          	beq	s1,s5,8000686c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006630:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006632:	00020697          	auipc	a3,0x20
    80006636:	9e668693          	addi	a3,a3,-1562 # 80026018 <disk+0x2018>
    8000663a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000663c:	0006c583          	lbu	a1,0(a3)
    80006640:	fde1                	bnez	a1,80006618 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006642:	2785                	addiw	a5,a5,1
    80006644:	0685                	addi	a3,a3,1
    80006646:	ff879be3          	bne	a5,s8,8000663c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000664a:	57fd                	li	a5,-1
    8000664c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000664e:	02905a63          	blez	s1,80006682 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006652:	f9042503          	lw	a0,-112(s0)
    80006656:	00000097          	auipc	ra,0x0
    8000665a:	d90080e7          	jalr	-624(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000665e:	4785                	li	a5,1
    80006660:	0297d163          	bge	a5,s1,80006682 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006664:	f9442503          	lw	a0,-108(s0)
    80006668:	00000097          	auipc	ra,0x0
    8000666c:	d7e080e7          	jalr	-642(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006670:	4789                	li	a5,2
    80006672:	0097d863          	bge	a5,s1,80006682 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006676:	f9842503          	lw	a0,-104(s0)
    8000667a:	00000097          	auipc	ra,0x0
    8000667e:	d6c080e7          	jalr	-660(ra) # 800063e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006682:	00020597          	auipc	a1,0x20
    80006686:	aa658593          	addi	a1,a1,-1370 # 80026128 <disk+0x2128>
    8000668a:	00020517          	auipc	a0,0x20
    8000668e:	98e50513          	addi	a0,a0,-1650 # 80026018 <disk+0x2018>
    80006692:	ffffc097          	auipc	ra,0xffffc
    80006696:	cd6080e7          	jalr	-810(ra) # 80002368 <sleep>
  for(int i = 0; i < 3; i++){
    8000669a:	f9040713          	addi	a4,s0,-112
    8000669e:	84ce                	mv	s1,s3
    800066a0:	bf41                	j	80006630 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066a2:	20058713          	addi	a4,a1,512
    800066a6:	00471693          	slli	a3,a4,0x4
    800066aa:	0001e717          	auipc	a4,0x1e
    800066ae:	95670713          	addi	a4,a4,-1706 # 80024000 <disk>
    800066b2:	9736                	add	a4,a4,a3
    800066b4:	4685                	li	a3,1
    800066b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ba:	20058713          	addi	a4,a1,512
    800066be:	00471693          	slli	a3,a4,0x4
    800066c2:	0001e717          	auipc	a4,0x1e
    800066c6:	93e70713          	addi	a4,a4,-1730 # 80024000 <disk>
    800066ca:	9736                	add	a4,a4,a3
    800066cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066d4:	7679                	lui	a2,0xffffe
    800066d6:	963e                	add	a2,a2,a5
    800066d8:	00020697          	auipc	a3,0x20
    800066dc:	92868693          	addi	a3,a3,-1752 # 80026000 <disk+0x2000>
    800066e0:	6298                	ld	a4,0(a3)
    800066e2:	9732                	add	a4,a4,a2
    800066e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066e6:	6298                	ld	a4,0(a3)
    800066e8:	9732                	add	a4,a4,a2
    800066ea:	4541                	li	a0,16
    800066ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066ee:	6298                	ld	a4,0(a3)
    800066f0:	9732                	add	a4,a4,a2
    800066f2:	4505                	li	a0,1
    800066f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800066f8:	f9442703          	lw	a4,-108(s0)
    800066fc:	6288                	ld	a0,0(a3)
    800066fe:	962a                	add	a2,a2,a0
    80006700:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006704:	0712                	slli	a4,a4,0x4
    80006706:	6290                	ld	a2,0(a3)
    80006708:	963a                	add	a2,a2,a4
    8000670a:	05890513          	addi	a0,s2,88
    8000670e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006710:	6294                	ld	a3,0(a3)
    80006712:	96ba                	add	a3,a3,a4
    80006714:	40000613          	li	a2,1024
    80006718:	c690                	sw	a2,8(a3)
  if(write)
    8000671a:	140d0063          	beqz	s10,8000685a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000671e:	00020697          	auipc	a3,0x20
    80006722:	8e26b683          	ld	a3,-1822(a3) # 80026000 <disk+0x2000>
    80006726:	96ba                	add	a3,a3,a4
    80006728:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000672c:	0001e817          	auipc	a6,0x1e
    80006730:	8d480813          	addi	a6,a6,-1836 # 80024000 <disk>
    80006734:	00020517          	auipc	a0,0x20
    80006738:	8cc50513          	addi	a0,a0,-1844 # 80026000 <disk+0x2000>
    8000673c:	6114                	ld	a3,0(a0)
    8000673e:	96ba                	add	a3,a3,a4
    80006740:	00c6d603          	lhu	a2,12(a3)
    80006744:	00166613          	ori	a2,a2,1
    80006748:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000674c:	f9842683          	lw	a3,-104(s0)
    80006750:	6110                	ld	a2,0(a0)
    80006752:	9732                	add	a4,a4,a2
    80006754:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006758:	20058613          	addi	a2,a1,512
    8000675c:	0612                	slli	a2,a2,0x4
    8000675e:	9642                	add	a2,a2,a6
    80006760:	577d                	li	a4,-1
    80006762:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006766:	00469713          	slli	a4,a3,0x4
    8000676a:	6114                	ld	a3,0(a0)
    8000676c:	96ba                	add	a3,a3,a4
    8000676e:	03078793          	addi	a5,a5,48
    80006772:	97c2                	add	a5,a5,a6
    80006774:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006776:	611c                	ld	a5,0(a0)
    80006778:	97ba                	add	a5,a5,a4
    8000677a:	4685                	li	a3,1
    8000677c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000677e:	611c                	ld	a5,0(a0)
    80006780:	97ba                	add	a5,a5,a4
    80006782:	4809                	li	a6,2
    80006784:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006788:	611c                	ld	a5,0(a0)
    8000678a:	973e                	add	a4,a4,a5
    8000678c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006790:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006794:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006798:	6518                	ld	a4,8(a0)
    8000679a:	00275783          	lhu	a5,2(a4)
    8000679e:	8b9d                	andi	a5,a5,7
    800067a0:	0786                	slli	a5,a5,0x1
    800067a2:	97ba                	add	a5,a5,a4
    800067a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067ac:	6518                	ld	a4,8(a0)
    800067ae:	00275783          	lhu	a5,2(a4)
    800067b2:	2785                	addiw	a5,a5,1
    800067b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067bc:	100017b7          	lui	a5,0x10001
    800067c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067c4:	00492703          	lw	a4,4(s2)
    800067c8:	4785                	li	a5,1
    800067ca:	02f71163          	bne	a4,a5,800067ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067ce:	00020997          	auipc	s3,0x20
    800067d2:	95a98993          	addi	s3,s3,-1702 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    800067d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067d8:	85ce                	mv	a1,s3
    800067da:	854a                	mv	a0,s2
    800067dc:	ffffc097          	auipc	ra,0xffffc
    800067e0:	b8c080e7          	jalr	-1140(ra) # 80002368 <sleep>
  while(b->disk == 1) {
    800067e4:	00492783          	lw	a5,4(s2)
    800067e8:	fe9788e3          	beq	a5,s1,800067d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067ec:	f9042903          	lw	s2,-112(s0)
    800067f0:	20090793          	addi	a5,s2,512
    800067f4:	00479713          	slli	a4,a5,0x4
    800067f8:	0001e797          	auipc	a5,0x1e
    800067fc:	80878793          	addi	a5,a5,-2040 # 80024000 <disk>
    80006800:	97ba                	add	a5,a5,a4
    80006802:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006806:	0001f997          	auipc	s3,0x1f
    8000680a:	7fa98993          	addi	s3,s3,2042 # 80026000 <disk+0x2000>
    8000680e:	00491713          	slli	a4,s2,0x4
    80006812:	0009b783          	ld	a5,0(s3)
    80006816:	97ba                	add	a5,a5,a4
    80006818:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000681c:	854a                	mv	a0,s2
    8000681e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006822:	00000097          	auipc	ra,0x0
    80006826:	bc4080e7          	jalr	-1084(ra) # 800063e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000682a:	8885                	andi	s1,s1,1
    8000682c:	f0ed                	bnez	s1,8000680e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000682e:	00020517          	auipc	a0,0x20
    80006832:	8fa50513          	addi	a0,a0,-1798 # 80026128 <disk+0x2128>
    80006836:	ffffa097          	auipc	ra,0xffffa
    8000683a:	462080e7          	jalr	1122(ra) # 80000c98 <release>
}
    8000683e:	70a6                	ld	ra,104(sp)
    80006840:	7406                	ld	s0,96(sp)
    80006842:	64e6                	ld	s1,88(sp)
    80006844:	6946                	ld	s2,80(sp)
    80006846:	69a6                	ld	s3,72(sp)
    80006848:	6a06                	ld	s4,64(sp)
    8000684a:	7ae2                	ld	s5,56(sp)
    8000684c:	7b42                	ld	s6,48(sp)
    8000684e:	7ba2                	ld	s7,40(sp)
    80006850:	7c02                	ld	s8,32(sp)
    80006852:	6ce2                	ld	s9,24(sp)
    80006854:	6d42                	ld	s10,16(sp)
    80006856:	6165                	addi	sp,sp,112
    80006858:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000685a:	0001f697          	auipc	a3,0x1f
    8000685e:	7a66b683          	ld	a3,1958(a3) # 80026000 <disk+0x2000>
    80006862:	96ba                	add	a3,a3,a4
    80006864:	4609                	li	a2,2
    80006866:	00c69623          	sh	a2,12(a3)
    8000686a:	b5c9                	j	8000672c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000686c:	f9042583          	lw	a1,-112(s0)
    80006870:	20058793          	addi	a5,a1,512
    80006874:	0792                	slli	a5,a5,0x4
    80006876:	0001e517          	auipc	a0,0x1e
    8000687a:	83250513          	addi	a0,a0,-1998 # 800240a8 <disk+0xa8>
    8000687e:	953e                	add	a0,a0,a5
  if(write)
    80006880:	e20d11e3          	bnez	s10,800066a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006884:	20058713          	addi	a4,a1,512
    80006888:	00471693          	slli	a3,a4,0x4
    8000688c:	0001d717          	auipc	a4,0x1d
    80006890:	77470713          	addi	a4,a4,1908 # 80024000 <disk>
    80006894:	9736                	add	a4,a4,a3
    80006896:	0a072423          	sw	zero,168(a4)
    8000689a:	b505                	j	800066ba <virtio_disk_rw+0xf4>

000000008000689c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000689c:	1101                	addi	sp,sp,-32
    8000689e:	ec06                	sd	ra,24(sp)
    800068a0:	e822                	sd	s0,16(sp)
    800068a2:	e426                	sd	s1,8(sp)
    800068a4:	e04a                	sd	s2,0(sp)
    800068a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068a8:	00020517          	auipc	a0,0x20
    800068ac:	88050513          	addi	a0,a0,-1920 # 80026128 <disk+0x2128>
    800068b0:	ffffa097          	auipc	ra,0xffffa
    800068b4:	334080e7          	jalr	820(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068b8:	10001737          	lui	a4,0x10001
    800068bc:	533c                	lw	a5,96(a4)
    800068be:	8b8d                	andi	a5,a5,3
    800068c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068c6:	0001f797          	auipc	a5,0x1f
    800068ca:	73a78793          	addi	a5,a5,1850 # 80026000 <disk+0x2000>
    800068ce:	6b94                	ld	a3,16(a5)
    800068d0:	0207d703          	lhu	a4,32(a5)
    800068d4:	0026d783          	lhu	a5,2(a3)
    800068d8:	06f70163          	beq	a4,a5,8000693a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068dc:	0001d917          	auipc	s2,0x1d
    800068e0:	72490913          	addi	s2,s2,1828 # 80024000 <disk>
    800068e4:	0001f497          	auipc	s1,0x1f
    800068e8:	71c48493          	addi	s1,s1,1820 # 80026000 <disk+0x2000>
    __sync_synchronize();
    800068ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068f0:	6898                	ld	a4,16(s1)
    800068f2:	0204d783          	lhu	a5,32(s1)
    800068f6:	8b9d                	andi	a5,a5,7
    800068f8:	078e                	slli	a5,a5,0x3
    800068fa:	97ba                	add	a5,a5,a4
    800068fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068fe:	20078713          	addi	a4,a5,512
    80006902:	0712                	slli	a4,a4,0x4
    80006904:	974a                	add	a4,a4,s2
    80006906:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000690a:	e731                	bnez	a4,80006956 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000690c:	20078793          	addi	a5,a5,512
    80006910:	0792                	slli	a5,a5,0x4
    80006912:	97ca                	add	a5,a5,s2
    80006914:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006916:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000691a:	ffffc097          	auipc	ra,0xffffc
    8000691e:	d3e080e7          	jalr	-706(ra) # 80002658 <wakeup>

    disk.used_idx += 1;
    80006922:	0204d783          	lhu	a5,32(s1)
    80006926:	2785                	addiw	a5,a5,1
    80006928:	17c2                	slli	a5,a5,0x30
    8000692a:	93c1                	srli	a5,a5,0x30
    8000692c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006930:	6898                	ld	a4,16(s1)
    80006932:	00275703          	lhu	a4,2(a4)
    80006936:	faf71be3          	bne	a4,a5,800068ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000693a:	0001f517          	auipc	a0,0x1f
    8000693e:	7ee50513          	addi	a0,a0,2030 # 80026128 <disk+0x2128>
    80006942:	ffffa097          	auipc	ra,0xffffa
    80006946:	356080e7          	jalr	854(ra) # 80000c98 <release>
}
    8000694a:	60e2                	ld	ra,24(sp)
    8000694c:	6442                	ld	s0,16(sp)
    8000694e:	64a2                	ld	s1,8(sp)
    80006950:	6902                	ld	s2,0(sp)
    80006952:	6105                	addi	sp,sp,32
    80006954:	8082                	ret
      panic("virtio_disk_intr status");
    80006956:	00002517          	auipc	a0,0x2
    8000695a:	ffa50513          	addi	a0,a0,-6 # 80008950 <syscalls+0x3c0>
    8000695e:	ffffa097          	auipc	ra,0xffffa
    80006962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
