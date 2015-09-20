;CPUID.ASM : (c) Intel Corp
; modifie pour PMOS486 par N. CLERC
;
;       Part 1: Identifies CPU type in the variable cpu_type:
;               0=8086 processor
;               2=Intel 286 processor
;               3=Intel386(TM) processor
;               4=Intel486(TM) processor
;               5=Pentium(TM) processor
;
;       Part 2: Identifies FPU type in the variable fpu_type:
;               0=FPU not present
;               1=FPU present
;               2=287 present (only if cpu_type=3)
;               3=387 present (only if cpu_type=3)
;

OPND32 MACRO op_code, op_erand
	db      66h     ; Force 32-bit operand size
  IFNB <op_code>
	db      op_code
    IFNB <op_erand>
	dd      op_erand; 32-bit immediate value
    ENDIF
  ENDIF
ENDM

CPUID MACRO
	db      0fh     ; Hardcoded opcode for CPUID instruction
	db      0a2h
ENDM

TRUE            equ     1
FAMILY_MASK     equ     0f00h
FAMILY_SHIFT    equ     8
MODEL_MASK      equ     0f0h
MODEL_SHIFT     equ     4
STEPPING_MASK   equ     0fh
FPU_FLAG        equ     1h
MCE_FLAG        equ     80h
CMPXCHG8B_FLAG  equ     100h

get_cpuid proc
;
;       This procedure determines the type of CPU in a system
;       and sets the cpu_type variable with the appropriate
;       value.
;       All registers are used by this procedure, none are preserved.

;       Intel 8086 CPU check
;       Bits 12-15 of the FLAGS register are always set on the
;       8086 processor.
;
check_8086:
	pushf                   ; push original FLAGS
	pop     ax              ; get original FLAGS
	mov     cx, ax          ; save original FLAGS
	and     ax, 0fffh       ; clear bits 12-15 in FLAGS
	push    ax              ; save new FLAGS value on stack
	popf                    ; replace current FLAGS value
	pushf                   ; get new FLAGS
	pop     ax              ; store new FLAGS in AX
	and     ax, 0f000h      ; if bits 12-15 are set, then CPU
	cmp     ax, 0f000h      ;   is an 8086/8088
	mov     cpu_type, 0     ; turn on 8086/8088 flag
	je      end_get_cpuid   ; jump if CPU is 8086/8088

;       Intel 286 CPU check
;       Bits 12-15 of the FLAGS register are always clear on the
;       Intel 286 processor in real-address mode.
;
check_80286:
	or      cx, 0f000h      ; try to set bits 12-15
	push    cx              ; save new FLAGS value on stack
	popf                    ; replace current FLAGS value
	pushf                   ; get new FLAGS
	pop     ax              ; store new FLAGS in AX
	and     ax, 0f000h      ; if bits 12-15 clear, CPU=80286
	mov     cpu_type, 2     ; turn on 80286 flag
	jz      end_get_cpuid   ; if no bits set, CPU is 80286

;       Intel386 CPU check
;       The AC bit, bit #18, is a new bit introduced in the EFLAGS
;       register on the Intel486 DX CPU to generate alignment faults.
;       This bit cannot be set on the Intel386 CPU.
;
check_80386:
;       It is now safe to use 32-bit opcode/operands
	mov     bx, sp          ; save current stack pointer to align
	and     sp, not 3       ; align stack to avoid AC fault
	OPND32
	pushf                   ; push original EFLAGS
	OPND32
	pop     ax              ; get original EFLAGS
	OPND32
	mov     cx, ax          ; save original EFLAGS
	OPND32  35h, 40000h     ; flip AC bit in EFLAGS
	OPND32
	push    ax              ; save new EFLAGS value on stack
	OPND32
	popf                    ; replace current EFLAGS value
	OPND32
	pushf                   ; get new EFLAGS
	OPND32
	pop     ax              ; store new EFLAGS in EAX
	OPND32
	xor     ax, cx          ; can't toggle AC bit, CPU=80386
	mov     cpu_type, 3     ; turn on 80386 CPU flag
	mov     sp, bx          ; restore original stack pointer
	jz      end_get_cpuid   ; jump if 80386 CPU
	and     sp, not 3       ; align stack to avoid AC fault
	OPND32
	push    cx
	OPND32
	popf                    ; restore AC bit in EFLAGS first
	mov     sp, bx          ; restore original stack pointer

