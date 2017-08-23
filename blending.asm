.data
	header1:	.space 54
	header2:	.space 54
	input_arr1:	.word 0 #pixel array of input nr 1
	input_arr2:	.word 0 #pixel array of input nr 2
#open_error
	#print error

file1:	.asciiz "fileDebug1.bmp"
file2:	.asciiz "fileDebug2.bmp"
output:	.asciiz "output.bmp"

	.text
	.globl main
main :	
	#open first file
	la $a0, file1
	li $a1, 0
	li $v0, 13
	syscall
	move $s0, $v0
	
	#open second file
	la $a0 file2
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
	
	#ulw $t0, header1 + 2
	#ulw $t1, header2 + 2
	
	#find max height and width to create result file
	#t0,t2 - height | t1,t3 - width
	ulw $t0, header1+22
	ulw $t1, header1+18
	
	ulw $t2, header2+22
	ulw $t3, header2+18
	
	#saving height of first file to t9
	la $t9, ($t0)
	#saving width of fist file to t8
	la $t8, ($t1)
	#saving height of second file to t7
	la $t7, ($t2)
	#saving width of second file to t6
	la $t6, ($t3)
	
	#calculate input1 rowsize
	sll	$s4, $t8, 1
	add	$s4, $s4, $t8
	sll	$s4, $s4, 3 
	addi	$s4, $s4, 31
	srl	$s4, $s4, 5
	sll	$s4, $s4, 2
	
	#calculate input2 rowsize
	sll	$s5, $t6, 1
	add	$s5, $s5, $t6
	sll	$s5, $s5, 3 
	addi	$s5, $s5, 31
	srl	$s5, $s5, 5
	sll	$s5, $s5, 2
	
	#we now have Rowsizes of inputs in s4 and s5 respectively
	
	#compare height to find biggest values
	bgt $t0, $t2, compare_width
	move  $t0, $t2
	
compare_width:
	#compare width to find biggest values
	bgt $t1, $t3, continue
	move  $t1, $t3
	
	#now we have biggest height and width in t0 and t1 respectively
	
continue:
#create new bmp with size : max height and max width (our result file)
	li	$v0, 13
	la	$a0, output
	li	$a1, 1
	li	$a2, 0
	syscall
	move	$s2, $v0
		
	#calculate size of new file.Rowsize = ((24*t1 + 31)/32)*4 Size = RowSize * height + 54. 
	sll	$s3, $t1, 1
	add	$s3, $s3, $t1
	sll	$s3, $s3, 3 
	addi	$s3, $s3, 31
	srl	$s3, $s3, 5
	sll	$s3, $s3, 2
	
	# s3 now contains our rowsize. Now we calculate the file size
	
	multu	$s3, $t0 
	mflo	$t4
	addi	$t3, $t4, 54
	
	#t3 finally has our file size
	# we update data in header2 to get new header for our output file with correct height,width and size
	usw $t0, header2 + 22
	usw $t1, header2 + 18
	usw $t3, header2 + 2
	
	#store new header in output file	
	li	$v0, 15
	move	$a0, $s2
	la	$a1, header2
	#li	$a2, 54
	move	$a2, $t3
	syscall
	
	# Calculate space needed for pixel array of first input
	multu	$s4, $t9
	mflo	$s7
	#size of first pixel array in s7
	
	# Calculate space needed for pixel array of second input
	multu	$s5, $t7 	
	mflo	$s6
	#size of second pixel array in s6
	
	#now allocate memory for first pixel array.
	move $a0, $s7
	li $v0, 9
	syscall
	sw $v0, input_arr1

	#save pixel array1 in allocated space
	move $a2, $s7
	move $a0, $s0
	lw $a1, input_arr1
	li $v0, 14
	syscall
	
	#lw $a0, ($v0)
	#li $v0, 1
	#syscall
	
	#we now can close file nr 1
	move $a0, $s0
	li $v0, 16
	syscall
	
	
	
	
	#now allocate memory for second pixel array.
	move $a0, $s6
	li $v0, 9
	syscall
	sw $v0, input_arr2
	
	#save pixel array2 in allocated space
	move $a2, $s6
	move $a0, $s1
	lw $a1, input_arr2
	li $v0, 14
	syscall
	
	#we now can close file nr 2
	move $a0, $s1
	li $v0, 16
	syscall
		
		
	#begin blending in a loop consisting of 4 possible parts
	#start with creating "pointers" to both input arrays
	
	lw $k0, input_arr1
	lw $k1, input_arr2
	#case 1 - both images overlap so we need to calculate a weighted mean from the pixel values
both_images_crossing:
	

end_program:
	
	li $v0, 10
	syscall
