#include <flutter/runtime_effect.glsl>
precision highp float;
uniform vec2 viewport;
uniform float focal;
uniform vec3 forwardRay;
uniform vec3 rightRay;
uniform vec3 upRay;
uniform vec3 galacticRow0;
uniform vec3 galacticRow1;
uniform vec3 galacticRow2;
uniform float brightness;
uniform sampler2D panorama;
out vec4 fragColor;
vec3 sampleSky(vec2 uv) {
  return texture(panorama, vec2(fract(uv.x), clamp(uv.y, 0.001, 0.999))).rgb;
}
void main() {
  vec2 pixel = FlutterFragCoord().xy - viewport * 0.5;
  vec3 enu = normalize(forwardRay + rightRay * pixel.x / focal - upRay * pixel.y / focal);
  vec3 gal = vec3(dot(galacticRow0, enu), dot(galacticRow1, enu), dot(galacticRow2, enu));
  vec2 uv = vec2(0.5 - atan(gal.y, gal.x) / 6.28318530718, 0.5 - asin(clamp(gal.z,-1.0,1.0)) / 3.14159265359);
  // Low-pass the archival multi-epoch panorama; live point sources are separate.
  vec2 d = vec2(0.0045, 0.0045);
  vec3 rgb = sampleSky(uv) * 0.36 + (sampleSky(uv+vec2(d.x,0.0)) + sampleSky(uv-vec2(d.x,0.0))
    + sampleSky(uv+vec2(0.0,d.y)) + sampleSky(uv-vec2(0.0,d.y))) * 0.16;
  float band = 1.0 - smoothstep(0.40, 0.85, abs(gal.z));
  fragColor = vec4(rgb * brightness * band, 1.0);
}
