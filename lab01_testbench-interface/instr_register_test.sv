/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   output operand_res    exp_res,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns;

  parameter WRITE_NR = 50;
  parameter READ_NR = WRITE_NR -1;
  //2 parametri noi: WRITE_ORDER, READ_ORDER
  parameter WRITE_ORDER = 1;  //dupa ma asigur ca merg 7, dupa 50
  parameter READ_ORDER = 1;
  //9 cazuri de testare -> i-i,i-r,i-d;r-i,r-r,r-d;d-i,d-r,d-i
  parameter TEST_NAME;
  parameter SEED_VAL;
  operand_res dut_res;   //variabila pentru rezultatul primit din dut
  instruction_t  iw_reg_test [0:31];  // an array of instruction_word structures

  int pass = 0;
  int fail = 0;

  int seed = SEED_VAL;

  initial begin   //la timpul 0 al simularii se executa codul
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS A SELF-CHECKING TESTBENCH.  YOU  DON'T    ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES    ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION ***");
    $display(    "**********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    //repeat (3) begin
      repeat(WRITE_NR) begin  //modificat in 11.03
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
      save_test_data;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    //for (int i=0; i<=2; i++) begin
    for (int i=0; i<=READ_NR-1; i++) begin  //modificat in 11.03
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back

      //@(posedge clk) read_pointer = i;
      @(posedge clk)
      case(READ_ORDER)
        0: read_pointer <= i;
        1: read_pointer <= $unsigned($random)%32;
        2: read_pointer <= 31-(i%32);
      endcase
      @(negedge clk) print_results;
      check_results;
    end

    final_report;

    @(posedge clk) ;
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS A SELF-CHECKING TESTBENCH.  YOU  DON'T    ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES    ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION ***");
    $display(    "**********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //

    static int temp = 0;    // static -> e alocata o singura data
    static int temp_dec = 31;
    operand_a     <= $random(seed)%16;                 // between -15 and 15 ->random genereaza pe 32biti; pseudoaleator-algoritm in functie de vendor
    operand_b     <= $unsigned($random)%16;            // between 0 and 15  -> $unsigned -converteste nr neg in pozitive
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type  -> opcode_t' -cast-conversie de la un tip de date la altul
    //write_pointer <= temp++;    //se asigneaza si dupa de incrementeaza
    //write_pointer - 3 cazuri: inc, random, dec
    case (WRITE_ORDER)    //modificat 25.03
      0: write_pointer <= temp++;
      1: write_pointer <= $unsigned($random)%32; 
      2: write_pointer <= temp_dec--;
    endcase
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d", instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  result = %0d\n", instruction_word.res);
  endfunction: print_results

  always@(instruction_word.res)
    dut_res = instruction_word.res;
    
  function void save_test_data;
    iw_reg_test[write_pointer]= '{opcode,operand_a,operand_b,0};
    $display("Saved data:  opcode = %0d (%s), operand_a = %0d, operand_b = %0d.", iw_reg_test[write_pointer].opc, iw_reg_test[write_pointer].opc.name, iw_reg_test[write_pointer].op_a, iw_reg_test[write_pointer].op_b);
    $display("Saved at location %0d.\n",write_pointer);
  endfunction: save_test_data


  function void check_results;
    $display("Reading from location %0d",read_pointer);
    if(iw_reg_test[read_pointer].opc == instruction_word.opc)
      $display("Corresponding opcode.");
    else $display("Wrong opcode.");
    if(iw_reg_test[read_pointer].op_a == instruction_word.op_a)
      $display("Corresponding operand_a.");
    else $display("Wrong operand_a.");
    if(iw_reg_test[read_pointer].op_b == instruction_word.op_b)
      $display("Corresponding operand_b.");
    else $display("Wrong operand_b.");


    if (instruction_word.opc == ZERO)
      exp_res = 0;
    else if (instruction_word.opc == PASSA)
      exp_res = instruction_word.op_a;
    else if (instruction_word.opc == PASSB)
      exp_res = instruction_word.op_b;
    else if (instruction_word.opc == ADD)
      exp_res = instruction_word.op_a + instruction_word.op_b;
    else if (instruction_word.opc == SUB)
      exp_res = instruction_word.op_a - instruction_word.op_b;
    else if (instruction_word.opc == MULT)
      exp_res = instruction_word.op_a * instruction_word.op_b;
    else if (instruction_word.opc == DIV) 
      if (instruction_word.op_b == 0) 
        exp_res = 0;
      else exp_res = instruction_word.op_a / instruction_word.op_b;      
    else if (instruction_word.opc == MOD)
      if (instruction_word.op_b == 0) 
        exp_res = 0;
      else exp_res = instruction_word.op_a % instruction_word.op_b;
  
    if (exp_res == dut_res) begin
      $display("\nExpected result: %0d. Received result: %0d.\nTest PASSED.\n", exp_res, dut_res);
      $display("------------------------------------\n");
      pass++;
    end
    else begin 
      $display("\nExpected result: %0d. Received result: %0d.\nTest FAILED.\n", exp_res, dut_res);
      $display("------------------------------------\n");
      fail++;
    end
  endfunction: check_results

  function void final_report;
    // $display("--- FINAL REPORT ---");
    // $display("Operations passed: %0d/%0d.",pass,WRITE_NR);
    // $display("Operations failed: %0d/%0d.",fail,WRITE_NR);

    int fd;
    fd = $fopen("../reports/regression_status.txt", "a");
    if(fail == 0) begin
      $fdisplay(fd, "%s: PASSED", TEST_NAME);
      $fdisplay(fd, "Operations passed: %0d/%0d.",pass,WRITE_NR);
    end
    else begin
      $fdisplay(fd, "%s: FAILED", TEST_NAME);
      $fdisplay(fd, "Operations passed: %0d/%0d.",pass,WRITE_NR);
    end
    
  endfunction: final_report

endmodule: instr_register_test

//semn, ridicat la putere, salvare forme de unda, adaugare parametru, comenzi git
