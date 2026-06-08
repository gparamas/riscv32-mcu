`timescale 1ns / 10ps

module dmem #(
    // parameters
) (
    input logic clk,
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

    logic [31:0] data;
    assign out_wdata = wdata[7:0];

    logic [1:0] state, next_state;
    assign apb_addr = addr;

    logic [15:0] ram_raddr, ram_waddr;
    logic [31:0] ram_wdata, ram_rdata;
    logic ram_read_en, ram_write_en;

    ram #(.DEPTH(44800)) rambf (
        .clk(clk),
        .raddr(ram_raddr),
        .waddr(ram_waddr),
        .ren(ram_read_en),
        .wen(ram_write_en),
        .wdata(ram_wdata),
        .rdata(ram_rdata)
    );

    initial begin
        data = '0;
        pwenm = '0;
        prenm = '0;
        paddr = '0;
        pwdata = '0;
        pfunct3 = '0;
        state = '0;
    end

    always_ff@(posedge clk) begin
        pwenm <= wenm;
        prenm <= renm;
        paddr <= addr;
        pwdata <= wdata;
        pfunct3 <= funct3;
        state <= next_state;
    end

    always_comb begin
        data = 0;
        next_state = '0;
        ram_read_en = 1'b0;
        stall = 0; read_en = 0; write_en = 0;
        if(renm || wenm) begin
            if(addr < 32'h2C000) begin
                ram_read_en = 1'b1;
                ram_raddr = addr[17:2];
                data = ram_rdata;
                if((addr[17:2] == paddr[17:2]) && renm && pwenm) begin
                    case(pfunct3[1:0])
                        2'b00: begin 
                                case(paddr[1:0])
                                    2'b00: data[7:0] = pwdata[7:0];
                                    2'b01: data[15:8] = pwdata[7:0];
                                    2'b10: data[23:16] = pwdata[7:0];
                                    default: data[31:24] = pwdata[7:0];
                                endcase
                            end
                        2'b01: begin
                                case(paddr[1:0])
                                    2'b10: data[31:16] = pwdata[15:0];
                                    default: data[15:0] = pwdata[15:0];
                                endcase
                            end
                        default: data = pwdata;
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
        rdata = '0;
        if(prenm && paddr < 32'h2C000) begin
            case(pfunct3[1:0])
                2'b00: rdata = pfunct3[2] ?  {24'b0, data[{paddr[1:0], 3'b0} +: 8]} : {{24{data[{paddr[1:0], 3'b0} + 7]}}, data[{paddr[1:0], 3'b0} +: 8]};
                2'b01: rdata = pfunct3[2] ? {16'b0, data[{paddr[1:0], 3'b0} +: 16]} :  {{16{data[{paddr[1:0], 3'b0} + 15]}}, data[{paddr[1:0], 3'b0} +: 16]};
                2'b10: rdata = data;
                default: rdata = data;
            endcase
        end
        else if (pwenm && paddr < 32'h2C000) begin
            ram_waddr = paddr[17:2];
            ram_write_en = 1'b1;
            case(pfunct3[1:0])
                2'b00: begin 
                        case(paddr[1:0])
                            2'b00: ram_wdata = {data[31:8], pwdata[7:0]};
                            2'b01: ram_wdata = {data[31:16], pwdata[7:0], data[7:0]};
                            2'b10: ram_wdata = {data[31:24], pwdata[7:0], data[15:0]};
                            default: ram_wdata = {pwdata[7:0], data[23:0]};
                        endcase
                    end
                2'b01: begin
                        case(paddr[1:0])
                            2'b10: ram_wdata = {pwdata[15:0], data[15:0]};
                            default: ram_wdata = {data[31:16], pwdata[15:0]};
                        endcase
                    end
                default: ram_wdata = pwdata;
            endcase
        end
        else if (paddr >= 32'h2C000) begin
             rdata = {24'b0, out_rdata};
        end
    end
endmodule

