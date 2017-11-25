#include "./Data/base.shader"

VERT_OUTPUT vert(in VERT_INPUT input)
{
	VERT_OUTPUT output;
	output.location = mul(input.location, _transform);
	output.color = input.color * _color;
	output.uv = input.uv * 2 - float2(1, 1);
	return output;
}
float3 norm(float3 t)
{
	float ta = sqrt(t.x*t.x+ t.y*t.y + t.z*t.z);
	return t/ta;
}
float3 _lightNormal;
float _darkness;
float _haloOuterWidth;
float _haloInnerWidth;
float _haloAnimateSpeed;
float _planetTime;
float _bgDimFactor;
float _grayscaleFactor;

PIX_OUTPUT pix(in VERT_OUTPUT input) : SV_TARGET
{
	float sqrX = input.uv.x * input.uv.x;
	float sqrY = input.uv.y * input.uv.y;
	float dist = sqrt(sqrX + sqrY);
	float haloMax = 1 - _haloOuterWidth;
	float haloMin = haloMax - _haloInnerWidth;
	if(dist > 1 )
		discard;

	float u = atan2(input.uv.y, input.uv.x) / TWO_PI;
	float v = _planetTime * _haloAnimateSpeed;
	float4 ret = _texture.Sample(_texture_SS, float2(u, v));
	if(ret.a > 0)
	{
		
		if(dist >= haloMax)
			ret.a = inverseLerp(haloMax + _haloOuterWidth * ret.a, haloMax, dist);
		else
			ret.a = inverseLerp(haloMin, haloMin + _haloInnerWidth * ret.a, dist);
		
	}

	// Too many instructions for 9.1 era graphics cards, so don't grayscale on those cards.
#ifdef GTE_PS_4_0_level_9_3
	float4 grayscale;
	grayscale.rgb = (ret.r + ret.g + ret.b) / 3;
	grayscale.a = ret.a;
	ret = lerp(ret, grayscale, _bgDimFactor * _grayscaleFactor) * _color;
#endif

	float3 nrml = float3(input.uv.x, input.uv.y, -sqrt(1 - sqrX - sqrY));
	float3 Nt;
	float3 Nb;
	Nt = float3(nrml.z, 0, -nrml.x);
	Nt/=(sqrt(nrml.x * nrml.x + nrml.z * nrml.z)); 
    Nb = float3(cross(nrml,Nt)); 
	
	float3 bumpnormal = float3(0,0,0.7);
	bumpnormal = norm(bumpnormal);
	nrml = float3(bumpnormal.x * Nb.x + bumpnormal.y * nrml.x + bumpnormal.z * Nt.x, 
	
	bumpnormal.x * Nb.y + bumpnormal.y * nrml.y + bumpnormal.z * Nt.y, 
	bumpnormal.x * Nb.z + bumpnormal.y * nrml.z + bumpnormal.z * Nt.z);
	float adark = _darkness;
	if(1 - _darkness>1.01){
		nrml = -nrml;
		adark = -_darkness;
	}
	
	float diffuseFactor = lerp(1 - adark, 1, dot(-_lightNormal, nrml));
	
	float disappearFactor = lerp(0, 1, dot(-_lightNormal, nrml));
	//ret.rgb *= diffuseFactor;
	if(_haloOuterWidth>0.2 || (1 - adark>0.99)){
		disappearFactor=1;
	}
	ret.a *= disappearFactor;
	return ret * input.color;
}