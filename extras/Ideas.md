#Ideas for possible additions to libSFX code/macro library


##Automate tests
Build, invoke emulator, dump RAM and diff against known good output..?


##Decent PRG
Go for pcg-random or settle for something simpler?


##Graphics pipeline
Make "SuperFamiconv" public and usable... :)
Or maybe integrate one of the existing and working python scripts instead.


##Move "meta-instruction"
Probably not a good idea after all, since while debugging code it will look too different from source.

Registers:
a
x
y
d    Direct page
db   Data bank
pb   Program bank
s    Stack


;Register to register move
move  a, x            ;tax
move  a, y            ;tay
move  x, a            ;txa
move  y, a            ;tya
move  x, y            ;txy
move  y, x            ;tyx

move  a, d            ;tcd
move  x, d            ;phx pld
move  y, d            ;phy pld
move  d, a            ;tdc
move  d, x            ;phd plx
move  d, y            ;phd ply

move  a, db           ;pha plb
move  db, a           ;phb pla


;Move to stack (implicit pre-decrement)
move  a, s            ;pha
move  x, s            ;phx
move  y, s            ;phy
move  d, s            ;phd
move  db, s           ;phb
move  pb, s           ;phk

move  #$aabb, s       ;pea #$aabb
move  ($20), s        ;pei ($20)
move  label, s        ;per label

;Move from stack (implicit post-increment)
move  s, a            ;pla
move  s, x            ;plx
move  s, y            ;ply
move  s, d            ;pld
move  s, db           ;plb

;Immediate
move  #$ca, a         ;lda #$ca
move  #$c0d3, x       ;ldx #$c0d3

move  $4000, a        ;lda $4000
move  a, $4000        ;sta $4000

move  a:$4000, a      ;lda a:$4000
move  a, z:$40        ;sta z:$40

move  a, $4000+x      ;sta $4000,x
move  $6000+y, a      ;lda $6000,y

move  a, f:$804000+x  ;sta f:$804000,x

move  ($40)+y, a      ;lda ($40),y
move  ($40+x), a      ;lda ($40,x)

;Stack relative
move  s+3, a        ;lda  3,s
move  (s+3)+y, a    ;lda  (3,s),y
