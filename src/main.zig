const std = @import("std");
const ray = @import("raylib.zig");

const Key = enum { A, S, D, F, J, K, L, SEMICOLON };

const Note = struct {
    time: f32,
    key: Key,
};

const Map = struct {
    alloc: *std.mem.Allocator,
    notes: []const Note,
    pub fn fromString(alloc: *std.mem.Allocator, text: []const u8) !Map {
        var res_notes = std.ArrayList(Note).init(alloc);
        errdefer res_notes.deinit();
        var lines = std.mem.split(text, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) break;
            var cols = std.mem.split(line, ": ");
            _ = cols.next().?;
            const note: Note = .{
                .key = std.meta.stringToEnum(Key, cols.next().?).?,
                .time = try std.fmt.parseFloat(f32, cols.next().?),
            };
            try res_notes.append(note);
        }
        return Map{
            .alloc = alloc,
            .notes = res_notes.toOwnedSlice(),
        };
    }
    pub fn deinit(map: Map) void {
        map.alloc.free(map.notes);
    }
};

const note_w: f32 = 20;
const note_h: f32 = 20;
const hitline = 400;

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const map = blk: {
        const map_txt = try std.fs.cwd().readFileAlloc(alloc, "music.map", std.math.maxInt(usize));
        defer alloc.free(map_txt);
        break :blk try Map.fromString(alloc, map_txt);
    };
    defer map.deinit();

    const window_w = 800;
    const window_h = 450;
    ray.InitWindow(window_w, window_h, "sample");
    defer ray.CloseWindow();
    ray.InitAudioDevice();
    defer ray.CloseAudioDevice();

    ray.SetTargetFPS(60);

    const music: ray.Music = ray.LoadMusicStream("music.mp3");
    ray.PlayMusicStream(music);

    var overlays = std.ArrayList(Note).init(alloc);
    defer overlays.deinit();

    var ocursor: usize = 0;

    var cursor: usize = 0;
    while (!ray.WindowShouldClose()) {
        ray.UpdateMusicStream(music);

        var ctime: f32 = ray.GetMusicTimePlayed(music);
        inline for (.{ "A", "S", "D", "F", "J", "K", "L", "SEMICOLON" }) |key| {
            if (ray.IsKeyPressed(
                @field(ray, "KEY_" ++ key),
            )) {
                std.log.info("{s}: {d}", .{ key, ctime });
                const enumv = @field(Key, key);
                overlays.append(.{ .key = enumv, .time = ctime }) catch @panic("oom");
            }
        }

        while (cursor < map.notes.len and map.notes[cursor].time < ctime - 1) {
            cursor += 1;
        }
        while (ocursor < overlays.items.len and overlays.items[ocursor].time < ctime - 1) {
            ocursor += 1;
        }

        ray.BeginDrawing();
        ray.ClearBackground(ray.BLACK);

        var j: c_int = 0;
        while (j < 8) : (j += 1) {
            const x = @intToFloat(f32, j) * 50 + 100;
            ray.DrawRectangle(
                @floatToInt(c_int, x),
                0,
                1,
                window_h,
                ray.GRAY,
            );
        }
        ray.DrawRectangle(0, hitline, window_w, 1, ray.RAYWHITE);

        var i = cursor;
        while (i < map.notes.len and map.notes[i].time < ctime + 1) : (i += 1) {
            renderNote(map.notes[i], ctime, ray.WHITE);
        }
        var ii = ocursor;
        while (ii < overlays.items.len and overlays.items[ii].time < ctime + 1) : (ii += 1) {
            renderNote(overlays.items[ii], ctime, ray.RED);
        }

        ray.EndDrawing();
    }
}

fn renderNote(note: Note, ctime: f32, color: ray.Color) void {
    const noffset = note.time - ctime;
    const nscale: f32 = 1 - std.math.fabs(noffset);
    const w = note_w * nscale;
    const h = note_h * nscale;
    ray.DrawRectangle(
        @floatToInt(c_int, @intToFloat(f32, @enumToInt(note.key)) * 50 + 100 - (w / 2)),
        @floatToInt(c_int, -(noffset * 500) + hitline - (h / 2)),
        @floatToInt(c_int, w),
        @floatToInt(c_int, h),
        color,
    );
}
