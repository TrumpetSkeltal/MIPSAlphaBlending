.data
	header1:    .space 54
	header2:    .space 54
	savingBuffer:   .space 3
	input_arr1: .word 0 #pixel array of input nr 1
    	input_arr2: .word 0 #pixel array of input nr 2
    	output_padding: .word 0 #output padding size
    	input_padding1: .word 0
    	input_padding2: .word 0
    	weight1:    .word 0
   	weight2:    .word 0
    	outputSize: .word 0
    	outputHeight:   .word 0
    	outputWidth:    .word 0
    	input1Height:   .word 0
    	input1Width:    .word 0
    	input2Height:   .word 0
    	input2Width:    .word 0
    	input1RowSize:  .word 0
    	input2RowSize:  .word 0
    	outputRowSize:  .word 0
    	divConstant:    .word 255
    	minWidth:   .word 0
    	minHeight:  .word 0
    	widthDiff:  .word 0
    	higherWidth:.word 0
    	higherPadding:	.word 0
    	widerPadding:	.word 0
    	narrowerPadding:	.word 0
    	outputDescriptor:   .word 0
    	file1:	.space 256
    	file2:	.space 256
	output: .asciiz "output.bmp"
	text0:  .asciiz "Enter weight for 2nd image (0-255)"
	text1:	.asciiz "Enter file name 1"
	text2:	.asciiz "Enter file name 2"
.text
.globl main
   
.macro weighted_blend (%input1Blue,%input1Green,%input1Red, %input2Blue, %input2Green, %input2Red)
	lw $t5, weight1
    	lw $t6, weight2
   	 
  
    andi %input1Blue, %input1Blue, 0xFF
    andi %input1Green, %input1Green, 0xFF
    andi %input1Red, %input1Red, 0xFF
    andi %input2Blue, %input2Blue, 0xFF
    andi %input2Green, %input2Green, 0xFF
    andi %input2Red, %input2Red, 0xFF
    
    #calculate output Blue
    multu %input1Blue, $t5
    mflo $s0
    multu %input2Blue, $t6
    mflo $t0
    addu $s0, $s0, $t0
    srl $s0, $s0, 8
    #s0 now containts our output Blue
   
    #calculate output Green
    multu %input1Green, $t5
    mflo $s1
    multu %input2Green, $t6
    mflo $t1
    addu $s1,$s1, $t1
    srl $s1, $s1, 8
    #s1 contains our output Green
   
    #calculate output Red

    mult %input1Red, $t5
    mflo $s2
    mult %input2Red, $t6
    mflo $t2
    addu $s2, $s2, $t2
    srl $s2, $s2, 8
   
    #s2 now contains our output Red
    .end_macro
   
   
    .macro save_to_output (%descriptor, %buffer, %amount)
    li $v0, 15
    move $a0, %descriptor
    move $a1, %buffer
    li $a2, %amount
    syscall
    .end_macro
    
    .macro print_color_value(%register)
    li $v0, 1
    move $a0 %register
    syscall 
    li $v0, 11
    li $a0, '\n'
    syscall
    .end_macro
#<----------------------------------------------------------------------------------------------------------------------------->  
main :
 
    #enter weights for blending
    	la $a0, text0
    	li $v0, 4
    	syscall
    	li $v0, 5
    	syscall
    	sw $v0, weight1
    	li $v1, 256
    	sub $v1, $v1, $v0
   	 sw $v1, weight2
    
    #enter filename 1
    	la $a0, text1
    	li $v0, 4
    	syscall
    	la $a0, file1
    	li $a1, 256
    	li $v0, 8
    	syscall
	la $t8, file1
loop:
	lb $t9, ($t8)
	beq $t9, '\n', remove
	addiu $t8, $t8, 1
	b loop
remove:
	sb $zero, ($t8)
	 
    #enter filename 2
    la $a0, text2
    li $v0, 4
    syscall
    la $a0, file2
    li $a1, 256
    li $v0, 8
    syscall
    	la $t7, file2
