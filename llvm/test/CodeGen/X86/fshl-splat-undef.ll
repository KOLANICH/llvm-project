; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i386-unknown-linux-gnu -mcpu=cannonlake | FileCheck %s

; Check the correctness of following test.
; For this case:
; In 32-bits targets the <i64 12, ...> will convert to <i32 12, i32 0, ...> in
; type legalization and turn to <i32 12, i32 undef, ...> in combining due to it
; only use the low i32 bits.
; But the fshl is <8 x i64> fshl, the <i32 12, i32 undef, ...> will bitcast to
; <i64 Element, ...> back. Some like:
; ==============================================================================
; // t1: v16i32 = Constant:i32<12>, undef:i32, Constant:i32<12>, undef:i32, ...
; // t2: v8i64 = bitcast t1
; // t5: v8i64 = fshl t3, t4, t2
; ==============================================================================
; We should make sure not "merging" <i32 12, i32 undef> to <i64 undef>
; (We can not convert t2 to {i64 undef, i64 undef, ...})
; That is not equal with the origin result)
;
define void @test_fshl(<8 x i64> %lo, <8 x i64> %hi, <8 x i64>* %arr) {
; CHECK-LABEL: test_fshl:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl {{[0-9]+}}(%esp), %eax
; CHECK-NEXT:    vpsrlq $1, %zmm0, %zmm0
; CHECK-NEXT:    vpternlogq $168, {{\.?LCPI[0-9]+_[0-9]+}}, %zmm1, %zmm0
; CHECK-NEXT:    vmovdqa64 %zmm0, (%eax)
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    retl
entry:
  %fshl = call <8 x i64> @llvm.fshl.v8i64(<8 x i64> %hi, <8 x i64> %lo, <8 x i64> <i64 12, i64 12, i64 12, i64 12, i64 12, i64 12, i64 12, i64 12>)
  %res = shufflevector <8 x i64> %fshl, <8 x i64> zeroinitializer, <8 x i32> <i32 0, i32 1, i32 10, i32 11, i32 12, i32 13, i32 6, i32 7>
  store <8 x i64> %res, <8 x i64>* %arr, align 64
  ret void
}


; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare <8 x i64> @llvm.fshl.v8i64(<8 x i64>, <8 x i64>, <8 x i64>)
