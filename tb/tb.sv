//Модуль для тестирования pkt_stat
module tb;
parameter A_WIDTH = 3;
parameter D_WIDTH = 32;

logic               clk;
logic               rst;

logic [A_WIDTH-1:0] rx_flow_num;
logic [15:0]        pkt_size;
logic               pkt_size_ena;
                           
logic               rd_stb;
logic [A_WIDTH-1:0] rd_flow_num;

logic [D_WIDTH-1:0] rd_data;
logic               rd_data_val;

bit [D_WIDTH-1:0] test_ram [2**A_WIDTH-1:0];
bit [D_WIDTH-1:0] rd_ram   [2**A_WIDTH-1:0];
bit [A_WIDTH-1:0] rd_flow_num_d;
int a;

initial 
  begin
    clk = 1'b0;
    forever
      begin
        #10.0 clk = ~clk;
      end
  end

initial 
  begin
    rst = 1'b1;
    #11.0 rst = 1'b0;
    $display( "RST done" );
  end


logic first_rd;
initial
  begin
    init();
    #30.0
    wr_1_flow_and_rd();
    @cb;
    wr_2_flow_and_rd();
    @cb;
    all_random();
  end

clocking cb @( posedge clk );
endclocking
task wr_stat( input [A_WIDTH-1:0]  _rx_flow_num,
              input [15:0]         _pkt_size,
	      input                _pkt_size_ena
                                                );
  @cb;
  rx_flow_num  <= _rx_flow_num;
  pkt_size     <= _pkt_size;
  pkt_size_ena <= _pkt_size_ena;

endtask

task rd_stat( input [A_WIDTH-1:0]  _rd_flow_num,
	      input                _rd_stb
                                                );
  @cb;
  rd_flow_num <= _rd_flow_num;
  rd_stb      <= _rd_stb;

  @cb;
  rd_stb <= 1'b0;
  
endtask

task init();
  rx_flow_num  <= 0;
  pkt_size     <= 0;
  pkt_size_ena <= 0;
  rd_flow_num  <= 0;
  rd_stb       <= 0;
endtask

//Test task
task check( );
  wait( rd_data_val )
    @cb;
    if( test_ram != rd_ram )
      $display( $time, "ERROR" );
endtask


task wr_1_flow_and_rd ();
  $display("WR 1 flow and rd");
  stat.ram.rst_ram();

  repeat( 7 )
     begin
       wr_stat( 0, 16'd100, 1'b1 );
     end
  rd_stat( 0, 1'b1 );

   repeat( 2 )
     begin
       wr_stat( 0, 16'd100, 1'b1 );
     end

  wr_stat( 0, 16'd100, 1'b0 );
  rd_stat( 0, 1'b1 );

  @cb;
  check();
  $display("Done");

endtask

task wr_2_flow_and_rd();
    $display( "wr 2 flow and rd" );
    stat.ram.rst_ram();

    wr_stat( 0, 16'd100, 1'b1 );
    wr_stat( 1, 16'd100, 1'b1 );
    wr_stat( 0, 16'd100, 1'b1 );

    wr_stat( 1, 16'd100, 1'b1 );
    wr_stat( 0, 16'd100, 1'b1 );
    wr_stat( 1, 16'd100, 1'b1 );

    wr_stat( 1, 16'd100, 1'b0 );
    wr_stat( 0, 16'd100, 1'b1 );
    wr_stat( 1, 16'd100, 1'b0 );
    rd_stat( 0, 1'b1          );
    wait( rd_data_val )
      begin
	@cb;
        rd_stat( 1, 1'b1 );
      end
    @cb;
    check();
    $display("Done");
endtask

task all_random();
  $display( "All random" );
  stat.ram.rst_ram();
  
  repeat( 7 )
    begin
      wr_stat( $random, $random, 1'b1 );
    end

  rd_stat( $random, 1'b1 );

  repeat( 7 )
    begin
      wr_stat( $random, $random, $random );
    end
    
  wr_stat( $random, $random, 1'b0 );
  rd_stat( 0, 1'b1 );
  for( int a = 1; a < 2**A_WIDTH; a++ )
    begin
      wait( rd_data_val )
          begin
            @cb;
            rd_stat( a, 1'b1 );
          end
    end

    @cb;
    check();
    $display("Done");
  
endtask
//Test rams

always_ff @( posedge clk or posedge rst)
  begin
    if( pkt_size_ena )
      begin
        test_ram[rx_flow_num] <= test_ram[rx_flow_num] + pkt_size;
      end
  end

always @( posedge rd_data_val )
  begin
    rd_ram[rd_flow_num_d] <= rd_ram[rd_flow_num_d] + rd_data;
  end


always_ff @( posedge clk or posedge rst)
  begin
     rd_flow_num_d <= rd_flow_num;
  end

  
  
stat_pkt 
#(
  .D_WIDTH ( D_WIDTH ),
  .A_WIDTH ( A_WIDTH )
) stat (
  .clk_i              ( clk           ),
  .rst_i              ( rst           ),

  .rx_flow_num_i      ( rx_flow_num   ),
  .pkt_size_i         ( pkt_size      ),
  .pkt_size_ena_i     ( pkt_size_ena  ),

  .rd_stb_i           ( rd_stb        ),
  .rd_flow_num_i      ( rd_flow_num   ),

  .rd_data_o          ( rd_data       ),
  .rd_data_val_o      ( rd_data_val   )
);
endmodule
