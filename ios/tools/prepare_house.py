"""Convert the inspected house using explicit, user-reviewed facade/corner metadata.
Pillow provides geometry review diagrams; Apple USD tools package the native asset.
"""
import json, struct, math, hashlib, zipfile
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[2]
config = json.loads((Path(__file__).parent / 'house-reference.json').read_text())
source = ROOT / config['source']
corner = tuple(config['sourceCornerMeters'])
yaw = math.radians(config['nativeYawDegrees'])
cos_yaw, sin_yaw = math.cos(yaw), math.sin(yaw)
review = ROOT / 'docs/model-review/corrected'
review.mkdir(parents=True, exist_ok=True)
def rotate(p):
    return (cos_yaw*p[0]+sin_yaw*p[2], p[1], -sin_yaw*p[0]+cos_yaw*p[2])
b = source.read_bytes()
size = struct.unpack_from('<I', b, 12)[0]
g = json.loads(b[20:20+size])
binary = b[28+size:]
assert len(g['nodes']) == 1 and len(g['meshes']) == 1 and not g.get('animations')
n = g['nodes'][0]
assert 'matrix' not in n
x,y,z,w = n.get('rotation',[0,0,0,1]); sx,sy,sz = n.get('scale',[1,1,1]); tx,ty,tz = n.get('translation',[0,0,0])
m = [(1-2*y*y-2*z*z)*sx,(2*x*y+2*z*w)*sx,(2*x*z-2*y*w)*sx,
     (2*x*y-2*z*w)*sy,(1-2*x*x-2*z*z)*sy,(2*y*z+2*x*w)*sy,
     (2*x*z+2*y*w)*sz,(2*y*z-2*x*w)*sz,(1-2*x*x-2*y*y)*sz]
