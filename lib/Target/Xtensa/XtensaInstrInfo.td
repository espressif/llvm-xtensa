//===- XtensaInstrInfo.td - Target Description for Xtensa Target -*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------------===//
//
// This file describes the Xtensa instructions in TableGen format.
//
//===----------------------------------------------------------------------------===//

include "XtensaInstrFormats.td"
include "XtensaOperands.td"

// Arithmetic & Logical instructions
class ArithLogic_RRRN<bits<4> oper0, string instrAsm, SDPatternOperator opNode, 
    bit isComm = 0>:
  RRRN_Inst<oper0, (outs AR:$r), (ins AR:$s, AR:$t),
     instrAsm#"\t$r, $s, $t",
     [(set AR:$r, (opNode AR:$s, AR:$t))]> 
{
  let isCommutable = isComm;
  let isReMaterializable = 0;
}

def ADD_N: ArithLogic_RRRN<0x0a, "add.n", add, 1>;

class ArithLogic_RRR<bits<4> oper2, bits<4> oper1, string instrAsm, 
    SDPatternOperator opNode, bit isComm = 0>:
  RRR_Inst<0x00, oper1, oper2, (outs AR:$r), (ins AR:$s, AR:$t),
     instrAsm#"\t$r, $s, $t",
     [(set AR:$r, (opNode AR:$s, AR:$t))]> 
{
  let isCommutable = isComm;
  let isReMaterializable = 0;
}

def ADD: ArithLogic_RRR<0x08, 0x00, "add", add, 1>;
def SUB: ArithLogic_RRR<0x0C, 0x00, "sub", sub>;
def AND: ArithLogic_RRR<0x01, 0x00, "and", and, 1>;
def MULL: ArithLogic_RRR<0x08, 0x02, "mull", mul, 1>, Requires<[HasMul32]>;
def MULUH: ArithLogic_RRR<0x0A, 0x02, "muluh", mulhu, 1>, Requires<[HasMul32High]>;
def MULSH: ArithLogic_RRR<0x0B, 0x02, "mulus", mulhs, 1>, Requires<[HasMul32High]>;
def QUOS: ArithLogic_RRR<0x0D, 0x02, "quos", sdiv>, Requires<[HasDiv32]>;
def QUOU: ArithLogic_RRR<0x0C, 0x02, "quou", udiv>, Requires<[HasDiv32]>;
def REMS: ArithLogic_RRR<0x0F, 0x02, "rems", srem>, Requires<[HasDiv32]>;
def REMU: ArithLogic_RRR<0x0E, 0x02, "remu", urem>, Requires<[HasDiv32]>;
def OR: ArithLogic_RRR<0x02, 0x00, "or", or, 1>;
def XOR: ArithLogic_RRR<0x03, 0x00, "xor", xor, 1>;

def ADDI_N: RRRN_Inst<0x0B, (outs AR:$r), (ins AR:$s, immn:$imm),
     "addi.n\t$r, $s, $imm",
     [(set AR:$r, (add AR:$s, immn:$imm))]> 
{
  bits<4> imm;

  let t = imm;
}

def ADDI: RRI8_Inst<0x02, (outs AR:$t), (ins AR:$s, imm8:$imm8),
     "addi\t$t, $s, $imm8",
     [(set AR:$t, (add AR:$s, imm8:$imm8))]> 
{
  let r = 0x0C;
}

def ADDMI: RRI8_Inst<0x02, (outs AR:$t), (ins AR:$s, imm8_sh8:$imm_sh8),
     "addmi\t$t, $s, $imm_sh8",
     [(set AR:$t, (add AR:$s, imm8_sh8:$imm_sh8))]> 
{
  bits<16> imm_sh8;

  let r = 0x0D;
  let imm8 = imm_sh8{15-8};
}

class ADDX<bits<4> oper, string instrAsm, list<dag> pattern>:
  RRR_Inst<0x00, 0x00, oper, (outs AR:$r), (ins AR:$s, AR:$t),
     instrAsm#"\t$r, $s, $t",
     pattern>; 

def ADDX2: ADDX<0x09, "addx2", [(set AR:$r, (add AR:$t, (shl AR:$s, (i32 1))))]>;
def ADDX4: ADDX<0x0A, "addx4", [(set AR:$r, (add AR:$t, (shl AR:$s, (i32 2))))]>;
def ADDX8: ADDX<0x0B, "addx8", [(set AR:$r, (add AR:$t, (shl AR:$s, (i32 3))))]>;
def SUBX2: ADDX<0x0D, "subx2", [(set AR:$r, (sub (shl AR:$s, (i32 1)), AR:$t))]>;
def SUBX4: ADDX<0x0E, "subx4", [(set AR:$r, (sub (shl AR:$s, (i32 2)), AR:$t))]>;
def SUBX8: ADDX<0x0F, "subx8", [(set AR:$r, (sub (shl AR:$s, (i32 3)), AR:$t))]>;

def NEG: RRR_Inst<0x00, 0x00, 0x06, (outs AR:$r), (ins AR:$t),
     "neg\t$r, $t",
		 [(set AR:$r, (ineg AR:$t))]>
{
  let s = 0x00;
}

// Shift instructions
let Uses = [sar] in
{
  def SLL: RRR_Inst<0x00, 0x01, 0x0A, (outs AR:$r), (ins AR:$s),
       "sll\t$r, $s",
       [(set AR:$r, (Xtensa_shl AR:$s))]>
  {
    let t = 0x00;
  }

  def SRA: RRR_Inst<0x00, 0x01, 0x0B, (outs AR:$r), (ins AR:$t),
       "sra\t$r, $t",
       [(set AR:$r, (Xtensa_sra AR:$t))]>
  {
    let s = 0x00;
  }

  def SRC: RRR_Inst<0x00, 0x01, 0x08, (outs AR:$r), (ins AR:$s, AR:$t),
       "src\t$r, $s, $t",
       [(set AR:$r, (Xtensa_src AR:$s, AR:$t))]>;

  def SRL: RRR_Inst<0x00, 0x01, 0x09, (outs AR:$r), (ins AR:$t),
       "srl\t$r, $t",
       [(set AR:$r, (Xtensa_srl AR:$t))]>
  {
    let s = 0x00;
  }
}

