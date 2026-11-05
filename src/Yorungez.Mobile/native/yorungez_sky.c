/* Yorungez bulk ABI v2. Original wrapper: Apache-2.0.
 * Upstream Astronomy Engine 2.1.19 is unmodified and separately MIT licensed.
 * Call from one serial calculation worker; never from the sensor callback.
 */
#include <math.h>
#include "../../../third-party/astronomy-engine/source/c/astronomy.h"

#if defined(_WIN32)
#define YG_EXPORT __declspec(dllexport)
#else
#define YG_EXPORT __attribute__((visibility("default"), used))
#endif

YG_EXPORT int yg_abi_version(void) { return 2; }

/* Planning ABI: [count, initiallyAbove, (unixSeconds, rises)*8]. Standard
 * sea-level rise/set, 34 arcmin refraction and Sun/Moon upper limb, exactly as
 * the Web planner. Invoked only on the same serial worker as yg_sky. */
YG_EXPORT int yg_crossings(double start, double end, double lat, double lon,
    int index, double *out, int length)
{
    const astro_body_t bodies[9] = {BODY_SUN, BODY_MOON, BODY_MERCURY,
        BODY_VENUS, BODY_MARS, BODY_JUPITER, BODY_SATURN, BODY_URANUS, BODY_NEPTUNE};
    if (!out || length != 18 || index < 0 || index > 8 || !isfinite(start) ||
        !isfinite(end) || start < 946684800 || end > 2082758400 ||
        end <= start || end-start > 27*3600 || !isfinite(lat) || fabs(lat)>=89 ||
        !isfinite(lon) || fabs(lon)>180) return 1;
    astro_observer_t observer = Astronomy_MakeObserver(lat, lon, 0);
    astro_time_t begin = Astronomy_TimeFromDays((start-946728000.0)/86400.0);
    int count = 0;
    for (int direction = -1; direction <= 1; direction += 2) {
        astro_time_t cursor = begin;
        for (int n = 0; n < 4; ++n) {
            double left = (end - (cursor.ut*86400.0+946728000.0))/86400.0;
            astro_search_result_t found = Astronomy_SearchRiseSet(bodies[index], observer,
                (astro_direction_t)direction, cursor, left);
            if (found.status == ASTRO_SEARCH_FAILURE) break;
            if (found.status != ASTRO_SUCCESS) return 2;
            double time = found.time.ut*86400.0+946728000.0;
            if (time >= end) break;
            out[2+2*count] = time; out[3+2*count] = direction == 1; ++count;
            cursor = Astronomy_AddDays(found.time, 1.0/86400.0);
        }
    }
    for (int i = 0; i < count; ++i) for (int j = i+1; j < count; ++j)
        if (out[2+2*j] < out[2+2*i]) {
            double t=out[2+2*i], up=out[3+2*i]; out[2+2*i]=out[2+2*j];
            out[3+2*i]=out[3+2*j]; out[2+2*j]=t; out[3+2*j]=up;
        }
    out[0]=count;
    if (count) out[1]=!out[3];
    else {
        astro_equatorial_t eq = Astronomy_Equator(bodies[index], &begin, observer, EQUATOR_OF_DATE, ABERRATION);
        if (eq.status) return 2;
        astro_horizon_t h = Astronomy_Horizon(&begin, observer, eq.ra, eq.dec, REFRACTION_NONE);
        double radius = index == 0 ? 695700 : index == 1 ? 1737.4 : 0;
        out[1] = h.altitude + asin(radius/(eq.dist*KM_PER_AU))*RAD2DEG + 34.0/60 > 0;
    }
    return 0;
}

/* Output: 9 solar records [az,alt,RA-of-date,Dec-of-date,AU,mag,radius-deg,illuminated-fraction],
 * star [az,alt] pairs, DSO [az,alt] pairs, row-major EQJ-to-ENU matrix.
 * Input star records: Cartesian pc position followed by pc/year velocity.
 * DSO records: J2000 RA hours and declination degrees.
 * UTC Unix seconds; elevation metres relative to model reference ellipsoid.
 * Airless topocentric apparent body centre. 2000 <= year < 2036.
 * Polar azimuth is intentionally unsupported, matching the product boundary.
 */
