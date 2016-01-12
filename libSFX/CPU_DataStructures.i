; libSFX Data Structures Macros
; David Lindecrantz <optiroc@gmail.com>

.ifndef ::__MBSFX_CPU_DataStructures__
::__MBSFX_CPU_DataStructures__ = 1

;-------------------------------------------------------------------------------

/**
  FIFO_alloc
  Allocate static FIFO buffer

  Buffer is allocated in the LORAM segment by default.
  If <name> ends with a token named "hi" or "ex" ("midi1-hi" for example)
  the buffer is instead allocated in HIRAM or EXRAM respectively.

  :in:    name    Name                  string  value
  :in:    size    Capacity in bytes     uint8   value
*/
.macro FIFO_alloc name, size
.if (.blank({size}))
  SFX_error "FIFO_alloc: Missing required parameter(s)"
.else
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
    .export .ident(.concat("__FIFO__",.string(.left(1,{name})))): far
    .export .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): far
  .else
    .export .ident(.concat("__FIFO__",.string(.left(1,{name})))): absolute
    .export .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): absolute
  .endif
  .export .ident(.concat("__FIFO_SIZE__",.string(.left(1,{name})))): absolute = .lobyte(size)

  .pushseg
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi)))
    .segment "HIRAM"
  .elseif ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), ex)))
    .segment "EXRAM"
  .else
    .segment "LORAM"
  .endif
  .ident(.concat("__FIFO__",.string(.left(1,{name})))): .res .lobyte(size)
  .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): .res 2
  .popseg

          RW_push set:a8i16
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
          lda   #$00
          sta   f:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))
          sta   f:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))+1
  .else
          stz   .ident(.concat("__FIFO_META__",.string(.left(1,{name}))))
          stz   .ident(.concat("__FIFO_META__",.string(.left(1,{name}))))+1
  .endif
          RW_pull
.endif
.endmac

/**
  FIFO_enq
  Write (enqueue) byte to FIFO buffer

  :in:    name    Buffer name           string  value
  :in:    data    Value to put          uint8   a or constant
*/
.macro FIFO_enq name, data
.if (.blank({data}))
  SFX_error "FIFO_enq: Missing required parameter(s)"
.else
  .import .ident(.concat("__FIFO_SIZE__",.string(.left(1,{name})))): absolute
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
    .import .ident(.concat("__FIFO__",.string(.left(1,{name})))): far
    .import .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): far
          lda   #<.ident(.concat("__FIFO_SIZE__",.string(.left(1,{name}))))
          lda   f:.ident(.concat("__FIFO__",.string(.left(1,{name}))))
          sta   f:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))+11
  .else
    .import .ident(.concat("__FIFO__",.string(.left(1,{name})))): absolute
    .import .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): absolute
          RW_push set:a8i8
          ldx   a:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))
    .if (.not .xmatch({data}, {a}))
          lda   #data
    .endif
          sta   a:.ident(.concat("__FIFO__",.string(.left(1,{name})))),x
          inx
          cpx   #<.ident(.concat("__FIFO_SIZE__",.string(.left(1,{name}))))
          bne   :+
          ldx   #0
:         stx   a:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))
          RW_pull
  .endif
.endif
.endmac

/**
  FIFO_deq
  Read (dequeue) byte from FIFO buffer

  Value is returned in register a with z = 0.
  If queue is empty a is untouched and z = 1.

  :in:    name    Buffer name           string  value
*/
.macro FIFO_deq name
.if (.blank({data}))
  SFX_error "FIFO_read: Missing required parameter(s)"
.else
  .import .ident(.concat("__FIFO_SIZE__",.string(.left(1,{name})))): absolute
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
    .import .ident(.concat("__FIFO__",.string(.left(1,{name})))): far
    .import .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): far
          lda   #<.ident(.concat("__FIFO_SIZE__",.string(.left(1,{name}))))
          lda   f:.ident(.concat("__FIFO__",.string(.left(1,{name}))))
          sta   f:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))+1
  .else
    .import .ident(.concat("__FIFO__",.string(.left(1,{name})))): absolute
    .import .ident(.concat("__FIFO_META__",.string(.left(1,{name})))): absolute
          RW_push set:a8i8
          ldx   a:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))+1   ;x = tail
          cpx   a:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))     ;if (tail == head) return, z = 1
          beq   :++
          lda   a:.ident(.concat("__FIFO__",.string(.left(1,{name})))),x        ;a = buffer[tail]
          inx                                                                   ;++tail
          cpx   #<.ident(.concat("__FIFO_SIZE__",.string(.left(1,{name}))))     ;if (tail == size) tail = 0
          bne   :+
          ldx   #0
