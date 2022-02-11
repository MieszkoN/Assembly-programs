.eqv BMP_FILE_SIZE 90122
.eqv BYTES_PER_ROW 1800
.eqv ROW_TO_PROCEED 25
.eqv WIDTH 600
.eqv HEIGHT 50
.eqv BITMAP_NUMBER_OF_BITS_PER_PIXEL 24
.eqv HEADER_SIZE 54
.eqv WIDTH_OFFSET 18
.eqv HEIGHT_OFFSET 22
.eqv BITMAP_NUMBER_OF_BITS_PER_PIXEL_OFFSET 28
.eqv DATA_SECTION_OFFSET 34
.eqv BYTES_PER_PIXEL 3
.eqv ASCII_START 32
.eqv START_A 103
.eqv START_B 104
.eqv START_C 105
.eqv STOP_CODE 106
.eqv STOP_CODE_INDEX 424
.eqv ASCII_SET_CHANGE 95

	.data
buffer: .space 2
header:	.space 54
result:	.space 150
fname: .asciiz "source.bmp"

#text messages
incorrect_file_descriptor_exception_message: .asciiz "There is a problem in identifying a file descriptor! The file with the given name is not opened.\n"
incorrect_file_width_exception_message:	.asciiz	"There is a problem in reading the width of the bmp file! It is not 600px.\n"
incorrect_file_height_exception_message: .asciiz "There is a problem in reading the height of the bmp file! It is not 50px.\n"
incorrect_number_of_bits_per_pixel_exception_message: .asciiz "There is a problem in reading bits per pixel value! It is not 24bpp.\n"
no_barcode_exception_message: .asciiz "There is a problem in detecting barcode! No barcode found.\n"
code_set_B_exception_message: .asciiz "There is a problem in reading character! This is not code B.\n"
code_set_C_exception_message: .asciiz "There is a problem in reading character! This is not code C.\n"
incorrect_check_symbol_exception_message: .asciiz "There is a problem with check symbol value!\n"
incorrect_stop_code_value_exception_message: .asciiz "There is a problem in finding code value!\n"
incorrect_barcode_exception_message: .asciiz "There is a problem in a barcode! There is no such code value.\n"
change_set_character_exception_message: .asciiz "There is a problem with character! This program does not change code set."
result_message: .asciiz "There is a following text in bitmap: \n"

#b -> bar, s -> space
#bsbsbs
#212222 -> each digit refers how many 1's or 0's are present in the binary number
#b -> 1
#s -> 0
#11011001100
#binary -> decimal
code_set_A: .word 1740, 1644, 1638, 1176, 1164, 1100, 1224, 1220, 1124, 1608,
		  1604, 1572, 1436, 1244, 1230, 1484, 1260, 1254, 1650, 1628,
		  1614, 1764, 1654, 1902, 1868, 1836, 1830, 1892, 1844, 1842,
		  1752, 1734, 1590, 1304, 1112, 1094, 1416, 1128, 1122, 1672,
		  1576, 1570, 1464, 1422, 1134, 1496, 1478, 1142, 1910, 1678, 
		  1582, 1768, 1762, 1774, 1880, 1862, 1814, 1896, 1890, 1818,
		  1914, 1602, 1930, 1328, 1292, 1200, 1158, 1068, 1062, 1424,
		  1412, 1232, 1218, 1076, 1074, 1554, 1616, 1978, 1556, 1146,
		  1340, 1212, 1182, 1508, 1268, 1266, 1956, 1940, 1938, 1758,
		  1782, 1974, 1400, 1310, 1118, 1512, 1506, 1960, 1954, 1502,
		  1518, 1886, 1966, 1668, 1680, 1692, 6379

	.text
	.globl main
main:

open_file:
	li $v0, 13
	la $a0, fname
	li $a1, 0
	li $a2, 0
	syscall

#handle_file_exceptions
check_file_descriptor:
	bltz $v0, incorrect_file_descriptor_exception
	move $s0, $v0

read_header:	
	li $v0, 14
	move $a0, $s0
	la $a1, header
	li $a2, HEADER_SIZE
	syscall

check_width:	
	lw $t0, header+WIDTH_OFFSET
	bne $t0, WIDTH, incorrect_file_width_exception

check_height:	
	lw $t0, header+HEIGHT_OFFSET
	bne $t0, HEIGHT, incorrect_file_height_exception

check_number_of_bits_per_pixel:	
	lb $t0, header+BITMAP_NUMBER_OF_BITS_PER_PIXEL_OFFSET
	bne $t0, BITMAP_NUMBER_OF_BITS_PER_PIXEL, incorrect_number_of_bits_per_pixel_exception

store_data:		
	lw $s3, header+DATA_SECTION_OFFSET
	li $v0, 9
	move $a0, $t4
	syscall
	move $s4, $v0
	
read_file:
	li $v0, 14
	move $a0, $s0
	move $a1, $s4
	move $a2, $s3
	syscall
	
close_file:
	li $v0, 16
	move $a0, $s0
	syscall
	
get_starting_pixel:
	move $t0, $s4
	li $s4, 0
	li $t1, ROW_TO_PROCEED
	li $t2, BYTES_PER_ROW
	mul $t1, $t1, $t2
	add $t0, $t0, $t1
	li $t3, 0
	la $a3, result
	
find_barcode:
	lb $t4, ($t0)
	beqz $t4, calculate_width
	