loop2:
	lb $t9, ($t8)
	beq $t9, '\n', remove2
	addiu $t8, $t8, 1
	b loop2
remove2:
	sb $zero, ($t8)
   
    #open first file
    la $a0, file1
    li $a1, 0
    li $v0, 13
    syscall
    move $s0, $v0
   
    #open second file
    la $a0, file2
    li $a1, 0
    li $v0, 13
    syscall
    move $s1 $v0
   
    #read first file
    li $v0, 14
    move $a0, $s0
    la $a1, header1
    li $a2, 54
    syscall
   
    #read second file
    li $v0, 14
    move $a0, $s1
    la $a1, header2
    li $a2, 54
    syscall
   
    #find max height and width to create result file
    #t0,t2 - height | t1,t3 - width
    ulw $t0, header1+22
    ulw $t1, header1+18
   
    ulw $t2, header2+22
    ulw $t3, header2+18
   
    #saving height of first file to t9
    move $t9, $t0
    sw $t9, input1Height
    #saving width of first file to t8
    move $t8, $t1
    sw $t8, input1Width
    #saving height of second file to t7
    move $t7, $t2
    sw $t7, input2Height
    #saving width of second file to t6
    move $t6, $t3
    sw $t6, input2Width
  
    #calculate input1 rowsize
    sll $s4, $t8, 1
    add $s4, $s4, $t8
    sll $s4, $s4, 3
    addi    $s4, $s4, 31
    srl $s4, $s4, 5
    sll $s4, $s4, 2
   
    #calculate input2 rowsize
    sll $s5, $t6, 1
    add $s5, $s5, $t6
    sll $s5, $s5, 3
    addi    $s5, $s5, 31
    srl $s5, $s5, 5
    sll $s5, $s5, 2
   
    sw $s4, input1RowSize
    sw $s5, input2RowSize
   
    #calculate padding for input1 file. Used later in blending loop
    ulw $t1, header1+18
    sll $t0, $t1, 1
    addu $t0, $t0, $t1
    andi $t0, $t0, 3
    li $t1, 4
    subu $t0, $t1, $t0
    andi $t0, $t0, 3
    sw $t0, input_padding1
    #calculate padding for input2 file. Used later in blending loop
    ulw $t1, header2+18
    sll $t0, $t1, 1
    addu $t0, $t0, $t1
    andi $t0, $t0, 3
    li $t1, 4
    subu $t0, $t1, $t0
    andi $t0, $t0, 3
    sw $t0, input_padding2
   
    #we now have Rowsizes of inputs in s4 and s5 respectively
    #compare height to find biggest values
    lw $t0, input1Height
    lw $t2, input2Height
    bgt $t0, $t2, compare_width
    sw $t0, minHeight
    move  $t0, $t2
   
compare_width:
    #compare width to find biggest values
    lw $t1, input1Width
    lw $t3, input2Width
    sw $t2, minHeight
    bgt $t1, $t3, continue
    sw $t1, minWidth
    move  $t1, $t3
 