let Defs = [sar] in
{
  def SSL: RRR_Inst<0x00, 0x00, 0x04, (outs), (ins AR:$s),
       "ssl\t$s",
	   [(Xtensa_ssl AR:$s)]>
  {
    let r = 0x01;
    let t = 0x00;
  }

  def SSR: RRR_Inst<0x00, 0x00, 0x04, (outs), (ins AR:$s),
       "ssr\t$s", 
	   [(Xtensa_ssr AR:$s)]>
  {
    let r = 0x00;
    let t = 0x00;
  }
}

// Shift Pseudo instructions:
// SSL/SSR + Shift combination
let usesCustomInserter = 1 in
{
  def SLL_P: Pseudo<(outs AR:$r), (ins AR:$s, AR:$sa),
                       "# SLL_P $r, $s, $sa",
                       [(set AR:$r, (shl AR:$s, AR:$sa))]>;
 
  def SRA_P: Pseudo<(outs AR:$r), (ins AR:$t, AR:$sa),
                       "# SRA_P $r, $t, $sa",
                       [(set AR:$r, (sra AR:$t, AR:$sa))]>;

  def SRL_P: Pseudo<(outs AR:$r), (ins AR:$t, AR:$sa),
                       "# SRL_P $r, $t, $sa",
                       [(set AR:$r, (srl AR:$t, AR:$sa))]>;
}


def SLLI_SHORT: RRR_Inst<0x00, 0x01, 0x01, (outs AR:$r), (ins AR:$s, shimm1_16:$sa),
     "slli\t$r, $s, $sa",
     [(set AR:$r, (shl AR:$s, shimm1_16:$sa))]> 
{
  bits<4> sa;

  let t = sa;
} 

def SLLI: RRR_Inst<0x00, 0x01, 0x00, (outs AR:$r), (ins AR:$s, shimm17_31:$sa),
     "slli\t$r, $s, $sa",
     [(set AR:$r, (shl AR:$s, shimm17_31:$sa))]> 
{
  bits<5> sa;

  let t = sa{3-0};
} 

def SRAI_SHORT: RRR_Inst<0x00, 0x01, 0x02, (outs AR:$r), (ins AR:$t, shimm4:$sa),
     "srai\t$r, $t, $sa",
     [(set AR:$r, (sra AR:$t, shimm4:$sa))]> 
{
  bits<4> sa;

  let s = sa;
}

def SRAI: RRR_Inst<0x00, 0x01, 0x03, (outs AR:$r), (ins AR:$t, shimm16_31:$sa),
     "srai\t$r, $t, $sa",
     [(set AR:$r, (sra AR:$t, shimm16_31:$sa))]> 
{
  bits<5> sa;

  let s = sa{3-0};
}

def SRLI: RRR_Inst<0x00, 0x01, 0x04, (outs AR:$r), (ins AR:$t, shimm4:$sa),
     "srli\t$r, $t, $sa",
     [(set AR:$r, (srl AR:$t, shimm4:$sa))]> 
{
  bits<4> sa; 

  let s = sa;
}  

// Move instructions
def MOV_N: RRRN_Inst<0x0D, (outs AR:$t), (ins AR:$s),
   "mov.n\t$t, $s",
   []>
{
  let r = 0;
}

def MOVSP: RRR_Inst<0x00, 0x00, 0x00, (outs AR:$t), (ins AR:$s),
   "movsp\t$t, $s",
   [(set AR:$t, (Xtensa_movsp AR:$s))]>, Requires<[HasWindowed]>
{
  let r = 0x01;
}

def MOVI_N: RI7_Inst<0xc, 0x0, (outs AR:$s), (ins imm7n:$imm7),
   "movi.n\t$s, $imm7",
   [(set AR:$s, imm7n:$imm7)]>;

def MOVI: RRI8_Inst<0x02, (outs AR:$t), (ins imm12:$imm),
   "movi\t$t, $imm",
   [(set AR:$t, imm12:$imm)]>
{
  bits<12> imm;

  let imm8{7-0} = imm{7-0}; 
  let s{3-0} = imm{11-8}; 
  let r = 0xa;
}

// Set Shift Amount register
def SSAI: RRR_Inst<0x00, 0x00, 0x04, (outs), (ins shimm5:$imm),
     "ssai\t$imm",
     []>
{
  bits<5> imm;

  let r = 0x04;
  let s = imm{3-0};
  let t{3-1} = 0;
  let t{0} = imm{4};
}

// Load instructions
let mayLoad = 1, usesCustomInserter = 1 in
{
  def L32I_N: RRRN_Inst<0x8, (outs AR:$t), (ins mem32n:$addr), 
                "l32i.n\t$t, $addr", 
                []>
 {
   bits<8> addr;

   let r{3-0} = addr{7-4};
   let s{3-0} = addr{3-0};
 }

  class Load_RRI8<bits<4> oper, string instrAsm, SDPatternOperator opNode, 
      ComplexPattern addrOp, Operand memOp>: RRI8_Inst<0x02, (outs AR:$t), (ins memOp:$addr), 
                instrAsm#"\t$t, $addr", 
                [(set AR:$t, (opNode addrOp:$addr))]>
  {
   bits<12> addr;

   let r = oper;
   let imm8{7-0} = addr{11-4};
   let s{3-0} = addr{3-0};
  }
}

