/* Original Yorungez wrapper: Apache-2.0.
 * Propagator: Vallado, Crawford, Hujsak and Kelso, AIAA 2006-6753.
 * https://celestrak.org/publications/AIAA/2006-6753/
 * Source use permission/citation: https://celestrak.org/publications/AIAA/2006-6753/faq.php
 * OMM Earth/TEME/UTC/SGP4, WGS72 gravity; UT1=UTC, polar motion=0.
 * Observer: WGS84 geodetic; no refraction or visibility/weather prediction.
 */
#include <cmath>
#include "../../../third-party/sgp4/SGP4.h"
#if defined(_WIN32)
#define YG_EXPORT extern "C" __declspec(dllexport)
#else
#define YG_EXPORT extern "C" __attribute__((visibility("default"), used))
#endif
YG_EXPORT int yg_satellite_abi(void) { return 1; }
// Elements: epoch Unix seconds, BSTAR, mean-motion derivative rev/day²,
// second derivative rev/day³, eccentricity, argument of pericentre degrees,
// inclination degrees, mean anomaly degrees, mean motion rev/day, RAAN degrees.
// Output: TEME position km (3), velocity km/s (3), azimuth/elevation degrees, range km.
YG_EXPORT int yg_satellite(const double *e, double utc, double lat, double lon,
    double elevation, double *out, int count) {
    if (!e || !out || count != 9) return 1;
    for (int i=0;i<10;i++) if (!std::isfinite(e[i])) return 1;
    if (!std::isfinite(utc) || !std::isfinite(lat) || std::abs(lat)>=89 ||
        !std::isfinite(lon) || std::abs(lon)>180 || !std::isfinite(elevation) ||
        elevation < -500 || elevation > 100000 || std::abs(utc-e[0])>7*86400 ||
        e[0]<-631152000 || e[0]>2745532800 || e[4]<0 || e[4]>=1 ||
        e[6]<0 || e[6]>180 || e[8]<=0 || e[8]>20) return 1;
    const double pi=3.14159265358979323846, rad=pi/180, day=86400;
    elsetrec sat = {};
    if (!SGP4Funcs::sgp4init(wgs72,'a',"25544",e[0]/day+2440587.5-2433281.5,
        e[1],e[2]*2*pi/(1440*1440),e[3]*2*pi/(1440.0*1440*1440),e[4],e[5]*rad,
        e[6]*rad,e[7]*rad,e[8]*2*pi/1440,e[9]*rad,sat) || sat.error) return 2;
    if (!SGP4Funcs::sgp4(sat,(utc-e[0])/60,out,out+3) || sat.error) return 2;
    const double theta=SGP4Funcs::gstime_SGP4(utc/day+2440587.5);
    const double x=out[0]*cos(theta)+out[1]*sin(theta), y=-out[0]*sin(theta)+out[1]*cos(theta), z=out[2];
    const double phi=lat*rad,lambda=lon*rad,esq=6.6943799901413165e-3;
    const double n=6378.137/sqrt(1-esq*sin(phi)*sin(phi)),h=elevation/1000;
    const double dx=x-(n+h)*cos(phi)*cos(lambda),dy=y-(n+h)*cos(phi)*sin(lambda),dz=z-(n*(1-esq)+h)*sin(phi);
    const double east=-sin(lambda)*dx+cos(lambda)*dy;
    const double north=-sin(phi)*cos(lambda)*dx-sin(phi)*sin(lambda)*dy+cos(phi)*dz;
    const double up=cos(phi)*cos(lambda)*dx+cos(phi)*sin(lambda)*dy+sin(phi)*dz;
    out[6]=fmod(atan2(east,north)/rad+360,360);
    out[7]=atan2(up,hypot(east,north))/rad;out[8]=hypot(hypot(east,north),up);
    for(int i=0;i<9;i++) if(!std::isfinite(out[i])) return 2;
    return 0;
}
