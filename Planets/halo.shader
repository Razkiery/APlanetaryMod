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
	
	return normalize(t);
}




float3 getIntersect(in float3 rayori,in float3 raydir,in float3 n, out float3 normal, out bool found,in float inner,in float outer,float3 pos){
    float denom = dot(n,float3(raydir.x,raydir.y,raydir.z)); 
    found = false;
    if (denom != 0.0) { 
        float3 thing= pos- rayori; 
        float t = dot(thing,n) / denom; 
        normal = (n*sign(-dot(n,raydir)));
        if(t>0.0){
            float3 pointofintersect = (rayori+raydir*t);
            float d = distance(pointofintersect,pos);
            if(d>inner && d<outer){
            	found = true;
                return pointofintersect;
            }
        }
    } 
	found = false;
    return float3(0,0,0);
}

float sqrd(float x){
	return x*x;
}



float3 getSphereIntersect(in float3 rayori,in float3 raydir,in float rad, out bool found,float3 pos ){
    
    
    //float B = 2*(p.dx*(p.x-x) + p.dy*(p.y-y) + p.dz*(p.z-z));
    float B = 2.0*dot(raydir,rayori-pos);
    
 
    float C = sqrd(length(rayori-pos)) - sqrd(rad);
    float D =(B*B - 4.0*C);
      //println(D);
    found = false;
    if(D<0.0 ){
      return float3(0,0,0);
    }
    D = sqrt(D)/2.0;
    if(-B/2.0+D<=0.0){
      return float3(0,0,0);
    }
    found = true;
    if(-B/2.0-D<0.0){
      
      float3 pIn = (rayori+raydir*(-B/2.0+D));
      
     	
      //normal.z*=-1;
      //tIn.z*=-1;
      return pIn;
    }
    float3 pIn = (rayori+raydir*(-B/2.0-D));
    
    
    //normal.z*=-1;
    //tIn.z*=-1;
    return pIn;
  
}



float3 _lightNormal;
float _darkness;
float _haloOuterWidth;
float _haloInnerWidth;
float _haloAnimateSpeed;
float _planetTime;
float _bgDimFactor;
float _grayscaleFactor;
float spin;
float tilt = 30.0;




PIX_OUTPUT pix(in VERT_OUTPUT input) : SV_TARGET
{
	if(input.color.a<0.01){
		float outerrad = 1.2+_haloOuterWidth/3.0;
		float innerrad = 1.2-_haloInnerWidth/3.0;
		float2 uv = input.uv;
		float3 pos = float3(0,0,0);
		pos.xy = float2(0,0); 
		float4 color = float4(0,0,0,0);
		float3 ori = float3(uv.xy,2);
		
		float3 dir = float3((uv.xy)/3.0,-1);
		dir = normalize(dir);
		float3 n = input.color.rgb-0.5;
		n =normalize(n);
		float3 on;
		bool found;
		bool found2;
		bool found3;
		float useless=0;
		float planetrad = 0.50;
		
		float3 f = getIntersect(ori,dir,n,on,found,innerrad,outerrad,pos);
		float3 f2 = getSphereIntersect(ori,dir,planetrad,found2,pos);
		float3 f6 = getIntersect(f,-_lightNormal,_lightNormal,on,found3,0,200,-_lightNormal*10);
		//if(found2 || (found)){
		if(found){
			//if(found2 || (found)){
			if(!found2 || (found&&distance(ori,f)<distance(ori,f2))){
				getSphereIntersect(f,-_lightNormal,planetrad,found3,pos);
				float  fef = distance(pos,f);
				fef = modf((fef),useless);
				color.rgba = _texture.Sample(_texture_SS,float2( modf((fef),useless)*2-1 , 0.3));
				//color.rgba = float4(fef,fef,fef,1);
				if(found3){
					
					color.rgb *=0.2;
				}
			}else{
				//color.rgb = float3(0,0,0);
			}
		}
		if(found2){
			float3 f7 = getIntersect(f2,-_lightNormal,n,on,found3,innerrad,outerrad,pos);
			float  fef = distance(pos,f7);
			float darkam = _texture.Sample(_texture_SS,float2( modf((fef),useless)*2-1 , 0.3)).a;
			//getSphereIntersect(f2*1.01,-_lightNormal,planetrad,found,pos);
			//float3 dark = float3(0,0,0);
			if(found3){	
				color.rgba = float4(color.rgb*color.a ,(1-color.a)*darkam+color.a);
			}
		}
		
		//color.rgb *=0.5-0.7*(distance(f,f6)-9.2);
		//color.rgb*=input.color.rgb;
		return color;
	}
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
	
	float3 bumpnormal = float3(0,0.7,0);
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