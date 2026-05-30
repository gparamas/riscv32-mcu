`timescale 1ns / 10ps

module dmem #(
    // parameters
) (
    input logic clk, n_rst,
    input logic renm, wenm,
    input logic [31:0] addr, wdata,
    input logic [2:0] funct3,
    input logic [7:0] out_rdata,
    output logic [7:0] out_wdata,
    output logic [31:0] rdata, apb_addr,
    output logic read_en, write_en,
    output logic stall
);

    logic pwenm, prenm;
    logic [31:0] paddr, pwdata;
    logic [2:0] pfunct3;

    logic [31:0] data, n_data;
    logic [31:0] mask, n_mask;
    assign out_wdata = wdata[7:0];

    logic [1:0] state, next_state;
    assign apb_addr = addr;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            pwenm <= '0;
            prenm <= '0;
            paddr <= '0;
            pwdata <= '0;
            pfunct3 <= '0;
            data <= '0;
            mask <= '1;
            state <= '0;
        end
        else begin
            data <= n_data;
            mask <= n_mask;
            pwenm <= wenm;
            prenm <= renm;
            paddr <= addr;
            pwdata <= wdata;
            pfunct3 <= funct3;
            state <= next_state;
        end
    end


    logic [14:0] ram_raddr, ram_waddr;
    logic [31:0] ram_wdata, ram_rdata;
    logic ram_read_en, ram_write_en;

    ram #(.DEPTH(32768)) rambf (
        .clk(clk), .n_rst(n_rst),
        .raddr(ram_raddr),
        .waddr(ram_waddr),
        .ren(ram_read_en),
        .wen(ram_write_en),
        .wdata(ram_wdata),
        .rdata(ram_rdata)
    );

    always_comb begin
        n_data = '0;
        n_mask = '1;
        next_state = '0;
        ram_read_en = 1'b0;
        stall = 0; read_en = 0; write_en = 0;
        ram_raddr = addr[16:2];
        if(renm || wenm) begin
            if(!(&addr[17:16])) begin
                ram_read_en = 1'b1;
                if((addr[16:2] == paddr[16:2]) && renm && pwenm) begin
                    case(pfunct3[1:0])
                        2'b00: begin 
                                case(paddr[1:0])
                                    2'b00: begin n_data[7:0] = pwdata[7:0]; n_mask[7:0] = '0; end
                                    2'b01: begin n_data[15:8] = pwdata[7:0]; n_mask[15:8] = '0; end
                                    2'b10: begin n_data[23:16] = pwdata[7:0]; n_mask[23:16] = '0; end
                                    default: begin n_data[31:24] = pwdata[7:0]; n_mask[31:24] = '0; end
                                endcase
                            end
                        2'b01: begin
                                case(paddr[1:0])
                                    2'b10: begin n_data[31:16] = pwdata[15:0]; n_mask[31:16] = '0; end
                                    default: begin n_data[15:0] = pwdata[15:0]; n_mask[15:0] = '0; end
                                endcase
                            end
                        default: begin n_data = pwdata; n_mask = '0; end
                    endcase
                end
            end
            else if(state != 2'b11) begin
                stall = 1'b1;
                next_state = state == 2'b0 ? 2'b01 : (state == 2'b01) ? 2'b11 : 2'b0;
                read_en = renm;
                write_en = wenm;
            end
        end
    end

    logic [31:0] forwarded_data;
    assign forwarded_data = (ram_rdata & mask) | data;
    always_comb begin
        rdata = '0;
        ram_waddr = paddr[16:2];
        ram_write_en = 1'b0;
        ram_wdata = '0;
        if(prenm && (!(&paddr[17:16]))) begin
            case(pfunct3[1:0])
                2'b00: rdata = pfunct3[2] ?  {24'b0, forwarded_data[{paddr[1:0], 3'b0} +: 8]} : {{24{forwarded_data[{paddr[1:0], 3'b0} + 7]}}, forwarded_data[{paddr[1:0], 3'b0} +: 8]};
                2'b01: rdata = pfunct3[2] ? {16'b0, forwarded_data[{paddr[1:0], 3'b0} +: 16]} :  {{16{forwarded_data[{paddr[1:0], 3'b0} + 15]}}, forwarded_data[{paddr[1:0], 3'b0} +: 16]};
                2'b10: rdata = forwarded_data;
                default: rdata = forwarded_data;
            endcase
        end
        else if (pwenm && (!(&paddr[17:16]))) begin
            ram_write_en = 1'b1;
            case(pfunct3[1:0])
                2'b00: begin 
                        case(paddr[1:0])
                            2'b00: ram_wdata = {ram_rdata[31:8], pwdata[7:0]};
                            2'b01: ram_wdata = {ram_rdata[31:16], pwdata[7:0], ram_rdata[7:0]};
                            2'b10: ram_wdata = {ram_rdata[31:24], pwdata[7:0], ram_rdata[15:0]};
                            default: ram_wdata = {pwdata[7:0], ram_rdata[23:0]};
                        endcase
                    end
                2'b01: begin
                        case(paddr[1:0])
                            2'b10: ram_wdata = {pwdata[15:0], ram_rdata[15:0]};
                            default: ram_wdata = {ram_rdata[31:16], pwdata[15:0]};
                        endcase
                    end
                default: ram_wdata = pwdata;
            endcase
        end
        else if (&paddr[17:16]) begin
             rdata = {24'b0, out_rdata};
        end
    end
endmodule
