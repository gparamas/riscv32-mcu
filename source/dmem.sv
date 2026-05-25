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
    logic [44800:0] [31:0] ram, nram;
    assign out_wdata = wdata[7:0];

    logic [1:0] state, next_state;
    assign apb_addr = addr;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            ram <= '0;
            data <= '0;
            pwenm <= '0;
            prenm <= '0;
            paddr <= '0;
            pwdata <= '0;
            pfunct3 <= '0;
            state <= '0;
        end
        else begin
            ram <= nram;
            data <= n_data;
            pwenm <= wenm;
            prenm <= renm;
            paddr <= addr;
            pwdata <= wdata;
            pfunct3 <= funct3;
            state <= next_state;
        end
    end

    always_comb begin
        n_data = 0;
        next_state = '0;
        stall = 0; read_en = 0; write_en = 0;
        if(renm || wenm) begin
            if(addr < 32'h25000) begin
                n_data = ram[addr[18:2]];
                if((addr[18:2] == paddr[18:2]) && renm && pwenm) begin
                    case(pfunct3[1:0])
                        2'b00: begin 
                                case(paddr[1:0])
                                    2'b00: n_data[7:0] = pwdata[7:0];
                                    2'b01: n_data[15:8] = pwdata[7:0];
                                    2'b10: n_data[23:16] = pwdata[7:0];
                                    default: n_data[31:24] = pwdata[7:0];
                                endcase
                            end
                        2'b01: begin
                                case(paddr[1:0])
                                    2'b10: n_data[31:16] = pwdata[15:0];
                                    default: n_data[15:0] = pwdata[15:0];
                                endcase
                            end
                        default: n_data = pwdata;
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


    always_comb begin
        nram = ram;
        rdata = '0;
        if(prenm && paddr < 32'h25000) begin
            case(pfunct3[1:0])
                2'b00: rdata = pfunct3[2] ?  {24'b0, data[{paddr[1:0], 3'b0} +: 8]} : {{24{data[{paddr[1:0], 3'b0} + 7]}}, data[{paddr[1:0], 3'b0} +: 8]};
                2'b01: rdata = pfunct3[2] ? {16'b0, data[{paddr[1:0], 3'b0} +: 16]} :  {{16{data[{paddr[1:0], 3'b0} + 15]}}, data[{paddr[1:0], 3'b0} +: 16]};
                2'b10: rdata = data;
                default: rdata = data;
            endcase
        end
        else if (pwenm && paddr < 32'h25000) begin
            case(pfunct3[1:0])
                2'b00: begin 
                        case(paddr[1:0])
                            2'b00: nram[paddr[18:2]] = {data[31:8], pwdata[7:0]};
                            2'b01: nram[paddr[18:2]] = {data[31:16], pwdata[7:0], data[7:0]};
                            2'b10: nram[paddr[18:2]] = {data[31:24], pwdata[7:0], data[15:0]};
                            default: nram[paddr[18:2]] = {pwdata[7:0], data[23:0]};
                        endcase
                    end
                2'b01: begin
                        case(paddr[1:0])
                            2'b10: nram[paddr[18:2]] = {pwdata[15:0], data[15:0]};
                            default: nram[paddr[18:2]] = {data[31:16], pwdata[15:0]};
                        endcase
                    end
                default: nram[paddr[18:2]] = pwdata;
            endcase
        end
        else if (paddr >= 32'h25000) begin
             rdata = {24'b0, out_rdata};
        end
    end




endmodule