// Xtensa missed L8I load operation, use pseudo operation
let usesCustomInserter = 1 in
def L8I_P: Pseudo<(outs AR:$t), (ins mem8:$addr),
               "!L8I_P $t, $addr",
                [(set AR:$t, (sextloadi8 
				addr_ish1:$addr))]>;

def SEXT: RRR_Inst<0x00, 0x03, 0x02, (outs AR:$r), (ins AR:$s, seimm7_22:$imm),
     "sext\t$r, $s, $imm",
     []>,Requires<[HasSEXT]>
{
  bits<4> imm;

  let t = imm;
}

def L8UI: Load_RRI8<0x00, "l8ui", zextloadi8, addr_ish1, mem8>;
def L16SI: Load_RRI8<0x09, "l16si", sextloadi16, addr_ish2, mem16>;
def L16UI: Load_RRI8<0x01, "l16ui", zextloadi16, addr_ish2, mem16>;
def L32I: Load_RRI8<0x02, "l32i", load, addr_ish4, mem32>;

//extended loads
def : Pat<(i32 (extloadi1  addr_ish1:$addr)), (L8UI addr_ish1:$addr)>;
def : Pat<(i32 (extloadi8  addr_ish1:$addr)), (L8UI addr_ish1:$addr)>;
def : Pat<(i32 (extloadi16 addr_ish2:$addr)), (L16UI addr_ish2:$addr)>;

// Store instructions
let mayStore = 1, usesCustomInserter = 1 in
{
  def S32I_N: RRRN_Inst<0x9, (outs), (ins  AR:$t, mem32n:$addr),
              "s32i.n\t$t, $addr", 
              []>
 {
   bits<8> addr;

   let r{3-0} = addr{7-4};
   let s{3-0} = addr{3-0};
 }

  class Store_II8<bits<4> oper, string instrAsm, SDPatternOperator opNode, 
      ComplexPattern addrOp, Operand memOp>: RRI8_Inst<0x02, (outs), (ins AR:$t, memOp:$addr),
              instrAsm#"\t$t, $addr", 
              [(opNode AR:$t, addrOp:$addr)]>
  {
   bits<12> addr;

   let r = oper;
   let imm8{7-0} = addr{11-4};
   let s{3-0} = addr{3-0};
  }
}

def S8I: Store_II8<0x04, "s8i", truncstorei8, addr_ish1, mem8>;
def S16I: Store_II8<0x05, "s16i", truncstorei16, addr_ish2, mem16>;
def S32I: Store_II8<0x06, "s32i", store, addr_ish4, mem32>;
 
def L32R: RI16_Inst<0x01, (outs AR:$t), (ins imm32:$label), "l32r\t$t, $label", 
    []>
{
  bits<16> label;	
  let imm16 = label;
}

// Conditional move instructions
def MOVEQZ : RRR_Inst<0x00, 0x03, 0x08, (outs AR:$r), (ins AR:$s, AR:$t),
     "moveqz\t$r, $s, $t",
     []>;
def MOVNEZ : RRR_Inst<0x00, 0x03, 0x09, (outs AR:$r), (ins AR:$s, AR:$t),
     "movnez\t$r, $s, $t",
     []>;
def MOVLTZ : RRR_Inst<0x00, 0x03, 0x0A, (outs AR:$r), (ins AR:$s, AR:$t),
     "movltz\t$r, $s, $t",
     []>;
def MOVGEZ : RRR_Inst<0x00, 0x03, 0x0B, (outs AR:$r), (ins AR:$s, AR:$t),
     "movgez\t$r, $s, $t",
     []>;

let Predicates = [HasNSA] in {
  def NSA : RRR_Inst<0x00, 0x00, 0x04, (outs AR:$t), (ins AR:$s),
       "nsa\t$t, $s",
       []>
  {
    let r = 0xE;
  }

  def NSAU : RRR_Inst<0x00, 0x00, 0x04, (outs AR:$t), (ins AR:$s),
       "nsau\t$t, $s",
       []>
  {
    let r = 0xF;
  }
}

// FrameIndexes are legalized when they are operands from load/store
// instructions. The same not happens for stack address copies, so an
// add op with mem ComplexPattern is used and the stack address copy
// can be matched.
// Setting of attribute mayLoad is trick to process instruction operands
// in function XtensaRegisterInfo::eliminateFI

let isCodeGenOnly = 1, mayLoad = 1 in
{

  def LEA_ADD : RRI8_Inst<0x02, (outs AR:$t), (ins mem32:$addr),
       "addi\t$t, $addr",
       [(set AR:$t, addr_ish4:$addr)]>
  {
   bits<12> addr;

   let r = 0x0C;
   let imm8{7-0} = addr{11-4};
   let s{3-0} = addr{3-0};
  }
}


// Conditional branch instructions

