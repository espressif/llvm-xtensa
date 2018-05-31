#ifndef LLVM_LIB_TARGET_XTENSA_XTENSASUBTARGET_H
#define LLVM_LIB_TARGET_XTENSA_XTENSASUBTARGET_H

#include "XtensaFrameLowering.h"
#include "XtensaISelLowering.h"
#include "XtensaInstrInfo.h"
#include "XtensaRegisterInfo.h"
#if 0
#include "llvm/IR/DataLayout.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetSelectionDAGInfo.h"
#include "llvm/Target/TargetSubtargetInfo.h"
#else
#include "llvm/CodeGen/SelectionDAGTargetInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetMachine.h"
#endif
#include <string>

#define GET_SUBTARGETINFO_HEADER
#include "XtensaGenSubtargetInfo.inc"

namespace llvm 
{
class GlobalValue;
class StringRef;

class XtensaSubtarget : public XtensaGenSubtargetInfo 
{
protected:
  enum XtensaArchEnum 
  {
    ESP8266,
    ESP32
  };

  XtensaArchEnum XtensaArchVersion;

  bool UseSoftFloat;
  bool HasF;

private:
  Triple TargetTriple;
  XtensaInstrInfo InstrInfo;
  XtensaTargetLowering TLInfo;
  SelectionDAGTargetInfo TSInfo;
  XtensaFrameLowering FrameLowering;
  bool UseSmallSection;

  XtensaSubtarget &initializeSubtargetDependencies(StringRef CPU, StringRef FS);

public:
  XtensaSubtarget(const Triple &TT, const std::string &CPU,
                 const std::string &FS, const TargetMachine &TM);

  const TargetFrameLowering *getFrameLowering() const { return &FrameLowering; }
  const XtensaInstrInfo *getInstrInfo() const { return &InstrInfo; }
  const XtensaRegisterInfo *getRegisterInfo() const 
  {
    return &InstrInfo.getRegisterInfo();
  }
  const XtensaTargetLowering *getTargetLowering() const { return &TLInfo; }
  const SelectionDAGTargetInfo *getSelectionDAGInfo() const { return &TSInfo; }

  bool isESP8266() const { return XtensaArchVersion == ESP8266; };
  bool isESP32() const { return XtensaArchVersion == ESP32; };
  
  bool hasF() const { return HasF; };

  bool useSoftFloat() const { return UseSoftFloat; }

  // Automatically generated by tblgen.
  void ParseSubtargetFeatures(StringRef CPU, StringRef FS);

  bool isTargetELF() const { return TargetTriple.isOSBinFormatELF(); }
  
  bool useSmallSection() const { return UseSmallSection; }
};
} // end namespace llvm

#endif /* LLVM_LIB_TARGET_XTENSA_XTENSASUBTARGET_H */


