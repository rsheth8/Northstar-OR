"""Build the 3D Northstar OR emblem in Blender and render it.

Run from the repo root:
  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
    -P docs/brand/source/emblem_blender.py -- docs/brand
The signal and star come from build_brand.py so 2D and 3D always match.
"""
import bpy, math, sys, os
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_brand as flat

OUT = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene

def hexc(h, a=1.0):
    h = h.lstrip("#")
    srgb = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    return (*lin, a)

def mat(name, color, rough=0.6, metal=0.0, emit=0.0):
    m = bpy.data.materials.new(name)
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexc(color)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = hexc(color)
        b.inputs["Emission Strength"].default_value = emit
    return m

# Brand palette (NorthstarTheme.swift)
NAVY = mat("Navy", "#121C33", 0.45)
SNOW = mat("Snow", "#9FB6CC", 0.9)
WHITE = mat("Clinic", "#E8F1F8", 0.5)
AURORA = mat("Aurora", "#3DDC97", 0.55)
GOLD = mat("Starlight", "#F9D98A", 0.3, 0.6, 1.2)
RIM = mat("Rim", "#F9D98A", 0.3, 1.0)
WINDOW = mat("Window", "#FFB020", 0.4, 0.0, 3.0)
SIGNAL = mat("Signal", "#4FA8DC", 0.4, 0.0, 0.9)

def put(obj, m, smooth=False):
    obj.data.materials.append(m)
    if smooth:
        bpy.ops.object.shade_smooth()
    return obj

# Coin base + gold rim
bpy.ops.mesh.primitive_cylinder_add(vertices=128, radius=1.0, depth=0.25, location=(0, 0, -0.125))
put(bpy.context.object, NAVY, True)
bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.045, major_segments=128, minor_segments=24)
put(bpy.context.object, RIM, True)

# Snowy hill
bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=1.0)
hill = bpy.context.object
hill.scale = (0.92, 0.92, 0.14)
put(hill, SNOW, True)

# Pines (left)
def pine(x, y, s):
    gz = 0.1
    for r, d, z, m in ((0.16, 0.30, 0.20, AURORA), (0.12, 0.25, 0.35, AURORA), (0.065, 0.13, 0.47, SNOW)):
        bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=r * s, depth=d * s, location=(x, y, gz + (z - 0.05) * s))
        put(bpy.context.object, m)

pine(-0.52, 0.05, 1.0)
pine(-0.30, -0.28, 0.95)
pine(-0.74, -0.22, 0.85)

# Clinic (right): body, gable roof, lit door + windows
cx, cy, lift = 0.5, 0.0, 0.11  # clinic sits on a small rise, like the 2D mark
bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, location=(cx, cy, 0.04))
mound = bpy.context.object; mound.scale = (0.44, 0.36, 0.13); put(mound, SNOW, True)
bpy.ops.mesh.primitive_cube_add(location=(cx, cy, 0.2 + lift))
body = bpy.context.object
body.scale = (0.2, 0.15, 0.12)
put(body, WHITE)
verts = [(cx - 0.23, cy - 0.18, 0.32), (cx + 0.23, cy - 0.18, 0.32), (cx, cy - 0.18, 0.47),
         (cx - 0.23, cy + 0.18, 0.32), (cx + 0.23, cy + 0.18, 0.32), (cx, cy + 0.18, 0.47)]
verts = [(x, y, z + lift) for x, y, z in verts]
faces = [(0, 1, 2), (3, 5, 4), (0, 2, 5, 3), (1, 4, 5, 2), (0, 3, 4, 1)]
me = bpy.data.meshes.new("Roof"); me.from_pydata(verts, [], faces)
roof = bpy.data.objects.new("Roof", me); scn.collection.objects.link(roof)
roof.data.materials.append(AURORA)
for (x, z, sx, sz) in ((cx, 0.15, 0.04, 0.07), (cx - 0.12, 0.23, 0.035, 0.035), (cx + 0.12, 0.23, 0.035, 0.035)):
    bpy.ops.mesh.primitive_cube_add(location=(x, cy - 0.151, z + lift))
    o = bpy.context.object; o.scale = (sx, 0.002, sz); put(o, WINDOW)

# 2D (512 px scene) -> 3D: pine tip and clinic roof peak line up with the flat mark
K = 1.02 / (flat.B[0] - flat.A[0])
X0, Z0 = 0.5 - (flat.B[0] - flat.STAR_X) * K, 0.58


def to3d(x, y, depth=-0.05):
    return Vector((X0 + (x - flat.STAR_X) * K, depth, Z0 + (flat.A[1] - y) * K))