let isBranch = 1, isTerminator = 1 in 
{
  class Branch_RR<bits<4> oper, string instrAsm, CondCode CC>: 
        RRI8_Inst<0x07, (outs), 
              (ins AR:$s, AR:$t, brtarget:$target), 
              instrAsm#"\t$s, $t, $target", 
              [(brcc CC, AR:$s, AR:$t,  bb:$target)]>
  {
    bits<8> target;

    let r = oper;
    let imm8 = target;
  }

  class Branch_RR_rev<bits<4> oper, string instrAsm, CondCode CC>:  
        RRI8_Inst<0x07, (outs), 
              (ins AR:$t, AR:$s, brtarget:$target), 
              instrAsm#"\t$s, $t, $target", 
              [(brcc CC, AR:$t, AR:$s,  bb:$target)]>
  {
    bits<8> target;

    let r = oper;
    let imm8 = target;
  }

  class Branch_RI<bits<4> oper, string instrAsm, CondCode CC>: 
        RRI8_Inst<0x06, (outs), 
              (ins AR:$s, b4const:$imm, brtarget:$target), 
              instrAsm#"\t$s, $imm, $target", 
              [(brcc CC, AR:$s, b4const:$imm,  bb:$target)]>
  {
    bits<4> imm;
    bits<8> target;

    let t = oper;
    let r = imm;
    let imm8 = target;
  }

  class Branch_RIU<bits<4> oper, string instrAsm, CondCode CC>: 
        RRI8_Inst<0x06, (outs), 
              (ins AR:$s, b4constu:$imm, brtarget:$target), 
              instrAsm#"\t$s, $imm, $target", 
              [(brcc CC, AR:$s, b4constu:$imm,  bb:$target)]>
  {
    bits<4> imm;
    bits<8> target;

    let t = oper;
    let r = imm;
    let imm8 = target;
  }

  class Branch_RZ<bits<2> n, bits<2> m, string instrAsm, CondCode CC>: 
        BRI12_Inst<0x06, n, m, (outs), 
              (ins AR:$s, brtarget:$target), 
              instrAsm#"\t$s, $target", 
              [(brcc CC, AR:$s, (i32 0),  bb:$target)]>
  {
    bits<12> target;

    let imm12 = target;
  }
}

def BEQ: Branch_RR<0x01, "beq", SETEQ>;
def BNE: Branch_RR<0x09, "bne", SETNE>;
def BGE: Branch_RR<0x0A, "bge", SETGE>;
def BLT: Branch_RR<0x02, "blt", SETLT>;
def BGEU: Branch_RR<0x0B, "bgeu", SETUGE>;
def BLTU: Branch_RR<0x03, "bltu", SETULT>;

//Synthesize remaining condition codes by reverseing operands
def BGT: Branch_RR_rev<0x02, "blt", SETGT>;
def BGTU: Branch_RR_rev<0x03, "bltu", SETUGT>;
def BLE: Branch_RR_rev<0x0A, "bge", SETLE>;
def BLEU: Branch_RR_rev<0x0B, "bgeu", SETULE>;

def BEQI: Branch_RI<0x02, "beqi", SETEQ>;
def BNEI: Branch_RI<0x06, "bnei", SETNE>;
def BGEI: Branch_RI<0x0E, "bgei", SETGE>;
def BLTI: Branch_RI<0x0A, "blti", SETLT>;
def BGEUI: Branch_RIU<0x0F, "bgeui", SETUGE>;
def BLTUI: Branch_RIU<0x0B, "bltui", SETULT>;

def BEQZ: Branch_RZ<0x01, 0x00, "beqz", SETEQ>;
def BNEZ: Branch_RZ<0x01, 0x01, "bnez", SETNE>;
def BGEZ: Branch_RZ<0x01, 0x03, "bgez", SETGE>;
def BLTZ: Branch_RZ<0x01, 0x02, "bltz", SETLT>;


def : Pat<(brcond (i32 (seteq AR:$s, AR:$t)), bb:$target),
          (BEQ AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setne AR:$s, AR:$t)), bb:$target),
          (BNE AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setge AR:$s, AR:$t)), bb:$target),
          (BGE AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setle AR:$s, AR:$t)), bb:$target),
          (BLT AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setuge AR:$s, AR:$t)), bb:$target),
          (BGEU AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setult AR:$s, AR:$t)), bb:$target),
          (BLTU AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setgt AR:$s, AR:$t)), bb:$target),
          (BGT AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setugt AR:$s, AR:$t)), bb:$target),
          (BGTU AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setle AR:$s, AR:$t)), bb:$target),
          (BLE AR:$s, AR:$t, bb:$target)>;
def : Pat<(brcond (i32 (setule AR:$s, AR:$t)), bb:$target),
          (BLEU AR:$s, AR:$t, bb:$target)>;


// Unconditional jumps
let isBranch = 1, isTerminator = 1, isBarrier = 1 in 
{
  def J: CALL_Inst<0x06, (outs), (ins jumptarget:$offset), "j\t$offset", 
          [(br bb:$offset)]>
  {
    let n = 0x0;
  }

  def JX: CALLX_Inst<0x00, 0x00, 0x00, (outs), (ins AR:$s), "jx\t$s",
          [(brind AR:$s)]>
  {
    let m = 0x2;
    let n = 0x2;
	let r = 0;
    let isIndirectBranch = 1;
  }
}

def : Pat<(brcond AR:$s, bb:$target),
          (BNEZ AR:$s, bb:$target)>;

// It's a trick for redundant branches with -O0 option
// like br i1 true, label ...
def : Pat<(brcond (i32 1), bb:$target),
          (J bb:$target)>;

let isBranch = 1, isTerminator = 1, isBarrier = 1 in 
{
 def BR_JT: CALLX_Inst<0x00, 0x00, 0x00, (outs), (ins AR:$s, i32imm:$jt), "jx\t$s",
          [(Xtensa_brjt AR:$s, tjumptable:$jt)]>
  {
    let m = 0x2;
    let n = 0x2;
    let r = 0;
    let isIndirectBranch = 1;
  }
}