:         stx   a:.ident(.concat("__FIFO_META__",.string(.left(1,{name}))))+1
          rep   #$02                                                            ;z = 0
:         RW_pull
  .endif
.endif
.endmac


/**
  FILO_alloc
  Allocate static FILO (stack) buffer

  Buffer is allocated in the LORAM segment by default.
  If <name> ends with a token named "hi" or "ex" ("midi1-hi" for example)
  the buffer is instead allocated in HIRAM or EXRAM respectively.

  :in:    name    Name                  string  value
  :in:    size    Capacity in bytes     uint8   value
*/
.macro FILO_alloc name, size
.if (.blank({size}))
  SFX_error "FILO_alloc: Missing required parameter(s)"
.else
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
    .export .ident(.concat("__FILO__",.string(.left(1,{name})))): far
    .export .ident(.concat("__FILO_TOP__",.string(.left(1,{name})))): far
  .else
    .export .ident(.concat("__FILO__",.string(.left(1,{name})))): absolute
    .export .ident(.concat("__FILO_TOP__",.string(.left(1,{name})))): absolute
  .endif
  .export .ident(.concat("__FILO_SIZE__",.string(.left(1,{name})))): absolute = .lobyte(size)

  .pushseg
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi)))
    .segment "HIRAM"
  .elseif ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), ex)))
    .segment "EXRAM"
  .else
    .segment "LORAM"
  .endif
  .ident(.concat("__FILO__",.string(.left(1,{name})))): .res .lobyte(size)
  .ident(.concat("__FILO_META__",.string(.left(1,{name})))): .res 3
  .popseg

          RW_push set:a8i16
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
          lda   #$00
          sta   f:.ident(.concat("__FILO_TOP__",.string(.left(1,{name}))))
  .else
          stz   .ident(.concat("__FILO_TOP__",.string(.left(1,{name}))))
  .endif
          RW_pull
.endif
.endmac

/**
  FILO_push
  Write byte to FILO buffer

  :in:    name    Buffer name           string  value
  :in:    value   Value to push         uint8   a or constant
*/
.macro FILO_push name, data
.if (.blank({data}))
  SFX_error "FILO_write: Missing required parameter(s)"
.else
  .import .ident(.concat("__FILO_SIZE__",.string(.left(1,{name})))): absolute
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
    .import .ident(.concat("__FILO__",.string(.left(1,{name})))): far
    .import .ident(.concat("__FILO_TOP__",.string(.left(1,{name})))): far
          lda   #<.ident(.concat("__FILO_SIZE__",.string(.left(1,{name}))))
          lda   f:.ident(.concat("__FILO__",.string(.left(1,{name}))))
          sta   f:.ident(.concat("__FILO_TOP__",.string(.left(1,{name}))))+11
  .else
    .import .ident(.concat("__FILO__",.string(.left(1,{name})))): absolute
    .import .ident(.concat("__FILO_TOP__",.string(.left(1,{name})))): absolute
          lda   #<.ident(.concat("__FILO_SIZE__",.string(.left(1,{name}))))
          lda   a:.ident(.concat("__FILO__",.string(.left(1,{name}))))
  .endif
.endif
.endmac

/**
  FILO_pop
  Read byte from FILO buffer

  Value is returned in register a with z = 0.
  If empty stack z = 1.

  :in:    name    Buffer name           string  value
*/
.macro FILO_pop name
.if (.blank({data}))
  SFX_error "FILO_pop: Missing required parameter(s)"
.else
  .import .ident(.concat("__FILO_SIZE__",.string(.left(1,{name})))): absolute
  .if ((.tcount({name}) > 1) .and (.xmatch(.right(1,{name}), hi) .or .xmatch(.right(1,{name}), ex)))
    .import .ident(.concat("__FILO__",.string(.left(1,{name})))): far
    .import .ident(.concat("__FILO_TOP__",.string(.left(1,{name})))): far
          lda   #<.ident(.concat("__FILO_SIZE__",.string(.left(1,{name}))))
          lda   f:.ident(.concat("__FILO__",.string(.left(1,{name}))))
          sta   f:.ident(.concat("__FILO_TOP__",.string(.left(1,{name}))))+11
  .else
    .import .ident(.concat("__FILO__",.string(.left(1,{name})))): absolute
    .import .ident(.concat("__FILO_TOP__",.string(.left(1,{name})))): absolute
          lda   #<.ident(.concat("__FILO_SIZE__",.string(.left(1,{name}))))
          lda   a:.ident(.concat("__FILO__",.string(.left(1,{name}))))
  .endif
.endif
.endmac

.endif ;__MBSFX_CPU_DataStructures__
