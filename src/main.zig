const std = @import("std");
const delve = @import("delve");
const app = delve.app;
const colors = delve.colors;

const graphics = delve.platform.graphics;
const math = delve.math;
const mesh = delve.graphics.mesh;
const mem = delve.mem;

const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Vec2 = math.Vec2;
const Color = colors.Color;
const Mesh = mesh.Mesh;
const MeshBuilder = mesh.MeshBuilder;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// const test_asset = @embedFile("static/test.gif");
var camera: delve.graphics.camera.Camera = undefined;
var material: graphics.Material = undefined;

var cube1: delve.graphics.mesh.Mesh = undefined;
var cube2: delve.graphics.mesh.Mesh = undefined;
var cube3: delve.graphics.mesh.Mesh = undefined;
var triangle: delve.graphics.mesh.Mesh = undefined;

var time: f64 = 0.0;

pub fn main() !void {
    // Pick the allocator to use depending on platform
    const builtin = @import("builtin");
    if (builtin.os.tag == .wasi or builtin.os.tag == .emscripten) {
        // Web builds hack: use the C allocator to avoid OOM errors
        // See https://github.com/ziglang/zig/issues/19072
        try delve.init(std.heap.c_allocator);
    } else {
        // Using the default allocator will let us detect memory leaks
        try delve.init(delve.mem.createDefaultAllocator());
    }

    const example = delve.modules.Module{
        .name = "meshbuilder_example",
        .init_fn = on_init,
        .tick_fn = on_tick,
        .draw_fn = on_draw,
        .cleanup_fn = on_cleanup,
    };

    try delve.modules.registerModule(example);
    try delve.module.fps_counter.registerModule();

    try app.start(app.AppConfig{ .title = "Delve Framework - Mesh Builder Example" });
}

fn createTriangle(p1: Vec3, p2: Vec3, p3: Vec3, trans: math.Mat4, color: Color, mat: graphics.Material) !Mesh {
    var builder = MeshBuilder.init(mem.getAllocator());
    defer builder.deinit();

    try builder.addTriangle(p1, p2, p3, trans, color);

    return builder.buildMesh(mat);
}

pub fn on_init() !void {
    // var img = delve.images.loadBytes(test_asset) catch {
    //     delve.debug.log("Error loading image", .{});
    //     return;
    // };
    // defer img.deinit();
    // const tex = graphics.Texture.init(img);
    const tex = graphics.Texture.initFromBytes(1, 1, &[_]u8{255, 255, 255, 255});

    const shader = try graphics.Shader.initFromBuiltin(.{ .vertex_attributes = delve.graphics.mesh.getShaderAttributes() }, delve.shaders.default_mesh);

    // Create a material out of the texture
    material = try graphics.Material.init(.{
        .shader = shader,
        .own_shader = true,
        .texture_0 = tex,
        .samplers = &[_]graphics.FilterMode{.NEAREST},
    });

    // create our camera
    camera = delve.graphics.camera.Camera.initThirdPerson(90.0, 0.01, 20.0, 5.0, math.Vec3.up);

    // make a cube
    cube1 = delve.graphics.mesh.createCube(math.Vec3.new(0, 0, 0), math.Vec3.new(2, 3, 1), delve.colors.white, material) catch {
        delve.debug.log("Could not create cube!", .{});
        return;
    };

    // make a cube
    cube1 = delve.graphics.mesh.createCube(math.Vec3.new(0, 0, 0), math.Vec3.new(2, 3, 1), delve.colors.white, material) catch {
        delve.debug.log("Could not create cube!", .{});
        return;
    };

    // and another
    cube2 = delve.graphics.mesh.createCube(math.Vec3.new(3, 0, -1), math.Vec3.new(1, 1, 2), delve.colors.green, material) catch {
        delve.debug.log("Could not create cube!", .{});
        return;
    };

    // and then a floor
    cube3 = delve.graphics.mesh.createCube(math.Vec3.new(0, -2, 0), math.Vec3.new(12, 0.25, 12), delve.colors.red, material) catch {
        delve.debug.log("Could not create cube!", .{});
        return;
    };

    triangle = try createTriangle(math.Vec3.new(-1, 0, 0), math.Vec3.new(1, 0, 0), math.Vec3.new(0, 1, 0), math.Mat4.identity, delve.colors.blue, material);

    // set a bg color
    delve.platform.graphics.setClearColor(delve.colors.examples_bg_dark);

    // capture mouse
    delve.platform.app.captureMouse(true);
}

pub fn on_tick(delta: f32) void {
    if (delve.platform.input.isKeyJustPressed(.ESCAPE))
        delve.platform.app.exit();

    time += delta;

    camera.runSimpleCamera(8 * delta, 120 * delta, true);
}

pub fn on_draw() void {
    const view_mats = camera.update();
    // var model = math.Mat4.identity;
    const model = math.Mat4.identity;

    const frustum = camera.getViewFrustum();
    if (!frustum.containsPoint(math.Vec3.new(0, 0, 0))) {
        return;
    }

    // cube1.draw(view_mats, model.mul(math.Mat4.rotate(@floatCast(time * 40.0), math.Vec3.new(0, 1, 0))));
    cube2.draw(view_mats, model);
    cube3.draw(view_mats, model);
    triangle.draw(view_mats, model);
}

pub fn on_cleanup() !void {
    material.deinit();
}