let isCall = 1,
   Defs = [a0] in 
{
  def CALL0: CALL_Inst<0x05, (outs), (ins pcrel32call:$offset),
          "call0\t$offset",
          []>
  {
    let n = 0;
  }
  
  def CALL4: CALL_Inst<0x05, (outs), (ins pcrel32call:$offset),
          "call4\t$offset", 
          []>, Requires<[HasWindowed]>
  {
    let n = 1;
  }

  def CALL8: CALL_Inst<0x05, (outs), (ins pcrel32call:$offset),
          "call8\t$offset", 
          []>, Requires<[HasWindowed]>
  {
    let n = 2;
  }

  def CALL12: CALL_Inst<0x05, (outs), (ins pcrel32call:$offset),
          "call12\t$offset", 
          []>, Requires<[HasWindowed]>
  {
    let n = 3;
  }
   
  let isIndirectBranch = 1 in
  {
    def CALLX0: CALLX_Inst<0x00, 0x00, 0x00, (outs), (ins AR:$s), 
            "callx0\t$s", [(Xtensa_call AR:$s)]>
    {
      let m = 0x3;
      let n = 0x0;
      let r = 0;
    }
	
    def CALLX4: CALLX_Inst<0x00, 0x00, 0x00, (outs), (ins AR:$s), 
            "callx4\t$s", []>, Requires<[HasWindowed]>
    {
      let m = 0x3;
      let n = 0x1;
      let r = 0;
    }

    def CALLX8: CALLX_Inst<0x00, 0x00, 0x00, (outs), (ins AR:$s), 
            "callx8\t$s", []>, Requires<[HasWindowed]>
    {
      let m = 0x3;
      let n = 0x2;
      let r = 0;
    }

    def CALLX12: CALLX_Inst<0x00, 0x00, 0x00, (outs), (ins AR:$s), 
            "callx12\t$s", []>, Requires<[HasWindowed]>
    {
      let m = 0x3;
      let n = 0x3;
      let r = 0;
    }
  }
}

let isReturn = 1, isTerminator = 1,
    isBarrier = 1, hasCtrlDep = 1, Uses = [a0], Predicates = [HasDensity] in
{

  def RET_N: RRRN_Inst<0x0D, (outs), (ins),
                "ret.n", [(Xtensa_retflag)]>
  {
    let r = 0x0F;
    let s = 0;
    let t = 0;
  } 

  def RETW_N: RRRN_Inst<0x0D, (outs), (ins),
                "retw.n", [(Xtensa_retWflag)]>, Requires<[HasWindowed]>
  {
    let r = 0x0F;
    let s = 0;
    let t = 1;
  } 
}

def : Pat<(Xtensa_retflag), (RET_N)>;
def : Pat<(Xtensa_retWflag), (RETW_N)>;

def ENTRY: BRI12_Inst<0x06, 0x3, 0x0, (outs), (ins AR:$s, entry_imm12:$imm), 
                "entry\t$s, $imm", []>, Requires<[HasWindowed]>
{
  bits<15> imm;

  let imm12{11-0} = imm{14-3};
  let Defs = [sp];
}


// calls
def : Pat<(Xtensa_call (i32 tglobaladdr:$dst)),
          (CALL0 tglobaladdr:$dst)>;
def : Pat<(Xtensa_callw (i32 tglobaladdr:$dst)),
          (CALL8 tglobaladdr:$dst)>;
def : Pat<(Xtensa_call (i32 texternalsym:$dst)),
          (CALL0 texternalsym:$dst)>;
def : Pat<(Xtensa_callw (i32 texternalsym:$dst)),
          (CALL8 texternalsym:$dst)>;
def : Pat<(Xtensa_call AR:$dst),
          (CALLX0 AR:$dst)>;
def : Pat<(Xtensa_callw AR:$dst),
          (CALLX8 AR:$dst)>;

//pcrel addr loading using L32R
def : Pat<(Xtensa_pcrel_wrapper tconstpool:$in), (L32R tconstpool:$in)>;

//def : Pat<(Xtensa_pcrel_wrapper tglobaladdr:$in), (LA tglobaladdr:$in)>;
//def : Pat<(Xtensa_pcrel_wrapper tblockaddress:$in), (LA tblockaddress:$in)>;
//def : Pat<(Xtensa_pcrel_wrapper tjumptable:$in), (LA tjumptable:$in)>;
//def : Pat<(Xtensa_pcrel_wrapper tglobaltlsaddr:$in), (LA tglobaltlsaddr:$in)>;
//def : Pat<(Xtensa_pcrel_wrapper texternalsym:$in), (LA texternalsym:$in)>;

//===----------------------------------------------------------------------===//
// Stack allocation
//===----------------------------------------------------------------------===//

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
let Defs = [sp], Uses = [sp] in 
{
def ADJCALLSTACKDOWN: Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2), 
                              "#ADJCALLSTACKDOWN",
                              [(Xtensa_callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP  : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(Xtensa_callseq_end timm:$amt1, timm:$amt2)]>;
}

// Generic select instruction
let usesCustomInserter = 1 in
{
//def SELECT   : Pseudo<(outs AR:$res), (ins AR:$a, AR:$x, AR:$y),
//                       "!select $res, $a, $x, $y",
//                       [(set AR:$res, (Xtensa_select AR:$a, AR:$x, AR:$y))]>;

// Expanded into a branch sequence.
//def SELECT_CC : Pseudo<(outs AR:$dst),
//                       (ins AR:$cond, AR:$t, AR:$f),
//                        "# SELECT_CC PSEUDO!",
//                       [(set AR:$dst,
//                       (select AR:$cond, AR:$t, AR:$f))]>;

def SELECT: Pseudo<(outs AR:$dst), (ins AR:$lhs, AR:$rhs, AR:$t, AR:$f, i32imm:$cond),
                                  "!select $dst, $lhs, $rhs, $t, $f, $cond",
                                  [(set AR:$dst, (Xtensa_select_cc AR:$lhs, AR:$rhs, AR:$t, AR:$f, imm:$cond))]>;

//def SETCC_EQZ: Pseudo<(outs AR:$dst), (ins AR:$src),
//                                  "!setcc_eqz $dst, $src",
//                                  [(set AR:$dst, (seteq AR:$src, (i32 0)))]>;

//def SETCC_NEZ: Pseudo<(outs AR:$dst), (ins AR:$src),
//                                  "!setcc_eqz $dst, $src",
//                                  [(set AR:$dst, (setne AR:$src, (i32 0)))]>;

}
//def : Pat<(select (i32 (setne AR:$lhs, 0)), AR:$t, AR:$f),
//        (SELECT_CC AR:$lhs, AR:$t, AR:$f)>;
  
