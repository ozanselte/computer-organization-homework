.macro print_newline
    li		$a0, 10		# $a0 = 10
    li		$v0, 11     # $v0 = 11
    syscall
.end_macro

.macro print_space
    li		$a0, 32		# $a0 = 32
    li		$v0, 11     # $v0 = 11
    syscall
.end_macro

.macro print_int(%x)
    move 	$a0, %x		# $a0 = %x
    li		$v0, 1		# $v0 = 1
    syscall
    print_newline
.end_macro

.macro print_intsp(%x)
    move 	$a0, %x		# $a0 = %x
    li		$v0, 1		# $v0 = 1
    syscall
    print_space
.end_macro

.macro print_str(%str)
    .data
    text_addr: .asciiz %str
    .text
    la 	    $a0, text_addr		# $a0 = text_addr
    li		$v0, 4		# $v0 = 4
    syscall
    print_newline
.end_macro

.macro print_strsp(%str)
    .data
    text_addr: .asciiz %str
    .text
    la 	    $a0, text_addr		# $a0 = text_addr
    li		$v0, 4		# $v0 = 4
    syscall
    print_space
.end_macro

.macro get_bytes(%x)
    move 	$a0, %x		# $a0 = %x
    li		$v0, 9		# $v0 = 9
    syscall
.end_macro

.macro get_words(%x)
    sll     %x, %x, 2
    get_bytes(%x)
.end_macro

.macro chr2dec(%x, %y)
    move 	$t8, %x		# $t8 = %x
    li		$t9, 10		# $t8 = 10
    mult	$t8, $t9	# $t8 * $t9 = Hi and Lo registers
    mflo	$t8			# copy Lo to $t8
    add		$t8, $t8, %y    # $t8 = $t8 + %y
    subi	%x, $t8, 48     # %x = $t8 - 48
.end_macro

.macro iter_idx(%i, %a)
    addi	%i, %i, 1			# %i = %i + 1
    addi	%a, %a, 4			# %a = %a + 4
.end_macro

.macro store_sregs
    subi	$sp, $sp, 36			# $sp = $sp - 36
    sw		$ra, 32($sp)
    sw		$s0, 28($sp)
    sw		$s1, 24($sp)
    sw		$s2, 20($sp)
    sw		$s3, 16($sp)
    sw		$s4, 12($sp)
    sw		$s5, 8($sp)
    sw		$s6, 4($sp)
    sw		$s7, 0($sp)
.end_macro

.macro load_sregs
    lw		$ra, 32($sp)
    lw		$s0, 28($sp)
    lw		$s1, 24($sp)
    lw		$s2, 20($sp)
    lw		$s3, 16($sp)
    lw		$s4, 12($sp)
    lw		$s5, 8($sp)
    lw		$s6, 4($sp)
    lw		$s7, 0($sp)
    addi	$sp, $sp, 36			# $sp = $sp + 36
.end_macro

.data
ncnt:   .word 0
scnt:   .word 0
nums:   .word 0
chck:   .word 0
sets:   .word 0
name:   .asciiz "list_x.txt"
fbuf:   .space  4096

.text
begin:
    jal		openfile	# jump to openfile and save position to $ra
    move 	$a0, $v0	# $a0 = $v0
    jal		readfile	# jump to readfile and save position to $ra
    move 	$a0, $v0	# $a0 = $v0
    jal		closefile	# jump to closefile and save position to $ra
    jal		countncnt	# jump to countncnt and save position to $ra
    move 	$a0, $v1	# $a0 = $v1
    jal		countscnt	# jump to countscnt and save position to $ra
    jal		initheaps	# jump to initheaps and save position to $ra
    jal		getnums		# jump to getnums and save position to $ra
    move 	$a0, $v0	# $a0 = $v0
    jal		getsets		# jump to getsets and save position to $ra
    print_strsp("Beginning")
    main_lp1:
        jal		count_ones	# jump to count_ones and save position to $ra
        move 	$t0, $v0	# $t0 = $v0
        print_strsp(", Uncovered Count: ")
        print_int($t0)
        beq		$v0, 0, main_end	# if $t0 == 0 then main_end
        jal		select_subset		# jump to select_subset and save position to $ra
        move 	$a0, $v0		# $a0 = $v0
        move 	$a1, $v1		# $a1 = $v1
        beq		$a0, 0, main_end	# if $v0 == 0 then main_end
        jal		clear_checks		# jump to clear_checks and save position to $ra
        j       main_lp1    # jump to main_lp1
    main_end:
        print_newline
        print_str("END")
        j		exit		# jump to exit    