continue:
    #now we have biggest height and width in t0 and t1 respectively
    sw $t0, outputHeight
    sw $t1, outputWidth
    sw $t3, minWidth
   
    #create new bmp with size : max height and max width (our result file)
    li  $v0, 13
    la  $a0, output
    li  $a1, 1
    li  $a2, 0
    syscall
    move    $s2, $v0
    sw  $s2, outputDescriptor
       
    #calculate size of new file.Rowsize = ((24*t1 + 31)/32)*4 Size = RowSize * height + 54.
    sll $s3, $t1, 1
    add $s3, $s3, $t1
    sll $s3, $s3, 3
    addi    $s3, $s3, 31
    srl $s3, $s3, 5
    sll $s3, $s3, 2
   
    # s3 now contains our rowsize. Now we calculate the file size
    sw $s3, outputRowSize
   
    multu   $s3, $t0
    mflo    $t4
    addi    $t3, $t4, 54
   
    #t3 finally has our file size
    sw $t3, outputSize
 
   
    # we update data in header2 to get new header for our output file with correct height,width and size
    usw $t0, header2 + 22
    usw $t1, header2 + 18
    usw $t3, header2 + 2
   
    #store new header in output file  
    li  $v0, 15
    move    $a0, $s2
    la  $a1, header2
    li $a2, 54
    #move   $a2, $t3
    syscall
   
    # Calculate space needed for pixel array of first input
    multu   $s4, $t9
    mflo    $s7
    #size of first pixel array in s7
   
    # Calculate space needed for pixel array of second input
    multu   $s5, $t7    
    mflo    $s6
    #size of second pixel array in s6
   
    #now allocate memory for first pixel array.
    move $a0, $s7
    li $v0, 9
    syscall
    sw $v0, input_arr1
    move $a1, $v0
 
    #save pixel array1 in allocated space
    move $a2, $s7
    move $a0, $s0
    #zmiana na la
    #la $a1, input_arr1
    li $v0, 14
    syscall
   
    #we now can close file nr 1
    move $a0, $s0
    li $v0, 16
    syscall
 
    #now allocate memory for second pixel array.
    move $a0, $s6
    li $v0, 9
    syscall
    sw $v0, input_arr2
    move $a1, $v0
   
    #save pixel array2 in allocated space
    move $a2, $s6
    move $a0, $s1
    li $v0, 14
    syscall
   
    #we now can close file nr 2
    move $a0, $s1
    li $v0, 16
    syscall
       
    #calculate padding for output file. Might be needed later on to complete the bmp image
    ulw $t1, header2+18
    sll $t0, $t1, 1
    addu $t0, $t0, $t1
    andi $t0, $t0, 3
    li $t1, 4
    subu $t0, $t1, $t0
    andi $t0, $t0, 3
    sw $t0, output_padding
   
#<--------------------------------------------------------------------------------------------------------------------------------------------------------------->
    #begin blending in a loop consisting of 4 possible parts
    #start with creating "pointers" to both input arrays
    #loading additional things needed for blending loop
    lw $s3, minHeight
    lw $s4, minWidth
    lw $s5, input_padding1
    lw $s6, input_padding2
    lw $t5, minHeight #used later in loop
    lw $s7, outputDescriptor
    la $v1, savingBuffer
    lw $s0, input1Width
    lw $s1, input2Width
    
   
    blt $s0, $s1, get_lower_width
    lw $t4, input1Width
    lw $k0, input_arr1
    lw $k1, input_arr2
    sw $s5, widerPadding
    sw $s6, narrowerPadding
    addu $t4, $t4, $s5
    subu $t4, $t4, $s1
    sw $t4, widthDiff
   
get_lower_width:
    lw $t4, input2Width
    lw $t3, input_padding1
    lw $k0, input_arr2
    lw $k1, input_arr1
    sw $s5, narrowerPadding
    sw $s6, widerPadding
    addu $t4, $t4, $s6
    subu $t4, $t4, $s0
    sw $t4, widthDiff
    #we have wider array in k0
    #counter to check if we still blend 2 images
    move $t9, $zero
    move $t7, $t4
moveAcrossRow:
    lw $s0, minHeight
    lw $v0, widerPadding
    beqz $v0, moveAcrossRowContinue
    add $k0, $k0, $v0
moveAcrossRowContinue:    
    bge $t9, $s0, printOnlyHigherPreLoop
    addi $t9, $t9, 1
    move $t8, $zero
blend:
	#we reached the end of min width
    bge $t8, $s4, tryToPrintWiderPre
    lb $s0, 0($k0)
    lb $s1, 1($k0)
    lb $s2, 2($k0)	
    lb $t0, 0($k1)
    lb $t1, 1($k1)
    lb $t2, 2($k1)
    weighted_blend($s0,$s1,$s2,$t0,$t1,$t2)
    addi $k0, $k0, 3
    addi $k1, $k1, 3
    sb $s0, ($v1)
    save_to_output($s7,$v1,1)
    sb $s1, ($v1)
    save_to_output($s7,$v1,1)
    sb $s2, ($v1)
    save_to_output($s7,$v1,1)
    addi $t8, $t8, 1
    b blend
    
 tryToPrintWiderPre:
 	lw $t7, widthDiff
 	lw $v0, narrowerPadding
 	beqz $v0, tryToPrintWider
 	add $k1, $k1, $v0