//def : Pat<(select (i32 (seteq AR:$lhs, 0)), AR:$t, AR:$f),
//        (SELECT_CC AR:$lhs, AR:$f, AR:$t)>;

let isBarrier = 1, isTerminator = 1 in
{
def BREAK_N: RRRN_Inst<0x0F, (outs), (ins imm32:$t),
     "break.n\t$t",
     []> 
{
  let r = 0x0D;
  let s = 0x02;
}

def BREAK: RRR_Inst<0x00, 0x00, 0x00, (outs), (ins i32imm:$t, i32imm:$s),
   "break\t$t, $s",
   []>
{
  let r = 0x04;
}
}

//def: Pat<(trap), (BREAK (i32 1), (i32 15))>;
def: Pat<(trap), (BREAK_N (i32 1))>;

//===----------------------------------------------------------------------===//
// Floating-Point Instructions
//===----------------------------------------------------------------------===//

class FPArith_RRR<bits<4> oper2, bits<4> oper1, string instrAsm, 
    SDPatternOperator opNode, bit isComm = 0>:
  RRR_Inst<0x00, oper1, oper2, (outs FPR:$r), (ins FPR:$s, FPR:$t),
     instrAsm#"\t$r, $s, $t",
     [(set FPR:$r, (opNode FPR:$s, FPR:$t))]> 
{
  let isCommutable = isComm;
  let isReMaterializable = 0;
  let Predicates = [HasSingleFloat];
}

def ADD_S: FPArith_RRR<0x00, 0x0A, "add.s", fadd, 1>;
def SUB_S: FPArith_RRR<0x01, 0x0A, "sub.s", fsub>;
def MUL_S: FPArith_RRR<0x02, 0x0A, "mul.s", fmul, 1>;

def ABS_S: RRR_Inst<0x00, 0x0A, 0x0F, (outs FPR:$r), (ins FPR:$s),
     "abs.s\t$r, $s",
     [(set FPR:$r, (fabs FPR:$s))]> 
{
  let t = 0x01;
}  

def NEG_S: RRR_Inst<0x00, 0x0A, 0x0F, (outs FPR:$r), (ins FPR:$s),
     "neg.s\t$r, $s",
     [(set FPR:$r, (fneg FPR:$s))]> 
{
  let t = 0x06;
} 

def TRUNC_S: RRR_Inst<0x00, 0x0A, 0x09, (outs AR:$r), (ins FPR:$s),
     "trunc.s\t$r, $s, 0",
     [(set AR:$r, (fp_to_sint FPR:$s))]> 
{
  let t = 0x00;
} 

def UTRUNC_S: RRR_Inst<0x00, 0x0A, 0x0e, (outs AR:$r), (ins FPR:$s),
     "utrunc.s\t$r, $s, 0",
     [(set AR:$r, (fp_to_uint FPR:$s))]> 
{
  let t = 0x00;
} 

def FLOAT_S: RRR_Inst<0x00, 0x0A, 0x0c, (outs FPR:$r), (ins AR:$s),
     "float.s\t$r, $s, 0",
     [(set FPR:$r, (sint_to_fp AR:$s))]> 
{
  let t = 0x00;
} 

def UFLOAT_S: RRR_Inst<0x00, 0x0A, 0x0D, (outs FPR:$r), (ins AR:$s),
     "ufloat.s\t$r, $s, 0",
     [(set FPR:$r, (uint_to_fp AR:$s))]> 
{
  let t = 0x00;
} 

def RFR: RRR_Inst<0x00, 0x0A, 0x0f, (outs AR:$r), (ins FPR:$s),
     "rfr\t$r, $s",
     [(set AR:$r, (bitconvert FPR:$s))]> 
{
  let t = 0x04;
} 

def WFR: RRR_Inst<0x00, 0x0A, 0x0f, (outs FPR:$r), (ins AR:$s),
     "wfr\t$r, $s",
     [(set FPR:$r, (bitconvert AR:$s))]> 
{
  let t = 0x05;
} 

// FP load instructions
let mayLoad = 1, usesCustomInserter = 1, Predicates = [HasSingleFloat] in
{
  class LoadF_RRI8<bits<4> oper, string instrAsm, SDPatternOperator opNode, 
     // ComplexPattern addrOp, Operand memOp>: RRI8_Inst<0x02, (outs), (ins AR:$t, memOp:$addr),
      ComplexPattern addrOp,Operand memOp>: RRI8_Inst<0x03, (outs FPR:$t), (ins memOp:$addr), 
                instrAsm#"\t$t, $addr", 
                [(set FPR:$t, (opNode addrOp:$addr))]>
  {
    bits<12> addr;

    let r = oper;
    let imm8{7-0} = addr{11-4};
    let s{3-0} = addr{3-0};
  }
}

def L32F: LoadF_RRI8<0x00, "lsi", load, addr_ish4, mem32>, Requires<[]>;