openfile:
    li		$v0, 13		# $v0 = 13
    la		$a0, name   # $a0 = name
    li		$a1, 0		# $a1 = 0
    li		$a2, 0		# $a2 = 0
    syscall
    jr		$ra			# jump to $ra

closefile:
    li		$v0, 16		# $v0 = 16
    syscall
    jr		$ra			# jump to $ra

exit:
    li		$v0, 10		# $v0 = 10
    syscall

readfile:
    move 	$t0, $a0	# $t0 = $a0
    li		$v0, 14		# $v0 = 14
    la		$a1, fbuf	# $a1 = fbuf
    li		$a2, 1024	# $a2 = 1024
    syscall
    move 	$v0, $t0	# $v0 = $t0
    jr		$ra			# jump to $ra

countncnt:
    store_sregs
    li		$t0, 1		# $t0 = 0
    la		$s0, fbuf	# $s0 = fbuf
    lp_c1:
        lb		$t1, 0($s0)	# $t1 = $s0
        beq		$t1, 13, close1	# if $t1 == 13 then close1
        beq		$t1, 10, close1	# if $t1 == 10 then close1
        beq		$t1, 0, close1	# if $t1 == 0 then close1
        addi	$s0, $s0, 1		# $s0 = $s0 + 1
        bne		$t1, 32, lp_c1	# if $t1 != 32 then lp_c1
        addi	$t0, $t0, 1	# $t0 = $t0 + 1
        j		lp_c1		# jump to lp_c1
    close1:
        move 	$v0, $t0	# $v0 = $t0
        sw		$v0, ncnt   # ncnt = $v0
        move 	$v1, $s0		# $v1 = $s0
        load_sregs
        jr		$ra			# jump to $ra

countscnt:
    store_sregs
    move 	$s0, $a0		# $s0 = a0
    li		$t0, 0		# $t0 = 0
    lp_c2:
        addi	$s0, $s0, 1	# $s0 = $s0 + 1
        lb		$t4, 0($s0)	# $t4 = $s0
        beq		$t4, 0, close2	# if $t4 == 0 then close2
        bne		$t4, 10, lp_c2	# if $t4 != 10 then lp_c2
        addi	$t0, $t0, 1	# $t0 = $t0 + 1
        j		lp_c2		# jump to lp_c2
    close2:
        move 	$v0, $t0	# $v0 = $t0
        sw		$v0, scnt   # scnt = $v0
        load_sregs
        jr		$ra			# jump to $ra

initheaps:
    store_sregs
    lw		$t0, ncnt   # $t0 = ncnt
    get_words($t0)
    sw		$v0, nums	# nums = $v0
    lw		$t0, scnt   # $t0 = scnt
    get_words($t0)
    sw		$v0, sets	# sets = $v0
    lw		$t0, ncnt   # $t0 = ncnt
    get_bytes($t0)
    sw		$v0, chck	# chck = $v0
    li		$t4, 1		# $t4 = 1
    li		$t1, 0		# $t1 = 0
    move 	$t3, $v0	# $t3 = $v0
    init_lp:
        beq		$t0, $t1, init_cont	# if $t0 == $t1 then init_cont
        sb		$t4, 0($t3)         # $t3 = $t4
        addi	$t3, $t3, 1			# $t3 = $t3 + 1
        addi	$t1, $t1, 1			# $t1 = $t1 + 1
        j		init_lp				# jump to init_lp
    init_cont:
        load_sregs
        jr		$ra			# jump to $ra

