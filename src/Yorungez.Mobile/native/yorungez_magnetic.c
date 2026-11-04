/* Original wrapper Apache-2.0; pinned NOAA/NCEI WMM2025 public-domain core.
 * https://www.ncei.noaa.gov/products/world-magnetic-model
 * Height km above WGS84 ellipsoid; no geoid/file I/O or user-data logging.
 */
#include <stddef.h>
#include <math.h>
#include "../../../third-party/wmm2025/GeomagnetismHeader.h"
#include "wmm_coefficients.h"
#if defined(_WIN32)
#define YG_EXPORT __declspec(dllexport)
#else
#define YG_EXPORT __attribute__((visibility("default"), used))
#endif
YG_EXPORT int yg_magnetic_abi(void) { return 1; }
// Result declination degrees east, model uncertainty degrees, horizontal nT.
YG_EXPORT int yg_magnetic(double year,double lat,double lon,double height,double *out) {
    if(!out || !isfinite(year) || year<2025 || year>=2030 || !isfinite(lat) || fabs(lat)>=89 ||
        !isfinite(lon) || fabs(lon)>180 || !isfinite(height) || height<-.5 || height>100) return 1;
    MAGtype_MagneticModel *base=MAG_AllocateModelMemory(91),*timed=MAG_AllocateModelMemory(91);
    if(!base || !timed) { if(base) MAG_FreeMagneticModelMemory(base); if(timed) MAG_FreeMagneticModelMemory(timed); return 2; }
    base->epoch=2025; base->nMax=12;base->nMaxSecVar=12;base->CoefficientFileEndDate=2030;
    for(int i=0;i<90;i++) {
        const double *row=yg_wmm_coefficients[i];int n=(int)row[0],m=(int)row[1],index=n*(n+1)/2+m;
        base->Main_Field_Coeff_G[index]=row[2];base->Main_Field_Coeff_H[index]=row[3];
        base->Secular_Var_Coeff_G[index]=row[4];base->Secular_Var_Coeff_H[index]=row[5];
    }
    MAGtype_Ellipsoid ellipsoid;MAGtype_Geoid geoid;MAG_SetDefaults(&ellipsoid,&geoid);
    MAGtype_CoordGeodetic observer={lon,lat,height,0,0};MAGtype_CoordSpherical spherical;
    MAGtype_Date date={0,0,0,year};MAGtype_GeoMagneticElements elements,errors;
    MAG_GeodeticToSpherical(ellipsoid,observer,&spherical);
    MAG_TimelyModifyMagneticModel(date,base,timed);
    int success=MAG_Geomag(ellipsoid,spherical,observer,timed,&elements);
    MAG_WMMErrorCalc(elements.H,&errors);
    out[0]=elements.Decl;out[1]=errors.Decl;out[2]=elements.H;
    MAG_FreeMagneticModelMemory(base);MAG_FreeMagneticModelMemory(timed);
    return success && isfinite(out[0]) && isfinite(out[1]) && isfinite(out[2]) ? 0 : 2;
}