tryToPrintWider:
    ble $t7, $zero, moveAcrossRow
    lb $s0, 0($k0)
    sb $s0, ($v1)
    save_to_output($s7,$v1,1)
    addi $k0, $k0, 1
    subi $t7, $t7, 1
    b tryToPrintWider
   
printOnlyHigherPreLoop:
    #change higher array to k0, shorter to k1
    lw $t7, input1Height
    lw $t8, input2Height
    blt $t7, $t8, assignPointersHeightLoop
    lw $v0, input_padding1
    sw $v0, higherPadding
    lw $s0, input1Width
    lw $s1, input2Width
   blt $s0, $s1, secondWasWider
   # we are here it means that first input was wider
    sw $t7, higherWidth
   b printOnlyHigherOuterPre
secondWasWider:
	#we are here it means that second was wider so inputArr1 is in k1 but we need to change that cuz input1 was higher
	lw $a3, ($k0)
	move $k0, $k1
	move $k1, $a3
	sw $t7, higherWidth
	b printOnlyHigherOuterPre
   
assignPointersHeightLoop:
#we are here that means that second is higher. But which was wider? :0
blt $s0, $s1, secondWasWiderAgain
    #we are here that means first input was wider so it was in k0 but we need it switched
    sw $t8, higherWidth 
    lw $v0, input_padding2
    sw $v0, higherPadding
    move $a3, $k0
    move $k0, $k1
    move $k1, $a3
  sw $t8, higherWidth
    b printOnlyHigherOuterPre
secondWasWiderAgain:
	#second was wider that means that it is in k0 so we dont need to swap
	sw $t8, higherWidth
printOnlyHigherOuterPre:
	lw $t5, minHeight
printOnlyHigherOuter:
    lw $s3, outputHeight
    bge $t5, $s3, exitBlending
    move $s3, $zero
    lw $a3, higherWidth
   
printOnlyHigherInner:
	#a3 szerokosc wyzszego
 	bge $s3, $a3, printEmpty
   	lb $s0, 0($k0)
	lb $s1, 1($k0)
    	lb $s2, 2($k0)
    	addi $k0, $k0, 3
    	sb $s0, ($v1)
    	save_to_output($s7,$v1,1)
    	sb $s1, ($v1)
     	save_to_output($s7,$v1,1)
    	sb $s2, ($v1)
    	save_to_output($s7,$v1,1)
    #increment our iterator - we moved 1 pixel ahead
    	addi $s3, $s3, 1
    	b printOnlyHigherInner
  
printEmpty:
	lw $v0, higherPadding
	beqz $v0, printEmptyContinue
	add $k0, $k0, $v0
printEmptyContinue:
   	lw $t7, outputWidth
   	bge $s3, $t7, addOutputPadding
    #load black color to "empty" space
    	li $s0, 0
    	sb $s0, ($v1)
        save_to_output($s7,$v1,1)
	sb $s1, ($v1)
        save_to_output($s7,$v1,1)
   	sb $s2, ($v1)
        save_to_output($s7,$v1,1)
   	addi $s3, $s3, 1
    	b printEmpty
   
addOutputPadding:
    lw $t7, output_padding
    beqz $t7, continueOutput
paddingLoop:
    blez $t7, continueOutput
    li $s0, 0
    sb $s1, ($v1)
    save_to_output($s7,$v1,1)
    subi $t7, $t7, 1
    b paddingLoop
continueOutput:
    addi $t5, $t1, 1
    b printOnlyHigherOuter
   
exitBlending:
    #we finished blending. Entire image is now in output.
    #close output file
    lw $s0, outputDescriptor
    move $a0, $s0
    li $v0, 16
    syscall
end_program:
 
    li $v0, 10
    syscall
