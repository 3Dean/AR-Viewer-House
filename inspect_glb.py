import json, struct, math
from pathlib import Path

p = Path('house2story.glb')
b = p.read_bytes()
magic, version, length = struct.unpack_from('<III', b)
chunks = []
offset = 12
while offset < len(b):
    size, kind = struct.unpack_from('<II', b, offset)
    chunks.append((kind, b[offset+8:offset+8+size]))
    offset += 8 + size
g = json.loads(chunks[0][1])
binary = next((data for kind, data in chunks if kind == 0x004E4942), b'')
def mul(a, c):
    return [sum(a[k*4+r]*c[col*4+k] for k in range(4)) for col in range(4) for r in range(4)]
identity = [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
def matrix(n):
    if 'matrix' in n: return n['matrix']
    x,y,z,w = n.get('rotation', [0,0,0,1])
    sx,sy,sz = n.get('scale', [1,1,1])
    tx,ty,tz = n.get('translation', [0,0,0])
    return [(1-2*y*y-2*z*z)*sx,(2*x*y+2*z*w)*sx,(2*x*z-2*y*w)*sx,0,
            (2*x*y-2*z*w)*sy,(1-2*x*x-2*z*z)*sy,(2*y*z+2*x*w)*sy,0,
            (2*x*z+2*y*w)*sz,(2*y*z-2*x*w)*sz,(1-2*x*x-2*y*y)*sz,0,tx,ty,tz,1]
def positions(i):
    a = g['accessors'][i]
    v = g['bufferViews'][a['bufferView']]
    start = v.get('byteOffset',0) + a.get('byteOffset',0)
    stride = v.get('byteStride',12)
    if a['componentType'] != 5126 or a['type'] != 'VEC3': raise ValueError('Unexpected position format')
    return [struct.unpack_from('<fff', binary, start+j*stride) for j in range(a['count'])]
low = [math.inf]*3
high = [-math.inf]*3
vertices = triangles = 0
mesh_bounds = []
def visit(i, parent):
    global vertices, triangles
    n = g['nodes'][i]
    m = mul(parent, matrix(n))
    if 'mesh' in n:
        nl, nh = [math.inf]*3, [-math.inf]*3
        for pr in g['meshes'][n['mesh']]['primitives']:
            pts = positions(pr['attributes']['POSITION'])
            vertices += len(pts)
            count = g['accessors'][pr['indices']]['count'] if 'indices' in pr else len(pts)
            if pr.get('mode',4) == 4: triangles += count//3
            for pt in pts:
                q = [sum(m[k*4+r]*pt[k] for k in range(3))+m[12+r] for r in range(3)]
                for r in range(3):
                    low[r] = min(low[r],q[r]); high[r] = max(high[r],q[r])
                    nl[r] = min(nl[r],q[r]); nh[r] = max(nh[r],q[r])
        mesh_bounds.append({'node':i,'name':n.get('name'),'min':nl,'max':nh})
    for c in n.get('children',[]): visit(c,m)
scene = g.get('scene',0)
for i in g['scenes'][scene]['nodes']: visit(i,identity)
report = {'file':str(p),'bytes':len(b),'valid_header':magic==0x46546C67 and length==len(b),'version':version,
 'asset':g.get('asset'),'extensionsUsed':g.get('extensionsUsed',[]),'extensionsRequired':g.get('extensionsRequired',[]),
 'scene':scene,'nodes':g.get('nodes',[]),'mesh_count':len(g.get('meshes',[])),
 'primitive_count':sum(len(m['primitives']) for m in g.get('meshes',[])),
 'vertices_instanced':vertices,'triangles_instanced':triangles,'bounds_min':low,'bounds_max':high,
 'dimensions':[high[i]-low[i] for i in range(3)],'mesh_bounds':mesh_bounds,
 'materials':g.get('materials',[]),'images':g.get('images',[]),'textures':g.get('textures',[]),
 'animations':len(g.get('animations',[])),'external_uris':[x['uri'] for key in ['buffers','images'] for x in g.get(key,[]) if 'uri' in x]}
Path('house2story-inspection.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k not in ['nodes','materials','images','textures','mesh_bounds']},indent=2))
print('Nodes:',json.dumps(report['nodes']))
print('Materials:',json.dumps(report['materials']))
print('Images:',json.dumps(report['images']))