getnums:
    store_sregs
    la		$s0, fbuf   # $s0 = fbuf
    lw		$s1, ncnt   # $s1 = ncnt
    lw		$s2, nums   # $s2 = nums
    li		$t0, 0		# $t0 = 0, readed count
    li		$t1, 0		# $t1 = 0, char
    li		$t2, 0		# $t2 = 0, number
    lp_c3:
        beq		$t0, $s1, close3	# if $t1 == $s1 then close3
        lb		$t1, 0($s0) # $t1 = $s0
        addi	$s0, $s0, 1	# $s0 = $s0 + 1
        blt		$t1, 48, save1	# if $t1 < 48 then save1
        bgt		$t1, 57, save1	# if $t1 > 57 then save1
        chr2dec($t2, $t1)
        j		lp_c3		# jump to lp_c3
    save1:
        sw		$t2, 0($s2)
        iter_idx($t0, $s2)
        li		$t2, 0		# $t2 = 0
        j		lp_c3		# jump to lp_c3
    close3:
        move 	$v0, $s0		# $v0 = $s0
        load_sregs
        jr		$ra		    # jump to $ra

getsets:
    store_sregs
    move 	$s0, $a0	# $s0 = $a0
    lw		$s1, scnt   # $s1 = scnt
    lw		$s2, sets   # $s2 = sets
    li		$s4, 1		# $s4 = 1
    li		$t1, 0		# $t1 = 0, readed set count
    li		$t2, 0		# $t2 = 0, char
    li		$t3, 0		# $t3 = 0, number
    lp_st1:
        beq		$t1, $s1, close4	# if $t1 == $s2 then close4
        lw		$v0, ncnt
        get_bytes($v0)
        sw		$v0, 0($s2)
        move 	$s3, $v0		# $s3 = $v0
    lp_c4:
        lb		$t2, 0($s0)
        addi	$s0, $s0, 1	    # $s0 = $s0 + 1
        beq		$t2, 10, save3	# if $t2 == 10 then save3
        beq		$t2, 13, save3	# if $t2 == 13 then save3
        beq		$t2, 32, save2	# if $t2 == 32 then save2
        beq		$t2, 0, save3	# if $t2 == 0 then save3
        chr2dec($t3, $t2)
        j		lp_c4		    # jump to lp_c4
    save2:
        move 	$a0, $t3		# $a0 = $t3
        jal		get_index		# jump to get_index and save position to $ra
        add		$t4, $v0, $s3	# $t4 = $t4 + $t3
        sb		$s4, 0($t4)     # $t4 = $s4
        li		$t3, 0		    # $t3 = 0
        j		lp_c4			# jump to lp_c4
    save3:
        move 	$a0, $t3		# $a0 = $t3
        jal		get_index		# jump to get_index and save position to $ra
        add		$t4, $v0, $s3	# $t4 = $t4 + $t3
        sb		$s4, 0($t4)     # $t4 = $s4
        li		$t3, 0		    # $t3 = 0
        beq		$t2, 0, close4	# if $t2 == 0 then close4
        iter_idx($t1, $s2)
        j		lp_st1			# jump to lp_st1
    close4:
        load_sregs
        jr		$ra				# jump to $ra

count_ones:
    store_sregs
    print_strsp(", Uncovered Set: ")
    lw		$s0, ncnt   # numbers count
    lw		$s1, chck   # numbers beginning address
    li		$s2, 0		# $s2 = 0, counter
    lw		$s3, nums	# $s3 = nums, real numbers beginning address
    li		$t0, 0		# $t0 = 0, current number's index
    li		$t1, 0		# $t1 = 0, current number
    li		$t2, 0		# $t2 = 0, current real number
    lp_n1:
        beq		$t0, $s0, close5    # if $t0 == $s0 then close5
        lb		$t1, 0($s1)     # $t1 = 0($s1)
        lb		$t2, 0($s3)     # $t2 = 0($s3)
        addi	$s1, $s1, 1		# $t1 = $t1 + 1
        addi	$s3, $s3, 4		# $s3 = $s3 + 4
        addi	$t0, $t0, 1		# $t0 = $t0 + 1
        bne		$t1, 1, lp_n1	# if $t1 != 1 then lp_n1
        addi	$s2, $s2, 1		# $s2 = $s2 + 1
        print_intsp($t2)
        j		lp_n1			# jump to lp_n1
    close5:
        move 	$v0, $s2		# $v0 = $s2
        load_sregs
        jr		$ra				# jump to $ra