;       Intel486 DX CPU, Intel487 SX NDP, and Intel486 SX CPU check
;       Checking for ability to set/clear ID flag (Bit 21) in EFLAGS
;       which indicates the presence of a processor
;       with the ability to use the CPUID instruction.
;
check_80486:
	mov     cpu_type, 4     ; turn on 80486 CPU flag
	OPND32
	mov     ax, cx          ; get original EFLAGS
	OPND32  35h, 200000h    ; flip ID bit in EFLAGS
	OPND32
	push    ax              ; save new EFLAGS value on stack
	OPND32
	popf                    ; replace current EFLAGS value
	OPND32
	pushf                   ; get new EFLAGS
	OPND32
	pop     ax              ; store new EFLAGS in EAX
	OPND32
	xor     ax, cx          ; can't toggle ID bit,
	je      end_get_cpuid   ;   CPU=80486

;       Execute CPUID instruction to determine vendor, family,
;       model and stepping.
;
check_vendor:
	mov     id_flag, 1              ; set flag indicating use of CPUID inst.
	OPND32
	xor     ax, ax                  ; set up input for CPUID instruction
	CPUID                           ; macro for CPUID instruction
	OPND32
	mov     word ptr vendor_id, bx  ; setup to test for vendor id
	OPND32
	mov     word ptr vendor_id[+4], dx
	OPND32
	mov     word ptr vendor_id[+8], cx
	mov     si, offset vendor_id
	mov     di, offset intel_id
	mov     cx, length intel_id
compare:
	repe    cmpsb                   ; compare vendor id to "GenuineIntel"
	or      cx, cx
	jnz     end_get_cpuid           ; if not zero, not an Intel CPU,

intel_processor:
	mov     intel_proc, 1

cpuid_data:
	OPND32
	cmp     ax, 1                   ; make sure 1 is a valid input
					; value for CPUID
	jl      end_get_cpuid           ; if not, jump to end
	OPND32
	xor     ax, ax                  ; otherwise, use as input to CPUID
	OPND32
	inc     ax                      ; and get stepping, model and family
	CPUID
	mov     stepping, al
	and     stepping, STEPPING_MASK ; isolate stepping info

	and     al, MODEL_MASK          ; isolate model info
	shr     al, MODEL_SHIFT
	mov     model, al

	and     ax, FAMILY_MASK         ; mask everything but family
	shr     ax, FAMILY_SHIFT
	mov     cpu_type, al            ; set cpu_type with family

	OPND32
	mov     feature_flags, dx       ; save feature flag data

end_get_cpuid:
	ret
get_cpuid endp


;******************************************************************

get_fpuid proc
;
;       This procedure determines the type of FPU in a system
;       and sets the fpu_type variable with the appropriate
;       value.
;       All registers are used by this procedure, none are preserved.

;       Coprocessor check
;       The algorithm is to determine whether the floating-point
;       status and control words can be written to.  If not, no
;       coprocessor exists.  If the status and control words can be
;       written to, the correct coprocessor is then determined
;       depending on the processor id.  The Intel386 CPU can
;       work with either an Intel287 NDP or an Intel387 NDP.
;       The infinity of the coprocessor must be
;       checked to determine the correct coprocessor id.

	fninit                  ; reset FP status word
	mov     fp_status, 5a5ah; initialize temp word to
				; non-zero value
	fnstsw  fp_status       ; save FP status word
	mov     ax, fp_status   ; check FP status word
	cmp     al, 0           ; see if correct status with
				; written
	mov     fpu_type, 0     ; no fpu present
	jne     end_get_fpuid

check_control_word:
	fnstcw  fp_status       ; save FP control word
	mov     ax, fp_status   ; check FP control word
	and     ax, 103fh       ; see if selected parts
				; looks OK
	cmp     ax, 3fh         ; check that 1's & 0's
				; correctly read
	mov     fpu_type, 0
	jne     end_get_fpuid
	mov     fpu_type, 1

;
;   80287/80387 check for the Intel386 CPU
;
check_infinity:
	cmp     cpu_type, 3
	jne     end_get_fpuid
	fld1                    ; must use default control from FNINIT
	fldz                    ; form infinity
	fdiv                    ; 8087 and Intel287 NDP say +inf = -inf
	fld     st              ; form negative infinity
	fchs                    ; Intel387 NDP says +inf <> -inf
	fcompp                  ; see if they are the same and remove them
	fstsw   fp_status       ; look at status from FCOMPP
	mov     ax, fp_status
	mov     fpu_type, 2     ; store Intel287 NDP for fpu type
	sahf                    ; see if infinities matched
	jz      end_get_fpuid   ; jump if 8087 or Intel287 is present
	mov     fpu_type, 3     ; store Intel387 NDP for fpu type
end_get_fpuid:
	ret
get_fpuid endp


;*********************************************************************