proceed_row:
	add $t0, $t0, BYTES_PER_PIXEL
	add $t3, $t3, 1
	blt $t3, WIDTH, find_barcode

no_barcode_exception:
	li $v0, 4
	la $a0, no_barcode_exception_message
	syscall
	j exit

calculate_width:
	li $t5, 1
	la $t1, ($t0)
	
loop:
	add $t1, $t1, BYTES_PER_PIXEL
	lb $t4, ($t1)
	bnez $t4, get_width
	add $t5, $t5, 1
	beq $t5, $t3, no_barcode_exception
	bne $t5, $t3, loop

get_width:
	srl $t2, $t5, 1
	move $t1, $t2 
	mul $t2, $t1, 5 
	
clear_registers:
	li $s0, 0
	li $s1, 0
	li $s2, 1
	li $s3, 0
	
start:
	li $t5, 0
	lb $t6, ($t0)

get_bar_or_space:
	lb $t4, ($t0)
	add $t5, $t5, 1
	add $t0, $t0, BYTES_PER_PIXEL
	move $t4, $t6
	bne $t5, $t1, get_bar_or_space
	
bar_or_space:
	add $s1, $s1, 1
	beq $t6, 1, white_space
	beq $t6, 0, black_bar
	
white_space:
	or $s0, $s0, $s3
	beq $s1, 11, get_code
	sll $s0, $s0, 1
	j start
	
black_bar:
	or $s0, $s0, $s2
	beq $s1, 11, get_code
	sll $s0, $s0, 1
	j start
	
get_code:
	li $t5, 0
	la $t9, code_set_A
	
continue:
	lw $t7, ($t9)
	bne $s0, $t7, more_characters

get_character_code:
	beq $t5, START_A, start_decoding
	beq $t5, START_B, code_set_B_exception
	beq $t5, START_C, code_set_C_exception
	bgt $t5, ASCII_SET_CHANGE, change_set_character_exception
	add $s4, $s4, 1
	move $s5, $t5
	mul $s6, $s4, $s5
	add $s7, $s7, $s6
	add $t5, $t5, ASCII_START
	bge $t5, ASCII_SET_CHANGE, subtract_ASCII
	sb $t5, ($a3)
	add $a3, $a3, 1
	j clear_registers
	
subtract_ASCII:
	sub $t5, $t5, ASCII_SET_CHANGE
	sb $t5, ($a3)
	add $a3, $a3, 1
	j clear_registers
	
start_decoding:
	add $s7, $s7, $t5
	j clear_registers

more_characters:
	add $t5, $t5, 1
	add $t9, $t9, 4
	bne $t5, STOP_CODE, continue
	xor $s1, $s1, $s1
	
get_bars:
	li $t5, 0
	lb $t6, ($t0)
	
while:
	lb $t4, ($t0)
	add $t5, $t5, 1
	add $t0, $t0, BYTES_PER_PIXEL
	move $t4, $t6
	bne $t5, $t1, while
	sll $s0, $s0, 1
	beq $t6, 0, set_bar
	bne $t6, 1, incorrect_barcode_exception
	
set_white_space:
	or $s0, $s0, $s3
	beq $s1, 2, get_stop_code_value
	j get_bars
	
set_bar:
	or $s0, $s0, $s2
	add $s1, $s1, 1
	bne $s1, 2, get_bars
	
get_stop_code_value:
	la $a1, code_set_A+STOP_CODE_INDEX
	lw $a2, ($a1)
	bne $s0, $a2, incorrect_stop_code_value_exception

calculate_check_symbol:
	sub $s7, $s7, $s6
	li $t7, 103
	div $s7, $t7
	xor $t7, $t7, $t7
	mfhi $t7
	bne $t7, $s5, incorrect_check_symbol_exception
	
ignore_check_symbol_character:
	li $t4, '\0'
	sub $a3, $a3, 1
	sb $t4, ($a3)
	
print_result:
	li $v0, 4
	la $a0, result_message
	syscall
	la $a0, result
	syscall
	j exit
	
incorrect_file_descriptor_exception:
	li $v0, 4
	la $a0, incorrect_file_descriptor_exception_message
	syscall
	j exit
	
incorrect_file_width_exception:
	li $v0, 4
	la $a0, incorrect_file_width_exception_message
	syscall
	j exit
	
incorrect_file_height_exception:
	li $v0, 4
	la $a0, incorrect_file_width_exception_message
	syscall
	j exit
	
incorrect_number_of_bits_per_pixel_exception:
	li $v0, 4
	la $a0, incorrect_number_of_bits_per_pixel_exception_message
	syscall
	j exit
	
incorrect_barcode_exception:
	li $v0, 4
	la $a0, incorrect_barcode_exception_message
	syscall
	j exit
	
code_set_B_exception:
	li $v0, 4
	la $a0, code_set_B_exception_message
	j exit
	
code_set_C_exception:
	li $v0, 4
	la $a0, code_set_C_exception_message
	j exit
	
change_set_character_exception:
	li $v0, 4
	la $a0, change_set_character_exception_message
	j exit	

incorrect_stop_code_value_exception:
	li $v0, 4
	la $a0, incorrect_stop_code_value_exception_message
	syscall
	j exit
	
incorrect_check_symbol_exception:
	li $v0, 4
	la $a0, incorrect_check_symbol_exception_message
	syscall
	
exit:
	li $v0, 10
	syscall