select_subset:
    store_sregs
    lw		$s0, ncnt   # numbers count
    lw		$s1, chck   # numbers in set's beginning address
    lw		$s2, scnt	# subsets count
    lw		$s3, sets	# current subset's beginning address
    li		$s4, 0		# $s4 = 0, best subset's score
    li		$s5, 0		# $s5 = 0, best subset's address
    li		$s6, 0		# $s6 = 0, best subset's index
    li		$t0, 0		# $t0 = 0, current subset's index
    li		$t1, 0		# $t1 = 0, current number's index
    li		$t2, 0		# $t2 = 0, current number's address in subset
    li		$t3, 0		# $t5 = 0, current number in set
    li		$t4, 0		# $t4 = 0, current number in subset
    li		$t5, 0		# $t5 = 0, current subset's score
    lp_st2:
        beq		$t0, $s2, close6	# if $t0 == $s2 then close6
        lw		$s1, chck   # numbers in set's beginning address
        li		$t1, 0		# $t1 = 0, current number's index
        lw		$t2, 0($s3)	# current number's adress in subset
        li		$t5, 0		# $t5 = 0, current subset's score
    lp_c5:
        beq		$t1, $s0, iter_s1	# if $t1 == $s0 then iter_s1
        lb		$t3, 0($s1)
        lb		$t4, 0($t2)
        addi	$s1, $s1, 1			# $s1 = $s1 + 1
        addi	$t1, $t1, 1			# $t1 = $t1 + 1
        addi	$t2, $t2, 1			# $t2 = $t2 + 1
        add		$t9, $t3, $t4		# $t9 = $t3 + $t4
        bne		$t9, 2, lp_c5	    # if $t9 != 2 then lp_c5
        addi	$t5, $t5, 1			# $t5 = $t5 + 1
        j		lp_c5		# jump to lp_c5
    iter_s1:
        iter_idx($t0, $s3)
        ble		$t5, $s4, lp_st2	# if $t5 <= $s4 then lp_st2
        move 	$s4, $t5	# $s4 = $t5
        lw		$s5, -4($s3)
        move 	$s6, $t0	# $s6 = $t0
        subi    $s6, $s6, 1
        j		lp_st2		# jump to lp_st2
    close6:
        beq		$s4, 0, hurry1	# if $s4 == 0 then hurry1
        print_strsp("Selected Subset: ")
        print_intsp($s6)
        print_strsp(", Covered Count: ")
        print_intsp($s4)
    hurry1:
        move 	$v0, $s4	# $v0 = $s4
        move 	$v1, $s5	# $v1 = $s5
        load_sregs
        jr		$ra			# jump to $ra

clear_checks:
    store_sregs
    lw		$s0, ncnt   # set numbers count
    lw		$s1, chck   # set numbers beginning address
    move 	$s2, $a1	# $s2 = $a1
    li		$t0, 0		# $t0 = 0, number index
    lp_c6:
        beq		$t0, $s0, close7	# if $t0 == $s0 then close7
        lb		$t1, 0($s2)         # $t1 = $s2
        addi	$s1, $s1, 1			# $s1 = $s1 + 1
        addi	$s2, $s2, 1			# $s2 = $s2 + 1
        addi	$t0, $t0, 1			# $t0 = $t0 + 1
        bne		$t1, 1, lp_c6	    # if $t1 != 1 then lp_c6
        sb		$zero, -1($s1)      # $s1-1 = 0
        j		lp_c6				# jump to lp_c6
    close7:
        load_sregs
        jr		$ra			# jump to $ra

get_index:
    store_sregs
    move 	$s0, $a0		# $s0 = $a0
    lw		$s1, nums
    li		$s2, 0		    # $t8 = 0
    lw		$s3, ncnt
    li		$v0, -1         # $v0 = -1
    idx_lp1:
        beq		$s2, $s3, idx_close1	# if $t8 == $t9 then idx_close1
        lw		$t6, 0($s1)
        bne		$s0, $t6, idx_iter1	# if %x != $t6 then idx_iter1
        move	$v0, $s2	    # $v0 = $t8
        j		idx_close1		# jump to idx_close1
    idx_iter1:
        iter_idx($s2, $s1)
        j		idx_lp1			# jump to idx_lp1
    idx_close1:
        load_sregs
        jr		$ra				# jump to $ra
