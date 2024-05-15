const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const mclk = hal.clocks.mclk;
const gclk = hal.clocks.gclk;
const sercom = hal.sercom;
const port = hal.port;
const timer = hal.timer;
const Lcd = board.Lcd;

const board = microzig.board;
const tft_rst_pin = board.TFT_RST;
const tft_lite_pin = board.TFT_LITE;
const tft_dc_pin = board.TFT_DC;
const tft_cs_pin = board.TFT_CS;
const tft_sck_pin = board.TFT_SCK;
const tft_mosi_pin = board.TFT_MOSI;

const led_pin = microzig.board.D13;

var fb0: [Lcd.width][Lcd.height]Lcd.Color16 = undefined;
var fb1: [Lcd.width][Lcd.height]Lcd.Color16 = undefined;

// fn tft_write_cmd(word: u8) void {
//     tft_mosi_pin.set_dir(.out);
//     tft_cs_pin.write(.high);
//     timer.delay(5);
//     tft_cs_pin.write(.low);
//     tft_dc_pin.write(.low);
//     timer.delay(5);
//     for (0..8) |i| {
//         tft_mosi_pin.write(switch ((word >> i) & 1) {
//             0 => .low,
//             1 => .high,
//         });
//         timer.delay(5);
//         tft_sck_pin.write(.high);
//         timer.delay(10);
//         tft_sck_pin.write(.low);
//         timer.delay(5);
//     }
// }

// fn tft_read_param() u8 {
//     tft_mosi_pin.set_dir(.in);
//     timer.delay(5);
//     tft_dc_pin.write(.high);
//     timer.delay(5);
//     var bits: u8 = 0;
//     for (0..8) |i| {
//         tft_sck_pin.write(.high);
//         timer.delay(5);
//         const bit = @intFromEnum(tft_mosi_pin.read());
//         bits |= @as(u8, bit) << i;
//         timer.delay(5);
//         tft_sck_pin.write(.low);
//         timer.delay(10);
//     }

//     return bits;
// }

pub fn main() !void {
    led_pin.set_dir(.out);

    mclk.set_apb_mask(.{
        .SERCOM4 = .enabled,
        .TC0 = .enabled,
        .TC1 = .enabled,
    });

    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    gclk.set_peripheral_clk_gen(.GCLK_SERCOM4_CORE, .GCLK1);
    gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK1);

    timer.init();
    var lcd = Lcd.init(.{
        .spi = sercom.spi.Master.init(.SERCOM4, .{
            .cpha = .LEADING_EDGE,
            .cpol = .IDLE_LOW,
            .dord = .MSB,
            .dopo = .PAD2,
            .ref_freq_hz = 120_000_000,
            .baud_freq_hz = 60_000_000,
        }),
        .pins = .{
            .rst = board.TFT_RST,
            .lite = board.TFT_LITE,
            .dc = board.TFT_DC,
            .cs = board.TFT_CS,
            .sck = board.TFT_SCK,
            .mosi = board.TFT_MOSI,
        },
        .fb = .{
            .bpp16 = &fb1,
        },
    });

    // var i: usize = 0;
    // for (0..160) |xi| {
    //     for (0..128) |yi| {
    //         const x: u8 = @intCast(xi);
    //         const y: u8 = @intCast(yi);
    //         fb0[x][y] = .{
    //             .r = @truncate(x ^ y),
    //             .g = 0,
    //             .b = @truncate(x ^ y),
    //         };
    //         fb1[x][y] = .{
    //             .r = @truncate(x ^ y),
    //             .g = 63,
    //             .b = @truncate(x ^ y),
    //         };
    //         i += 1;
    //     }
    // }

    // while (true) {
    //     lcd.set_window(0, 0, 160, 128);
    //     lcd.send_colors(@as([*]const Lcd.Color16, @ptrCast(&fb0))[0..128 * 160]);
    //     lcd.set_window(0, 0, 160, 128);
    //     lcd.send_colors(@as([*]const Lcd.Color16, @ptrCast(&fb1))[0..128 * 160]);
    // }

    var i: u6 = 0;
    while (true) {
        for (0..160) |xi| {
            for (0..128) |yi| {
                const x: u8 = @intCast(xi);
                const y: u8 = @intCast(yi);

                lcd.set_window(x, y, x + 1, y + 1);
                lcd.send_color(.{
                    .r = @truncate(x ^ y ^ i),
                    .g = i * 63,
                    .b = @truncate(x ^ y ^ i),
                }, 1);
            }
        }
        i ^= 1;
    }

    // lcd.clear_screen(.{
    //     .r = 31,
    //     .g = 0,
    //     .b = 0,
    // });

    // timer.delay_us(1 * std.time.us_per_s);
    // lcd.set_window(0, 0, 10, 10);

    lcd.clear_screen(.{
        .r = 31,
        .g = 0,
        .b = 31,
    });

    // while (true) {
    //     timer.delay_us(1 * std.time.us_per_s);
    //     led_pin.write(.high);
    //     timer.delay_us(1 * std.time.us_per_s);
    //     led_pin.write(.low);
    // }
}