// FP store instructions
let mayStore = 1, usesCustomInserter = 1, Predicates = [HasSingleFloat] in
{
  class StoreF_RRI8<bits<4> oper, string instrAsm, SDPatternOperator opNode, 
      ComplexPattern addrOp, Operand memOp>: RRI8_Inst<0x03, (outs), (ins FPR:$t, memOp:$addr),
              instrAsm#"\t$t, $addr", 
              [(opNode FPR:$t, addrOp:$addr)]>
  {
    bits<12> addr;

    let r = oper;
    let imm8{7-0} = addr{11-4};
    let s{3-0} = addr{3-0};
  }

}

def S32F: StoreF_RRI8<0x04, "ssi", store, addr_ish4, mem32>;

// FP compare instructions

let isCompare = 1, Predicates = [HasSingleFloat] in 
{
  class FCompare <bits<4> oper2, bits<4> oper1, string instrAsm, 
      SDPatternOperator opNode, bit isComm = 0>:
    RRR_Inst<0x00, oper1, oper2, (outs BR:$b), (ins FPR:$s, FPR:$t),
       instrAsm#"\t$b, $s, $t",
       [(set BR:$b, (opNode FPR:$s, FPR:$t))]> 
  {
    let isCommutable = isComm;
    let isReMaterializable = 0;
	let Predicates = [HasSingleFloat];
  }
}

def OEQ_S:  FCompare<0x02, 0x0b, "oeq.s", Xtensa_cmpoeq, 1>;
def OLT_S:  FCompare<0x04, 0x0b, "olt.s", Xtensa_cmpolt, 1>;
def OLE_S:  FCompare<0x06, 0x0b, "ole.s", Xtensa_cmpole, 1>;

def UEQ_S:  FCompare<0x03, 0x0b, "ueq.s", Xtensa_cmpueq, 1>;
def ULT_S:  FCompare<0x05, 0x0b, "ult.s", Xtensa_cmpult, 1>;
def ULE_S:  FCompare<0x07, 0x0b, "ule.s", Xtensa_cmpule, 1>;
def UN_S:   FCompare<0x01, 0x0b, "un.s",  Xtensa_cmpuo, 1>;

// FP select operations
let usesCustomInserter = 1 in
{
  def SELECT_CC_FP_INT: Pseudo<(outs AR:$dst), (ins FPR:$lhs, FPR:$rhs, AR:$t, AR:$f, i32imm:$cond),
                                    "!select_cc_fp_int $dst, $lhs, $rhs, $t, $f, $cond",
                                    [(set AR:$dst, (Xtensa_select_cc_fp FPR:$lhs, FPR:$rhs, AR:$t, AR:$f, imm:$cond))]>;
  def SELECT_CC_INT_FP: Pseudo<(outs FPR:$dst), (ins AR:$lhs, AR:$rhs, FPR:$t, FPR:$f, i32imm:$cond),
                                    "!select_cc_int_fp $dst, $lhs, $rhs, $t, $f, $cond",
                                    [(set FPR:$dst, (Xtensa_select_cc_fp AR:$lhs, AR:$rhs, FPR:$t, FPR:$f, imm:$cond))]>;
  def SELECT_CC_FP_FP: Pseudo<(outs FPR:$dst), (ins FPR:$lhs, FPR:$rhs, FPR:$t, FPR:$f, i32imm:$cond),
                                    "!select_cc_fp_fp $dst, $lhs, $rhs, $t, $f, $cond",
                                    [(set FPR:$dst, (Xtensa_select_cc_fp FPR:$lhs, FPR:$rhs, FPR:$t, FPR:$f, imm:$cond))]>;
}

//FP complex operations
def MADD_S: RRR_Inst<0x00, 0x0A, 0x04, (outs FPR:$r), (ins FPR:$a, FPR:$s, FPR:$t),
     "madd.s\t$r, $s, $t",
     [(set FPR:$r, (Xtensa_madd FPR:$a, FPR:$s, FPR:$t))]>, Requires<[HasSingleFloat]>
{
  let isCommutable = 0;
  let isReMaterializable = 0;
  let Constraints = "$r = $a";
}

def MSUB_S: RRR_Inst<0x00, 0x0A, 0x05, (outs FPR:$r), (ins FPR:$a, FPR:$s, FPR:$t),
     "msub.s\t$r, $s, $t",
     [(set FPR:$r, (Xtensa_msub FPR:$a, FPR:$s, FPR:$t))]>, Requires<[HasSingleFloat]> 
{
  let isCommutable = 0;
  let isReMaterializable = 0;
  let Constraints = "$r = $a";
}

//FP move operations
def MOV_S: RRR_Inst<0x00, 0x0A, 0x0f, (outs FPR:$r), (ins FPR:$s),
     "mov.s\t$r, $s",
     [(set FPR:$r, (Xtensa_movs FPR:$s))]>, Requires<[HasSingleFloat]>
{
  let t = 0x00;
} 
//===----------------------------------------------------------------------===//
// Boolean branch Instructions
//===----------------------------------------------------------------------===//

let isBranch = 1, isTerminator = 1, Predicates = [HasBoolean] in 
{
  def BTs: RRI8_Inst<0x06, (outs), 
              (ins BR:$b, brtarget:$target), 
              "bt\t$b, $target", 
              [(Xtensa_brcc_t BR:$b, bb:$target)]>
  {
    bits<8> target;
    bits<4> b;

    let r = 0x1;
    let s = b;
    let t = 0x7; 
    let imm8 = target;
  }

  def BFs: RRI8_Inst<0x06, (outs), 
              (ins BR:$b, brtarget:$target), 
              "bf\t$b, $target", 
              [(Xtensa_brcc_f BR:$b, bb:$target)]>
  {
    bits<8> target;
    bits<4> b;

    let r = 0x0;
    let s = b;
    let t = 0x7; 
    let imm8 = target;
  }
}
//===----------------------------------------------------------------------===//
// Atomic patterns
//===----------------------------------------------------------------------===//