def read(i):
    a=g['accessors'][i]; v=g['bufferViews'][a['bufferView']]
    assert not a.get('sparse')
    fmt={5126:'f',5123:'H',5125:'I'}[a['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    form='<'+fmt*count; stride=v.get('byteStride',struct.calcsize(form))
    start=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from(form,binary,start+j*stride) for j in range(a['count'])]
def world(p): return tuple(sum(m[k*3+r]*p[k] for k in range(3))+[tx,ty,tz][r] for r in range(3))
primitives=[]
for pr in g['meshes'][0]['primitives']:
    assert pr.get('mode',4)==4
    pts=[world(p) for p in read(pr['attributes']['POSITION'])]
    ids=[i[0] for i in read(pr['indices'])]
    primitives.append((pr,pts,ids))
all_points = [p for _,pts,_ in primitives for p in pts]
low = [min(p[i] for p in all_points) for i in range(3)]
high = [max(p[i] for p in all_points) for i in range(3)]
center = [(low[i]+high[i])/2 for i in range(3)]
dimensions = [high[i]-low[i] for i in range(3)]
assert all(abs(a-b)<0.01 for a,b in zip(dimensions,[15.2991334877,8.3009296001,13.7675261965])), 'Unexpected house dimensions; review scale before conversion'
reference_points = [p for pr,pts,_ in primitives if g['materials'][pr['material']]['name'] == config['referenceMaterial'] for p in pts]
assert min(sum((p[i]-corner[i])**2 for i in range(3)) for p in reference_points) < 1e-12, 'Reviewed foundation vertex is absent'
colors=['#a64c2d','#e8cdb0','#e5c2a0','#624b37','#aaa29a','#665646','#87bdce','#e1c4a1','#eedbc1','#383b36','#595c60']
# Orthographic geometry review, four diagonals. Painter's algorithm is for inspection only.
for name,ax,az in [('southwest',-1,-1),('southeast',1,-1),('northwest',-1,1),('northeast',1,1)]:
    forward=(ax/math.sqrt(2),.45,az/math.sqrt(2))
    right=(az/math.sqrt(2),0,-ax/math.sqrt(2))
    up=(-.318*ax,1,-.318*az)
    def project(p):
        q=tuple(p[i]-center[i] for i in range(3))
        return (500+28*sum(q[i]*right[i] for i in range(3)),450-28*sum(q[i]*up[i] for i in range(3)))
    faces=[]
    for pr,pts,ids in primitives:
        for j in range(0,len(ids),3):
            tri=[pts[i] for i in ids[j:j+3]]
            depth=sum(sum(p[i]*forward[i] for i in range(3)) for p in tri)/3
            faces.append((depth,[project(p) for p in tri],colors[pr['material']]))
    im=Image.new('RGB',(1000,850),'#d5e0e5'); draw=ImageDraw.Draw(im)
    for depth,tri,color in sorted(faces): draw.polygon(tri,fill=color)
    draw.text((20,20),name+' | source coordinates | Y up | -Z entrance facade',fill='black')
    im.save(review / (name+'.png'))
# Physical camera handedness: viewed from source -Z, source +X appears screen-left.
for name,axis,sign in [('front',2,-1),('left',0,1),('rear',2,1)]:
    faces=[]
    for pr,pts,ids in primitives:
        for j in range(0,len(ids),3):
            tri=[pts[i] for i in ids[j:j+3]]
            projected=[(500+(sign if axis==2 else -sign)*40*(p[0 if axis==2 else 2]-center[0 if axis==2 else 2]),650-50*(p[1]-corner[1])) for p in tri]
            faces.append((sum(sign*p[axis] for p in tri),projected,colors[pr['material']]))
    im=Image.new('RGB',(1000,760),'#d5e0e5'); draw=ImageDraw.Draw(im)
    for _,tri,color in sorted(faces): draw.polygon(tri,fill=color)
    draw.text((20,20),name+' | source geometry elevation',fill='black')
    im.save(review/(name+'.png'))
# Annotate the front elevation with physical screen orientation.
im=Image.open(review/'front.png'); dr=ImageDraw.Draw(im)
px=500-40*(corner[0]-center[0]); py=650
dr.ellipse((px-8,py-8,px+8,py+8),fill='#05aa59',outline='black',width=2)
dr.line((px,py,px-35,py+38),fill='black',width=2)
dr.text((max(10,px-130),py+42),'Origin: user-marked front bay foundation',fill='black')
im.save(review/'front-reference.png')

# Conversion uses the native-render-reviewed foundation corner in source metres.
if __name__=='__main__' and '--convert' not in __import__('sys').argv:
    print('Review images prepared; conversion requires --convert after reference selection.')
    raise SystemExit
import subprocess
out=ROOT/'public/models/ios'; out.mkdir(exist_ok=True)
work=out/'conversion'; work.mkdir(exist_ok=True)
f=lambda v: format(v,'.9g')
vec=lambda p:'('+', '.join(f(x) for x in p)+')'
arr=lambda ps:', '.join(vec(p) for p in ps)
lines=['#usda 1.0','(defaultPrim = "House"\n metersPerUnit = 1\n upAxis = "Y")','def Xform "House" {','def Scope "Materials" {']
for index,mat in enumerate(g['materials']):
 pbr=mat.get('pbrMetallicRoughness',{}); base=pbr.get('baseColorFactor',[1,1,1,1])
 lines += [f'def Material "M{index}" {{',f'token outputs:surface.connect = </House/Materials/M{index}/Surface.outputs:surface>', 'def Shader "Surface" {','uniform token info:id = "UsdPreviewSurface"',f'color3f inputs:diffuseColor = {vec(base[:3])}',f'float inputs:metallic = {f(pbr.get("metallicFactor",1))}',f'float inputs:roughness = {f(pbr.get("roughnessFactor",1))}','token outputs:surface']
 textures=[]
 for role,entry,output in [('diffuseColor',pbr.get('baseColorTexture'),'rgb'),('normal',mat.get('normalTexture'),'rgb'),('roughness',pbr.get('metallicRoughnessTexture'),'g'),('metallic',pbr.get('metallicRoughnessTexture'),'b')]:
  if not entry: continue
  imageIndex=g['textures'][entry['index']]['source']; view=g['bufferViews'][g['images'][imageIndex]['bufferView']]
  raw=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
  filename=f'tex_{imageIndex}.jpg'; (work/filename).write_bytes(raw)
  lines.append(f'{"normal3f" if role=="normal" else "color3f" if output=="rgb" else "float"} inputs:{role}.connect = </House/Materials/M{index}/{role}.outputs:{output}>')
  textures.append((role,output,filename,entry.get('scale',1)))
 lines += ['}','def Shader "UV" {','uniform token info:id = "UsdPrimvarReader_float2"','token inputs:varname = "st"','float2 outputs:result','}']
 for role,output,filename,scale in textures:
  lines += [f'def Shader "{role}" {{','uniform token info:id = "UsdUVTexture"',f'asset inputs:file = @{filename}@',f'float2 inputs:st.connect = </House/Materials/M{index}/UV.outputs:result>',f'token inputs:sourceColorSpace = "{"sRGB" if role=="diffuseColor" else "raw"}"','token inputs:wrapS = "repeat"','token inputs:wrapT = "repeat"']
  if role=='normal': lines += [f'float4 inputs:scale = {vec((2*scale,2*scale,2,1))}',f'float4 inputs:bias = {vec((-scale,-scale,-1,0))}']
  elif role in ['roughness','metallic']:
   factor=pbr.get(role+'Factor',1); lines += [f'float4 inputs:scale = {vec((factor,)*4)}']
  lines += [f'{"float3" if output=="rgb" else "float"} outputs:{output}','}']
 lines += ['}']
lines += ['}']
for index,(pr,pts,ids) in enumerate(primitives):
 points=[rotate(tuple(p[i]-corner[i] for i in range(3))) for p in pts]
 normals=[]
 for normal in read(pr['attributes']['NORMAL']):
  q=[sum(m[k*3+r]*normal[k]/(n.get('scale',[1,1,1])[k]**2) for k in range(3)) for r in range(3)]
  length=math.sqrt(sum(v*v for v in q)); normals.append(rotate(tuple(v/length for v in q)))
 uv=[(u,1-v) for u,v in read(pr['attributes']['TEXCOORD_0'])]
 lines += [f'def Mesh "Mesh{index}" (prepend apiSchemas = ["MaterialBindingAPI"]) {{',f'point3f[] points = [{arr(points)}]',f'int[] faceVertexCounts = [{", ".join(["3"]*(len(ids)//3))}]',f'int[] faceVertexIndices = [{", ".join(map(str,ids))}]',f'normal3f[] normals = [{arr(normals)}] (interpolation = "vertex")',f'texCoord2f[] primvars:st = [{arr(uv)}] (interpolation = "vertex")','uniform token subdivisionScheme = "none"','uniform bool doubleSided = true',f'rel material:binding = </House/Materials/M{pr["material"]}>','}']
lines += ['}']
(work/'house.usda').write_text('\n'.join(lines)+'\n')
subprocess.run(['usdcat',str(work/'house.usda'),'-o',str(work/'house.usdc')],check=True)
asset=out/'house2story.usdz'
if asset.exists(): asset.unlink()
subprocess.run(['usdzip',str(asset),'house.usdc']+[p.name for p in sorted(work.glob('tex_*.jpg'))],cwd=work,check=True)
subprocess.run(['usdcat','--loadOnly',str(asset)],check=True)
with zipfile.ZipFile(asset) as z:
 assert len(z.namelist()) == 31
 for info in z.infolist():
  with asset.open('rb') as fp:
   fp.seek(info.header_offset); h=fp.read(30); namelen,extra=struct.unpack_from('<HH',h,26)
  assert (info.header_offset+30+namelen+extra)%64==0
  assert info.compress_type==zipfile.ZIP_STORED
normalized = [rotate(tuple(p[i]-corner[i] for i in range(3))) for p in all_points]
metadata = {
 'source': config['source'], 'sourceSHA256': hashlib.sha256(b).hexdigest(),
 'assetSHA256': hashlib.sha256(asset.read_bytes()).hexdigest(), 'metersPerUnit': 1,
 'sourceReferenceMeters': corner, 'reference': config['reference'],
 'referenceImage': config['referenceImage'], 'sourceFrontDirection': config['sourceFrontDirection'],
 'nativeYawDegrees': config['nativeYawDegrees'], 'frontDirection': [0,0,1],
 'rightDirection': [1,0,0], 'rearDirection': [0,0,-1], 'dimensionsMeters': dimensions,
 'nativeBoundsMinMeters': [min(p[i] for p in normalized) for i in range(3)],
 'nativeBoundsMaxMeters': [max(p[i] for p in normalized) for i in range(3)],
 'visualReview': 'User red-arrow reference identifies the front bay corner; converted native render must match facade, garage and porch. Phone confirmation remains required.',
 'triangleCount': sum(len(ids)//3 for _,_,ids in primitives)
}
(out/'house2story-metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
print(json.dumps(metadata,indent=2))
