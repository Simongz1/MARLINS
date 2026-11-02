#pragma once
#include "ADReal.h"
#include <utility>

/** Linear acoustic interface velocity and Cauchy traction, expressed in x. */
inline std::pair<ADReal, ADReal>
materialAcousticState(const ADReal & ul, const ADReal & ur,
                      const ADReal & sl, const ADReal & sr,
                      const ADReal & zl, const ADReal & zr, Real nx)
{
  return {(zl*ul+zr*ur+nx*(sr-sl))/(zl+zr),
          (zr*sl+zl*sr+nx*zl*zr*(ur-ul))/(zl+zr)};
}
