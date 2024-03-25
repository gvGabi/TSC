/***********************************************************************
 * A SystemVerilog RTL model of an instruction regisgter:
 * User-defined type definiti
 **********************************************************************/
package instr_register_pkg;
  timeunit 1ns/1ns;

  typedef enum logic [3:0] {
  	ZERO,
    PASSA,
    PASSB,
    ADD,
    SUB,
    MULT,
    DIV,
    MOD
  } opcode_t;

  typedef enum logic [31:0] {
    INC,
    RAND,
    DEC
  } order_t;

  typedef logic signed [31:0] operand_t;
  typedef logic signed [63:0] operand_res;
  
  typedef logic [4:0] address_t;
  
  typedef struct {
    opcode_t    opc;
    operand_t   op_a;
    operand_t   op_b;
	  operand_res res;
  } instruction_t;

endpackage: instr_register_pkg