# Signal: rainbow arc with the EKG beat, as a glowing tube
pts = [tuple(map(float, p.split())) for p in flat.heartbeat_d()[1:].split(" L")]
cu = bpy.data.curves.new("Signal", "CURVE"); cu.dimensions = "3D"
cu.bevel_depth, cu.bevel_resolution = 0.013, 4
sp = cu.splines.new("POLY"); sp.points.add(len(pts) - 1)
for p, (x, y) in zip(sp.points, pts):
    p.co = (*to3d(x, y), 1)
sig = bpy.data.objects.new("Signal", cu); scn.collection.objects.link(sig)
sig.data.materials.append(SIGNAL)
for end in (flat.A, flat.B):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.026, location=to3d(*end))
    put(bpy.context.object, SIGNAL, True)

# North star: faceted 4-point gem, same proportions and position as the flat mark
c = to3d(flat.STAR_X, flat.STAR_Y, 0)
tip = {90: flat.STAR_TOP, 0: flat.STAR_SIDE, -90: flat.STAR_BOTTOM, 180: flat.STAR_SIDE}
outline = []
for ang in (90, 0, -90, 180):
    a, a2 = math.radians(ang), math.radians(ang - 45)
    outline.append((tip[ang] * K * math.cos(a), tip[ang] * K * math.sin(a)))
    outline.append((0.05 * math.cos(a2), 0.05 * math.sin(a2)))
v = [(c.x + x, 0, c.z + z) for x, z in outline] + [(c.x, -0.06, c.z), (c.x, 0.06, c.z)]
f, F, Bk = [], len(outline), len(outline) + 1
for i in range(F):
    j = (i + 1) % F
    f.append((i, j, F)); f.append((j, i, Bk))
me = bpy.data.meshes.new("Star"); me.from_pydata(v, [], f); me.validate()
star = bpy.data.objects.new("NorthStar", me); scn.collection.objects.link(star)
star.data.materials.append(GOLD)

# Lights
def light(kind, loc, energy, color="#FFFFFF", size=None, rot=None):
    d = bpy.data.lights.new(kind, kind); d.energy = energy; d.color = hexc(color)[:3]
    if size: d.size = size
    o = bpy.data.objects.new(kind, d); o.location = loc; scn.collection.objects.link(o)
    if rot: o.rotation_euler = rot
    return o

key = light("AREA", (-2.5, -3.0, 4.0), 380, "#FFF1D6", 3.0)
key.rotation_euler = (Vector((0, 0, 0.4)) - key.location).to_track_quat("-Z", "Y").to_euler()
rim = light("AREA", (2.5, 3.0, 2.5), 600, "#7FC4E8", 3.0)
rim.rotation_euler = (Vector((0, 0, 0.4)) - rim.location).to_track_quat("-Z", "Y").to_euler()
light("POINT", (c.x, -0.4, c.z), 40, "#F9D98A")

# World + camera
w = bpy.data.worlds.new("Night"); scn.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = hexc("#0B1220")
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
cd = bpy.data.cameras.new("Cam"); cd.lens = 74
cam = bpy.data.objects.new("Cam", cd); scn.collection.objects.link(cam)
cam.location = (0, -5.2, 2.2)
cam.rotation_euler = (Vector((0, 0, 0.62)) - cam.location).to_track_quat("-Z", "Y").to_euler()
scn.camera = cam

for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
    try:
        scn.render.engine = eng; break
    except TypeError:
        pass
scn.render.resolution_x = scn.render.resolution_y = 1024
scn.view_settings.view_transform = "Standard"

try:
    ng = bpy.data.node_groups.new("Bloom", "CompositorNodeTree")
    ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    rl = ng.nodes.new("CompositorNodeRLayers"); gl = ng.nodes.new("CompositorNodeGlare"); out = ng.nodes.new("NodeGroupOutput")
    for name, val in (("Type", "Bloom"), ("Quality", "High"), ("Threshold", 1.0), ("Strength", 0.6), ("Size", 0.6)):
        if name in gl.inputs: gl.inputs[name].default_value = val
    ng.links.new(rl.outputs["Image"], gl.inputs["Image"]); ng.links.new(gl.outputs["Image"], out.inputs[0])
    scn.compositing_node_group = ng
    print("BLOOM OK", [i.name for i in gl.inputs])
except Exception as e:
    print("BLOOM FAIL", e)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "northstar-emblem.blend"))
scn.render.film_transparent = False
scn.render.filepath = os.path.join(OUT, "emblem-3d-1024.png"); bpy.ops.render.render(write_still=True)
scn.render.film_transparent = True
scn.render.filepath = os.path.join(OUT, "emblem-3d-transparent.png"); bpy.ops.render.render(write_still=True)