def : Pat<(i32 (atomic_load_8  addr_ish1:$addr)), (L8UI addr_ish1:$addr)>;
def : Pat<(i32 (atomic_load_16 addr_ish2:$addr)), (L16UI addr_ish2:$addr)>;
def : Pat<(i32 (atomic_load_32 addr_ish4:$addr)), (L32I addr_ish4:$addr)>;

def : Pat<(atomic_store_8  addr_ish1:$addr, AR:$t), (S8I AR:$t, addr_ish1:$addr)>;
def : Pat<(atomic_store_16 addr_ish2:$addr, AR:$t), (S16I AR:$t, addr_ish2:$addr)>;
def : Pat<(atomic_store_32 addr_ish4:$addr, AR:$t), (S32I AR:$t, addr_ish4:$addr)>;

let usesCustomInserter = 1, Predicates = [HasS32C1I] in
{
	def ATOMIC_CMP_SWAP_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$cmp, AR:$swap),
										"!atomic_cmp_swap_8_p, $dst, $ptr, $cmp, $swap",
										[(set AR:$dst, (atomic_cmp_swap_8 AR:$ptr, AR:$cmp, AR:$swap))]>;
	def ATOMIC_CMP_SWAP_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$cmp, AR:$swap),
										"!atomic_cmp_swap_16_p, $dst, $ptr, $cmp, $swap",
										[(set AR:$dst, (atomic_cmp_swap_16 AR:$ptr, AR:$cmp, AR:$swap))]>;
	def ATOMIC_CMP_SWAP_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$cmp, AR:$swap),
										"!atomic_cmp_swap_32_p, $dst, $ptr, $cmp, $swap",
										[(set AR:$dst, (atomic_cmp_swap_32 AR:$ptr, AR:$cmp, AR:$swap))]>;

	def ATOMIC_LOAD_ADD_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_add_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_add_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_ADD_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_add_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_add_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_ADD_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_add_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_add_32 AR:$ptr, AR:$arg))]>;

	def ATOMIC_LOAD_SUB_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_sub_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_sub_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_SUB_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_sub_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_sub_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_SUB_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_sub_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_sub_32 AR:$ptr, AR:$arg))]>;

	def ATOMIC_LOAD_AND_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_and_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_and_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_AND_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_and_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_and_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_AND_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_and_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_and_32 AR:$ptr, AR:$arg))]>;

	def ATOMIC_LOAD_OR_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_or_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_or_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_OR_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_or_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_or_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_OR_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_or_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_or_32 AR:$ptr, AR:$arg))]>;

	def ATOMIC_LOAD_XOR_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_xor_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_xor_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_XOR_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_xor_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_xor_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_XOR_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_xor_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_xor_32 AR:$ptr, AR:$arg))]>;

	def ATOMIC_LOAD_NAND_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_nand_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_nand_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_NAND_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_nand_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_nand_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_NAND_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_nand_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_nand_32 AR:$ptr, AR:$arg))]>;

	def ATOMIC_LOAD_MIN_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_min_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_min_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_MIN_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_min_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_min_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_MIN_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_min_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_min_32 AR:$ptr, AR:$arg))]>;			
										
	def ATOMIC_LOAD_MAX_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_max_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_max_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_MAX_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_max_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_max_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_MAX_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_max_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_max_32 AR:$ptr, AR:$arg))]>;	

	def ATOMIC_LOAD_UMIN_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_umin_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_umin_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_UMIN_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_umin_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_umin_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_UMIN_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_umin_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_umin_32 AR:$ptr, AR:$arg))]>;			
										
	def ATOMIC_LOAD_UMAX_8_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_umax_8_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_umax_8 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_UMAX_16_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_umax_16_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_umax_16 AR:$ptr, AR:$arg))]>;
	def ATOMIC_LOAD_UMAX_32_P: Pseudo<(outs AR:$dst), (ins AR:$ptr, AR:$arg),
										"!atomic_load_umax_32_p, $dst, $ptr, $arg",
										[(set AR:$dst, (atomic_load_umax_32 AR:$ptr, AR:$arg))]>;	
}

//===----------------------------------------------------------------------===//
// Special instructions
//===----------------------------------------------------------------------===//
let isCodeGenOnly = 1  in
{
	def MEMW:  RRR_Inst<0x00, 0x00, 0x00, (outs), (ins),
					"memw", [(Xtensa_mem_barrier)]>
	{
	  let r = 0x2;
	  let t = 0x0c;
	  let s = 0x0;
	}
}

let mayStore = 1, mayLoad = 1, usesCustomInserter = 1, Predicates = [HasS32C1I] in
{
  def S32C1I: RRI8_Inst<0x02, (outs AR:$a), (ins AR:$t, mem32:$addr),
              "s32c1i\t$t, $addr", 
			   []>
  {
    bits<12> addr;

    let r = 0x0e;
	let Uses = [SCOMPARE1];
	let Constraints = "$a = $t";
    let imm8{7-0} = addr{11-4};
    let s{3-0} = addr{3-0};
  }
}

def WSR_SCOMPARE1: RSR_Inst<0x00, 0x03, 0x01, (outs), (ins AR:$t),
					"wsr\t$t, SCOMPARE1", [(Xtensa_wsr AR:$t)]>, Requires<[HasS32C1I]>
{
	let Defs = [SCOMPARE1];
	let sr = 12;
}

def RUR_THREADPTR: RRR_Inst<0x00, 0x03, 0x0e, (outs AR:$dst), (ins),
					"rur\t$dst, THREADPTR", [(set AR:$dst, (Xtensa_rur))]>, Requires<[HasTHREADPTR]>
{
	let s = 0xE;
	let t = 0x7;
}