YG_EXPORT int yg_sky(double utc, double lat, double lon, double elevation,
    const double *stars, int star_count, const double *dsos, int dso_count,
    double *out, int out_count)
{
    const astro_body_t bodies[9] = {BODY_SUN, BODY_MOON, BODY_MERCURY,
        BODY_VENUS, BODY_MARS, BODY_JUPITER, BODY_SATURN, BODY_URANUS, BODY_NEPTUNE};
    const double radii[9] = {695700, 1737.4, 2439.7, 6051.8, 3389.5,
        69911, 58232, 25362, 24622};
    if (!out || !isfinite(utc) || utc < 946684800 || utc >= 2082758400 ||
        !isfinite(lat) || fabs(lat) >= 89 || !isfinite(lon) || fabs(lon) > 180 ||
        !isfinite(elevation) || elevation < -500 || elevation > 100000 ||
        star_count < 0 || star_count > 100000 || dso_count < 0 || dso_count > 100000 ||
        (star_count && !stars) || (dso_count && !dsos) ||
        out_count != 81 + 2 * star_count + 2 * dso_count) return 1;
    astro_time_t time = Astronomy_TimeFromDays((utc - 946728000.0) / 86400.0);
    astro_observer_t observer = Astronomy_MakeObserver(lat, lon, elevation);
    astro_rotation_t rotation = Astronomy_Rotation_EQJ_HOR(&time, observer);
    astro_state_vector_t earth = Astronomy_BaryState(BODY_EARTH, time);
    astro_vector_t site = Astronomy_ObserverVector(&time, observer, EQUATOR_J2000);
    if (rotation.status || earth.status || site.status) return 2;
    for (int i = 0; i < 9; ++i) {
        astro_equatorial_t eq = Astronomy_Equator(bodies[i], &time, observer,
            EQUATOR_OF_DATE, ABERRATION);
        astro_illum_t illum = Astronomy_Illumination(bodies[i], time);
        if (eq.status || illum.status) return 2;
        astro_horizon_t h = Astronomy_Horizon(&time, observer, eq.ra, eq.dec, REFRACTION_NONE);
        double *o = out + 8 * i;
        o[0] = h.azimuth; o[1] = h.altitude; o[2] = eq.ra; o[3] = eq.dec;
        o[4] = eq.dist; o[5] = illum.mag;
        o[6] = atan(radii[i] / (eq.dist * KM_PER_AU)) * RAD2DEG;
        o[7] = illum.phase_fraction;
    }
    double years = time.tt / 365.25;
    const double au_per_pc = 648000.0 / 3.14159265358979323846;
    double beta[3] = {earth.vx / C_AUDAY, earth.vy / C_AUDAY, earth.vz / C_AUDAY};
    for (int i = 0; i < star_count; ++i) {
        const double *s = stars + 6 * i;
        for (int j = 0; j < 6; ++j) if (!isfinite(s[j])) return 1;
        double p[3] = {(s[0]+s[3]*years)*au_per_pc-earth.x-site.x,
            (s[1]+s[4]*years)*au_per_pc-earth.y-site.y,
            (s[2]+s[5]*years)*au_per_pc-earth.z-site.z};
        double length = hypot(hypot(p[0], p[1]), p[2]);
        if (length <= 0 || !isfinite(length)) return 1;
        for (int j = 0; j < 3; ++j) p[j] /= length;
        double dot = p[0]*beta[0]+p[1]*beta[1]+p[2]*beta[2];
        for (int j = 0; j < 3; ++j) p[j] += beta[j]-dot*p[j];
        astro_vector_t v = {ASTRO_SUCCESS, p[0], p[1], p[2], time};
        astro_spherical_t h = Astronomy_HorizonFromVector(Astronomy_RotateVector(rotation, v), REFRACTION_NONE);
        if (h.status) return 2;
        out[72+2*i] = h.lon; out[73+2*i] = h.lat;
    }
    int offset = 72 + 2 * star_count;
    for (int i = 0; i < dso_count; ++i) {
        double ra = dsos[2*i], dec = dsos[2*i+1];
        if (!isfinite(ra) || ra < 0 || ra >= 24 || !isfinite(dec) || fabs(dec)>90) return 1;
        ra *= HOUR2RAD; dec *= DEG2RAD;
        astro_vector_t v = {ASTRO_SUCCESS, cos(dec)*cos(ra), cos(dec)*sin(ra), sin(dec), time};
        astro_spherical_t h = Astronomy_HorizonFromVector(Astronomy_RotateVector(rotation, v), REFRACTION_NONE);
        if (h.status) return 2;
        out[offset+2*i] = h.lon; out[offset+2*i+1] = h.lat;
    }
    offset += 2 * dso_count;
    for (int col = 0; col < 3; ++col) {
        astro_vector_t v = {ASTRO_SUCCESS, col==0, col==1, col==2, time};
        v = Astronomy_RotateVector(rotation, v);
        out[offset+col] = -v.y; out[offset+3+col] = v.x; out[offset+6+col] = v.z;
    }
    for (int i = 0; i < out_count; ++i) if (!isfinite(out[i])) return 2;
    return 0;
}
