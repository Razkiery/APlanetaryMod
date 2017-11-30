#include "./Data/base.shader"

VERT_OUTPUT vert(in VERT_INPUT input)
{
	VERT_OUTPUT output;
	output.location = mul(input.location, _transform);
	output.color = input.color * _color;
	output.uv = input.uv * 2 - float2(1, 1);
	return output;
}

float _rotSpeed;
float3 _lightNormal;
float _darkness;
float _planetTime;
float _bgDimFactor;
float _grayscaleFactor;



float maxOf(float4 t)
{
	float ta = max(max(t.x, t.y), t.z);
	return ta;
}
float minOf(float4 t)
{
	float ta = min(min(t.x, t.y), t.z);
	return ta;
}
float3 norm(float3 t)
{
	float ta = sqrt(t.x*t.x+ t.y*t.y + t.z*t.z);
	return t/ta;
}
float cub(float t){
	return t*t*t;
}

float3 hsl(in float4 col){
	float maxe = maxOf(col);
	float mine = minOf(col);
	float f = maxe-mine;
	float hue;
	if(col.x == maxe){
		hue= 60*((col.g-col.b)/f);
	}else if(col.y == maxe){
		hue= 60*(2+(col.b-col.r)/f);
	}else{
		hue= 60*(4+(col.r-col.g)/f);
	}
	hue = (hue+360.0)%360.0;
	
	return float3(hue,f/(1-abs((maxe+mine)-1.0)),(maxe+mine)/2.0);
	
}
bool between(float x,float mine,float maxe){
	return x>mine && x<maxe;
}


PIX_OUTPUT pix(in VERT_OUTPUT input) : SV_TARGET
{
	float bumpstep = 0.002;
	float sqrX = input.uv.x * input.uv.x;
	float sqrY = input.uv.y * input.uv.y;
	if(sqrX + sqrY > 1)
		discard;

	

	float width = sqrt(1 - input.uv.y * input.uv.y);
	float iuvx = input.uv.x;
	input.uv.x = (-acos(input.uv.x / width) / PI * 2 + 1);

	float2 uv = float2(
		(input.uv.x + 1) / 4 + _planetTime * _rotSpeed,
		(input.uv.y + 1) / 2);

	float4 ret = _texture.Sample(_texture_SS, uv);
	//ret.a=1;
	ret*= input.color;
	
	float hmid = (_texture.Sample(_texture_SS, uv).a);
	float4 grayscale;
	grayscale.rgb = (ret.r + ret.g + ret.b) / 3;
	grayscale.a = ret.a;
	ret = lerp(ret, grayscale, _bgDimFactor * _grayscaleFactor) * _color;
		
	float top = (_texture.Sample(_texture_SS, uv + float2(0,-bumpstep)).a);	
	float bot = (_texture.Sample(_texture_SS, uv + float2(0,bumpstep)).a);	
	float lef = (_texture.Sample(_texture_SS, uv + float2(-bumpstep,0)).a);	
	float rig = (_texture.Sample(_texture_SS, uv + float2(bumpstep,0)).a);	
	
	float3 bumpnormal;
	
	float3 nrml = float3(iuvx, input.uv.y, -sqrt(1 - sqrX - sqrY));
	float3 Nt;
	float3 Nb;
	Nt = float3(nrml.z, 0, -nrml.x);
	Nt/=(sqrt(nrml.x * nrml.x + nrml.z * nrml.z)); 
    Nb = float3(cross(nrml,Nt)); 
	//ret.rgb=-nrml;
	bool clouds = (grayscale.r>=0.999);
	float cloudadd= 0;
	float alpha = ret.a;
	float dim = max(0,dot(_lightNormal, nrml))*2;
	float dim2 = max(0,dot(float3(0,0,0.8), Nt))*5;
	float3 bnrml = nrml;
	if(!clouds){
	//,
		bumpnormal = float3(bot - hmid + (hmid-top),0.12,rig - hmid + (hmid-lef));
		
	}else{
		bumpnormal = float3(rig - hmid + (hmid-lef),0.7,bot - hmid + (hmid-top));
		cloudadd = cub(1-hmid)-0.3;
		
	}
	bumpnormal = norm(bumpnormal);
	nrml = float3(bumpnormal.x * Nb.x + bumpnormal.y * nrml.x + bumpnormal.z * Nt.x, 
			  bumpnormal.x * Nb.y + bumpnormal.y * nrml.y + bumpnormal.z * Nt.y, 
			  bumpnormal.x * Nb.z + bumpnormal.y * nrml.z + bumpnormal.z * Nt.z);
	float adark = 0;
	if(1 - _darkness>0.5){
		adark = 1 - _darkness;
	}
	float crescentness = cub(max(1,2*(dot(-_lightNormal, float3(0,1,0)))));
	
	float diffuseFactor = lerp(adark, 1, (dot(-_lightNormal, nrml)) - dim);			
	//diffuseFactor*=crescentness;
	//diffuseFactor += min(max(adark, 2*(0.22+dot(float3(0.8,0,0), nrml)- dim2)),0.2);;
	float3 hslret = hsl(ret);
	if(between(hslret.x,190,240)&&between(hslret.z*100,14,65)&&adark<0.01){
		ret.rgb*=(diffuseFactor);
		ret.rgb += cub(cub(max(0,dot(-_lightNormal, bnrml))));
	}else{
		ret.rgb*=(diffuseFactor);
	}
	//ret.rgb = nrml;
	ret.a=alpha;
	//ret.a-=crescentness/5.0;
	//ret.rgb = bumpnormal;
	return ret;
}